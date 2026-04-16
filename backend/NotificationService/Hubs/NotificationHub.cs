using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace NotificationService.Hubs;

/// <summary>
/// SignalR Hub for real-time notifications (price alerts, new listings, etc.)
/// </summary>
[Authorize]
public class NotificationHub : Hub
{
    private readonly ILogger<NotificationHub> _logger;

    public NotificationHub(ILogger<NotificationHub> logger)
    {
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier;
        if (!string.IsNullOrEmpty(userId))
        {
            // Add user to their personal notification group
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
            _logger.LogInformation("🔔 User {UserId} connected to NotificationHub", userId);
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.UserIdentifier;
        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
            _logger.LogInformation("🔕 User {UserId} disconnected from NotificationHub", userId);
        }
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Subscribe to price alerts for a specific listing
    /// </summary>
    public async Task SubscribeToListing(string listingId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"listing_{listingId}");
        _logger.LogInformation("User {UserId} subscribed to listing {ListingId}", Context.UserIdentifier, listingId);
    }

    /// <summary>
    /// Unsubscribe from price alerts for a specific listing
    /// </summary>
    public async Task UnsubscribeFromListing(string listingId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"listing_{listingId}");
        _logger.LogInformation("User {UserId} unsubscribed from listing {ListingId}", Context.UserIdentifier, listingId);
    }
}
