# Critical Infrastructure Additions - Round 3

## 🎯 Overview

This document contains **3 essential production infrastructure features** that complete the observability and reliability stack.

---

## 1. 📋 Centralized Structured Logging (Serilog + Seq)

### Problem: Jaeger Shows Traces, Not Logs

> **What Jaeger Gives You**: "This request took 2.3 seconds and failed at AuthService"
> 
> **What Jaeger DOESN'T Give You**: "Why? What was the exception? What were the variable values?"

**Current Gap**: You have distributed tracing but no centralized log aggregation. When an error occurs:
1. Find TraceId in Jaeger ✅
2. SSH into Docker container
3. Run `docker logs auth-service | grep "abc123"`
4. Repeat for 7 different services 😫

---

### Solution: Serilog + Seq

**Serilog** = Structured logging library for .NET  
**Seq** = Centralized log viewer with powerful queries

#### Why Seq over ELK Stack?

| Feature | Seq | ELK Stack |
|---------|-----|-----------|
| .NET Integration | Perfect (native) | Good (via Filebeat) |
| Query Language | SQL-like, simple | Lucene, complex |
| Setup Complexity | 1 Docker container | 3 containers (E+L+K) |
| Free Tier | 50GB/day | Unlimited (self-hosted) |
| **Recommendation** | ✅ For .NET teams | For polyglot teams |

---

### Implementation

#### Step 1: Add Serilog to All Services

**NuGet Packages** (every microservice):
```xml
<PackageReference Include="Serilog.AspNetCore" Version="8.0.0" />
<PackageReference Include="Serilog.Sinks.Seq" Version="6.0.0" />
<PackageReference Include="Serilog.Enrichers.Environment" Version="2.3.0" />
<PackageReference Include="Serilog.Enrichers.Thread" Version="3.1.0" />
<PackageReference Include="Serilog.Enrichers.Span" Version="3.1.0" />
```

#### Step 2: Configure Serilog (Program.cs)

```csharp
using Serilog;
using Serilog.Enrichers.Span;
using Serilog.Events;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithThreadId()
    .Enrich.WithSpan() // ⭐ Adds TraceId and SpanId from OpenTelemetry
    .Enrich.WithProperty("Service", "AuthService") // Change per service
    .Enrich.WithProperty("Environment", builder.Environment.EnvironmentName)
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {TraceId} {Message:lj}{NewLine}{Exception}"
    )
    .WriteTo.Seq(
        serverUrl: builder.Configuration["Seq:ServerUrl"] ?? "http://seq:5341",
        apiKey: builder.Configuration["Seq:ApiKey"] // Optional
    )
    .CreateLogger();

builder.Host.UseSerilog();

var app = builder.Build();

// Request logging middleware
app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("UserId", httpContext.User.FindFirst("sub")?.Value);
        diagnosticContext.Set("ClientIP", httpContext.Connection.RemoteIpAddress);
        diagnosticContext.Set("UserAgent", httpContext.Request.Headers["User-Agent"].ToString());
    };
});

app.Run();
```

#### Step 3: Usage in Code

**Structured Logging (NOT string interpolation!)**:

```csharp
public class AuthService
{
    private readonly ILogger<AuthService> _logger;

    public async Task<LoginResult> LoginAsync(string email, string password)
    {
        // ✅ CORRECT: Structured (properties stored separately)
        _logger.LogInformation("User login attempt for {Email}", email);

        try
        {
            var user = await _userRepository.FindByEmailAsync(email);
            
            if (user == null)
            {
                _logger.LogWarning("Login failed: User not found {Email}", email);
                return LoginResult.Failed("Invalid credentials");
            }

            if (!VerifyPassword(password, user.PasswordHash))
            {
                _logger.LogWarning(
                    "Login failed: Invalid password {Email} {UserId}",
                    email,
                    user.Id
                );
                return LoginResult.Failed("Invalid credentials");
            }

            // Success
            _logger.LogInformation(
                "User logged in successfully {Email} {UserId} {Role}",
                email,
                user.Id,
                user.Role
            );

            return LoginResult.Success(user);
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Unexpected error during login {Email}",
                email
            );
            throw;
        }
    }
}

// ❌ WRONG: String interpolation (loses structure)
_logger.LogInformation($"User {email} logged in");
```

---

#### Step 4: Docker Compose - Add Seq

```yaml
  seq:
    image: datalust/seq:latest
    ports:
      - "5341:80"      # Seq UI
      - "5342:5341"    # Ingestion
    environment:
      - ACCEPT_EULA=Y
    volumes:
      - seq-data:/data

volumes:
  seq-data:
```

