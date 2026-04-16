using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PaymentService.Models;
using PaymentService.Services;
using System.Security.Claims;

namespace PaymentService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;
    private readonly ILogger<PaymentsController> _logger;

    public PaymentsController(IPaymentService paymentService, ILogger<PaymentsController> logger)
    {
        _paymentService = paymentService;
        _logger = logger;
    }

    /// <summary>
    /// Initiate a payment — creates a pending payment and returns iyzico checkout URL
    /// </summary>
    [Authorize]
    [HttpPost]
    public async Task<ActionResult<PaymentInitResult>> InitiatePayment([FromBody] CreatePaymentRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        try
        {
            var result = await _paymentService.InitiatePaymentAsync(userId, request);

            if (result.ErrorMessage != null)
                return BadRequest(new { error = result.ErrorMessage });

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Payment initiation failed for user {UserId}", userId);
            return StatusCode(500, new { error = "Payment initiation failed" });
        }
    }

    /// <summary>
    /// iyzico callback — verifies payment and completes the transaction
    /// </summary>
    [HttpPost("callback")]
    public async Task<IActionResult> PaymentCallback([FromQuery] string? paymentId, [FromBody] IyzicoCallbackDto? body)
    {
        var token = body?.Token;
        if (string.IsNullOrEmpty(token))
            return BadRequest(new { error = "Missing token" });

        try
        {
            var payment = await _paymentService.CompletePaymentAsync(token);
            return Ok(new
            {
                success = true,
                paymentId = payment.Id,
                status = payment.Status,
                message = "Payment completed successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Payment callback failed for token {Token}", token);
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Refund a completed payment
    /// </summary>
    [Authorize]
    [HttpPost("{paymentId}/refund")]
    public async Task<IActionResult> RefundPayment(string paymentId)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        try
        {
            var payment = await _paymentService.RefundPaymentAsync(paymentId, userId);
            return Ok(new { success = true, payment.Status, message = "Refund processed" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Refund failed for payment {PaymentId}", paymentId);
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get current user's payment history
    /// </summary>
    [Authorize]
    [HttpGet("my-payments")]
    public async Task<ActionResult<List<Payment>>> GetMyPayments()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var payments = await _paymentService.GetUserPaymentsAsync(userId);
        return Ok(payments);
    }

    /// <summary>
    /// Get current user's active subscription
    /// </summary>
    [Authorize]
    [HttpGet("subscription")]
    public async Task<IActionResult> GetSubscription()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var subscription = await _paymentService.GetActiveSubscriptionAsync(userId);
        if (subscription == null) return NotFound(new { message = "No active subscription" });

        return Ok(subscription);
    }

    /// <summary>
    /// Cancel current user's subscription
    /// </summary>
    [Authorize]
    [HttpPost("subscription/cancel")]
    public async Task<IActionResult> CancelSubscription()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var result = await _paymentService.CancelSubscriptionAsync(userId);
        if (!result.Success) return NotFound(new { message = result.Message });

        return Ok(new { message = result.Message });
    }

    /// <summary>
    /// Get plans catalog
    /// </summary>
    [HttpGet("plans")]
    public IActionResult GetPlans()
    {
        return Ok(new[]
        {
            new { id = "premium_monthly", name = "Premium Aylık", price = 149.99m, currency = "TRY", period = "monthly",
                features = new[] { "Sınırsız ilan", "Öncelikli listeleme", "İstatistik dashboard", "Premium rozet" } },
            new { id = "premium_yearly", name = "Premium Yıllık", price = 1499.99m, currency = "TRY", period = "yearly",
                features = new[] { "Sınırsız ilan", "Öncelikli listeleme", "İstatistik dashboard", "Premium rozet", "2 ay ücretsiz", "Öncelikli destek" } },
            new { id = "featured_listing", name = "Öne Çıkan İlan", price = 99.99m, currency = "TRY", period = "one-time",
                features = new[] { "7 gün öne çıkarma", "Sarı çerçeve", "Vitrin önceliği" } }
        });
    }
}

public record IyzicoCallbackDto(string Token, string? Status);
