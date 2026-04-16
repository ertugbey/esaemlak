using MongoDB.Driver;
using ListingsService.Models;
using Microsoft.Extensions.Options;

namespace ListingsService.Repositories;

public interface IListingRepository
{
    Task<Listing?> GetByIdAsync(string id);
    Task<List<Listing>> GetAllAsync(int skip = 0, int limit = 20);
    Task<List<Listing>> GetByUserAsync(string userId, int skip = 0, int limit = 20);
    Task<Listing> CreateAsync(Listing listing);
    Task UpdateAsync(string id, Listing listing);
    Task DeleteAsync(string id);
    Task IncrementViewCountAsync(string id);
    Task<long> GetCountAsync();
    Task<List<Listing>> GetAcilSatilikAsync(int limit = 10);
    Task<List<Listing>> GetFiyatiDusenlerAsync(int limit = 10);
    Task<List<Listing>> GetSonEklenenlerAsync(int hours = 48, int limit = 10);
    Task<List<Listing>> GetCokGoruntulenlerAsync(int limit = 10);
    // Admin methods
    Task<List<Listing>> GetAdminAllAsync(int skip, int limit, string? search, string? kategori, string? islemTipi, bool? aktif, bool? onaylandi);
    Task<long> GetAdminCountAsync(string? search, string? kategori, string? islemTipi, bool? aktif, bool? onaylandi);
    Task<List<Listing>> GetPendingAsync(int skip, int limit);
    Task<long> GetPendingCountAsync();
    Task ApproveAsync(string id, bool approve);
    Task<AdminListingStats> GetAdminStatsAsync();
}

public class AdminListingStats
{
    public long Total { get; set; }
    public long Active { get; set; }
    public long Pending { get; set; }
    public long NewLast7Days { get; set; }
    public long NewLast30Days { get; set; }
    public long TotalViews { get; set; }
}

public class ListingRepository : IListingRepository
{
    private readonly IMongoCollection<Listing> _listings;
    private readonly ILogger<ListingRepository> _logger;

    public ListingRepository(
        IMongoDatabase database,
        IOptions<MongoDBSettings> settings,
        ILogger<ListingRepository> logger)
    {
        _listings = database.GetCollection<Listing>(settings.Value.ListingsCollectionName);
        _logger = logger;
        CreateIndexes().Wait();
    }

    private async Task CreateIndexes()
    {
        try
        {
            var userIdIndex = new CreateIndexModel<Listing>(
                Builders<Listing>.IndexKeys.Ascending(l => l.EmlakciId)
            );

            var activeIndex = new CreateIndexModel<Listing>(
                Builders<Listing>.IndexKeys.Ascending(l => l.Aktif)
            );

            await _listings.Indexes.CreateManyAsync(new[] { userIdIndex, activeIndex });
            _logger.LogInformation("MongoDB basic indexes created for listings");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error creating basic indexes (may already exist)");
        }

        // Geo index ayrı oluştur — hatalı GeoJSON verisi varsa patlamasın
        try
        {
            var geoIndex = new CreateIndexModel<Listing>(
                Builders<Listing>.IndexKeys.Geo2DSphere(l => l.Konum)
            );
            await _listings.Indexes.CreateManyAsync(new[] { geoIndex });
            _logger.LogInformation("MongoDB geo index created for listings");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Geo2DSphere index oluşturulamadı (hatalı GeoJSON verisi olabilir), konum araması devre dışı");
        }
    }

    public async Task<Listing?> GetByIdAsync(string id)
    {
        return await _listings.Find(l => l.Id == id).FirstOrDefaultAsync();
    }

