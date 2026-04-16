using Nest;
using ListingsService.Models;
using ListingsService.DTOs;

namespace ListingsService.Elasticsearch;

/// <summary>
/// Elasticsearch document with all Sahibinden-style fields for indexing
/// </summary>
public class ListingSearchDocument
{
    public string Id { get; set; } = string.Empty;
    public string EmlakciId { get; set; } = string.Empty;
    
    // Temel
    public string Baslik { get; set; } = string.Empty;
    public string Aciklama { get; set; } = string.Empty;
    
    // Kategori
    public string Kategori { get; set; } = string.Empty;
    public string AltKategori { get; set; } = string.Empty;
    public string IslemTipi { get; set; } = string.Empty;
    public string EmlakTipi { get; set; } = string.Empty; // Legacy
    
    // Fiyat
    public decimal Fiyat { get; set; }
    public decimal? OldPrice { get; set; }
    public decimal? PriceChangePercent { get; set; }
    public DateTime? PriceUpdatedAt { get; set; }
    
    // Ölçüler
    public int? BrutMetrekare { get; set; }
    public int? NetMetrekare { get; set; }
    public double? Metrekare { get; set; } // Legacy
    
    // Oda & Bina
    public string? OdaSayisi { get; set; }
    public string? BinaYasi { get; set; }
    public int? BanyoSayisi { get; set; }
    public int? BulunduguKat { get; set; }
    public int? KatSayisi { get; set; }
    
    // Özellikler
    public string? IsitmaTipi { get; set; }
    public bool Esyali { get; set; }
    public bool Balkon { get; set; }
    public bool Asansor { get; set; }
    public bool Otopark { get; set; }
    public bool SiteIcerisinde { get; set; }
    public bool Havuz { get; set; }
    public bool Guvenlik { get; set; }
    
    // Satış Detayları
    public bool KrediyeUygun { get; set; }
    public bool Takasli { get; set; }
    public string? TapuDurumu { get; set; }
    public string? Kimden { get; set; }
    
    // İş Yeri Alanları
    public double? GirisYuksekligi { get; set; }
    public bool? ZeminEtudu { get; set; }
    public bool? Devren { get; set; }
    public bool? Kiracili { get; set; }
    public string? YapininDurumu { get; set; }
    
    // Arsa Alanları
    public string? AdaParsel { get; set; }
    public double? Gabari { get; set; }
    public double? KaksEmsal { get; set; }
    public bool? KatKarsiligi { get; set; }
    public string? ImarDurumu { get; set; }
    
    // Özellik Listeleri
    public List<string> Manzara { get; set; } = new();
    public List<string> Cephe { get; set; } = new();
    public List<string> Ulasim { get; set; } = new();
    public List<string> Muhit { get; set; } = new();
    public List<string> IcOzellikler { get; set; } = new();
    public List<string> DisOzellikler { get; set; } = new();
    public List<string> EngelliyeUygunluk { get; set; } = new();
    
    // Promosyon
    public bool AcilSatilik { get; set; }
    public bool FiyatiDustu { get; set; }
    
    // Konum
    public string Il { get; set; } = string.Empty;
    public string Ilce { get; set; } = string.Empty;
    public string? Mahalle { get; set; }
    public Models.GeoLocation? Location { get; set; }
    
    // Medya & Durum
    public List<string> Fotograflar { get; set; } = new();
    public bool Aktif { get; set; }
    public DateTime CreatedAt { get; set; }
}

public interface ISearchService
{
    Task IndexListingAsync(Listing listing);
    Task UpdatePriceAsync(string listingId, decimal newPrice, decimal oldPrice);
    Task DeleteListingAsync(string id);
    Task<List<ListingSearchDocument>> SearchAsync(SearchFilterRequest filter);
    Task<FacetedSearchResult> FacetedSearchAsync(SearchFilterRequest filter);
    Task<List<ListingSearchDocument>> GetPriceDropsAsync(int hours = 24, decimal minDiscountPercent = 5, int limit = 10);
}

