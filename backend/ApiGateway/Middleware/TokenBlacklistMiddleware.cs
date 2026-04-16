using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using System.Text;
using StackExchange.Redis;

namespace ApiGateway.Middleware;

/// <summary>
/// Middleware that checks if the incoming JWT token has been revoked
/// (blacklisted in Redis). Runs BEFORE YARP reverse proxy routing.
/// 
/// Two-level check:
/// 1. Per-token blacklist: logout revokes a single token
/// 2. Per-user blacklist: logout-all-devices revokes ALL tokens for a user
/// </summary>
public class TokenBlacklistMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<TokenBlacklistMiddleware> _logger;
    private const string TokenKeyPrefix = "blacklist:token:";
    private const string UserKeyPrefix = "blacklist:user:";

    public TokenBlacklistMiddleware(RequestDelegate next, ILogger<TokenBlacklistMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var authHeader = context.Request.Headers["Authorization"].FirstOrDefault();

        if (!string.IsNullOrEmpty(authHeader) && authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            var token = authHeader["Bearer ".Length..].Trim();

            try
            {
                var redis = context.RequestServices.GetService<IConnectionMultiplexer>();
                if (redis != null && redis.IsConnected)
                {
                    var db = redis.GetDatabase();

                    // Check 1: Per-token blacklist
                    var tokenKey = TokenKeyPrefix + ComputeSha256Hash(token);
                    if (await db.KeyExistsAsync(tokenKey))
                    {
                        _logger.LogWarning("Blocked request with revoked token");
                        context.Response.StatusCode = 401;
                        context.Response.ContentType = "application/json";
                        await context.Response.WriteAsync(
                            "{\"error\":\"Token has been revoked\",\"code\":\"TOKEN_REVOKED\"}");
                        return;
                    }

                    // Check 2: Per-user blacklist (logout-all-devices)
                    try
                    {
                        var handler = new JwtSecurityTokenHandler();
                        if (handler.CanReadToken(token))
                        {
                            var jwtToken = handler.ReadJwtToken(token);
                            var userId = jwtToken.Claims.FirstOrDefault(c => c.Type == "sub")?.Value;

                            if (!string.IsNullOrEmpty(userId))
                            {
                                var userKey = UserKeyPrefix + userId;
                                var blacklistTimestamp = await db.StringGetAsync(userKey);

                                if (blacklistTimestamp.HasValue)
                                {
                                    // Check if the token was issued BEFORE the blacklist timestamp
                                    if (DateTime.TryParse(blacklistTimestamp.ToString(), out var blacklistTime))
                                    {
                                        var tokenIssuedAt = jwtToken.IssuedAt;
                                        if (tokenIssuedAt < blacklistTime)
                                        {
                                            _logger.LogWarning(
                                                "Blocked request — user {UserId} sessions invalidated at {BlacklistTime}",
                                                userId, blacklistTime);
                                            context.Response.StatusCode = 401;
                                            context.Response.ContentType = "application/json";
                                            await context.Response.WriteAsync(
                                                "{\"error\":\"All sessions have been invalidated. Please login again.\",\"code\":\"USER_SESSIONS_REVOKED\"}");
                                            return;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        // Token parsing failed — let normal JWT validation handle it downstream
                        _logger.LogDebug(ex, "Failed to parse JWT for user-level blacklist check");
                    }
                }
            }
            catch (Exception ex)
            {
                // Redis is down — fail open (let the request through)
                _logger.LogWarning(ex, "Redis unavailable for token blacklist check — allowing request");
            }
        }

        await _next(context);
    }

    private static string ComputeSha256Hash(string input)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToBase64String(bytes);
    }
}

/// <summary>Extension method to register the middleware</summary>
public static class TokenBlacklistMiddlewareExtensions
{
    public static IApplicationBuilder UseTokenBlacklist(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<TokenBlacklistMiddleware>();
    }
}
