using MongoDB.Driver;
using ListingsService.Models;
using Microsoft.Extensions.Options;

namespace ListingsService.Repositories;

public interface IAgencyRepository
{
    Task<Agency?> GetByIdAsync(string id);
    Task<Agency?> GetByOwnerIdAsync(string ownerId);
    Task<List<Agency>> GetAllAsync(int skip = 0, int limit = 20);
    Task<List<Agency>> SearchAsync(string? il, string? ilce, string? query, int skip = 0, int limit = 20);
    Task<Agency> CreateAsync(Agency agency);
    Task UpdateAsync(string id, Agency agency);
    Task<long> GetCountAsync();
}

public class AgencyRepository : IAgencyRepository
{
    private readonly IMongoCollection<Agency> _collection;

    public AgencyRepository(IMongoClient client, IOptions<MongoDBSettings> settings)
    {
        var database = client.GetDatabase(settings.Value.DatabaseName);
        _collection = database.GetCollection<Agency>("agencies");
    }

    public async Task<Agency?> GetByIdAsync(string id)
    {
        return await _collection.Find(a => a.Id == id && a.Aktif).FirstOrDefaultAsync();
    }

    public async Task<Agency?> GetByOwnerIdAsync(string ownerId)
    {
        return await _collection.Find(a => a.OwnerId == ownerId && a.Aktif).FirstOrDefaultAsync();
    }

    public async Task<List<Agency>> GetAllAsync(int skip = 0, int limit = 20)
    {
        return await _collection
            .Find(a => a.Aktif)
            .SortByDescending(a => a.Onaylanmis)
            .ThenByDescending(a => a.AktifIlan)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<Agency>> SearchAsync(string? il, string? ilce, string? query, int skip = 0, int limit = 20)
    {
        var builder = Builders<Agency>.Filter;
        var filter = builder.Eq(a => a.Aktif, true);

        if (!string.IsNullOrEmpty(il))
            filter &= builder.Eq(a => a.Il, il);

        if (!string.IsNullOrEmpty(ilce))
            filter &= builder.Eq(a => a.Ilce, ilce);

        if (!string.IsNullOrEmpty(query))
            filter &= builder.Regex(a => a.FirmaAdi, new MongoDB.Bson.BsonRegularExpression(query, "i"));

        return await _collection
            .Find(filter)
            .SortByDescending(a => a.Onaylanmis)
            .ThenByDescending(a => a.AktifIlan)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<Agency> CreateAsync(Agency agency)
    {
        await _collection.InsertOneAsync(agency);
        return agency;
    }

    public async Task UpdateAsync(string id, Agency agency)
    {
        agency.UpdatedAt = DateTime.UtcNow;
        await _collection.ReplaceOneAsync(a => a.Id == id, agency);
    }

    public async Task<long> GetCountAsync()
    {
        return await _collection.CountDocumentsAsync(a => a.Aktif);
    }
}
