using System.Security.Cryptography;
using System.Text;
using StackExchange.Redis;

namespace AuthService.Services;

/// <summary>
/// Redis-based JWT token blacklist service.
/// When a user logs out, their JWT is added to the blacklist with a TTL
/// equal to the token's remaining lifetime.
/// </summary>
public interface ITokenBlacklistService
{
    /// <summary>Blacklist a single JWT token (for logout)</summary>
    Task BlacklistTokenAsync(string jwtToken, TimeSpan? ttl = null);

    /// <summary>Check if a token is blacklisted</summary>
    Task<bool> IsTokenBlacklistedAsync(string jwtToken);

    /// <summary>Blacklist all tokens for a user (for logout-all-devices / password change)</summary>
    Task BlacklistAllUserTokensAsync(string userId, TimeSpan? ttl = null);

    /// <summary>Check if a user has been globally blacklisted</summary>
    Task<bool> IsUserBlacklistedAsync(string userId);
}

public class TokenBlacklistService : ITokenBlacklistService
{
    private readonly IConnectionMultiplexer _redis;
    private readonly ILogger<TokenBlacklistService> _logger;
    private const string TokenKeyPrefix = "blacklist:token:";
    private const string UserKeyPrefix = "blacklist:user:";
    private static readonly TimeSpan DefaultTtl = TimeSpan.FromHours(25); // slightly more than JWT lifetime (24h)

    public TokenBlacklistService(
        IConnectionMultiplexer redis,
        ILogger<TokenBlacklistService> logger)
    {
        _redis = redis;
        _logger = logger;
    }

    public async Task BlacklistTokenAsync(string jwtToken, TimeSpan? ttl = null)
    {
        try
        {
            var db = _redis.GetDatabase();
            var key = TokenKeyPrefix + ComputeSha256Hash(jwtToken);
            var expiry = ttl ?? DefaultTtl;

            await db.StringSetAsync(key, "revoked", expiry);
            _logger.LogInformation("Token blacklisted. TTL: {TTL} seconds", expiry.TotalSeconds);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to blacklist token in Redis");
            // Don't throw — graceful degradation. Log the error but don't break logout.
        }
    }

    public async Task<bool> IsTokenBlacklistedAsync(string jwtToken)
    {
        try
        {
            var db = _redis.GetDatabase();
            var key = TokenKeyPrefix + ComputeSha256Hash(jwtToken);
            return await db.KeyExistsAsync(key);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to check token blacklist in Redis");
            // On Redis failure, allow the request through (fail-open)
            // This is a trade-off: availability > perfect security for transient failures
            return false;
        }
    }

    public async Task BlacklistAllUserTokensAsync(string userId, TimeSpan? ttl = null)
    {
        try
        {
            var db = _redis.GetDatabase();
            var key = UserKeyPrefix + userId;
            var expiry = ttl ?? DefaultTtl;

            // Store the timestamp. Any token issued BEFORE this timestamp is invalid.
            await db.StringSetAsync(key, DateTime.UtcNow.ToString("O"), expiry);
            _logger.LogInformation("All tokens blacklisted for user {UserId}. TTL: {TTL}s", userId, expiry.TotalSeconds);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to blacklist all tokens for user {UserId}", userId);
        }
    }

    public async Task<bool> IsUserBlacklistedAsync(string userId)
    {
        try
        {
            var db = _redis.GetDatabase();
            var key = UserKeyPrefix + userId;
            return await db.KeyExistsAsync(key);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to check user blacklist for {UserId}", userId);
            return false;
        }
    }

    private static string ComputeSha256Hash(string input)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToBase64String(bytes);
    }
}
