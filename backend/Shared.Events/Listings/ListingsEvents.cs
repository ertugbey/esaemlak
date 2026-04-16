namespace Shared.Events.Listings;

/// <summary>
/// Published when a new listing is created
/// </summary>
public class ListingCreatedEvent : BaseEvent
{
    public ListingCreatedEvent()
    {
        EventType = "listings.listing.created";
    }

    public string ListingId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string Baslik { get; set; } = string.Empty;
    public string EmlakTipi { get; set; } = string.Empty;
    public string IslemTipi { get; set; } = string.Empty;
    public decimal Fiyat { get; set; }
    public string Il { get; set; } = string.Empty;
    public string Ilce { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

/// <summary>
/// Published when a listing is updated
/// </summary>
public class ListingUpdatedEvent : BaseEvent
{
    public ListingUpdatedEvent()
    {
        EventType = "listings.listing.updated";
    }

    public string ListingId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public decimal? OldFiyat { get; set; }
    public decimal? NewFiyat { get; set; }
}

/// <summary>
/// Published when a listing is deleted
/// </summary>
public class ListingDeletedEvent : BaseEvent
{
    public ListingDeletedEvent()
    {
        EventType = "listings.listing.deleted";
    }

    public string ListingId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
}

/// <summary>
/// Published when a listing's price changes (for price alerts)
/// </summary>
public class ListingPriceChangedEvent : BaseEvent
{
    public ListingPriceChangedEvent()
    {
        EventType = "listings.listing.pricechanged";
    }

    public string ListingId { get; set; } = string.Empty;
    public decimal OldPrice { get; set; }
    public decimal NewPrice { get; set; }
    public decimal ChangePercentage { get; set; }
}

/// <summary>
/// Published when a listing is viewed
/// </summary>
public class ListingViewedEvent : BaseEvent
{
    public ListingViewedEvent()
    {
        EventType = "listings.listing.viewed";
    }

    public string ListingId { get; set; } = string.Empty;
    public string? UserId { get; set; } // Nullable for anonymous views
    public string ViewerIpAddress { get; set; } = string.Empty;
}
