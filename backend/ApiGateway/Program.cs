using System.IO.Compression;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using Serilog.Events;
using HealthChecks.UI.Client;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using OpenTelemetry.Metrics;
using AspNetCoreRateLimit;
using ApiGateway.Middleware;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

// ==================== SERILOG ====================
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .MinimumLevel.Override("Yarp", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithProperty("Service", "ApiGateway")
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] [{Service}] {Message:lj}{NewLine}{Exception}"
    )
    .WriteTo.Seq(builder.Configuration["Seq:ServerUrl"] ?? "http://localhost:5341")
    .CreateLogger();

builder.Host.UseSerilog();

// ==================== OPENTELEMETRY (Tracing + Metrics) ====================
builder.Services.AddOpenTelemetry()
    .WithTracing(tracerProviderBuilder =>
    {
        tracerProviderBuilder
            .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService("ApiGateway"))
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddJaegerExporter(options =>
            {
                options.AgentHost = builder.Configuration["Jaeger:AgentHost"] ?? "localhost";
                options.AgentPort = int.Parse(builder.Configuration["Jaeger:AgentPort"] ?? "6831");
            });
    })
    .WithMetrics(meterProviderBuilder =>
    {
        meterProviderBuilder
            .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService("ApiGateway"))
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddRuntimeInstrumentation()
            .AddPrometheusExporter();
    });

// ==================== JWT AUTHENTICATION ====================
var jwtSecret = builder.Configuration["JwtSettings:Secret"]!;
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["JwtSettings:Issuer"],
            ValidAudience = builder.Configuration["JwtSettings:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret))
        };
    });

builder.Services.AddAuthorization();

// ==================== REDIS ====================
var redisConnectionString = builder.Configuration["Redis:ConnectionString"] ?? "localhost:6379,abortConnect=false";
try
{
    var redisConnection = ConnectionMultiplexer.Connect(redisConnectionString);
    builder.Services.AddSingleton<IConnectionMultiplexer>(redisConnection);
    Log.Information("✅ Redis connected for token blacklist checking");
}
catch (Exception ex)
{
    Log.Warning(ex, "⚠️ Redis not available — token blacklist checking disabled");
    builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
        ConnectionMultiplexer.Connect(new ConfigurationOptions { AbortOnConnectFail = false }));
}

// ==================== YARP REVERSE PROXY ====================
builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

// ==================== HEALTH CHECKS ====================
var authUrl = builder.Configuration["ReverseProxy:Clusters:auth-cluster:Destinations:auth-service:Address"] ?? "http://localhost:5001";
var listingsUrl = builder.Configuration["ReverseProxy:Clusters:listings-cluster:Destinations:listings-service:Address"] ?? "http://localhost:5002";
var paymentUrl = builder.Configuration["ReverseProxy:Clusters:payment-cluster:Destinations:payment-service:Address"] ?? "http://localhost:5005";
var notificationUrl = builder.Configuration["ReverseProxy:Clusters:notification-cluster:Destinations:notification-service:Address"] ?? "http://localhost:5006";
var messagingUrl = builder.Configuration["ReverseProxy:Clusters:messaging-cluster:Destinations:messaging-service:Address"] ?? "http://localhost:5004";

builder.Services.AddHealthChecks()
    .AddUrlGroup(new Uri($"{authUrl}/health"), name: "auth-service", tags: new[] { "services", "critical" })
    .AddUrlGroup(new Uri($"{listingsUrl}/health"), name: "listings-service", tags: new[] { "services", "critical" })
    .AddUrlGroup(new Uri($"{paymentUrl}/health"), name: "payment-service", tags: new[] { "services" })
    .AddUrlGroup(new Uri($"{notificationUrl}/health"), name: "notification-service", tags: new[] { "services" })
    .AddUrlGroup(new Uri($"{messagingUrl}/health"), name: "messaging-service", tags: new[] { "services" })
    .AddRedis(redisConnectionString, name: "redis", tags: new[] { "infrastructure" });

// Health Checks UI Dashboard
builder.Services.AddHealthChecksUI(options =>
{
    options.SetEvaluationTimeInSeconds(30);
    options.MaximumHistoryEntriesPerEndpoint(50);
    options.AddHealthCheckEndpoint("API Gateway", "/health");
}).AddInMemoryStorage();

