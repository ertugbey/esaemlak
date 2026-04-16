using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ListingsService.DTOs;
using ListingsService.Repositories;
using ListingsService.Services;
using System.Security.Claims;

namespace ListingsService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ListingsController : ControllerBase
{
    private readonly IListingService _listingService;
    private readonly IShowcaseService _showcaseService;
    private readonly IListingRepository _repository;
    private readonly ILogger<ListingsController> _logger;

    public ListingsController(
        IListingService listingService, 
        IShowcaseService showcaseService,
        IListingRepository repository,
        ILogger<ListingsController> logger)
    {
        _listingService = listingService;
        _showcaseService = showcaseService;
        _repository = repository;
        _logger = logger;
    }

    /// <summary>
    /// Get all active listings with pagination
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAllListings([FromQuery] int skip = 0, [FromQuery] int limit = 20)
    {
        try
        {
            var listings = await _repository.GetAllAsync(skip, limit);
            return Ok(listings);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all listings");
            return Ok(new List<ListingDto>());
        }
    }

    /// <summary>
    /// Get a single listing by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<ListingDto>> GetListing(string id)
    {
        var listing = await _listingService.GetListingByIdAsync(id);
        if (listing == null)
        {
            return NotFound();
        }
        return Ok(listing);
    }

    /// <summary>
    /// Search listings with advanced Sahibinden-style filters
    /// </summary>
    [HttpPost("search")]
    public async Task<ActionResult<List<ListingDto>>> SearchListings([FromBody] SearchFilterRequest filter)
    {
        try
        {
            var listings = await _listingService.SearchListingsAsync(filter);
            return Ok(listings);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error searching listings");
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get listings with the biggest price drops in the last 24 hours
    /// </summary>
    [HttpGet("price-drops")]
    public async Task<ActionResult<List<PriceDropDto>>> GetPriceDrops([FromQuery] int limit = 10)
    {
        try
        {
            var listings = await _listingService.GetPriceDropsAsync(limit);
            return Ok(listings);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting price drops");
            return Ok(new List<PriceDropDto>());
        }
    }

    /// <summary>
    /// Get showcase data for homepage (Günün Fırsatları, Acil Satılık, Son Eklenenler, etc.)
    /// </summary>
    [HttpGet("showcase")]
    public async Task<ActionResult<ShowcaseDto>> GetShowcase()
    {
        try
        {
            var showcase = await _showcaseService.GetShowcaseAsync();
            return Ok(showcase);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting showcase data");
            return Ok(new ShowcaseDto());
        }
    }

    /// <summary>
    /// Diagnostic endpoint to check database state
    /// </summary>
    [HttpGet("debug")]
    public async Task<IActionResult> DebugListings()
    {
        try
        {
            var totalCount = await _repository.GetCountAsync();
            // Try to get ALL listings without Aktif filter
            var activeListings = await _repository.GetAllAsync(0, 5);
            return Ok(new
            {
                totalInDb = totalCount,
                activeCount = activeListings.Count,
                sampleActiveIds = activeListings.Select(l => new { l.Id, l.Baslik, l.Aktif, l.Onaylandi }).ToList(),
                dbInfo = "Collection: ilans, DB: EsaEmlakDb"
            });
        }
        catch (Exception ex)
        {
            return Ok(new { error = ex.Message, stack = ex.StackTrace });
        }
    }

    /// <summary>
    /// Get current user's listings
    /// </summary>
    [Authorize]
    [HttpGet("my-listings")]
    public async Task<ActionResult<List<ListingDto>>> GetMyListings([FromQuery] int skip = 0, [FromQuery] int limit = 20)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var listings = await _listingService.GetUserListingsAsync(userId, skip, limit);
        return Ok(listings);
    }

    /// <summary>
    /// Create a new listing with Sahibinden-style fields
    /// </summary>
    [Authorize]
    [HttpPost]
    public async Task<ActionResult<ListingDto>> CreateListing([FromBody] CreateListingRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        try
        {
            var listing = await _listingService.CreateListingAsync(userId, request);
            return CreatedAtAction(nameof(GetListing), new { id = listing.Id }, listing);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating listing");
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Update an existing listing
    /// </summary>
    [Authorize]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateListing(string id, [FromBody] UpdateListingRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        try
        {
            await _listingService.UpdateListingAsync(id, userId, request);
            return NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating listing {ListingId}", id);
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Delete a listing
    /// </summary>
    [Authorize]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteListing(string id)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        try
        {
            await _listingService.DeleteListingAsync(id, userId);
            return NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting listing {ListingId}", id);
            return BadRequest(new { error = ex.Message });
        }
    }
}
