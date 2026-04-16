using MongoDB.Driver;
using PaymentService.Models;
using Shared.Events.Payment;

namespace PaymentService.Services;

public interface IPaymentService
{
    Task<PaymentInitResult> InitiatePaymentAsync(string userId, CreatePaymentRequest request);
    Task<Payment> CompletePaymentAsync(string token);
    Task<Payment> RefundPaymentAsync(string paymentId, string userId);
    Task<Payment?> GetPaymentAsync(string paymentId);
    Task<List<Payment>> GetUserPaymentsAsync(string userId);
    Task<Subscription?> GetActiveSubscriptionAsync(string userId);
    Task<SubscriptionCancelResult> CancelSubscriptionAsync(string userId);
}

public class PaymentInitResult
{
    public string PaymentId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string CheckoutUrl { get; set; } = string.Empty;
    public string Token { get; set; } = string.Empty;
    public string? ErrorMessage { get; set; }
}

public class SubscriptionCancelResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
}

public class PaymentServiceImpl : IPaymentService
{
    private readonly IMongoClient _mongoClient;
    private readonly IMongoCollection<Payment> _payments;
    private readonly IMongoCollection<Subscription> _subscriptions;
    private readonly IIyzicoService _iyzicoService;
    private readonly IEventBus _eventBus;
    private readonly ILogger<PaymentServiceImpl> _logger;

    public PaymentServiceImpl(
        IMongoClient mongoClient,
        IMongoDatabase database,
        IIyzicoService iyzicoService,
        IEventBus eventBus,
        ILogger<PaymentServiceImpl> logger)
    {
        _mongoClient = mongoClient;
        _payments = database.GetCollection<Payment>("payments");
        _subscriptions = database.GetCollection<Subscription>("subscriptions");
        _iyzicoService = iyzicoService;
        _eventBus = eventBus;
        _logger = logger;
    }

    /// <summary>
    /// Step 1: Initiate payment — create pending record + iyzico checkout form
    /// </summary>
    public async Task<PaymentInitResult> InitiatePaymentAsync(string userId, CreatePaymentRequest request)
    {
        // Validate payment type and set correct amount from plan catalog
        var (validatedAmount, plan) = ValidatePaymentPlan(request.PaymentType, request.Amount);

        var payment = new Payment
        {
            UserId = userId,
            Amount = validatedAmount,
            PaymentType = request.PaymentType,
            ListingId = request.ListingId,
            Status = "pending"
        };

        await _payments.InsertOneAsync(payment);
        _logger.LogInformation("Created pending payment {PaymentId} for user {UserId}, type: {Type}", 
            payment.Id, userId, request.PaymentType);

        // Call iyzico to create checkout form
        var iyzicoResult = await _iyzicoService.CreateCheckoutFormAsync(new IyzicoPaymentRequest
        {
            BuyerId = userId,
            BuyerName = "EsaEmlak User",
            BuyerEmail = "user@esaemlak.com",
            Amount = validatedAmount,
            Currency = "TRY",
            PaymentType = request.PaymentType,
            ListingId = request.ListingId,
            CallbackUrl = $"/api/payments/callback?paymentId={payment.Id}"
        });

        if (!iyzicoResult.Success)
        {
            payment.Status = "failed";
            payment.Metadata["error"] = iyzicoResult.ErrorMessage ?? "iyzico checkout creation failed";
            await _payments.ReplaceOneAsync(p => p.Id == payment.Id, payment);

            return new PaymentInitResult
            {
                PaymentId = payment.Id,
                Status = "failed",
                ErrorMessage = iyzicoResult.ErrorMessage
            };
        }

        // Store token for callback verification
        payment.Metadata["iyzicoToken"] = iyzicoResult.Token;
        payment.Metadata["conversationId"] = iyzicoResult.ConversationId;
        await _payments.ReplaceOneAsync(p => p.Id == payment.Id, payment);

        return new PaymentInitResult
        {
            PaymentId = payment.Id,
            Status = "pending",
            CheckoutUrl = iyzicoResult.CheckoutUrl,
            Token = iyzicoResult.Token
        };
    }

