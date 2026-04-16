using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using MongoDB.Driver;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Conventions;
using Serilog;
using Serilog.Events;
using Serilog.Enrichers.Span;
using ListingsService.Models;
using ListingsService.Repositories;
using ListingsService.Services;
using ListingsService.Infrastructure;
using HealthChecks.UI.Client;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Polly;

// === GLOBAL MongoDB Conventions — MUST be first before any DB access ===
var conventionPack = new ConventionPack
{
    new IgnoreExtraElementsConvention(true)
};
ConventionRegistry.Register("EsaEmlakConventions", conventionPack, _ => true);

// Register class maps to avoid deserialization issues with extra/renamed fields
if (!BsonClassMap.IsClassMapRegistered(typeof(Listing)))
{
    BsonClassMap.RegisterClassMap<Listing>(cm =>
    {
        cm.AutoMap();
        cm.SetIgnoreExtraElements(true);
    });
}

if (!BsonClassMap.IsClassMapRegistered(typeof(GeoLocation)))
{
    BsonClassMap.RegisterClassMap<GeoLocation>(cm =>
    {
        cm.AutoMap();
        cm.SetIgnoreExtraElements(true);
    });
}

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithThreadId()
    .Enrich.WithSpan()
    .Enrich.WithProperty("Service", "ListingsService")
    .Enrich.WithProperty("Environment", builder.Environment.EnvironmentName)
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] [{Service}] {TraceId} {Message:lj}{NewLine}{Exception}"
    )
    .WriteTo.Seq(
        serverUrl: builder.Configuration["Seq:ServerUrl"] ?? "http://localhost:5341",
        apiKey: builder.Configuration["Seq:ApiKey"]
    )
    .CreateLogger();

builder.Host.UseSerilog();

// Configure OpenTelemetry
builder.Services.AddOpenTelemetry()
    .WithTracing(tracerProviderBuilder =>
    {
        tracerProviderBuilder
            .SetResourceBuilder(ResourceBuilder.CreateDefault()
                .AddService("ListingsService")
                .AddAttributes(new Dictionary<string, object>
                {
                    ["deployment.environment"] = builder.Environment.EnvironmentName,
                    ["service.version"] = "1.0.0"
                }))
            .AddAspNetCoreInstrumentation(options =>
            {
                options.RecordException = true;
            })
            .AddHttpClientInstrumentation()
            .AddJaegerExporter(options =>
            {
                options.AgentHost = builder.Configuration["Jaeger:AgentHost"] ?? "localhost";
                options.AgentPort = int.Parse(builder.Configuration["Jaeger:AgentPort"] ?? "6831");
            });
    });

// Configure MongoDB
builder.Services.Configure<MongoDBSettings>(
    builder.Configuration.GetSection("MongoDBSettings"));

builder.Services.AddSingleton<IMongoClient>(sp =>
{
    var settings = builder.Configuration.GetSection("MongoDBSettings").Get<MongoDBSettings>()!;
    return new MongoClient(settings.ConnectionString);
});

builder.Services.AddScoped<IMongoDatabase>(sp =>
{
    var settings = builder.Configuration.GetSection("MongoDBSettings").Get<MongoDBSettings>()!;
    var client = sp.GetRequiredService<IMongoClient>();
    return client.GetDatabase(settings.DatabaseName);
});

// Configure JWT Authentication
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

// Register services
builder.Services.AddScoped<IListingRepository, ListingRepository>();
builder.Services.AddScoped<IFavoriteRepository, FavoriteRepository>();
builder.Services.AddScoped<IAgencyRepository, AgencyRepository>();
builder.Services.AddScoped<IListingService, ListingService>();
builder.Services.AddScoped<IShowcaseService, ShowcaseService>();
builder.Services.AddScoped<DataSeederService>();
builder.Services.AddScoped<IImageProcessingService, ImageProcessingService>();
builder.Services.AddSingleton<IEventBus, RabbitMQEventBus>();

// Elasticsearch (opsiyonel - bağlanamazsa uygulama çalışmaya devam eder)
var elasticsearchUri = builder.Configuration["Elasticsearch:Uri"] ?? "http://localhost:9200";
try
{
    var esSettings = new Nest.ConnectionSettings(new Uri(elasticsearchUri))
        .DefaultIndex("emlaktan-listings");
    builder.Services.AddSingleton<Nest.IElasticClient>(new Nest.ElasticClient(esSettings));
    builder.Services.AddScoped<ListingsService.Elasticsearch.ISearchService, ListingsService.Elasticsearch.ElasticsearchService>();
    Log.Information("Elasticsearch configured: {Uri}", elasticsearchUri);
}
catch (Exception ex)
{
    Log.Warning(ex, "Elasticsearch yapılandırılamadı, NoOp kullanılıyor");
    builder.Services.AddSingleton<Nest.IElasticClient>(_ =>
        new Nest.ElasticClient(new Nest.ConnectionSettings(new Uri(elasticsearchUri))));
    builder.Services.AddScoped<ListingsService.Elasticsearch.ISearchService, ListingsService.Elasticsearch.NoOpElasticsearchService>();
}

// In-Memory Cache (Redis yerine - harici servis gerektirmez)
builder.Services.AddDistributedMemoryCache();
builder.Services.AddScoped<ICacheService, RedisCacheService>();
Log.Information("In-memory cache configured (Redis yerine)");

// Polly-enabled HttpClient
builder.Services.AddHttpClient("resilient")
    .AddPolicyHandler(PollyPolicies.GetRetryPolicy())
    .AddPolicyHandler(PollyPolicies.GetCircuitBreakerPolicy());

// Health checks (sadece MongoDB zorunlu, diğerleri opsiyonel)
builder.Services.AddHealthChecks()
    .AddMongoDb(
        mongodbConnectionString: builder.Configuration["MongoDBSettings:ConnectionString"]!,
        name: "mongodb",
        tags: new[] { "db", "ready" }
    );

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});

var app = builder.Build();

// Seed database on startup (only seeds if empty)
try
{
    using (var scope = app.Services.CreateScope())
    {
        var seeder = scope.ServiceProvider.GetRequiredService<DataSeederService>();
        await seeder.SeedIfEmptyAsync();
    }
}
catch (Exception ex)
{
    Log.Warning(ex, "Data seeding failed, continuing without seeding.");
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("UserId", httpContext.User.FindFirst("sub")?.Value);
        diagnosticContext.Set("ClientIP", httpContext.Connection.RemoteIpAddress?.ToString());
    };
});

app.UseStaticFiles(); // Serve uploaded listing images from wwwroot/
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

app.MapHealthChecks("/health", new HealthCheckOptions
{
    Predicate = _ => true,
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("db"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false
});

app.MapControllers();

Log.Information("ListingsService starting up...");
app.Run();
