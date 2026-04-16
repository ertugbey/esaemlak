using PaymentService.Models;

namespace PaymentService.Services;

/// <summary>
/// iyzico sandbox integration service.
/// In production, replace with real iyzico SDK calls.
/// This sandbox simulates iyzico payment flow:
///   1. CreateCheckoutForm → returns a checkout URL
///   2. RetrieveCheckoutResult → verifies payment status
///   3. Refund → processes refund
/// </summary>
public interface IIyzicoService
{
    /// <summary>Create a checkout form session (returns checkout URL)</summary>
    Task<IyzicoCheckoutResult> CreateCheckoutFormAsync(IyzicoPaymentRequest request);
    
    /// <summary>Verify a completed payment by token</summary>
    Task<IyzicoPaymentResult> RetrieveCheckoutResultAsync(string token);
    
    /// <summary>Process a refund</summary>
    Task<IyzicoRefundResult> RefundAsync(string paymentId, decimal amount);
}

public class IyzicoSandboxService : IIyzicoService
{
    private readonly ILogger<IyzicoSandboxService> _logger;
    private readonly IConfiguration _configuration;
    
    // Simulated payment sessions
    private static readonly Dictionary<string, IyzicoPaymentSession> _sessions = new();

    public IyzicoSandboxService(ILogger<IyzicoSandboxService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public Task<IyzicoCheckoutResult> CreateCheckoutFormAsync(IyzicoPaymentRequest request)
    {
        var apiKey = _configuration["Iyzico:ApiKey"] ?? "sandbox-api-key";
        var baseUrl = _configuration["Iyzico:BaseUrl"] ?? "https://sandbox-api.iyzipay.com";

        _logger.LogInformation(
            "[iyzico-sandbox] Creating checkout form — Amount: {Amount} {Currency}, Buyer: {BuyerId}",
            request.Amount, request.Currency, request.BuyerId);

        // Generate sandbox token and session
        var token = $"sandbox-token-{Guid.NewGuid():N}"[..32];
        var conversationId = $"ESA-{DateTime.UtcNow:yyyyMMddHHmmss}-{Random.Shared.Next(1000, 9999)}";

        var session = new IyzicoPaymentSession
        {
            Token = token,
            ConversationId = conversationId,
            Amount = request.Amount,
            Currency = request.Currency,
            BuyerId = request.BuyerId,
            PaymentType = request.PaymentType,
            Status = "CREATED",
            CreatedAt = DateTime.UtcNow
        };
        _sessions[token] = session;

        // Simulate iyzico checkout URL
        var checkoutUrl = $"{baseUrl}/checkout?token={token}&locale=tr";

        _logger.LogInformation(
            "[iyzico-sandbox] Checkout form created — Token: {Token}, ConversationId: {ConversationId}",
            token, conversationId);

        return Task.FromResult(new IyzicoCheckoutResult
        {
            Success = true,
            Token = token,
            ConversationId = conversationId,
            CheckoutFormContent = $"<div id='iyzipay-checkout-form' class='responsive'></div><script>/* sandbox form for {token} */</script>",
            CheckoutUrl = checkoutUrl,
            ErrorMessage = null
        });
    }

    public Task<IyzicoPaymentResult> RetrieveCheckoutResultAsync(string token)
    {
        _logger.LogInformation("[iyzico-sandbox] Retrieving checkout result for token: {Token}", token);

        if (!_sessions.TryGetValue(token, out var session))
        {
            return Task.FromResult(new IyzicoPaymentResult
            {
                Success = false,
                Status = "NOT_FOUND",
                ErrorMessage = "Payment session not found"
            });
        }

        // Sandbox: always approve payments
        session.Status = "SUCCESS";
        var paymentId = $"sandbox-payment-{Guid.NewGuid():N}"[..28];
        var transactionId = $"sandbox-txn-{DateTime.UtcNow:yyyyMMddHHmmss}";

        _logger.LogInformation(
            "[iyzico-sandbox] Payment APPROVED — PaymentId: {PaymentId}, Amount: {Amount} {Currency}",
            paymentId, session.Amount, session.Currency);

        return Task.FromResult(new IyzicoPaymentResult
        {
            Success = true,
            Status = "SUCCESS",
            PaymentId = paymentId,
            TransactionId = transactionId,
            Price = session.Amount,
            PaidPrice = session.Amount,
            Currency = session.Currency,
            InstallmentCount = 1,
            FraudStatus = 1, // 1 = approved
            MerchantCommissionRate = 0,
            MerchantCommissionRateAmount = 0,
            IyziCommissionFee = session.Amount * 0.0399m, // ~3.99% sandbox commission
            CardType = "CREDIT_CARD",
            CardAssociation = "VISA",
            CardFamily = "Bonus",
            LastFourDigits = "4242",
            BinNumber = "454360",
            ErrorMessage = null
        });
    }

    public Task<IyzicoRefundResult> RefundAsync(string paymentId, decimal amount)
    {
        _logger.LogInformation(
            "[iyzico-sandbox] Processing refund — PaymentId: {PaymentId}, Amount: {Amount}",
            paymentId, amount);

        return Task.FromResult(new IyzicoRefundResult
        {
            Success = true,
            PaymentId = paymentId,
            RefundId = $"sandbox-refund-{Guid.NewGuid():N}"[..28],
            Amount = amount,
            Status = "REFUNDED"
        });
    }
}

// === DTOs ===

public class IyzicoPaymentRequest
{
    public string BuyerId { get; set; } = string.Empty;
    public string BuyerName { get; set; } = string.Empty;
    public string BuyerEmail { get; set; } = string.Empty;
    public string BuyerPhone { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "TRY";
    public string PaymentType { get; set; } = string.Empty; // premium, featured_listing
    public string? ListingId { get; set; }
    public string CallbackUrl { get; set; } = string.Empty;
}

public class IyzicoCheckoutResult
{
    public bool Success { get; set; }
    public string Token { get; set; } = string.Empty;
    public string ConversationId { get; set; } = string.Empty;
    public string CheckoutFormContent { get; set; } = string.Empty;
    public string CheckoutUrl { get; set; } = string.Empty;
    public string? ErrorMessage { get; set; }
}

public class IyzicoPaymentResult
{
    public bool Success { get; set; }
    public string Status { get; set; } = string.Empty;
    public string PaymentId { get; set; } = string.Empty;
    public string TransactionId { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal PaidPrice { get; set; }
    public string Currency { get; set; } = "TRY";
    public int InstallmentCount { get; set; } = 1;
    public int FraudStatus { get; set; }
    public decimal MerchantCommissionRate { get; set; }
    public decimal MerchantCommissionRateAmount { get; set; }
    public decimal IyziCommissionFee { get; set; }
    public string CardType { get; set; } = string.Empty;
    public string CardAssociation { get; set; } = string.Empty;
    public string CardFamily { get; set; } = string.Empty;
    public string LastFourDigits { get; set; } = string.Empty;
    public string BinNumber { get; set; } = string.Empty;
    public string? ErrorMessage { get; set; }
}

public class IyzicoRefundResult
{
    public bool Success { get; set; }
    public string PaymentId { get; set; } = string.Empty;
    public string RefundId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class IyzicoPaymentSession
{
    public string Token { get; set; } = string.Empty;
    public string ConversationId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "TRY";
    public string BuyerId { get; set; } = string.Empty;
    public string PaymentType { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