/// <summary>
/// Search result with aggregation facets for filtering UI
/// </summary>
public class FacetedSearchResult
{
    public List<ListingSearchDocument> Results { get; set; } = new();
    public long TotalCount { get; set; }
    public Dictionary<string, List<FacetBucket>> Facets { get; set; } = new();
}

public class FacetBucket
{
    public string Key { get; set; } = string.Empty;
    public long Count { get; set; }
}

public class ElasticsearchService : ISearchService
{
    private readonly IElasticClient _client;
    private readonly ILogger<ElasticsearchService> _logger;
    private const string IndexName = "emlaktan-listings";

    public ElasticsearchService(IElasticClient client, ILogger<ElasticsearchService> logger)
    {
        _client = client;
        _logger = logger;
        try
        {
            EnsureIndexExists().Wait();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Elasticsearch index oluşturulamıyor, servis devam ediyor");
        }
    }

    private async Task EnsureIndexExists()
    {
        var exists = await _client.Indices.ExistsAsync(IndexName);
        if (!exists.Exists)
        {
            var response = await _client.Indices.CreateAsync(IndexName, c => c
                // Custom Turkish analyzer with stemmer, stopwords, ASCII folding
                .Settings(s => s
                    .Analysis(a => a
                        .Analyzers(an => an
                            .Custom("turkish_custom", ca => ca
                                .Tokenizer("standard")
                                .Filters("lowercase", "turkish_stop", "turkish_stemmer", "asciifolding")
                            )
                        )
                        .TokenFilters(tf => tf
                            .Stop("turkish_stop", st => st
                                .StopWords("_turkish_")
                            )
                            .Stemmer("turkish_stemmer", st => st
                                .Language("turkish")
                            )
                        )
                    )
                    .NumberOfShards(1)
                    .NumberOfReplicas(0)
                )
                .Map<ListingSearchDocument>(m => m
                    .AutoMap()
                    .Properties(p => p
                        // Text fields with custom Turkish analyzer
                        .Text(t => t.Name(n => n.Baslik).Analyzer("turkish_custom").Boost(2))
                        .Text(t => t.Name(n => n.Aciklama).Analyzer("turkish_custom"))
                        
                        // Keyword fields for exact matching & aggregations
                        .Keyword(k => k.Name(n => n.Kategori))
                        .Keyword(k => k.Name(n => n.AltKategori))
                        .Keyword(k => k.Name(n => n.IslemTipi))
                        .Keyword(k => k.Name(n => n.EmlakTipi))
                        .Keyword(k => k.Name(n => n.OdaSayisi))
                        .Keyword(k => k.Name(n => n.BinaYasi))
                        .Keyword(k => k.Name(n => n.IsitmaTipi))
                        .Keyword(k => k.Name(n => n.TapuDurumu))
                        .Keyword(k => k.Name(n => n.Kimden))
                        .Keyword(k => k.Name(n => n.Il))
                        .Keyword(k => k.Name(n => n.Ilce))
                        .Keyword(k => k.Name(n => n.Mahalle))
                        
                        // Boolean fields
                        .Boolean(b => b.Name(n => n.Esyali))
                        .Boolean(b => b.Name(n => n.Balkon))
                        .Boolean(b => b.Name(n => n.Asansor))
                        .Boolean(b => b.Name(n => n.Otopark))
                        .Boolean(b => b.Name(n => n.SiteIcerisinde))
                        .Boolean(b => b.Name(n => n.Havuz))
                        .Boolean(b => b.Name(n => n.Guvenlik))
                        .Boolean(b => b.Name(n => n.KrediyeUygun))
                        .Boolean(b => b.Name(n => n.Takasli))
                        .Boolean(b => b.Name(n => n.Aktif))
                        .Boolean(b => b.Name(n => n.AcilSatilik))
                        .Boolean(b => b.Name(n => n.FiyatiDustu))
                        .Boolean(b => b.Name(n => n.Devren))
                        .Boolean(b => b.Name(n => n.Kiracili))
                        .Boolean(b => b.Name(n => n.KatKarsiligi))
                        
                        // Keyword arrays
                        .Keyword(k => k.Name(n => n.Manzara))
                        .Keyword(k => k.Name(n => n.Cephe))
                        .Keyword(k => k.Name(n => n.Ulasim))
                        .Keyword(k => k.Name(n => n.Muhit))
                        .Keyword(k => k.Name(n => n.IcOzellikler))
                        .Keyword(k => k.Name(n => n.DisOzellikler))
                        .Keyword(k => k.Name(n => n.EngelliyeUygunluk))
                        .Keyword(k => k.Name(n => n.YapininDurumu))
                        .Keyword(k => k.Name(n => n.ImarDurumu))
                        .Keyword(k => k.Name(n => n.AdaParsel))
                        
                        // Numeric fields
                        .Number(n => n.Name(x => x.GirisYuksekligi).Type(NumberType.Double))
                        .Number(n => n.Name(x => x.Gabari).Type(NumberType.Double))
                        .Number(n => n.Name(x => x.KaksEmsal).Type(NumberType.Double))
                        
                        // Geo location
                        .GeoPoint(g => g.Name(n => n.Location))
                    )
                )
            );
            _logger.LogInformation("Created Elasticsearch index with custom Turkish analyzer: {IndexName}", IndexName);
        }
    }

