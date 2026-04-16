using MongoDB.Driver;
using ListingsService.Models;

namespace ListingsService.Repositories;

public interface IFavoriteRepository
{
    Task<List<Favorite>> GetUserFavoritesAsync(string userId);
    Task AddFavoriteAsync(string userId, string listingId);
    Task RemoveFavoriteAsync(string userId, string listingId);
    Task<bool> IsFavoritedAsync(string userId, string listingId);
}

public class FavoriteRepository : IFavoriteRepository
{
    private readonly IMongoCollection<Favorite> _favorites;

    public FavoriteRepository(IMongoDatabase database)
    {
        _favorites = database.GetCollection<Favorite>("favorites");
        
        // Create compound index for efficient queries
        var indexKeys = Builders<Favorite>.IndexKeys
            .Ascending(f => f.UserId)
            .Ascending(f => f.ListingId);
        _favorites.Indexes.CreateOne(new CreateIndexModel<Favorite>(indexKeys, new CreateIndexOptions { Unique = true }));
    }

    public async Task<List<Favorite>> GetUserFavoritesAsync(string userId)
    {
        return await _favorites
            .Find(f => f.UserId == userId)
            .SortByDescending(f => f.CreatedAt)
            .ToListAsync();
    }

    public async Task AddFavoriteAsync(string userId, string listingId)
    {
        var favorite = new Favorite
        {
            UserId = userId,
            ListingId = listingId,
            CreatedAt = DateTime.UtcNow
        };

        try
        {
            await _favorites.InsertOneAsync(favorite);
        }
        catch (MongoWriteException ex) when (ex.WriteError.Category == ServerErrorCategory.DuplicateKey)
        {
            // Already favorited, ignore
        }
    }

    public async Task RemoveFavoriteAsync(string userId, string listingId)
    {
        await _favorites.DeleteOneAsync(f => f.UserId == userId && f.ListingId == listingId);
    }

    public async Task<bool> IsFavoritedAsync(string userId, string listingId)
    {
        return await _favorites.Find(f => f.UserId == userId && f.ListingId == listingId).AnyAsync();
    }
}
