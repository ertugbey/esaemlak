using System.Diagnostics;

namespace ApiGateway.Middleware;

/// <summary>
/// Request/Response logging middleware — enriches structured logging with:
/// - Correlation ID (X-Correlation-Id header — propagated across services)
/// - Request timing (duration in ms)
/// - Request body size, response status code
/// - Client IP, User-Agent
/// </summary>
public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Generate or propagate Correlation ID
        var correlationId = context.Request.Headers["X-Correlation-Id"].FirstOrDefault()
            ?? Activity.Current?.TraceId.ToString()
            ?? Guid.NewGuid().ToString("N")[..16];

        context.Items["CorrelationId"] = correlationId;
        context.Response.Headers["X-Correlation-Id"] = correlationId;

        var sw = Stopwatch.StartNew();
        var clientIp = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var userAgent = context.Request.Headers.UserAgent.FirstOrDefault() ?? "unknown";
        var method = context.Request.Method;
        var path = context.Request.Path.Value ?? "/";
        var contentLength = context.Request.ContentLength ?? 0;

        _logger.LogInformation(
            "→ {Method} {Path} | IP: {ClientIP} | Size: {ContentLength}B | CID: {CorrelationId}",
            method, path, clientIp, contentLength, correlationId);

        try
        {
            await _next(context);
            sw.Stop();

            var statusCode = context.Response.StatusCode;
            var level = statusCode >= 500 ? LogLevel.Error
                : statusCode >= 400 ? LogLevel.Warning
                : LogLevel.Information;

            _logger.Log(level,
                "← {Method} {Path} → {StatusCode} | {Duration}ms | CID: {CorrelationId}",
                method, path, statusCode, sw.ElapsedMilliseconds, correlationId);
        }
        catch (Exception ex)
        {
            sw.Stop();
            _logger.LogError(ex,
                "✖ {Method} {Path} → EXCEPTION | {Duration}ms | CID: {CorrelationId}",
                method, path, sw.ElapsedMilliseconds, correlationId);
            throw;
        }
    }
}

public static class RequestLoggingMiddlewareExtensions
{
    public static IApplicationBuilder UseRequestLogging(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<RequestLoggingMiddleware>();
    }
}