    public async Task<List<Listing>> GetAllAsync(int skip = 0, int limit = 20)
    {
        return await _listings.Find(l => l.Aktif)
            .SortByDescending(l => l.CreatedAt)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<Listing>> GetByUserAsync(string userId, int skip = 0, int limit = 20)
    {
        return await _listings.Find(l => l.EmlakciId == userId)
            .SortByDescending(l => l.CreatedAt)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<Listing> CreateAsync(Listing listing)
    {
        listing.CreatedAt = DateTime.UtcNow;
        listing.UpdatedAt = DateTime.UtcNow;
        await _listings.InsertOneAsync(listing);
        _logger.LogInformation("Created listing {ListingId}", listing.Id);
        return listing;
    }

    public async Task UpdateAsync(string id, Listing listing)
    {
        listing.UpdatedAt = DateTime.UtcNow;
        await _listings.ReplaceOneAsync(l => l.Id == id, listing);
        _logger.LogInformation("Updated listing {ListingId}", id);
    }

    public async Task DeleteAsync(string id)
    {
        await _listings.DeleteOneAsync(l => l.Id == id);
        _logger.LogInformation("Deleted listing {ListingId}", id);
    }

    public async Task IncrementViewCountAsync(string id)
    {
        await _listings.UpdateOneAsync(
            l => l.Id == id,
            Builders<Listing>.Update.Inc(l => l.GoruntulemeSayisi, 1)
        );
    }

    public async Task<long> GetCountAsync()
    {
        return await _listings.CountDocumentsAsync(FilterDefinition<Listing>.Empty);
    }

    public async Task<List<Listing>> GetAcilSatilikAsync(int limit = 10)
    {
        return await _listings.Find(l => l.Aktif && l.AcilSatilik)
            .SortByDescending(l => l.GoruntulemeSayisi)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<Listing>> GetFiyatiDusenlerAsync(int limit = 10)
    {
        return await _listings.Find(l => l.Aktif && l.FiyatiDustu)
            .SortByDescending(l => l.UpdatedAt)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<Listing>> GetSonEklenenlerAsync(int hours = 48, int limit = 10)
    {
        var cutoff = DateTime.UtcNow.AddHours(-hours);
        return await _listings.Find(l => l.Aktif && l.CreatedAt >= cutoff)
            .SortByDescending(l => l.CreatedAt)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<Listing>> GetCokGoruntulenlerAsync(int limit = 10)
    {
        return await _listings.Find(l => l.Aktif)
            .SortByDescending(l => l.GoruntulemeSayisi)
            .Limit(limit)
            .ToListAsync();
    }

    // ===== ADMIN METHODS =====

    private FilterDefinition<Listing> BuildAdminFilter(string? search, string? kategori, string? islemTipi, bool? aktif, bool? onaylandi)
    {
        var filter = Builders<Listing>.Filter.Empty;
        if (!string.IsNullOrEmpty(search))
            filter &= Builders<Listing>.Filter.Regex(l => l.Baslik, new MongoDB.Bson.BsonRegularExpression(search, "i"));
        if (!string.IsNullOrEmpty(kategori))
            filter &= Builders<Listing>.Filter.Eq(l => l.Kategori, kategori);
        if (!string.IsNullOrEmpty(islemTipi))
            filter &= Builders<Listing>.Filter.Eq(l => l.IslemTipi, islemTipi);
        if (aktif.HasValue)
            filter &= Builders<Listing>.Filter.Eq(l => l.Aktif, aktif.Value);
        if (onaylandi.HasValue)
            filter &= Builders<Listing>.Filter.Eq(l => l.Onaylandi, onaylandi.Value);
        return filter;
    }

    public async Task<List<Listing>> GetAdminAllAsync(int skip, int limit, string? search, string? kategori, string? islemTipi, bool? aktif, bool? onaylandi)
    {
        var filter = BuildAdminFilter(search, kategori, islemTipi, aktif, onaylandi);
        return await _listings.Find(filter)
            .SortByDescending(l => l.CreatedAt)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<long> GetAdminCountAsync(string? search, string? kategori, string? islemTipi, bool? aktif, bool? onaylandi)
    {
        var filter = BuildAdminFilter(search, kategori, islemTipi, aktif, onaylandi);
        return await _listings.CountDocumentsAsync(filter);
    }

    public async Task<List<Listing>> GetPendingAsync(int skip, int limit)
    {
        return await _listings.Find(l => !l.Onaylandi && l.Aktif)
            .SortByDescending(l => l.CreatedAt)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<long> GetPendingCountAsync()
    {
        return await _listings.CountDocumentsAsync(l => !l.Onaylandi && l.Aktif);
    }

    public async Task ApproveAsync(string id, bool approve)
    {
        var update = Builders<Listing>.Update
            .Set(l => l.Onaylandi, approve)
            .Set(l => l.Aktif, approve)
            .Set(l => l.UpdatedAt, DateTime.UtcNow);
        await _listings.UpdateOneAsync(l => l.Id == id, update);
    }

    public async Task<AdminListingStats> GetAdminStatsAsync()
    {
        var now = DateTime.UtcNow;
        var allListings = await _listings.Find(FilterDefinition<Listing>.Empty).ToListAsync();
        return new AdminListingStats
        {
            Total = allListings.Count,
            Active = allListings.Count(l => l.Aktif),
            Pending = allListings.Count(l => !l.Onaylandi && l.Aktif),
            NewLast7Days = allListings.Count(l => l.CreatedAt >= now.AddDays(-7)),
            NewLast30Days = allListings.Count(l => l.CreatedAt >= now.AddDays(-30)),
            TotalViews = allListings.Sum(l => (long)l.GoruntulemeSayisi)
        };
    }
}
