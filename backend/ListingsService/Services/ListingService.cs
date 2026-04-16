using ListingsService.Models;
using ListingsService.Repositories;
using ListingsService.DTOs;
using ListingsService.Elasticsearch;
using Shared.Events.Listings;

namespace ListingsService.Services;

public interface IListingService
{
    Task<ListingDto> CreateListingAsync(string userId, CreateListingRequest request);
    Task<ListingDto?> GetListingByIdAsync(string id);
    Task<List<ListingDto>> GetUserListingsAsync(string userId, int skip = 0, int limit = 20);
    Task<List<ListingDto>> SearchListingsAsync(SearchFilterRequest filter);
    Task UpdateListingAsync(string id, string userId, UpdateListingRequest request);
    Task DeleteListingAsync(string id, string userId);
    Task<List<PriceDropDto>> GetPriceDropsAsync(int limit = 10);
}

public class ListingService : IListingService
{
    private readonly IListingRepository _repository;
    private readonly IEventBus _eventBus;
    private readonly ISearchService _searchService;
    private readonly ICacheService _cache;
    private readonly ILogger<ListingService> _logger;
    
    private const string PRICE_DROPS_CACHE_KEY = "price_drops";
    private static readonly TimeSpan CACHE_TTL = TimeSpan.FromMinutes(15);

    public ListingService(
        IListingRepository repository,
        IEventBus eventBus,
        ISearchService searchService,
        ICacheService cache,
        ILogger<ListingService> logger)
    {
        _repository = repository;
        _eventBus = eventBus;
        _searchService = searchService;
        _cache = cache;
        _logger = logger;
    }

    public async Task<ListingDto> CreateListingAsync(string userId, CreateListingRequest request)
    {
        _logger.LogInformation("Creating listing for user {UserId}", userId);

        var listing = new Listing
        {
            EmlakciId = userId,
            
            // Temel
            Baslik = request.Baslik,
            Aciklama = request.Aciklama,
            
            // Kategori
            Kategori = request.Kategori,
            AltKategori = request.AltKategori,
            IslemTipi = request.IslemTipi,
            EmlakTipi = request.Kategori, // Legacy compatibility
            
            // Fiyat
            Fiyat = request.Fiyat,
            
            // Ölçüler
            BrutMetrekare = request.BrutMetrekare,
            NetMetrekare = request.NetMetrekare,
            Metrekare = request.NetMetrekare, // Legacy compatibility
            
            // Oda & Bina
            OdaSayisi = request.OdaSayisi,
            BinaYasi = request.BinaYasi,
            BanyoSayisi = request.BanyoSayisi,
            BulunduguKat = request.BulunduguKat,
            KatSayisi = request.KatSayisi,
            
            // Özellikler
            IsitmaTipi = request.IsitmaTipi,
            Esyali = request.Esyali,
            Balkon = request.Balkon,
            Asansor = request.Asansor,
            Otopark = request.Otopark,
            SiteIcerisinde = request.SiteIcerisinde,
            Havuz = request.Havuz,
            Guvenlik = request.Guvenlik,
            
            // Satış Detayları
            KrediyeUygun = request.KrediyeUygun,
            Takasli = request.Takasli,
            TapuDurumu = request.TapuDurumu,
            Kimden = request.Kimden,
            
            // Konum
            Il = request.Il,
            Ilce = request.Ilce,
            Mahalle = request.Mahalle,
            Konum = request.Latitude.HasValue && request.Longitude.HasValue
                ? new GeoLocation
                {
                    Type = "Point",
                    Coordinates = new[] { request.Longitude.Value, request.Latitude.Value }
                }
                : null
        };

        var created = await _repository.CreateAsync(listing);

        // Index to Elasticsearch
        await _searchService.IndexListingAsync(created);

        // Publish ListingCreated event
        await _eventBus.PublishAsync(new ListingCreatedEvent
        {
            ListingId = created.Id,
            UserId = created.EmlakciId,
            Baslik = created.Baslik,
            EmlakTipi = created.Kategori,
            IslemTipi = created.IslemTipi,
            Fiyat = created.Fiyat,
            Il = created.Il,
            Ilce = created.Ilce,
            Latitude = created.Konum?.Coordinates[1] ?? 0,
            Longitude = created.Konum?.Coordinates[0] ?? 0
        });

        _logger.LogInformation("Listing created {ListingId}, event published", created.Id);

        return MapToDto(created);
    }

