using Microsoft.AspNetCore.SignalR;
using NotificationService.Hubs;
using Shared.Events.Auth;
using Shared.Events.Listings;
using Shared.Events.Payment;

namespace NotificationService.Handlers;

public interface INotificationHandler
{
    Task HandleUserRegisteredAsync(UserRegisteredEvent @event);
    Task HandlePasswordResetRequestedAsync(PasswordResetRequestedEvent @event);
    Task HandleListingCreatedAsync(ListingCreatedEvent @event);
    Task HandleListingPriceChangedAsync(ListingPriceChangedEvent @event);
    Task HandlePaymentCompletedAsync(PaymentCompletedEvent @event);
    Task HandlePremiumActivatedAsync(PremiumActivatedEvent @event);
}

public class NotificationHandler : INotificationHandler
{
    private readonly ILogger<NotificationHandler> _logger;
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly IEmailService _emailService;
    private readonly IFirebasePushService _firebaseService;

    public NotificationHandler(
        ILogger<NotificationHandler> logger,
        IHubContext<NotificationHub> hubContext,
        IEmailService emailService,
        IFirebasePushService firebaseService)
    {
        _logger = logger;
        _hubContext = hubContext;
        _emailService = emailService;
        _firebaseService = firebaseService;
    }

    public async Task HandleUserRegisteredAsync(UserRegisteredEvent @event)
    {
        _logger.LogInformation(
            "📧 Processing welcome notification for {Email} (User: {FullName}, Role: {Role})",
            @event.Email, @event.FullName, @event.Role);

        // Send welcome email
        await _emailService.SendEmailAsync(new EmailMessage
        {
            To = @event.Email,
            Subject = "EsaEmlak'a Hoş Geldiniz! 🏠",
            Body = $"""
                <h1>Merhaba {HtmlEncode(@event.FullName)},</h1>
                <p>EsaEmlak ailesine katıldığınız için teşekkür ederiz!</p>
                <p>Hesabınız başarıyla oluşturuldu. Rol: <strong>{HtmlEncode(@event.Role)}</strong></p>
                <p>Hemen ilan vermeye başlayabilirsiniz.</p>
                <br/>
                <p>EsaEmlak Ekibi</p>
                """,
            IsHtml = true
        });

        if (@event.RequiresApproval)
        {
            _logger.LogInformation("📋 User {Email} requires approval — notifying admins", @event.Email);
            
            // Send admin notification via SignalR
            await _hubContext.Clients.Group("admins")
                .SendAsync("AdminNotification", new
                {
                    type = "USER_APPROVAL_REQUIRED",
                    email = @event.Email,
                    fullName = @event.FullName,
                    role = @event.Role,
                    timestamp = DateTime.UtcNow
                });
        }

        _logger.LogInformation("✅ Welcome notification processed for {Email}", @event.Email);
    }

    public async Task HandlePasswordResetRequestedAsync(PasswordResetRequestedEvent @event)
    {
        _logger.LogInformation(
            "🔑 Processing password reset email for {Email} (User: {UserId})",
            @event.Email, @event.UserId);

        await _emailService.SendEmailAsync(new EmailMessage
        {
            To = @event.Email,
            Subject = "EsaEmlak — Şifre Sıfırlama Kodunuz 🔐",
            Body = $"""
                <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                    <div style="text-align: center; padding: 20px 0; border-bottom: 2px solid #e74c3c;">
                        <h1 style="color: #2c3e50; margin: 0;">EsaEmlak</h1>
                        <p style="color: #7f8c8d; margin: 5px 0 0;">Şifre Sıfırlama</p>
                    </div>
                    <div style="padding: 30px 0;">
                        <p>Merhaba <strong>{HtmlEncode(@event.FullName)}</strong>,</p>
                        <p>Şifre sıfırlama talebiniz alındı. Aşağıdaki kodu kullanarak şifrenizi yenileyebilirsiniz:</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <span style="
                                font-size: 36px;
                                font-weight: bold;
                                letter-spacing: 8px;
                                color: #e74c3c;
                                background: #fdf2f2;
                                padding: 15px 30px;
                                border-radius: 8px;
                                border: 2px dashed #e74c3c;
                            ">{@event.ResetCode}</span>
                        </div>
                        <p style="color: #e67e22; font-size: 14px;">⏰ Bu kod <strong>{@event.ExpiresAt:dd MMM yyyy HH:mm}</strong> tarihine kadar geçerlidir (15 dakika).</p>
                        <p style="color: #95a5a6; font-size: 13px;">Eğer bu talebi siz yapmadıysanız, bu e-postayı görmezden gelebilirsiniz. Hesabınız güvendedir.</p>
                    </div>
                    <div style="border-top: 1px solid #ecf0f1; padding-top: 15px; text-align: center; color: #bdc3c7; font-size: 12px;">
                        <p>EsaEmlak Güvenlik Ekibi</p>
                    </div>
                </div>
                """,
            IsHtml = true
        });

        _logger.LogInformation("✅ Password reset email sent to {Email}", @event.Email);
    }