    /// <summary>
    /// Step 2: Complete payment — verify with iyzico + activate subscription (MongoDB transaction)
    /// </summary>
    public async Task<Payment> CompletePaymentAsync(string token)
    {
        // Find payment by iyzico token
        var payment = await _payments.Find(p => 
            p.Metadata.ContainsKey("iyzicoToken") && p.Metadata["iyzicoToken"] == token)
            .FirstOrDefaultAsync();

        if (payment == null)
            throw new Exception("Payment not found for token");

        // Verify payment with iyzico
        var iyzicoResult = await _iyzicoService.RetrieveCheckoutResultAsync(token);
        
        if (!iyzicoResult.Success || iyzicoResult.Status != "SUCCESS")
        {
            payment.Status = "failed";
            payment.Metadata["iyzicoError"] = iyzicoResult.ErrorMessage ?? "Payment verification failed";
            await _payments.ReplaceOneAsync(p => p.Id == payment.Id, payment);
            throw new Exception($"Payment failed: {iyzicoResult.ErrorMessage}");
        }

        // === MongoDB TRANSACTION: Payment + Subscription in single transaction ===
        using var session = await _mongoClient.StartSessionAsync();
        session.StartTransaction();

        try
        {
            // Update payment as completed
            payment.Status = "completed";
            payment.TransactionId = iyzicoResult.TransactionId;
            payment.CompletedAt = DateTime.UtcNow;
            payment.Metadata["iyzicoPaymentId"] = iyzicoResult.PaymentId;
            payment.Metadata["cardType"] = iyzicoResult.CardType;
            payment.Metadata["cardAssociation"] = iyzicoResult.CardAssociation;
            payment.Metadata["lastFourDigits"] = iyzicoResult.LastFourDigits;
            payment.Metadata["commission"] = iyzicoResult.IyziCommissionFee.ToString("F2");

            await _payments.ReplaceOneAsync(session, p => p.Id == payment.Id, payment);

            // If premium subscription, create/extend subscription
            Subscription? subscription = null;
            if (payment.PaymentType is "premium_monthly" or "premium_yearly" or "premium")
            {
                subscription = await CreateOrExtendSubscriptionAsync(session, payment);
            }

            await session.CommitTransactionAsync();

            _logger.LogInformation(
                "💳 Payment {PaymentId} completed via MongoDB transaction. Amount: {Amount} TRY, Type: {Type}",
                payment.Id, payment.Amount, payment.PaymentType);

            // Publish events (outside transaction — eventual consistency)
            await _eventBus.PublishAsync(new PaymentCompletedEvent
            {
                PaymentId = payment.Id,
                UserId = payment.UserId,
                Amount = payment.Amount,
                Currency = payment.Currency,
                PaymentProvider = payment.Provider,
                TransactionId = iyzicoResult.TransactionId
            });

            if (subscription != null)
            {
                await _eventBus.PublishAsync(new PremiumActivatedEvent
                {
                    UserId = payment.UserId,
                    SubscriptionType = subscription.Plan,
                    ExpiresAt = subscription.EndDate
                });
            }

            return payment;
        }
        catch (Exception ex)
        {
            await session.AbortTransactionAsync();
            _logger.LogError(ex, "MongoDB transaction failed for payment {PaymentId}", payment.Id);
            throw;
        }
    }

    /// <summary>
    /// Process a refund through iyzico + update payment status
    /// </summary>
    public async Task<Payment> RefundPaymentAsync(string paymentId, string userId)
    {
        var payment = await _payments.Find(p => p.Id == paymentId && p.UserId == userId).FirstOrDefaultAsync();
        if (payment == null) throw new Exception("Payment not found");
        if (payment.Status != "completed") throw new Exception("Only completed payments can be refunded");

        var iyzicoPaymentId = payment.Metadata.GetValueOrDefault("iyzicoPaymentId", payment.TransactionId ?? "");
        var refundResult = await _iyzicoService.RefundAsync(iyzicoPaymentId, payment.Amount);

        if (!refundResult.Success)
            throw new Exception("Refund failed at iyzico");

        using var session = await _mongoClient.StartSessionAsync();
        session.StartTransaction();

        try
        {
            payment.Status = "refunded";
            payment.Metadata["refundId"] = refundResult.RefundId;
            payment.Metadata["refundedAt"] = DateTime.UtcNow.ToString("O");
            await _payments.ReplaceOneAsync(session, p => p.Id == payment.Id, payment);

            // Cancel subscription if premium
            if (payment.PaymentType.StartsWith("premium"))
            {
                var sub = await _subscriptions.Find(session, 
                    s => s.UserId == userId && s.Status == "active").FirstOrDefaultAsync();
                if (sub != null)
                {
                    sub.Status = "cancelled";
                    await _subscriptions.ReplaceOneAsync(session, s => s.Id == sub.Id, sub);
                }
            }

            await session.CommitTransactionAsync();

            _logger.LogInformation("💸 Refund completed for payment {PaymentId}, refundId: {RefundId}",
                paymentId, refundResult.RefundId);

            return payment;
        }
        catch
        {
            await session.AbortTransactionAsync();
            throw;
        }
    }