    public async Task<ListingDto?> GetListingByIdAsync(string id)
    {
        var listing = await _repository.GetByIdAsync(id);
        if (listing == null) return null;

        // Increment view count
        await _repository.IncrementViewCountAsync(id);

        // Publish ListingViewed event
        await _eventBus.PublishAsync(new ListingViewedEvent
        {
            ListingId = id,
            ViewerIpAddress = "unknown"
        });

        return MapToDto(listing);
    }

    public async Task<List<ListingDto>> GetUserListingsAsync(string userId, int skip = 0, int limit = 20)
    {
        var listings = await _repository.GetByUserAsync(userId, skip, limit);
        return listings.Select(MapToDto).ToList();
    }

    /// <summary>
    /// Search listings with Sahibinden-style advanced filters
    /// </summary>
    public async Task<List<ListingDto>> SearchListingsAsync(SearchFilterRequest filter)
    {
        _logger.LogInformation("Searching listings with advanced filters");
        
        var searchResults = await _searchService.SearchAsync(filter);
        
        // Map search documents to DTOs
        return searchResults.Select(doc => new ListingDto(
            Id: doc.Id,
            EmlakciId: doc.EmlakciId,
            Baslik: doc.Baslik,
            Aciklama: doc.Aciklama,
            Kategori: doc.Kategori,
            AltKategori: doc.AltKategori,
            IslemTipi: doc.IslemTipi,
            EmlakTipi: doc.EmlakTipi,
            Fiyat: doc.Fiyat,
            BrutMetrekare: doc.BrutMetrekare,
            NetMetrekare: doc.NetMetrekare,
            Metrekare: doc.Metrekare,
            OdaSayisi: doc.OdaSayisi,
            BinaYasi: doc.BinaYasi,
            BanyoSayisi: doc.BanyoSayisi,
            BulunduguKat: doc.BulunduguKat,
            KatSayisi: doc.KatSayisi,
            IsitmaTipi: doc.IsitmaTipi,
            Esyali: doc.Esyali,
            Balkon: doc.Balkon,
            Asansor: doc.Asansor,
            Otopark: doc.Otopark,
            SiteIcerisinde: doc.SiteIcerisinde,
            Havuz: doc.Havuz,
            Guvenlik: doc.Guvenlik,
            // New Sahibinden fields
            GirisYuksekligi: null,
            ZeminEtudu: null,
            Devren: null,
            Kiracili: null,
            YapininDurumu: null,
            AdaParsel: null,
            Gabari: null,
            KaksEmsal: null,
            KatKarsiligi: null,
            ImarDurumu: null,
            Manzara: doc.Manzara ?? new List<string>(),
            Cephe: doc.Cephe ?? new List<string>(),
            Ulasim: doc.Ulasim ?? new List<string>(),
            Muhit: doc.Muhit ?? new List<string>(),
            IcOzellikler: new List<string>(),
            DisOzellikler: new List<string>(),
            EngelliyeUygunluk: new List<string>(),
            AcilSatilik: doc.AcilSatilik,
            FiyatiDustu: doc.FiyatiDustu,
            KrediyeUygun: doc.KrediyeUygun,
            Takasli: doc.Takasli,
            TapuDurumu: doc.TapuDurumu,
            Kimden: doc.Kimden,
            Il: doc.Il,
            Ilce: doc.Ilce,
            Mahalle: doc.Mahalle,
            Latitude: doc.Location?.Coordinates[1],
            Longitude: doc.Location?.Coordinates[0],
            Fotograflar: doc.Fotograflar,
            Aktif: doc.Aktif,
            GoruntulemeSayisi: 0,
            CreatedAt: doc.CreatedAt
        )).ToList();
    }

