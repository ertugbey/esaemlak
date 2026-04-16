using MongoDB.Driver;
using AuthService.Models;
using Microsoft.Extensions.Options;
using AuthService.Configuration;

namespace AuthService.Repositories;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(string id);
    Task<User?> GetByEmailAsync(string email);
    Task<User?> GetByPhoneAsync(string telefon);
    Task<User> CreateAsync(User user);
    Task UpdateAsync(string id, User user);
    Task<bool> DeleteAsync(string id);
    Task<bool> EmailExistsAsync(string email);
    Task<bool> PhoneExistsAsync(string telefon);
    // Refresh token
    Task UpdateRefreshTokenAsync(string userId, string refreshToken, DateTime expiry);
    Task<User?> GetByRefreshTokenAsync(string refreshToken);
    Task ClearRefreshTokenAsync(string userId);
    // Password reset
    Task UpdatePasswordResetTokenAsync(string userId, string token, DateTime expiry);
    Task UpdatePasswordAsync(string userId, string passwordHash);
    // Profile update
    Task UpdateProfileFieldsAsync(string userId, Dictionary<string, object?> updates);
    // Admin methods
    Task<List<User>> GetAllAsync(int skip, int limit, string? search, string? rol);
    Task<long> GetTotalCountAsync(string? search, string? rol);
    Task<User?> BanToggleAsync(string id);
    Task<User?> UpdateRolAsync(string id, string rol);
    Task<AdminUserStats> GetStatsAsync();
}

public class AdminUserStats
{
    public long Total { get; set; }
    public long NewLast7Days { get; set; }
    public long NewLast30Days { get; set; }
    public long Banned { get; set; }
    public long Admins { get; set; }
    public long Emlakcis { get; set; }
}

public class UserRepository : IUserRepository
{
    private readonly IMongoCollection<User> _users;
    private readonly ILogger<UserRepository> _logger;

    public UserRepository(
        IMongoDatabase database,
        IOptions<MongoDBSettings> settings,
        ILogger<UserRepository> logger)
    {
        _users = database.GetCollection<User>(settings.Value.UsersCollectionName);
        _logger = logger;

        // Create indexes
        CreateIndexes().Wait();
    }

    private async Task CreateIndexes()
    {
        try
        {
            var emailIndexModel = new CreateIndexModel<User>(
                Builders<User>.IndexKeys.Ascending(u => u.Email),
                new CreateIndexOptions { Unique = true }
            );

            var phoneIndexModel = new CreateIndexModel<User>(
                Builders<User>.IndexKeys.Ascending(u => u.Telefon),
                new CreateIndexOptions { Unique = true }
            );

            await _users.Indexes.CreateManyAsync(new[] { emailIndexModel, phoneIndexModel });
            _logger.LogInformation("MongoDB indexes created successfully");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error creating indexes (may already exist)");
        }
    }

    public async Task<User?> GetByIdAsync(string id)
    {
        _logger.LogDebug("Fetching user by ID: {UserId}", id);
        return await _users.Find(u => u.Id == id).FirstOrDefaultAsync();
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        _logger.LogDebug("Fetching user by email: {Email}", email);
        return await _users.Find(u => u.Email == email).FirstOrDefaultAsync();
    }

    public async Task<User?> GetByPhoneAsync(string telefon)
    {
        _logger.LogDebug("Fetching user by phone: {Phone}", telefon);
        return await _users.Find(u => u.Telefon == telefon).FirstOrDefaultAsync();
    }

    public async Task<User> CreateAsync(User user)
    {
        _logger.LogInformation("Creating new user: {Email}", user.Email);
        user.CreatedAt = DateTime.UtcNow;
        user.UpdatedAt = DateTime.UtcNow;
        await _users.InsertOneAsync(user);
        return user;
    }

    public async Task UpdateAsync(string id, User user)
    {
        _logger.LogInformation("Updating user: {UserId}", id);
        user.UpdatedAt = DateTime.UtcNow;
        await _users.ReplaceOneAsync(u => u.Id == id, user);
    }

    public async Task UpdateRefreshTokenAsync(string userId, string refreshToken, DateTime expiry)
    {
        var update = Builders<User>.Update
            .Set(u => u.RefreshToken, refreshToken)
            .Set(u => u.RefreshTokenExpiry, expiry)
            .Set(u => u.UpdatedAt, DateTime.UtcNow);
        await _users.UpdateOneAsync(u => u.Id == userId, update);
    }

    public async Task<User?> GetByRefreshTokenAsync(string refreshToken)
    {
        return await _users.Find(u => u.RefreshToken == refreshToken).FirstOrDefaultAsync();
    }

    public async Task ClearRefreshTokenAsync(string userId)
    {
        var update = Builders<User>.Update
            .Set(u => u.RefreshToken, (string?)null)
            .Set(u => u.RefreshTokenExpiry, (DateTime?)null)
            .Set(u => u.UpdatedAt, DateTime.UtcNow);
        await _users.UpdateOneAsync(u => u.Id == userId, update);
    }

    public async Task UpdatePasswordResetTokenAsync(string userId, string token, DateTime expiry)
    {
        var update = Builders<User>.Update
            .Set(u => u.PasswordResetToken, token)
            .Set(u => u.PasswordResetExpiry, expiry)
            .Set(u => u.UpdatedAt, DateTime.UtcNow);
        await _users.UpdateOneAsync(u => u.Id == userId, update);
    }