    public async Task IndexListingAsync(Listing listing)
    {
        var doc = new ListingSearchDocument
        {
            Id = listing.Id,
            EmlakciId = listing.EmlakciId,
            Baslik = listing.Baslik,
            Aciklama = listing.Aciklama,
            Kategori = listing.Kategori,
            AltKategori = listing.AltKategori,
            IslemTipi = listing.IslemTipi,
            EmlakTipi = listing.EmlakTipi,
            Fiyat = listing.Fiyat,
            BrutMetrekare = listing.BrutMetrekare,
            NetMetrekare = listing.NetMetrekare,
            Metrekare = listing.Metrekare,
            OdaSayisi = listing.OdaSayisi,
            BinaYasi = listing.BinaYasi,
            BanyoSayisi = listing.BanyoSayisi,
            BulunduguKat = listing.BulunduguKat,
            KatSayisi = listing.KatSayisi,
            IsitmaTipi = listing.IsitmaTipi,
            Esyali = listing.Esyali,
            Balkon = listing.Balkon,
            Asansor = listing.Asansor,
            Otopark = listing.Otopark,
            SiteIcerisinde = listing.SiteIcerisinde,
            Havuz = listing.Havuz,
            Guvenlik = listing.Guvenlik,
            KrediyeUygun = listing.KrediyeUygun,
            Takasli = listing.Takasli,
            TapuDurumu = listing.TapuDurumu,
            Kimden = listing.Kimden,
            // İş Yeri Alanları
            GirisYuksekligi = listing.GirisYuksekligi,
            ZeminEtudu = listing.ZeminEtudu,
            Devren = listing.Devren,
            Kiracili = listing.Kiracili,
            YapininDurumu = listing.YapininDurumu,
            // Arsa Alanları
            AdaParsel = listing.AdaParsel,
            Gabari = listing.Gabari,
            KaksEmsal = listing.KaksEmsal,
            KatKarsiligi = listing.KatKarsiligi,
            ImarDurumu = listing.ImarDurumu,
            // Özellik Listeleri
            Manzara = listing.Manzara,
            Cephe = listing.Cephe,
            Ulasim = listing.Ulasim,
            Muhit = listing.Muhit,
            IcOzellikler = listing.IcOzellikler,
            DisOzellikler = listing.DisOzellikler,
            EngelliyeUygunluk = listing.EngelliyeUygunluk,
            // Promosyon
            AcilSatilik = listing.AcilSatilik,
            FiyatiDustu = listing.FiyatiDustu,
            // Konum
            Il = listing.Il,
            Ilce = listing.Ilce,
            Mahalle = listing.Mahalle,
            Location = listing.Konum,
            Fotograflar = listing.Fotograflar,
            Aktif = listing.Aktif,
            CreatedAt = listing.CreatedAt
        };

        await _client.IndexDocumentAsync(doc);
        _logger.LogInformation("Indexed listing {ListingId} to Elasticsearch", listing.Id);
    }