// ==================== RATE LIMITING ====================
builder.Services.AddMemoryCache();
builder.Services.Configure<IpRateLimitOptions>(options =>
{
    options.EnableEndpointRateLimiting = true;
    options.StackBlockedRequests = false;
    options.RealIpHeader = "X-Forwarded-For";
    options.ClientIdHeader = "X-ClientId";
    options.HttpStatusCode = 429;
    options.GeneralRules = new List<RateLimitRule>
    {
        new RateLimitRule
        {
            Endpoint = "*",
            Period = "1s",
            Limit = 20
        },
        new RateLimitRule
        {
            Endpoint = "*:/api/auth/login",
            Period = "1m",
            Limit = 10 // Brute-force protection
        },
        new RateLimitRule
        {
            Endpoint = "*:/api/auth/register",
            Period = "1h",
            Limit = 5 // Registration spam protection
        },
        new RateLimitRule
        {
            Endpoint = "*:/api/payments/*",
            Period = "1m",
            Limit = 15 // Payment abuse protection
        },
        new RateLimitRule
        {
            Endpoint = "*:/api/listings/*/images",
            Period = "1m",
            Limit = 30 // Image upload rate limit
        }
    };
});
builder.Services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();
builder.Services.AddInMemoryRateLimiting();
Log.Information("🛡️ Rate Limiting configured: 20 req/s general, login 10/min, register 5/hr, image upload 30/min");

// ==================== RESPONSE COMPRESSION ====================
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
    options.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(new[]
    {
        "application/json",
        "application/javascript",
        "text/css",
        "text/html",
        "text/plain",
        "image/svg+xml"
    });
});

builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
{
    options.Level = CompressionLevel.Fastest;
});

builder.Services.Configure<GzipCompressionProviderOptions>(options =>
{
    options.Level = CompressionLevel.SmallestSize;
});

// ==================== CORS (Production-Ready) ====================
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? new[] { "http://localhost:3000", "http://localhost:8080", "http://localhost:5000" };

builder.Services.AddCors(options =>
{
    // Production policy (Flutter web, Admin panel)
    options.AddPolicy("ProductionPolicy", policy =>
    {
        policy.WithOrigins(allowedOrigins)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials() // Required for SignalR
            .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
    });

    // Development policy (permissive)
    options.AddPolicy("DevelopmentPolicy", policy =>
    {
        policy.SetIsOriginAllowed(_ => true) // Allow any origin in dev
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials(); // Required for SignalR
    });
});

var app = builder.Build();

// ==================== MIDDLEWARE PIPELINE ====================
// Order matters! Each middleware wraps the next.

// 1. Response Compression (outermost — compresses everything going out)
app.UseResponseCompression();

// 2. Request/Response logging (captures everything including correlation ID)
app.UseRequestLogging();

// 3. Serilog request logging (structured logs)
app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("ClientIP", httpContext.Connection.RemoteIpAddress?.ToString());
        diagnosticContext.Set("RequestPath", httpContext.Request.Path);
        diagnosticContext.Set("CorrelationId", httpContext.Items["CorrelationId"]?.ToString());
    };
});

// 4. Global Exception Handler
app.UseGlobalExceptionHandler();

// 5. Rate Limiting
app.UseIpRateLimiting();

// 6. CORS (environment-aware)
if (app.Environment.IsDevelopment())
{
    app.UseCors("DevelopmentPolicy");
}
else
{
    app.UseCors("ProductionPolicy");
}

// 7. Authentication & Authorization
app.UseAuthentication();
app.UseAuthorization();

// 8. Token blacklist check (after auth, before routing)
app.UseTokenBlacklist();

// ==================== ENDPOINTS ====================

// Prometheus metrics endpoint
app.MapPrometheusScrapingEndpoint("/metrics");

// Health check endpoint
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

// Health check for critical services only
app.MapHealthChecks("/health/critical", new HealthCheckOptions
{
    Predicate = reg => reg.Tags.Contains("critical"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

// Health check for infrastructure only
app.MapHealthChecks("/health/infra", new HealthCheckOptions
{
    Predicate = reg => reg.Tags.Contains("infrastructure"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

// Liveness probe (returns 200 if process is alive)
app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false
});

// Health Checks UI Dashboard
app.MapHealthChecksUI(options =>
{
    options.UIPath = "/health-ui";
    options.ApiPath = "/health-api";
});

// Service status info endpoint
app.MapGet("/api/gateway/info", () => new
{
    service = "EsaEmlak API Gateway",
    version = "3.0.0",
    environment = app.Environment.EnvironmentName,
    timestamp = DateTime.UtcNow,
    features = new
    {
        responseCompression = "Brotli + Gzip",
        rateLimiting = true,
        tokenBlacklist = true,
        distributedTracing = "Jaeger",
        metricsExporter = "Prometheus",
        centralizedLogging = "Seq"
    },
    endpoints = new
    {
        health = "/health",
        healthCritical = "/health/critical",
        healthInfra = "/health/infra",
        healthLive = "/health/live",
        healthDashboard = "/health-ui",
        metrics = "/metrics"
    }
});

// Map YARP reverse proxy
app.MapReverseProxy();

Log.Information("🚀 API Gateway v3.0 starting on port 5000...");
Log.Information("📡 Routes: Auth → 5001, Listings → 5002, Messaging → 5004, Payment → 5005, Notification → 5006");
Log.Information("📊 Health Dashboard: /health-ui | Metrics: /metrics | Info: /api/gateway/info");
Log.Information("🗜️ Response Compression: Brotli + Gzip enabled");

app.Run();
