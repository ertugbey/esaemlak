using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace PaymentService.Models;

public class Payment
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonElement("userId")]
    public string UserId { get; set; } = string.Empty;

    [BsonElement("amount")]
    public decimal Amount { get; set; }

    [BsonElement("currency")]
    public string Currency { get; set; } = "TRY";

    [BsonElement("paymentType")]
    public string PaymentType { get; set; } = string.Empty; // premium, featured_listing

    [BsonElement("status")]
    public string Status { get; set; } = "pending"; // pending, completed, failed, refunded

    [BsonElement("provider")]
    public string Provider { get; set; } = "iyzico";

    [BsonElement("transactionId")]
    public string? TransactionId { get; set; }

    [BsonElement("listingId")]
    public string? ListingId { get; set; } // For featured listings

    [BsonElement("metadata")]
    public Dictionary<string, string> Metadata { get; set; } = new();

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [BsonElement("completedAt")]
    public DateTime? CompletedAt { get; set; }
}

public class Subscription
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonElement("userId")]
    public string UserId { get; set; } = string.Empty;

    [BsonElement("plan")]
    public string Plan { get; set; } = string.Empty; // monthly, yearly

    [BsonElement("status")]
    public string Status { get; set; } = "active"; // active, cancelled, expired

    [BsonElement("startDate")]
    public DateTime StartDate { get; set; } = DateTime.UtcNow;

    [BsonElement("endDate")]
    public DateTime EndDate { get; set; }

    [BsonElement("autoRenew")]
    public bool AutoRenew { get; set; } = true;
}

public class MongoDBSettings
{
    public string ConnectionString { get; set; } = string.Empty;
    public string DatabaseName { get; set; } = string.Empty;
}

// DTOs
public record CreatePaymentRequest(decimal Amount, string PaymentType, string? ListingId);
public record PaymentResponse(string PaymentId, string Status, string? CheckoutUrl);