    public async Task DeleteListingAsync(string id)
    {
        await _client.DeleteAsync<ListingSearchDocument>(id, d => d.Index(IndexName));
        _logger.LogInformation("Deleted listing {ListingId} from Elasticsearch", id);
    }

    /// <summary>
    /// Advanced search with Sahibinden-style filters
    /// </summary>
    public async Task<List<ListingSearchDocument>> SearchAsync(SearchFilterRequest filter)
    {
        var response = await _client.SearchAsync<ListingSearchDocument>(s => s
            .Index(IndexName)
            .From(filter.Skip)
            .Size(filter.Limit)
            .Query(q => q
                .Bool(b => b
                    .Must(BuildMustQueries(filter))
                    .Filter(BuildFilterQueries(filter))
                )
            )
            .Sort(so => so.Descending(p => p.CreatedAt))
        );

        _logger.LogInformation("Search returned {Count} results", response.Documents.Count);
        return response.Documents.ToList();
    }

    private Func<QueryContainerDescriptor<ListingSearchDocument>, QueryContainer>[] BuildMustQueries(SearchFilterRequest filter)
    {
        var queries = new List<Func<QueryContainerDescriptor<ListingSearchDocument>, QueryContainer>>();

        // Text search
        if (!string.IsNullOrEmpty(filter.Query))
        {
            queries.Add(q => q.MultiMatch(mm => mm
                .Fields(f => f.Field(p => p.Baslik, 2).Field(p => p.Aciklama))
                .Query(filter.Query)
                .Fuzziness(Fuzziness.Auto)
            ));
        }

        // Always filter for active listings
        queries.Add(q => q.Term(t => t.Field(f => f.Aktif).Value(true)));

        return queries.ToArray();
    }

