using Microsoft.AspNetCore.Mvc;
using ListingsService.Elasticsearch;
using ListingsService.DTOs;

namespace ListingsService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SearchController : ControllerBase
{
    private readonly ISearchService _searchService;
    private readonly ILogger<SearchController> _logger;

    public SearchController(ISearchService searchService, ILogger<SearchController> logger)
    {
        _searchService = searchService;
        _logger = logger;
    }

    /// <summary>
    /// Basic search with query parameters (backward compatible)
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Search(
        [FromQuery] string? q,
        [FromQuery] string? il,
        [FromQuery] string? ilce,
        [FromQuery] string? kategori,
        [FromQuery] string? altKategori,
        [FromQuery] string? islemTipi,
        [FromQuery] decimal? minFiyat,
        [FromQuery] decimal? maxFiyat,
        [FromQuery] int? minMetrekare,
        [FromQuery] int? maxMetrekare,
        [FromQuery] string? odaSayisi,
        [FromQuery] int skip = 0,
        [FromQuery] int limit = 20)
    {
        _logger.LogInformation("Search request: q={Query}, il={City}, kategori={Kategori}", q, il, kategori);
        
        // Build filter from query params
        var filter = new SearchFilterRequest(
            Query: q,
            Kategori: kategori,
            AltKategori: altKategori,
            IslemTipi: islemTipi,
            Il: il,
            Ilce: ilce,
            MinFiyat: minFiyat,
            MaxFiyat: maxFiyat,
            MinMetrekare: minMetrekare,
            MaxMetrekare: maxMetrekare,
            OdaSayilari: string.IsNullOrEmpty(odaSayisi) ? null : new List<string> { odaSayisi },
            BinaYaslari: null,
            Esyali: null,
            Balkon: null,
            Asansor: null,
            Otopark: null,
            SiteIcerisinde: null,
            Havuz: null,
            Guvenlik: null,
            KrediyeUygun: null,
            Manzara: null,
            Cephe: null,
            AcilSatilik: null,
            FiyatiDustu: null,
            Kimden: null,
            NorthEastLat: null,
            NorthEastLon: null,
            SouthWestLat: null,
            SouthWestLon: null,
            Skip: skip,
            Limit: limit
        );
        
        var results = await _searchService.SearchAsync(filter);
        
        return Ok(new
        {
            total = results.Count,
            skip,
            limit,
            results
        });
    }

    /// <summary>
    /// Advanced search with full filter body (Sahibinden-style)
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> AdvancedSearch([FromBody] SearchFilterRequest filter)
    {
        _logger.LogInformation("Advanced search request with {FilterCount} filters", 
            CountActiveFilters(filter));
        
        var results = await _searchService.SearchAsync(filter);
        
        return Ok(new
        {
            total = results.Count,
            skip = filter.Skip,
            limit = filter.Limit,
            results
        });
    }

    /// <summary>
    /// Faceted search — returns results + aggregation counts for filter sidebar.
    /// Use this endpoint to show filter counts (e.g., "İstanbul (125)", "Ankara (84)")
    /// </summary>
    [HttpPost("faceted")]
    public async Task<IActionResult> FacetedSearch([FromBody] SearchFilterRequest filter)
    {
        _logger.LogInformation("Faceted search request with {FilterCount} filters",
            CountActiveFilters(filter));

        var result = await _searchService.FacetedSearchAsync(filter);

        return Ok(new
        {
            total = result.TotalCount,
            skip = filter.Skip,
            limit = filter.Limit,
            results = result.Results,
            facets = result.Facets
        });
    }

    private static int CountActiveFilters(SearchFilterRequest filter)
    {
        int count = 0;
        if (!string.IsNullOrEmpty(filter.Query)) count++;
        if (!string.IsNullOrEmpty(filter.Kategori)) count++;
        if (!string.IsNullOrEmpty(filter.AltKategori)) count++;
        if (!string.IsNullOrEmpty(filter.IslemTipi)) count++;
        if (!string.IsNullOrEmpty(filter.Il)) count++;
        if (!string.IsNullOrEmpty(filter.Ilce)) count++;
        if (filter.MinFiyat.HasValue) count++;
        if (filter.MaxFiyat.HasValue) count++;
        if (filter.MinMetrekare.HasValue) count++;
        if (filter.MaxMetrekare.HasValue) count++;
        if (filter.OdaSayilari?.Any() == true) count++;
        if (filter.BinaYaslari?.Any() == true) count++;
        if (filter.Esyali == true) count++;
        if (filter.Balkon == true) count++;
        if (filter.Asansor == true) count++;
        if (filter.Otopark == true) count++;
        if (filter.SiteIcerisinde == true) count++;
        if (filter.Havuz == true) count++;
        if (filter.Guvenlik == true) count++;
        if (filter.KrediyeUygun == true) count++;
        return count;
    }
}