    public async Task HandleListingCreatedAsync(ListingCreatedEvent @event)
    {
        _logger.LogInformation(
            "🏠 New listing: {Title} in {City}/{District} — {Price:N0} TL",
            @event.Baslik, @event.Il, @event.Ilce, @event.Fiyat);

        // Send SignalR notification to area subscribers
        await _hubContext.Clients.Group($"city_{@event.Il}")
            .SendAsync("NewListing", new
            {
                type = "NEW_LISTING",
                listingId = @event.ListingId,
                baslik = @event.Baslik,
                emlakTipi = @event.EmlakTipi,
                islemTipi = @event.IslemTipi,
                fiyat = @event.Fiyat,
                il = @event.Il,
                ilce = @event.Ilce,
                timestamp = DateTime.UtcNow,
                message = $"Yeni {GetIslemTipiText(@event.IslemTipi)} ilanı: {TruncateTitle(@event.Baslik)} — {FormatPrice(@event.Fiyat)}"
            });

        // Firebase push to area subscribers
        await _firebaseService.SendToTopicAsync(
            $"city_{@event.Il}",
            "Yeni İlan! 🏠",
            $"{TruncateTitle(@event.Baslik)} — {FormatPrice(@event.Fiyat)}",
            new Dictionary<string, string>
            {
                ["listingId"] = @event.ListingId,
                ["type"] = "NEW_LISTING"
            });

        _logger.LogInformation("📢 Area subscribers notified in {City}", @event.Il);
    }

    public async Task HandleListingPriceChangedAsync(ListingPriceChangedEvent @event)
    {
        var direction = @event.NewPrice < @event.OldPrice ? "düştü 📉" : "arttı 📈";
        var changePercent = Math.Abs(@event.ChangePercentage);

        _logger.LogInformation(
            "💰 Price changed: {ListingId} — {OldPrice:N0} → {NewPrice:N0} TL ({Direction} %{Change:F1})",
            @event.ListingId, @event.OldPrice, @event.NewPrice, direction, changePercent);

        var notification = new
        {
            type = "PRICE_CHANGED",
            listingId = @event.ListingId,
            oldPrice = @event.OldPrice,
            newPrice = @event.NewPrice,
            changePercentage = @event.ChangePercentage,
            isPriceReduced = @event.NewPrice < @event.OldPrice,
            timestamp = DateTime.UtcNow,
            message = @event.NewPrice < @event.OldPrice
                ? $"İlan fiyatı %{changePercent:F0} düştü! yeni: {FormatPrice(@event.NewPrice)}"
                : $"İlan fiyatı %{changePercent:F0} arttı. yeni: {FormatPrice(@event.NewPrice)}"
        };

        // SignalR to listing watchers
        await _hubContext.Clients.Group($"listing_{@event.ListingId}")
            .SendAsync("PriceChanged", notification);

        // Firebase push to listing watchers
        if (@event.NewPrice < @event.OldPrice)
        {
            await _firebaseService.SendToTopicAsync(
                $"listing_{@event.ListingId}",
                "Fiyat Düştü! 📉",
                $"İlan fiyatı %{changePercent:F0} düştü: {FormatPrice(@event.NewPrice)}",
                new Dictionary<string, string>
                {
                    ["listingId"] = @event.ListingId,
                    ["type"] = "PRICE_DROP"
                });
        }

        // All-users broadcast for significant drops
        if (@event.NewPrice < @event.OldPrice && changePercent >= 10)
        {
            await _hubContext.Clients.All.SendAsync("PriceAlert", notification);
        }

        _logger.LogInformation("🔔 Price change notifications sent for listing {ListingId}", @event.ListingId);
    }