    public async Task<Payment?> GetPaymentAsync(string paymentId)
    {
        return await _payments.Find(p => p.Id == paymentId).FirstOrDefaultAsync();
    }

    public async Task<List<Payment>> GetUserPaymentsAsync(string userId)
    {
        return await _payments.Find(p => p.UserId == userId)
            .SortByDescending(p => p.CreatedAt)
            .ToListAsync();
    }

    public async Task<Subscription?> GetActiveSubscriptionAsync(string userId)
    {
        return await _subscriptions.Find(s => 
            s.UserId == userId && 
            s.Status == "active" && 
            s.EndDate > DateTime.UtcNow)
            .FirstOrDefaultAsync();
    }

    public async Task<SubscriptionCancelResult> CancelSubscriptionAsync(string userId)
    {
        var sub = await _subscriptions.Find(s => s.UserId == userId && s.Status == "active").FirstOrDefaultAsync();
        if (sub == null)
            return new SubscriptionCancelResult { Success = false, Message = "No active subscription found" };

        sub.AutoRenew = false;
        sub.Status = "cancelled";
        await _subscriptions.ReplaceOneAsync(s => s.Id == sub.Id, sub);

        _logger.LogInformation("Subscription {SubId} cancelled for user {UserId}", sub.Id, userId);
        return new SubscriptionCancelResult { Success = true, Message = "Subscription cancelled. Access valid until " + sub.EndDate.ToString("yyyy-MM-dd") };
    }

    // === Private Helpers ===

    private async Task<Subscription> CreateOrExtendSubscriptionAsync(
        IClientSessionHandle session, Payment payment)
    {
        var existingSub = await _subscriptions.Find(session,
            s => s.UserId == payment.UserId && s.Status == "active")
            .FirstOrDefaultAsync();

        var isYearly = payment.PaymentType == "premium_yearly" || payment.Amount > 500;
        var duration = isYearly ? TimeSpan.FromDays(365) : TimeSpan.FromDays(30);

        if (existingSub != null)
        {
            // Extend existing subscription
            existingSub.EndDate = existingSub.EndDate > DateTime.UtcNow
                ? existingSub.EndDate.Add(duration) // Extend from current end
                : DateTime.UtcNow.Add(duration);   // Restart from now
            existingSub.Plan = isYearly ? "yearly" : "monthly";
            await _subscriptions.ReplaceOneAsync(session, s => s.Id == existingSub.Id, existingSub);

            _logger.LogInformation("Extended subscription for user {UserId} until {EndDate}", 
                payment.UserId, existingSub.EndDate);
            return existingSub;
        }
        else
        {
            // Create new subscription
            var subscription = new Subscription
            {
                UserId = payment.UserId,
                Plan = isYearly ? "yearly" : "monthly",
                StartDate = DateTime.UtcNow,
                EndDate = DateTime.UtcNow.Add(duration)
            };
            await _subscriptions.InsertOneAsync(session, subscription);

            _logger.LogInformation("Created new {Plan} subscription for user {UserId}", 
                subscription.Plan, payment.UserId);
            return subscription;
        }
    }

    private static (decimal amount, string plan) ValidatePaymentPlan(string paymentType, decimal requestedAmount)
    {
        return paymentType switch
        {
            "premium_monthly" => (149.99m, "monthly"),
            "premium_yearly" => (1499.99m, "yearly"),
            "premium" => (requestedAmount > 500 ? 1499.99m : 149.99m, requestedAmount > 500 ? "yearly" : "monthly"),
            "featured_listing" => (requestedAmount > 0 ? requestedAmount : 99.99m, "featured"),
            _ => (requestedAmount, "custom")
        };
    }
}