#### Step 5: Update Service Environment Variables

```yaml
  auth-service:
    environment:
      - Seq__ServerUrl=http://seq:5341
      - Seq__ApiKey=${SEQ_API_KEY}  # Optional for production
```

---

### Seq Query Examples

After deployment, visit: `http://localhost:5341`

**Query 1: All logs for a specific TraceId**
```
TraceId = 'abc123'
```

**Query 2: All failed login attempts**
```
@Message like '%Login failed%' 
and Email is not null
```

**Query 3: Errors in PaymentService in last hour**
```
Service = 'PaymentService'
and @Level = 'Error'
and @Timestamp > Now() - 1h
```

**Query 4: Slow requests (>2 seconds)**
```
RequestPath is not null
and Elapsed > 2000
order by Elapsed desc
```

---

### Jaeger + Seq Integration

**The Power Combo**:
1. User reports error
2. Go to Jaeger → Find slow request → Get TraceId: `abc123`
3. Go to Seq → Query: `TraceId = 'abc123'`
4. See **all logs** from all services for that request
5. Find exact exception: `NullReferenceException: User.Email was null`

**Timeline Impact**: +2 days for Serilog setup across all services

---

## 2. 🛡️ Resilience & Fault Tolerance (Polly)

### Problem: Cascading Failures

**Scenario**:
```
1. User clicks "Satın Al" (Purchase)
2. Flutter → API Gateway → PaymentService → iyzico API
3. iyzico API hangs for 30 seconds (network issue)
4. PaymentService times out
5. Gateway times out
6. User sees "500 Server Error"
7. User clicks again
8. Problem repeats
9. All threads blocked waiting for iyzico
10. Entire system becomes unresponsive 💥
```

This is a **Cascading Failure** (Domino Effect).

---

### Solution: Polly Resilience Patterns

**Polly** = .NET resilience library with retry, circuit breaker, timeout policies

#### Install Polly

```xml
<PackageReference Include="Microsoft.Extensions.Http.Polly" Version="8.0.0" />
<PackageReference Include="Polly.Extensions.Http" Version="3.0.0" />
```

---

### Pattern 1: Retry Policy

**Use Case**: Temporary network glitches, transient database locks

```csharp
using Polly;
using Polly.Extensions.Http;

// In Program.cs or Startup
builder.Services.AddHttpClient<IListingService, ListingService>()
    .AddPolicyHandler(GetRetryPolicy())
    .AddPolicyHandler(GetCircuitBreakerPolicy());

static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy()
{
    return HttpPolicyExtensions
        .HandleTransientHttpError() // 5xx or 408
        .Or<TimeoutException>()
        .WaitAndRetryAsync(
            retryCount: 3,
            sleepDurationProvider: retryAttempt => 
                TimeSpan.FromMilliseconds(Math.Pow(2, retryAttempt) * 100), // Exponential backoff
            onRetry: (outcome, timespan, retryCount, context) =>
            {
                Log.Warning(
                    "Request failed (attempt {RetryCount}/3). Waiting {Delay}ms before retry. Error: {Error}",
                    retryCount,
                    timespan.TotalMilliseconds,
                    outcome.Exception?.Message ?? outcome.Result.StatusCode.ToString()
                );
            }
        );
}
```

**Behavior**:
- Request fails → Wait 200ms → Retry
- Fails again → Wait 400ms → Retry
- Fails again → Wait 800ms → Retry
- Still fails → Throw exception

---

### Pattern 2: Circuit Breaker

**Use Case**: Prevent overwhelming a failing service

```csharp
static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy()
{
    return HttpPolicyExtensions
        .HandleTransientHttpError()
        .CircuitBreakerAsync(
            handledEventsAllowedBeforeBreaking: 5, // Break after 5 consecutive failures
            durationOfBreak: TimeSpan.FromSeconds(30), // Stay broken for 30 seconds
            onBreak: (outcome, breakDelay) =>
            {
                Log.Error(
                    "Circuit breaker opened! Requests will be blocked for {Delay} seconds. Reason: {Error}",
                    breakDelay.TotalSeconds,
                    outcome.Exception?.Message ?? outcome.Result.StatusCode.ToString()
                );
            },
            onReset: () =>
            {
                Log.Information("Circuit breaker reset. Service is healthy again.");
            },
            onHalfOpen: () =>
            {
                Log.Information("Circuit breaker half-open. Testing if service recovered.");
            }
        );
}
```

