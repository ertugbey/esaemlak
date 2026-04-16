using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ListingsService.Repositories;
using ListingsService.Services;
using ListingsService.Elasticsearch;

namespace ListingsService.Controllers;

[ApiController]
[Route("api/listings/admin")]
[Authorize(Roles = "admin")]
public class AdminListingsController : ControllerBase
{
    private readonly IListingRepository _repository;
    private readonly ISearchService _searchService;
    private readonly ILogger<AdminListingsController> _logger;

    public AdminListingsController(
        IListingRepository repository,
        ISearchService searchService,
        ILogger<AdminListingsController> logger)
    {
        _repository = repository;
        _searchService = searchService;
        _logger = logger;
    }

    /// <summary>Admin: Tüm ilanları listele (filtreli + sayfalı)</summary>
    [HttpGet("all")]
    public async Task<IActionResult> GetAllListings(
        [FromQuery] int skip = 0,
        [FromQuery] int limit = 20,
        [FromQuery] string? search = null,
        [FromQuery] string? kategori = null,
        [FromQuery] string? islemTipi = null,
        [FromQuery] bool? aktif = null,
        [FromQuery] bool? onaylandi = null)
    {
        var listings = await _repository.GetAdminAllAsync(skip, limit, search, kategori, islemTipi, aktif, onaylandi);
        var total = await _repository.GetAdminCountAsync(search, kategori, islemTipi, aktif, onaylandi);

        return Ok(new
        {
            total,
            skip,
            limit,
            listings = listings.Select(l => new
            {
                l.Id,
                l.EmlakciId,
                l.Baslik,
                l.Kategori,
                l.AltKategori,
                l.IslemTipi,
                l.Fiyat,
                l.Il,
                l.Ilce,
                l.BrutMetrekare,
                l.NetMetrekare,
                l.OdaSayisi,
                l.Fotograflar,
                l.Aktif,
                l.Onaylandi,
                l.GoruntulemeSayisi,
                l.CreatedAt,
                l.UpdatedAt
            })
        });
    }

    /// <summary>Admin: Onay bekleyen ilanlar</summary>
    [HttpGet("pending")]
    public async Task<IActionResult> GetPendingListings(
        [FromQuery] int skip = 0,
        [FromQuery] int limit = 20)
    {
        var listings = await _repository.GetPendingAsync(skip, limit);
        var total = await _repository.GetPendingCountAsync();

        return Ok(new
        {
            total,
            skip,
            limit,
            listings = listings.Select(l => new
            {
                l.Id,
                l.EmlakciId,
                l.Baslik,
                l.Aciklama,
                l.Kategori,
                l.AltKategori,
                l.IslemTipi,
                l.Fiyat,
                l.Il,
                l.Ilce,
                l.Mahalle,
                l.BrutMetrekare,
                l.OdaSayisi,
                l.Fotograflar,
                l.CreatedAt
            })
        });
    }

    /// <summary>Admin: İlanı onayla</summary>
    [HttpPatch("{id}/approve")]
    public async Task<IActionResult> ApproveListing(string id)
    {
        var listing = await _repository.GetByIdAsync(id);
        if (listing == null) return NotFound(new { error = "İlan bulunamadı" });

        await _repository.ApproveAsync(id, true);
        await _searchService.IndexListingAsync(listing); // Re-index after approval

        _logger.LogInformation("Admin approved listing {ListingId}", id);
        return Ok(new { message = "İlan onaylandı", id });
    }

    /// <summary>Admin: İlanı reddet (aktif = false)</summary>
    [HttpPatch("{id}/reject")]
    public async Task<IActionResult> RejectListing(string id)
    {
        var listing = await _repository.GetByIdAsync(id);
        if (listing == null) return NotFound(new { error = "İlan bulunamadı" });

        await _repository.ApproveAsync(id, false);
        await _searchService.DeleteListingAsync(id); // Remove from search index

        _logger.LogWarning("Admin rejected listing {ListingId}", id);
        return Ok(new { message = "İlan reddedildi", id });
    }

    /// <summary>Admin: İlanı zorla sil (sahiplik kontrolü yok)</summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> AdminDeleteListing(string id)
    {
        var listing = await _repository.GetByIdAsync(id);
        if (listing == null) return NotFound(new { error = "İlan bulunamadı" });

        await _repository.DeleteAsync(id);
        await _searchService.DeleteListingAsync(id);

        _logger.LogWarning("Admin force-deleted listing {ListingId}", id);
        return Ok(new { message = "İlan silindi", id });
    }

    /// <summary>Admin: İlan istatistikleri</summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var stats = await _repository.GetAdminStatsAsync();
        return Ok(stats);
    }

    /// <summary>Admin: Tek ilan detayı</summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetListing(string id)
    {
        var l = await _repository.GetByIdAsync(id);
        if (l == null) return NotFound(new { error = "İlan bulunamadı" });
        return Ok(l);
    }
}
