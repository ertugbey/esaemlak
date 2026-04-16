namespace Shared.Events.Payment;

/// <summary>
/// Published when a payment is completed successfully
/// </summary>
public class PaymentCompletedEvent : BaseEvent
{
    public PaymentCompletedEvent()
    {
        EventType = "payment.payment.completed";
    }

    public string PaymentId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "TRY";
    public string PaymentProvider { get; set; } = "iyzico";
    public string TransactionId { get; set; } = string.Empty;
}

/// <summary>
/// Published when premium subscription is activated
/// </summary>
public class PremiumActivatedEvent : BaseEvent
{
    public PremiumActivatedEvent()
    {
        EventType = "payment.premium.activated";
    }

    public string UserId { get; set; } = string.Empty;
    public string SubscriptionType { get; set; } = string.Empty; // monthly, yearly
    public DateTime ExpiresAt { get; set; }
}