    private Func<QueryContainerDescriptor<ListingSearchDocument>, QueryContainer>[] BuildFilterQueries(SearchFilterRequest filter)
    {
        var filters = new List<Func<QueryContainerDescriptor<ListingSearchDocument>, QueryContainer>>();

        // Kategori filters
        if (!string.IsNullOrEmpty(filter.Kategori))
            filters.Add(f => f.Term(t => t.Field(p => p.Kategori).Value(filter.Kategori)));

        if (!string.IsNullOrEmpty(filter.AltKategori))
            filters.Add(f => f.Term(t => t.Field(p => p.AltKategori).Value(filter.AltKategori)));

        if (!string.IsNullOrEmpty(filter.IslemTipi))
            filters.Add(f => f.Term(t => t.Field(p => p.IslemTipi).Value(filter.IslemTipi)));

        // Konum filters
        if (!string.IsNullOrEmpty(filter.Il))
            filters.Add(f => f.Term(t => t.Field(p => p.Il).Value(filter.Il)));

        if (!string.IsNullOrEmpty(filter.Ilce))
            filters.Add(f => f.Term(t => t.Field(p => p.Ilce).Value(filter.Ilce)));

        // Price range
        if (filter.MinFiyat.HasValue || filter.MaxFiyat.HasValue)
        {
            filters.Add(f => f.Range(r => r
                .Field(p => p.Fiyat)
                .GreaterThanOrEquals((double?)filter.MinFiyat)
                .LessThanOrEquals((double?)filter.MaxFiyat)
            ));
        }

        // Metrekare range (using BrutMetrekare)
        if (filter.MinMetrekare.HasValue || filter.MaxMetrekare.HasValue)
        {
            filters.Add(f => f.Range(r => r
                .Field(p => p.BrutMetrekare)
                .GreaterThanOrEquals(filter.MinMetrekare)
                .LessThanOrEquals(filter.MaxMetrekare)
            ));
        }

        // Multi-select oda sayısı
        if (filter.OdaSayilari != null && filter.OdaSayilari.Any())
        {
            filters.Add(f => f.Terms(t => t.Field(p => p.OdaSayisi).Terms(filter.OdaSayilari)));
        }

        // Multi-select bina yaşı
        if (filter.BinaYaslari != null && filter.BinaYaslari.Any())
        {
            filters.Add(f => f.Terms(t => t.Field(p => p.BinaYasi).Terms(filter.BinaYaslari)));
        }

        // Boolean feature filters
        if (filter.Esyali == true)
            filters.Add(f => f.Term(t => t.Field(p => p.Esyali).Value(true)));

        if (filter.Balkon == true)
            filters.Add(f => f.Term(t => t.Field(p => p.Balkon).Value(true)));

        if (filter.Asansor == true)
            filters.Add(f => f.Term(t => t.Field(p => p.Asansor).Value(true)));

        if (filter.Otopark == true)
            filters.Add(f => f.Term(t => t.Field(p => p.Otopark).Value(true)));

        if (filter.SiteIcerisinde == true)
            filters.Add(f => f.Term(t => t.Field(p => p.SiteIcerisinde).Value(true)));

        if (filter.Havuz == true)
            filters.Add(f => f.Term(t => t.Field(p => p.Havuz).Value(true)));

        if (filter.Guvenlik == true)
            filters.Add(f => f.Term(t => t.Field(p => p.Guvenlik).Value(true)));

        if (filter.KrediyeUygun == true)
            filters.Add(f => f.Term(t => t.Field(p => p.KrediyeUygun).Value(true)));

        // Promosyon filtreleri
        if (filter.AcilSatilik == true)
            filters.Add(f => f.Term(t => t.Field(p => p.AcilSatilik).Value(true)));

        if (filter.FiyatiDustu == true)
            filters.Add(f => f.Term(t => t.Field(p => p.FiyatiDustu).Value(true)));

        // Manzara filtresi (çoklu seçim)
        if (filter.Manzara != null && filter.Manzara.Any())
        {
            filters.Add(f => f.Terms(t => t.Field(p => p.Manzara).Terms(filter.Manzara)));
        }

        // Cephe filtresi (çoklu seçim)
        if (filter.Cephe != null && filter.Cephe.Any())
        {
            filters.Add(f => f.Terms(t => t.Field(p => p.Cephe).Terms(filter.Cephe)));
        }

        // Kimden filter
        if (!string.IsNullOrEmpty(filter.Kimden))
            filters.Add(f => f.Term(t => t.Field(p => p.Kimden).Value(filter.Kimden)));

        // ================== GEO BOUNDING BOX FILTER ==================
        // Filter listings within visible map area (for map-based search)
        if (filter.NorthEastLat.HasValue && filter.NorthEastLon.HasValue &&
            filter.SouthWestLat.HasValue && filter.SouthWestLon.HasValue)
        {
            filters.Add(f => f.GeoBoundingBox(geo => geo
                .Field(p => p.Location)
                .BoundingBox(bb => bb
                    .TopLeft(filter.NorthEastLat.Value, filter.SouthWestLon.Value)
                    .BottomRight(filter.SouthWestLat.Value, filter.NorthEastLon.Value)
                )
            ));
            
            _logger.LogInformation(
                "Geo-BoundingBox filter applied: NE({NeLat},{NeLon}) SW({SwLat},{SwLon})",
                filter.NorthEastLat, filter.NorthEastLon, filter.SouthWestLat, filter.SouthWestLon);
        }

        return filters.ToArray();
    }

