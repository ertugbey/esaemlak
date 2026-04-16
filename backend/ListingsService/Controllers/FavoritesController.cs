using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ListingsService.Repositories;
using System.Security.Claims;

namespace ListingsService.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FavoritesController : ControllerBase
{
    private readonly IFavoriteRepository _favoriteRepository;
    private readonly ILogger<FavoritesController> _logger;

    public FavoritesController(IFavoriteRepository favoriteRepository, ILogger<FavoritesController> logger)
    {
        _favoriteRepository = favoriteRepository;
        _logger = logger;
    }

    private string GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? 
                                  User.FindFirst("sub")?.Value ?? 
                                  throw new UnauthorizedAccessException("User ID not found");

    /// <summary>
    /// Get all favorites for the current user
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetFavorites()
    {
        var userId = GetUserId();
        var favorites = await _favoriteRepository.GetUserFavoritesAsync(userId);
        return Ok(favorites);
    }

    /// <summary>
    /// Add a listing to favorites
    /// </summary>
    [HttpPost("{listingId}")]
    public async Task<IActionResult> AddFavorite(string listingId)
    {
        var userId = GetUserId();
        
        // Check if already favorited
        var existing = await _favoriteRepository.IsFavoritedAsync(userId, listingId);
        if (existing)
        {
            return Conflict(new { message = "Bu ilan zaten favorilerde" });
        }

        await _favoriteRepository.AddFavoriteAsync(userId, listingId);
        _logger.LogInformation("User {UserId} added listing {ListingId} to favorites", userId, listingId);
        
        return Ok(new { message = "Favorilere eklendi" });
    }

    /// <summary>
    /// Remove a listing from favorites
    /// </summary>
    [HttpDelete("{listingId}")]
    public async Task<IActionResult> RemoveFavorite(string listingId)
    {
        var userId = GetUserId();
        await _favoriteRepository.RemoveFavoriteAsync(userId, listingId);
        _logger.LogInformation("User {UserId} removed listing {ListingId} from favorites", userId, listingId);
        
        return Ok(new { message = "Favorilerden çıkarıldı" });
    }

    /// <summary>
    /// Check if a listing is favorited
    /// </summary>
    [HttpGet("{listingId}/check")]
    public async Task<IActionResult> CheckFavorite(string listingId)
    {
        var userId = GetUserId();
        var isFavorited = await _favoriteRepository.IsFavoritedAsync(userId, listingId);
        return Ok(new { isFavorited });
    }
}
