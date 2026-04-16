using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace NotificationService.Handlers;

/// <summary>
/// Email service interface for sending emails.
/// </summary>
public interface IEmailService
{
    Task SendEmailAsync(EmailMessage message);
}

public class EmailMessage
{
    public string To { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public bool IsHtml { get; set; } = true;
    public string? From { get; set; }
}

/// <summary>
/// SMTP email service using MailKit.
/// Supports real SMTP (SendGrid, Mailtrap, Gmail SMTP, etc.) and mock (console) mode.
/// When Smtp:Host is "mock" or empty, emails are logged to console instead of sent.
/// </summary>
public class SmtpEmailService : IEmailService
{
    private readonly ILogger<SmtpEmailService> _logger;
    private readonly IConfiguration _configuration;
    private readonly bool _isMockMode;

    public SmtpEmailService(ILogger<SmtpEmailService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;

        var smtpHost = _configuration["Smtp:Host"];
        _isMockMode = string.IsNullOrEmpty(smtpHost) || smtpHost == "mock";

        if (_isMockMode)
        {
            _logger.LogWarning("📧 SMTP is in MOCK mode — emails will be logged to console only. " +
                "Set Smtp:Host in appsettings.json to enable real SMTP.");
        }
        else
        {
            _logger.LogInformation("📧 SMTP configured with host: {Host}:{Port}", smtpHost,
                _configuration["Smtp:Port"] ?? "587");
        }
    }

    public async Task SendEmailAsync(EmailMessage message)
    {
        if (_isMockMode)
        {
            _logger.LogInformation(
                "📧 [MOCK EMAIL] To: {To} | Subject: {Subject} | Body length: {Length} chars | HTML: {IsHtml}",
                message.To, message.Subject, message.Body.Length, message.IsHtml);
            return;
        }

        try
        {
            var fromEmail = message.From ?? _configuration["Smtp:FromEmail"] ?? "noreply@esaemlak.com";
            var fromName = _configuration["Smtp:FromName"] ?? "EsaEmlak";

            var mimeMessage = new MimeMessage();
            mimeMessage.From.Add(new MailboxAddress(fromName, fromEmail));
            mimeMessage.To.Add(MailboxAddress.Parse(message.To));
            mimeMessage.Subject = message.Subject;

            var bodyBuilder = new BodyBuilder();
            if (message.IsHtml)
            {
                bodyBuilder.HtmlBody = message.Body;
                // Set a plain-text fallback for email clients that don't support HTML
                bodyBuilder.TextBody = StripHtml(message.Body);
            }
            else
            {
                bodyBuilder.TextBody = message.Body;
            }

            mimeMessage.Body = bodyBuilder.ToMessageBody();

            var host = _configuration["Smtp:Host"]!;
            var port = int.Parse(_configuration["Smtp:Port"] ?? "587");
            var username = _configuration["Smtp:Username"];
            var password = _configuration["Smtp:Password"];

            using var client = new SmtpClient();

            // Determine TLS mode based on port
            var secureSocketOptions = port switch
            {
                465 => SecureSocketOptions.SslOnConnect,
                25 => SecureSocketOptions.None,
                _ => SecureSocketOptions.StartTls
            };

            await client.ConnectAsync(host, port, secureSocketOptions);

            // Authenticate if credentials are provided
            if (!string.IsNullOrEmpty(username) && !string.IsNullOrEmpty(password))
            {
                await client.AuthenticateAsync(username, password);
            }

            await client.SendAsync(mimeMessage);
            await client.DisconnectAsync(true);

            _logger.LogInformation(
                "📧 [SMTP] Email sent successfully to {To} — Subject: {Subject}",
                message.To, message.Subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "📧 [SMTP ERROR] Failed to send email to {To} — Subject: {Subject}",
                message.To, message.Subject);

            // Don't throw — email failure should not break the notification pipeline
            // The error is logged and can be monitored via Seq/centralized logging
        }
    }

    /// <summary>
    /// Basic HTML tag stripper for plain-text fallback.
    /// </summary>
    private static string StripHtml(string html)
    {
        return System.Text.RegularExpressions.Regex.Replace(html, "<.*?>", " ")
            .Replace("&nbsp;", " ")
            .Replace("&amp;", "&")
            .Replace("  ", " ")
            .Trim();
    }
}
