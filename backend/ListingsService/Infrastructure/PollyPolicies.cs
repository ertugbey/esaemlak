using Polly;
using Polly.Extensions.Http;
using Polly.CircuitBreaker;
using Serilog;

namespace ListingsService.Infrastructure;

/// <summary>
/// Polly resilience policies for HTTP communication
/// </summary>
public static class PollyPolicies
{
    /// <summary>
    /// Retry policy with exponential backoff: 3 retries (2s, 4s, 8s)
    /// </summary>
    public static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy()
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError()
            .OrResult(msg => msg.StatusCode == System.Net.HttpStatusCode.NotFound)
            .WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timespan, retryAttempt, context) =>
                {
                    Log.Warning(
                        "⚡ RETRY {RetryAttempt}/3 after {Delay}s. Reason: {Reason}",
                        retryAttempt,
                        timespan.TotalSeconds,
                        outcome.Exception?.Message ?? outcome.Result?.StatusCode.ToString()
                    );
                });
    }

    /// <summary>
    /// Circuit breaker: Opens after 5 failures, stays open for 30 seconds
    /// </summary>
    public static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy()
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError()
            .CircuitBreakerAsync(
                handledEventsAllowedBeforeBreaking: 5,
                durationOfBreak: TimeSpan.FromSeconds(30),
                onBreak: (exception, duration) =>
                {
                    Log.Error(
                        "🔴 CIRCUIT BREAKER OPENED for {Duration}s. Error: {Error}",
                        duration.TotalSeconds,
                        exception.Exception?.Message ?? exception.Result?.ReasonPhrase
                    );
                },
                onReset: () =>
                {
                    Log.Information("🟢 CIRCUIT BREAKER RESET - Service recovered");
                },
                onHalfOpen: () =>
                {
                    Log.Warning("🟡 CIRCUIT BREAKER HALF-OPEN - Testing service...");
                });
    }

    /// <summary>
    /// Combined policy wrap: Retry → Circuit Breaker
    /// </summary>
    public static IAsyncPolicy<HttpResponseMessage> GetCombinedPolicy()
    {
        return Policy.WrapAsync(GetRetryPolicy(), GetCircuitBreakerPolicy());
    }
}