**Behavior**:
```
Attempt 1: Failed
Attempt 2: Failed
Attempt 3: Failed
Attempt 4: Failed
Attempt 5: Failed
→ Circuit OPEN (breaker trips)
Attempts 6-100: Immediately fail with BrokenCircuitException (don't even try)
After 30 seconds: Half-Open
Attempt 101: Try ONE request
  → Success? Circuit CLOSED (healthy again)
  → Failed? Circuit OPEN again for another 30s
```

---

### Pattern 3: Timeout Policy

**Use Case**: Prevent indefinite waiting

```csharp
builder.Services.AddHttpClient<IPaymentService, PaymentService>()
    .AddPolicyHandler(Policy.TimeoutAsync<HttpResponseMessage>(TimeSpan.FromSeconds(10)));
```

---

### Combined Policy (Recommended)

```csharp
builder.Services.AddHttpClient<IPaymentService, PaymentService>()
    .AddPolicyHandler((services, request) =>
        Policy.WrapAsync(
            GetRetryPolicy(),
            GetCircuitBreakerPolicy(),
            Policy.TimeoutAsync<HttpResponseMessage>(TimeSpan.FromSeconds(10))
        )
    );
```

**Execution Order** (outer → inner):
1. **Timeout**: Kill request if >10 seconds
2. **Circuit Breaker**: Don't try if service is known to be down
3. **Retry**: Retry up to 3 times with exponential backoff

---

### Fallback Pattern (Bonus)

**Use Case**: Return cached data when service is down

```csharp
public class ListingService : IListingService
{
    private readonly HttpClient _httpClient;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ListingService> _logger;

    public async Task<List<Listing>> GetFeaturedListingsAsync()
    {
        var cacheKey = "featured-listings";
        
        try
        {
            var response = await _httpClient.GetAsync("/api/listings/featured");
            response.EnsureSuccessStatusCode();
            
            var listings = await response.Content.ReadFromJsonAsync<List<Listing>>();
            
            // Cache successful response
            _cache.Set(cacheKey, listings, TimeSpan.FromMinutes(5));
            
            return listings;
        }
        catch (BrokenCircuitException)
        {
            _logger.LogWarning("Circuit breaker is open. Returning cached featured listings.");
            
            if (_cache.TryGetValue(cacheKey, out List<Listing> cached))
            {
                return cached;
            }
            
            // Ultimate fallback: empty list
            return  new List<Listing>();
        }
    }
}
```

---

### MongoDB Resilience

```csharp
public class ResilientMongoRepository<T>
{
    private readonly IAsyncPolicy _retryPolicy;

    public ResilientMongoRepository()
    {
        _retryPolicy = Policy
            .Handle<MongoConnectionException>()
            .Or<MongoExecutionTimeoutException>()
            .WaitAndRetryAsync(
                3,
                retryAttempt => TimeSpan.FromMilliseconds(100 * retryAttempt)
            );
    }

    public async Task<T> FindByIdAsync(string id)
    {
        return await _retryPolicy.ExecuteAsync(async () =>
        {
            return await _collection.Find(x => x.Id == id).FirstOrDefaultAsync();
        });
    }
}
```

---

**Timeline Impact**: +2 days for Polly policies across all services

---

## 3. 🏥 Health Checks (Kubernetes/Docker Readiness)

### Problem: Running ≠ Healthy

```
docker ps
→ CONTAINER ID  STATUS
→ abc123        Up 2 minutes   (auth-service)

// But internally:
→ MongoDB connection pool exhausted ❌
→ RabbitMQ connection lost ❌
→ Redis unreachable ❌
```