    /// <summary>
    /// Update price in Elasticsearch when a price change event occurs
    /// </summary>
    public async Task UpdatePriceAsync(string listingId, decimal newPrice, decimal oldPrice)
    {
        var changePercent = ((newPrice - oldPrice) / oldPrice) * 100;

        var updateResponse = await _client.UpdateAsync<ListingSearchDocument, object>(
            listingId,
            u => u
                .Index(IndexName)
                .Doc(new 
                {
                    Fiyat = newPrice,
                    OldPrice = oldPrice,
                    PriceChangePercent = changePercent,
                    PriceUpdatedAt = DateTime.UtcNow
                })
                .DocAsUpsert(false)
        );

        if (updateResponse.IsValid)
        {
            _logger.LogInformation(
                "Updated price in Elasticsearch for listing {ListingId}: {OldPrice} -> {NewPrice} ({ChangePercent:F1}%)",
                listingId, oldPrice, newPrice, changePercent);
        }
        else
        {
            _logger.LogWarning("Failed to update price in Elasticsearch for listing {ListingId}: {Error}",
                listingId, updateResponse.OriginalException?.Message);
        }
    }

    /// <summary>
    /// Get listings with price drops in the last N hours
    /// </summary>
    public async Task<List<ListingSearchDocument>> GetPriceDropsAsync(int hours = 24, decimal minDiscountPercent = 5, int limit = 10)
    {
        var cutoffTime = DateTime.UtcNow.AddHours(-hours);

        var response = await _client.SearchAsync<ListingSearchDocument>(s => s
            .Index(IndexName)
            .Size(limit)
            .Query(q => q
                .Bool(b => b
                    .Must(
                        m => m.Term(t => t.Field(f => f.Aktif).Value(true)),
                        m => m.DateRange(dr => dr
                            .Field(f => f.PriceUpdatedAt)
                            .GreaterThanOrEquals(cutoffTime)
                        ),
                        m => m.Range(r => r
                            .Field(f => f.PriceChangePercent)
                            .LessThanOrEquals((double)(-minDiscountPercent))
                        )
                    )
                )
            )
            .Sort(so => so.Ascending(f => f.PriceChangePercent))
        );

        _logger.LogInformation("GetPriceDrops returned {Count} listings with discounts >= {MinPercent}%",
            response.Documents.Count, minDiscountPercent);

        return response.Documents.ToList();
    }