    public async Task UpdatePasswordAsync(string userId, string passwordHash)
    {
        var update = Builders<User>.Update
            .Set(u => u.PasswordHash, passwordHash)
            .Set(u => u.PasswordResetToken, (string?)null)
            .Set(u => u.PasswordResetExpiry, (DateTime?)null)
            .Set(u => u.UpdatedAt, DateTime.UtcNow);
        await _users.UpdateOneAsync(u => u.Id == userId, update);
    }

    public async Task UpdateProfileFieldsAsync(string userId, Dictionary<string, object?> updates)
    {
        var updateDefs = new List<UpdateDefinition<User>>();
        foreach (var kvp in updates)
        {
            updateDefs.Add(Builders<User>.Update.Set(kvp.Key, kvp.Value));
        }
        updateDefs.Add(Builders<User>.Update.Set(u => u.UpdatedAt, DateTime.UtcNow));
        var combinedUpdate = Builders<User>.Update.Combine(updateDefs);
        await _users.UpdateOneAsync(u => u.Id == userId, combinedUpdate);
    }

    public async Task<bool> DeleteAsync(string id)
    {
        _logger.LogInformation("Deleting user: {UserId}", id);
        var result = await _users.DeleteOneAsync(u => u.Id == id);
        return result.DeletedCount > 0;
    }

    public async Task<bool> EmailExistsAsync(string email)
    {
        return await _users.Find(u => u.Email == email).AnyAsync();
    }

    public async Task<bool> PhoneExistsAsync(string telefon)
    {
        return await _users.Find(u => u.Telefon == telefon).AnyAsync();
    }

    public async Task<List<User>> GetAllAsync(int skip, int limit, string? search, string? rol)
    {
        var filter = Builders<User>.Filter.Empty;
        if (!string.IsNullOrEmpty(search))
        {
            var searchFilter = Builders<User>.Filter.Or(
                Builders<User>.Filter.Regex(u => u.Ad, new MongoDB.Bson.BsonRegularExpression(search, "i")),
                Builders<User>.Filter.Regex(u => u.Soyad, new MongoDB.Bson.BsonRegularExpression(search, "i")),
                Builders<User>.Filter.Regex(u => u.Email, new MongoDB.Bson.BsonRegularExpression(search, "i"))
            );
            filter = Builders<User>.Filter.And(filter, searchFilter);
        }
        if (!string.IsNullOrEmpty(rol))
            filter = Builders<User>.Filter.And(filter, Builders<User>.Filter.Eq(u => u.Rol, rol));

        return await _users.Find(filter)
            .SortByDescending(u => u.CreatedAt)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<long> GetTotalCountAsync(string? search, string? rol)
    {
        var filter = Builders<User>.Filter.Empty;
        if (!string.IsNullOrEmpty(search))
        {
            var searchFilter = Builders<User>.Filter.Or(
                Builders<User>.Filter.Regex(u => u.Ad, new MongoDB.Bson.BsonRegularExpression(search, "i")),
                Builders<User>.Filter.Regex(u => u.Soyad, new MongoDB.Bson.BsonRegularExpression(search, "i")),
                Builders<User>.Filter.Regex(u => u.Email, new MongoDB.Bson.BsonRegularExpression(search, "i"))
            );
            filter = Builders<User>.Filter.And(filter, searchFilter);
        }
        if (!string.IsNullOrEmpty(rol))
            filter = Builders<User>.Filter.And(filter, Builders<User>.Filter.Eq(u => u.Rol, rol));
        return await _users.CountDocumentsAsync(filter);
    }

    public async Task<User?> BanToggleAsync(string id)
    {
        var user = await GetByIdAsync(id);
        if (user == null) return null;
        user.Banli = !user.Banli;
        user.UpdatedAt = DateTime.UtcNow;
        await _users.ReplaceOneAsync(u => u.Id == id, user);
        return user;
    }

    public async Task<User?> UpdateRolAsync(string id, string rol)
    {
        var user = await GetByIdAsync(id);
        if (user == null) return null;
        user.Rol = rol;
        user.UpdatedAt = DateTime.UtcNow;
        await _users.ReplaceOneAsync(u => u.Id == id, user);
        return user;
    }

    public async Task<AdminUserStats> GetStatsAsync()
    {
        var now = DateTime.UtcNow;
        var stats = new AdminUserStats
        {
            Total = await _users.CountDocumentsAsync(Builders<User>.Filter.Empty),
            NewLast7Days = await _users.CountDocumentsAsync(
                Builders<User>.Filter.Gte(u => u.CreatedAt, now.AddDays(-7))),
            NewLast30Days = await _users.CountDocumentsAsync(
                Builders<User>.Filter.Gte(u => u.CreatedAt, now.AddDays(-30))),
            Banned = await _users.CountDocumentsAsync(
                Builders<User>.Filter.Eq(u => u.Banli, true)),
            Admins = await _users.CountDocumentsAsync(
                Builders<User>.Filter.Eq(u => u.Rol, "admin")),
            Emlakcis = await _users.CountDocumentsAsync(
                Builders<User>.Filter.Eq(u => u.Rol, "emlakci"))
        };
        return stats;
    }
}