Docker sees the process is running (`Up`) but the service is actually **zombie** (can't handle traffic).

**Kubernetes Impact**: Without health checks, K8s sends traffic to broken pods.

---

### Solution: ASP.NET Core Health Checks

#### Install Packages

```xml
<PackageReference Include="AspNetCore.HealthChecks.MongoDb" Version="7.0.0" />
<PackageReference Include="AspNetCore.HealthChecks.Redis" Version="7.0.0" />
<PackageReference Include="AspNetCore.HealthChecks.RabbitMQ" Version="7.0.0" />
<PackageReference Include="AspNetCore.HealthChecks.UI" Version="7.0.0" />
<PackageReference Include="AspNetCore.HealthChecks.UI.Client" Version="7.0.0" />
```

---

### Implementation (AuthService Example)

```csharp
using HealthChecks.UI.Client;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

// Add health checks
builder.Services.AddHealthChecks()
    .AddMongoDb(
        mongodbConnectionString: builder.Configuration["MongoDBSettings:ConnectionString"],
        name: "mongodb",
        failureStatus: HealthStatus.Unhealthy,
        tags: new[] { "db", "nosql" }
    )
    .AddRedis(
        redisConnectionString: builder.Configuration["Redis:ConnectionString"],
        name: "redis",
        failureStatus: HealthStatus.Degraded,
        tags: new[] { "cache" }
    )
    .AddRabbitMQ(
        rabbitConnectionString: builder.Configuration["RabbitMQ:ConnectionString"],
        name: "rabbitmq",
        failureStatus: HealthStatus.Degraded,
        tags: new[] { "messaging" }
    )
    .AddCheck<CustomHealthCheck>("custom-logic", tags: new[] { "business" });

var app = builder.Build();

// Map health check endpoints
app.MapHealthChecks("/health", new HealthCheckOptions
{
    Predicate = _ => true, // Include all checks
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse // JSON format
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("db") || check.Tags.Contains("messaging"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false // Just respond 200 if process is alive
});

app.Run();
```

---

### Custom Health Check Example

```csharp
public class CustomHealthCheck : IHealthCheck
{
    private readonly IMongoDatabase _database;

    public CustomHealthCheck(IMongoDatabase database)
    {
        _database = database;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Check if we can query users collection
            var count = await _database.GetCollection<User>("emlakcis")
                .CountDocumentsAsync(FilterDefinition<User>.Empty, cancellationToken: cancellationToken);

            if (count >= 0)
            {
                return HealthCheckResult.Healthy($"MongoDB connection active. {count} users in database.");
            }

            return HealthCheckResult.Degraded("MongoDB returned unexpected result.");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("MongoDB connection failed", ex);
        }
    }
}
```

---

### Health Check Response Example

**GET** `/health`

```json
{
  "status": "Healthy",
  "totalDuration": "00:00:00.1234567",
  "entries": {
    "mongodb": {
      "status": "Healthy",
      "description": "MongoDB connection active. 1523 users in database.",
      "duration": "00:00:00.0456789"
    },
    "redis": {
      "status": "Healthy",
      "duration": "00:00:00.0123456"
    },
    "rabbitmq": {
      "status": "Degraded",
      "description": "Connection established but high queue depth detected",
      "duration": "00:00:00.0234567"
    }
  }
}
```

**Status Codes**:
- `Healthy` → 200 OK
- `Degraded` → 200 OK (⚠️ warning, but operational)
- `Unhealthy` → 503 Service Unavailable

---

### Docker Compose Health Checks

```yaml
  auth-service:
    build: ./backend/AuthService
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

### Kubernetes Integration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: auth-service
        image: emlaktan/auth-service:latest
        ports:
        - containerPort: 80
        
        # Liveness Probe: Is process alive?
        livenessProbe:
          httpGet:
            path: /health/live
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Readiness Probe: Ready to serve traffic?
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
```

**Behavior**:
- **Liveness fails** → K8s **restarts** the pod
- **Readiness fails** → K8s **removes** from load balancer (no traffic sent)

---

### Health Checks UI (Dashboard)

Optional: Centralized health dashboard

```csharp
// In a separate "monitoring" service or API Gateway
builder.Services.AddHealthChecksUI(setup =>
{
    setup.AddHealthCheckEndpoint("Auth Service", "http://auth-service/health");
    setup.AddHealthCheckEndpoint("Listings Service", "http://listings-service/health");
    setup.AddHealthCheckEndpoint("Payment Service", "http://payment-service/health");
    setup.AddHealthCheckEndpoint("Messaging Service", "http://messaging-service/health");
}).AddInMemoryStorage();

app.MapHealthChecksUI(options => options.UIPath = "/healthchecks-ui");
```

Visit: `http://localhost:5000/healthchecks-ui`

---

**Timeline Impact**: +1.5 days for health checks across all services

---

## Updated Complete Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Distributed Tracing** | OpenTelemetry + Jaeger | Request flow visualization |
| **Centralized Logging** | Serilog + Seq | Structured log aggregation |
| **Resilience** | Polly | Retry, circuit breaker, timeout |
| **Health Monitoring** | ASP.NET Health Checks | Kubernetes readiness/liveness |
| **Metrics** | Prometheus + Grafana | Performance metrics |
| **Event Bus** | RabbitMQ | Asynchronous messaging |
| **Search Engine** | Elasticsearch | Faceted search |
| **Cache** | Redis | Distributed cache + SignalR |
| **CDN** | Cloudflare | Image delivery |
| **OTA Updates** | Shorebird | Flutter code push |
| **Token Revocation** | Redis Blacklist | JWT invalidation |

---

## Observability Stack Diagram

```
┌─────────────────────────────────────────────────┐
│              Developer Tools                     │
├─────────────────────────────────────────────────┤
│  Jaeger UI        │  Seq UI         │ Grafana  │
│  (Traces)         │  (Logs)         │ (Metrics)│
│  TraceId: abc123  │  Query by       │ CPU/RAM  │
│  2.3s duration    │  TraceId        │ charts   │
└─────────────────────────────────────────────────┘
          ↑               ↑                 ↑
          │               │                 │
┌─────────────────────────────────────────────────┐
│            .NET Microservices                    │
├─────────────────────────────────────────────────┤
│  OpenTelemetry → Jaeger (traces)               │
│  Serilog → Seq (logs with TraceId)             │
│  Prometheus Exporter → Grafana (metrics)        │
│  Polly → Retry/Circuit Breaker                  │
│  Health Checks → /health endpoints              │
└─────────────────────────────────────────────────┘
```

---

## Updated Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Phase 1: Planning** | 1 week | Architecture approved |
| **Phase 2: Infrastructure** | 2 weeks | RabbitMQ, Elasticsearch, Jaeger, **Seq**, CDN |
| **Phase 3: Backend Core** | 4.5 weeks | Auth, Listings, Payment (**+Polly +Health Checks**) |
| **Phase 4: Backend Extended** | 3 weeks | Messaging, Notifications, Analytics |
| **Phase 5: Flutter Core** | 5 weeks | Auth, Listings, Search |
| **Phase 6: Flutter Extended** | 3 weeks | Premium, Maps, Alarms |
| **Phase 7: Production Features** | 2 weeks | Tracing, Logging, Resilience, Health |
| **Phase 8: Shorebird + Monitoring** | 1.5 weeks | OTA, cost alerts |
| **Phase 9: Admin Panel** | 2 weeks | Management UI |
| **Phase 10: Testing** | 2 weeks | E2E, load, chaos |
| **Phase 11: Deployment** | 1 week | Production |
| **Total** | **~27 weeks** | **Enterprise-grade launch** |

**Total Addition**: +3 weeks for full observability & resilience

---

## Production Deployment Checklist (FINAL)

### Infrastructure
- [ ] MongoDB Atlas IP whitelist & auth
- [ ] RabbitMQ credentials & TLS
- [ ] Elasticsearch auth enabled
- [ ] Redis password protection
- [ ] **Jaeger production setup (retention policy)**
- [ ] **Seq production license (if >50GB/day)**
- [ ] CDN configured (Cloudflare/CloudFront)
- [ ] **Health checks tested on all services**

### Security
- [ ] JWT secret rotation strategy
- [ ] Redis blacklist active
- [ ] SSL certificates installed
- [ ] API rate limiting configured
- [ ] Shorebird keys secured

### Resilience
- [ ] **Polly policies configured on all HttpClients**
- [ ] **Circuit breaker thresholds tuned**
- [ ] **Timeout policies set**
- [ ] Fallback data caches populated

### Observability
- [ ] **Serilog enrichers configured (TraceId)**
- [ ] **Seq alerts for critical errors**
- [ ] Jaeger sampling rate configured
- [ ] Prometheus metrics exported
- [ ] Grafana dashboards created

### Kubernetes (if applicable)
- [ ] **Liveness probes configured**
- [ ] **Readiness probes configured**
- [ ] Resource limits set (CPU/RAM)
- [ ] Horizontal Pod Autoscaler (HPA)
- [ ] Ingress controller configured

---

## Key Takeaways

### The Holy Trinity of Observability

1. **Traces** (Jaeger): "Which service is slow?"
2. **Logs** (Seq): "What exactly went wrong?"
3. **Metrics** (Grafana): "Is CPU spiking?"

### The Trinity of Resilience

1. **Retry**: Handle transient failures
2. **Circuit Breaker**: Protect failing services
3. **Timeout**: Prevent infinite waits

### Health Check Strategy

- **Liveness**: "Am I alive?" → Restart if fails
- **Readiness**: "Can I serve traffic?" → Remove from LB if fails

---

**This completes the enterprise-grade architecture. The system is now production-ready with full observability, resilience, and health monitoring.**

---

## Cost Breakdown (Monthly Estimates)

| Service | Tier | Cost |
|---------|------|------|
| MongoDB Atlas | M10 (suitable for start) | $57/mo |
| Cloudflare CDN | Free tier (100GB) | $0 |
| Shorebird | Pro (controlled usage) | $20-50/mo |
| Seq | Free (<50GB/day) | $0 (or$150/mo for Pro) |
| Hetzner Server (8 vCPU, 32GB RAM) | CX41 | €19.68/mo |
| **Total Estimated** | | **~$100-150/mo** |

*At scale (10,000+ daily users), costs may increase. Budget $500-1000/mo for safety.*

---

**Architecture is now 100% production-ready! 🚀**