    public async Task HandlePaymentCompletedAsync(PaymentCompletedEvent @event)
    {
        _logger.LogInformation(
            "💳 Payment completed: {PaymentId} — {Amount} {Currency} by user {UserId}",
            @event.PaymentId, @event.Amount, @event.Currency, @event.UserId);

        // SignalR notification to the paying user
        await _hubContext.Clients.Group($"user_{@event.UserId}")
            .SendAsync("PaymentCompleted", new
            {
                type = "PAYMENT_COMPLETED",
                paymentId = @event.PaymentId,
                amount = @event.Amount,
                currency = @event.Currency,
                transactionId = @event.TransactionId,
                timestamp = DateTime.UtcNow,
                message = $"Ödemeniz başarıyla tamamlandı: {FormatPrice(@event.Amount)}"
            });

        // Firebase push
        await _firebaseService.SendToUserAsync(
            @event.UserId,
            "Ödeme Başarılı ✅",
            $"{FormatPrice(@event.Amount)} tutarındaki ödemeniz tamamlandı.",
            new Dictionary<string, string>
            {
                ["paymentId"] = @event.PaymentId,
                ["type"] = "PAYMENT_COMPLETED"
            });

        _logger.LogInformation("✅ Payment notification sent to user {UserId}", @event.UserId);
    }

    public async Task HandlePremiumActivatedAsync(PremiumActivatedEvent @event)
    {
        _logger.LogInformation(
            "⭐ Premium activated for user {UserId} — Plan: {Plan}, Expires: {Expires}",
            @event.UserId, @event.SubscriptionType, @event.ExpiresAt);

        // SignalR notification
        await _hubContext.Clients.Group($"user_{@event.UserId}")
            .SendAsync("PremiumActivated", new
            {
                type = "PREMIUM_ACTIVATED",
                subscriptionType = @event.SubscriptionType,
                expiresAt = @event.ExpiresAt,
                timestamp = DateTime.UtcNow,
                message = $"Premium üyeliğiniz aktif! Plan: {GetPlanText(@event.SubscriptionType)}, Bitiş: {FormatDate(@event.ExpiresAt)}"
            });

        // Firebase push
        await _firebaseService.SendToUserAsync(
            @event.UserId,
            "Premium Aktif! ⭐",
            $"Artık premium üyesiniz. Plan: {GetPlanText(@event.SubscriptionType)}",
            new Dictionary<string, string>
            {
                ["type"] = "PREMIUM_ACTIVATED",
                ["plan"] = @event.SubscriptionType
            });

        // Send premium welcome email
        await _emailService.SendEmailAsync(new EmailMessage
        {
            To = $"user-{@event.UserId}@esaemlak.com", // In production, resolve actual email
            Subject = "EsaEmlak Premium Aktif! ⭐",
            Body = $"""
                <h1>Premium Üyeliğiniz Aktif!</h1>
                <p>Plan: <strong>{GetPlanText(@event.SubscriptionType)}</strong></p>
                <p>Bitiş tarihi: <strong>{FormatDate(@event.ExpiresAt)}</strong></p>
                <ul>
                    <li>✅ Sınırsız ilan hakkı</li>
                    <li>✅ Öncelikli listeleme</li>
                    <li>✅ İstatistik dashboard</li>
                    <li>✅ Premium rozet</li>
                </ul>
                <p>EsaEmlak Premium Ekibi</p>
                """,
            IsHtml = true
        });

        _logger.LogInformation("✅ Premium activation notifications sent to user {UserId}", @event.UserId);
    }

    // === Helpers ===
    private static string FormatPrice(decimal price)
    {
        if (price >= 1_000_000) return $"{price / 1_000_000:F1}M TL";
        if (price >= 1_000) return $"{price / 1_000:F0}K TL";
        return $"{price:N0} TL";
    }

    private static string GetIslemTipiText(string tip) => tip switch
    {
        "satilik" => "satılık",
        "kiralik" => "kiralık",
        _ => tip
    };

    private static string GetPlanText(string plan) => plan switch
    {
        "monthly" => "Aylık",
        "yearly" => "Yıllık",
        _ => plan
    };

    private static string TruncateTitle(string title) =>
        title.Length > 40 ? title[..37] + "..." : title;

    private static string FormatDate(DateTime date) => date.ToString("dd MMM yyyy");

    private static string HtmlEncode(string text) =>
        System.Net.WebUtility.HtmlEncode(text);
}
