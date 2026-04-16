using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ListingsService.Models;
using ListingsService.Repositories;
using System.Security.Claims;

namespace ListingsService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AgenciesController : ControllerBase
{
    private readonly IAgencyRepository _agencyRepository;
    private readonly IListingRepository _listingRepository;
    private readonly ILogger<AgenciesController> _logger;

    public AgenciesController(
        IAgencyRepository agencyRepository, 
        IListingRepository listingRepository,
        ILogger<AgenciesController> logger)
    {
        _agencyRepository = agencyRepository;
        _listingRepository = listingRepository;
        _logger = logger;
    }

    /// <summary>
    /// Get all agencies with pagination
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int skip = 0, [FromQuery] int limit = 20)
    {
        var agencies = await _agencyRepository.GetAllAsync(skip, limit);
        return Ok(agencies.Select(ToDto));
    }

    /// <summary>
    /// Search agencies by location and name
    /// </summary>
    [HttpGet("search")]
    public async Task<IActionResult> Search(
        [FromQuery] string? il,
        [FromQuery] string? ilce,
        [FromQuery] string? q,
        [FromQuery] int skip = 0,
        [FromQuery] int limit = 20)
    {
        var agencies = await _agencyRepository.SearchAsync(il, ilce, q, skip, limit);
        return Ok(agencies.Select(ToDto));
    }

    /// <summary>
    /// Get an agency by ID (store page)
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var agency = await _agencyRepository.GetByIdAsync(id);
        if (agency == null)
            return NotFound(new { message = "Emlak ofisi bulunamadı" });

        return Ok(ToDto(agency));
    }

    /// <summary>
    /// Get listings for a specific agency
    /// </summary>
    [HttpGet("{id}/listings")]
    public async Task<IActionResult> GetAgencyListings(
        string id, 
        [FromQuery] int skip = 0, 
        [FromQuery] int limit = 20)
    {
        var agency = await _agencyRepository.GetByIdAsync(id);
        if (agency == null)
            return NotFound(new { message = "Emlak ofisi bulunamadı" });

        // Get listings owned by the agency owner
        var listings = await _listingRepository.GetByUserAsync(agency.OwnerId, skip, limit);
        return Ok(listings);
    }

    /// <summary>
    /// Create a new agency (requires authentication)
    /// </summary>
    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] CreateAgencyRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        // Check if user already has an agency
        var existing = await _agencyRepository.GetByOwnerIdAsync(userId);
        if (existing != null)
            return BadRequest(new { message = "Zaten bir emlak ofisiniz var" });

        var agency = new Agency
        {
            OwnerId = userId,
            FirmaAdi = request.FirmaAdi,
            Telefon = request.Telefon,
            Telefon2 = request.Telefon2,
            Email = request.Email,
            Website = request.Website,
            WhatsApp = request.WhatsApp,
            Il = request.Il,
            Ilce = request.Ilce,
            Adres = request.Adres,
            Konum = request.Latitude.HasValue && request.Longitude.HasValue
                ? new GeoLocation { Coordinates = new double[] { request.Longitude.Value, request.Latitude.Value } }
                : null,
            Hakkinda = request.Hakkinda,
            KurulusYili = request.KurulusYili,
            VergiNo = request.VergiNo,
            CalismaSaatleri = request.CalismaSaatleri,
            CalismaGunleri = request.CalismaGunleri ?? new List<string> { "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma" },
            FacebookUrl = request.FacebookUrl,
            InstagramUrl = request.InstagramUrl,
            TwitterUrl = request.TwitterUrl,
            YouTubeUrl = request.YouTubeUrl
        };

        await _agencyRepository.CreateAsync(agency);
        _logger.LogInformation("Agency created: {AgencyId} by user {UserId}", agency.Id, userId);

        return CreatedAtAction(nameof(GetById), new { id = agency.Id }, ToDto(agency));
    }

    /// <summary>
    /// Get current user's agency
    /// </summary>
    [HttpGet("my")]
    [Authorize]
    public async Task<IActionResult> GetMyAgency()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        var agency = await _agencyRepository.GetByOwnerIdAsync(userId);
        if (agency == null)
            return NotFound(new { message = "Henüz bir emlak ofisiniz yok" });

        return Ok(ToDto(agency));
    }

    private static AgencyDto ToDto(Agency a) => new(
        a.Id,
        a.FirmaAdi,
        a.Logo,
        a.KapakFoto,
        a.Telefon,
        a.Email,
        a.Website,
        a.Il,
        a.Ilce,
        a.Adres,
        a.Hakkinda,
        a.KurulusYili,
        a.Onaylanmis,
        a.CalismaSaatleri,
        a.CalismaGunleri,
        a.FacebookUrl,
        a.InstagramUrl,
        a.ToplamIlan,
        a.AktifIlan,
        a.Puan,
        a.YorumSayisi,
        a.CreatedAt
    );
}