    public async Task UpdateListingAsync(string id, string userId, UpdateListingRequest request)
    {
        var existing = await _repository.GetByIdAsync(id);
        if (existing == null || existing.EmlakciId != userId)
        {
            throw new UnauthorizedAccessException("Cannot update this listing");
        }

        decimal? oldPrice = null;

        // Update fields if provided
        if (request.Baslik != null) existing.Baslik = request.Baslik;
        if (request.Aciklama != null) existing.Aciklama = request.Aciklama;
        if (request.BrutMetrekare.HasValue) existing.BrutMetrekare = request.BrutMetrekare;
        if (request.NetMetrekare.HasValue) existing.NetMetrekare = request.NetMetrekare;
        if (request.OdaSayisi != null) existing.OdaSayisi = request.OdaSayisi;
        if (request.BinaYasi != null) existing.BinaYasi = request.BinaYasi;
        if (request.BanyoSayisi.HasValue) existing.BanyoSayisi = request.BanyoSayisi;
        if (request.IsitmaTipi != null) existing.IsitmaTipi = request.IsitmaTipi;
        if (request.Esyali.HasValue) existing.Esyali = request.Esyali.Value;
        if (request.Balkon.HasValue) existing.Balkon = request.Balkon.Value;
        if (request.Asansor.HasValue) existing.Asansor = request.Asansor.Value;
        if (request.Otopark.HasValue) existing.Otopark = request.Otopark.Value;
        if (request.SiteIcerisinde.HasValue) existing.SiteIcerisinde = request.SiteIcerisinde.Value;
        if (request.Havuz.HasValue) existing.Havuz = request.Havuz.Value;
        if (request.Guvenlik.HasValue) existing.Guvenlik = request.Guvenlik.Value;
        if (request.KrediyeUygun.HasValue) existing.KrediyeUygun = request.KrediyeUygun.Value;
        if (request.Takasli.HasValue) existing.Takasli = request.Takasli.Value;
        if (request.TapuDurumu != null) existing.TapuDurumu = request.TapuDurumu;
        if (request.Kimden != null) existing.Kimden = request.Kimden;
        if (request.Aktif.HasValue) existing.Aktif = request.Aktif.Value;
        
        if (request.Fiyat.HasValue && request.Fiyat.Value != existing.Fiyat)
        {
            oldPrice = existing.Fiyat;
            existing.Fiyat = request.Fiyat.Value;
        }

        existing.UpdatedAt = DateTime.UtcNow;
        await _repository.UpdateAsync(id, existing);

        // Re-index to Elasticsearch
        await _searchService.IndexListingAsync(existing);

        // Publish ListingUpdated event
        await _eventBus.PublishAsync(new ListingUpdatedEvent
        {
            ListingId = id,
            UserId = userId,
            OldFiyat = oldPrice,
            NewFiyat = request.Fiyat
        });

        // If price changed significantly, publish price changed event
        if (oldPrice.HasValue && request.Fiyat.HasValue)
        {
            var changePercentage = Math.Abs((request.Fiyat.Value - oldPrice.Value) / oldPrice.Value * 100);
            if (changePercentage > 5)
            {
                await _searchService.UpdatePriceAsync(id, request.Fiyat.Value, oldPrice.Value);

                await _eventBus.PublishAsync(new ListingPriceChangedEvent
                {
                    ListingId = id,
                    OldPrice = oldPrice.Value,
                    NewPrice = request.Fiyat.Value,
                    ChangePercentage = changePercentage
                });
            }
        }

        _logger.LogInformation("Listing updated {ListingId}", id);
    }

    public async Task DeleteListingAsync(string id, string userId)
    {
        var existing = await _repository.GetByIdAsync(id);
        if (existing == null || existing.EmlakciId != userId)
        {
            throw new UnauthorizedAccessException("Cannot delete this listing");
        }

        await _repository.DeleteAsync(id);
        await _searchService.DeleteListingAsync(id);

        await _eventBus.PublishAsync(new ListingDeletedEvent
        {
            ListingId = id,
            UserId = userId
        });

        _logger.LogInformation("Listing deleted {ListingId}", id);
    }