    /// <summary>
    /// Faceted search: returns results + aggregation counts for filter sidebar
    /// </summary>
    public async Task<FacetedSearchResult> FacetedSearchAsync(SearchFilterRequest filter)
    {
        var response = await _client.SearchAsync<ListingSearchDocument>(s => s
            .Index(IndexName)
            .From(filter.Skip)
            .Size(filter.Limit)
            .Query(q => q
                .Bool(b => b
                    .Must(BuildMustQueries(filter))
                    .Filter(BuildFilterQueries(filter))
                )
            )
            .Sort(so => so.Descending(p => p.CreatedAt))
            // === AGGREGATIONS FOR FACETED SEARCH ===
            .Aggregations(agg => agg
                .Terms("kategori_facet", t => t.Field(f => f.Kategori).Size(10))
                .Terms("altKategori_facet", t => t.Field(f => f.AltKategori).Size(20))
                .Terms("il_facet", t => t.Field(f => f.Il).Size(82))
                .Terms("ilce_facet", t => t.Field(f => f.Ilce).Size(50))
                .Terms("islemTipi_facet", t => t.Field(f => f.IslemTipi).Size(5))
                .Terms("odaSayisi_facet", t => t.Field(f => f.OdaSayisi).Size(15))
                .Terms("binaYasi_facet", t => t.Field(f => f.BinaYasi).Size(10))
                .Terms("isitmaTipi_facet", t => t.Field(f => f.IsitmaTipi).Size(10))
                .Terms("kimden_facet", t => t.Field(f => f.Kimden).Size(5))
                .Range("fiyat_facet", r => r
                    .Field(f => f.Fiyat)
                    .Ranges(
                        rr => rr.To(500_000),
                        rr => rr.From(500_000).To(1_000_000),
                        rr => rr.From(1_000_000).To(2_000_000),
                        rr => rr.From(2_000_000).To(5_000_000),
                        rr => rr.From(5_000_000).To(10_000_000),
                        rr => rr.From(10_000_000)
                    )
                )
            )
        );

        var result = new FacetedSearchResult
        {
            Results = response.Documents.ToList(),
            TotalCount = response.Total,
            Facets = new Dictionary<string, List<FacetBucket>>()
        };

        // Extract term aggregations
        var termFacets = new[] { "kategori_facet", "altKategori_facet", "il_facet", "ilce_facet",
            "islemTipi_facet", "odaSayisi_facet", "binaYasi_facet", "isitmaTipi_facet", "kimden_facet" };

        foreach (var facetName in termFacets)
        {
            var agg = response.Aggregations.Terms(facetName);
            if (agg?.Buckets != null)
            {
                result.Facets[facetName.Replace("_facet", "")] = agg.Buckets
                    .Select(b => new FacetBucket { Key = b.Key, Count = b.DocCount ?? 0 })
                    .ToList();
            }
        }

        // Extract range aggregation for price
        var priceAgg = response.Aggregations.Range("fiyat_facet");
        if (priceAgg?.Buckets != null)
        {
            result.Facets["fiyat"] = priceAgg.Buckets
                .Select(b => new FacetBucket { Key = b.Key, Count = b.DocCount })
                .ToList();
        }

        _logger.LogInformation(
            "Faceted search returned {Count}/{Total} results with {FacetCount} facets",
            result.Results.Count, result.TotalCount, result.Facets.Count);

        return result;
    }
}

/// <summary>
/// Elasticsearch bağlantısı yokken kullanılan boş implementasyon.
/// Arama işlemleri MongoDB'ye fallback yapar.
/// </summary>
public class NoOpElasticsearchService : ISearchService
{
    private readonly ILogger<NoOpElasticsearchService> _logger;

    public NoOpElasticsearchService(ILogger<NoOpElasticsearchService> logger)
    {
        _logger = logger;
    }

    public Task IndexListingAsync(Listing listing)
    {
        _logger.LogDebug("[NoOp] IndexListingAsync: {Id}", listing.Id);
        return Task.CompletedTask;
    }

    public Task UpdatePriceAsync(string listingId, decimal newPrice, decimal oldPrice)
    {
        _logger.LogDebug("[NoOp] UpdatePriceAsync: {Id}", listingId);
        return Task.CompletedTask;
    }

    public Task DeleteListingAsync(string id)
    {
        _logger.LogDebug("[NoOp] DeleteListingAsync: {Id}", id);
        return Task.CompletedTask;
    }

    public Task<List<ListingSearchDocument>> SearchAsync(SearchFilterRequest filter)
    {
        _logger.LogDebug("[NoOp] SearchAsync çalıştırıldı (Elasticsearch yok)");
        return Task.FromResult(new List<ListingSearchDocument>());
    }

    public Task<FacetedSearchResult> FacetedSearchAsync(SearchFilterRequest filter)
    {
        _logger.LogDebug("[NoOp] FacetedSearchAsync çalıştırıldı (Elasticsearch yok)");
        return Task.FromResult(new FacetedSearchResult());
    }

    public Task<List<ListingSearchDocument>> GetPriceDropsAsync(int hours = 24, decimal minDiscountPercent = 5, int limit = 10)
    {
        return Task.FromResult(new List<ListingSearchDocument>());
    }
}