    private ListingDto MapToDto(Listing listing) => new ListingDto(
        Id: listing.Id,
        EmlakciId: listing.EmlakciId,
        Baslik: listing.Baslik,
        Aciklama: listing.Aciklama,
        Kategori: listing.Kategori,
        AltKategori: listing.AltKategori,
        IslemTipi: listing.IslemTipi,
        EmlakTipi: listing.EmlakTipi,
        Fiyat: listing.Fiyat,
        BrutMetrekare: listing.BrutMetrekare,
        NetMetrekare: listing.NetMetrekare,
        Metrekare: listing.Metrekare,
        OdaSayisi: listing.OdaSayisi,
        BinaYasi: listing.BinaYasi,
        BanyoSayisi: listing.BanyoSayisi,
        BulunduguKat: listing.BulunduguKat,
        KatSayisi: listing.KatSayisi,
        IsitmaTipi: listing.IsitmaTipi,
        Esyali: listing.Esyali,
        Balkon: listing.Balkon,
        Asansor: listing.Asansor,
        Otopark: listing.Otopark,
        SiteIcerisinde: listing.SiteIcerisinde,
        Havuz: listing.Havuz,
        Guvenlik: listing.Guvenlik,
        // New Sahibinden fields
        GirisYuksekligi: listing.GirisYuksekligi,
        ZeminEtudu: listing.ZeminEtudu,
        Devren: listing.Devren,
        Kiracili: listing.Kiracili,
        YapininDurumu: listing.YapininDurumu,
        AdaParsel: listing.AdaParsel,
        Gabari: listing.Gabari,
        KaksEmsal: listing.KaksEmsal,
        KatKarsiligi: listing.KatKarsiligi,
        ImarDurumu: listing.ImarDurumu,
        Manzara: listing.Manzara ?? new List<string>(),
        Cephe: listing.Cephe ?? new List<string>(),
        Ulasim: listing.Ulasim ?? new List<string>(),
        Muhit: listing.Muhit ?? new List<string>(),
        IcOzellikler: listing.IcOzellikler ?? new List<string>(),
        DisOzellikler: listing.DisOzellikler ?? new List<string>(),
        EngelliyeUygunluk: listing.EngelliyeUygunluk ?? new List<string>(),
        AcilSatilik: listing.AcilSatilik,
        FiyatiDustu: listing.FiyatiDustu,
        KrediyeUygun: listing.KrediyeUygun,
        Takasli: listing.Takasli,
        TapuDurumu: listing.TapuDurumu,
        Kimden: listing.Kimden,
        Il: listing.Il,
        Ilce: listing.Ilce,
        Mahalle: listing.Mahalle,
        Latitude: listing.Konum?.Coordinates[1],
        Longitude: listing.Konum?.Coordinates[0],
        Fotograflar: listing.Fotograflar,
        Aktif: listing.Aktif,
        GoruntulemeSayisi: listing.GoruntulemeSayisi,
        CreatedAt: listing.CreatedAt
    );

    /// <summary>
    /// Get listings with the biggest price drops in the last 24 hours (cached for 15 min)
    /// </summary>
    public async Task<List<PriceDropDto>> GetPriceDropsAsync(int limit = 10)
    {
        var cacheKey = $"{PRICE_DROPS_CACHE_KEY}:{limit}";
        
        var cached = await _cache.GetAsync<List<PriceDropDto>>(cacheKey);
        if (cached != null)
        {
            _logger.LogInformation("Price drops served from cache ({Count} items)", cached.Count);
            return cached;
        }

        _logger.LogInformation("Fetching top {Limit} price drops from Elasticsearch", limit);
        var searchResults = await _searchService.GetPriceDropsAsync(hours: 24, minDiscountPercent: 5, limit: limit);

        var result = searchResults.Select(doc => new PriceDropDto(
            Id: doc.Id,
            Baslik: doc.Baslik,
            Kategori: doc.Kategori,
            AltKategori: doc.AltKategori,
            IslemTipi: doc.IslemTipi,
            Fiyat: doc.Fiyat,
            OldPrice: doc.OldPrice ?? doc.Fiyat,
            DiscountPercent: Math.Abs(doc.PriceChangePercent ?? 0),
            Il: doc.Il,
            Ilce: doc.Ilce,
            BrutMetrekare: doc.BrutMetrekare,
            OdaSayisi: doc.OdaSayisi,
            Fotograflar: doc.Fotograflar,
            PriceUpdatedAt: doc.PriceUpdatedAt ?? DateTime.UtcNow
        )).ToList();

        await _cache.SetAsync(cacheKey, result, CACHE_TTL);
        
        return result;
    }
}
