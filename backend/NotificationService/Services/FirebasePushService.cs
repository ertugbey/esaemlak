using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;

namespace NotificationService.Handlers;

/// <summary>
/// Firebase Cloud Messaging (FCM) push notification service.
/// Supports both real FCM (when ServiceAccountKeyPath is configured)
/// and mock mode (logs to console).
/// </summary>
public interface IFirebasePushService
{
    /// <summary>Send push notification to a specific user by user ID</summary>
    Task SendToUserAsync(string userId, string title, string body, Dictionary<string, string>? data = null);
    
    /// <summary>Send push notification to a topic (e.g., city_İstanbul, listing_xyz)</summary>
    Task SendToTopicAsync(string topic, string title, string body, Dictionary<string, string>? data = null);
}

/// <summary>
/// Firebase push service with real FCM support.
/// To enable real FCM:
/// 1. Download your Firebase service account JSON key file
/// 2. Set Firebase:ServiceAccountKeyPath in appsettings.json to the file path
/// 3. Restart the service
/// </summary>
public class FirebasePushService : IFirebasePushService
{
    private readonly ILogger<FirebasePushService> _logger;
    private readonly bool _isFirebaseConfigured;

    public FirebasePushService(ILogger<FirebasePushService> logger, IConfiguration configuration)
    {
        _logger = logger;
        var keyPath = configuration["Firebase:ServiceAccountKeyPath"];
        _isFirebaseConfigured = !string.IsNullOrEmpty(keyPath) && File.Exists(keyPath);

        if (_isFirebaseConfigured)
        {
            try
            {
                if (FirebaseApp.DefaultInstance == null)
                {
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = GoogleCredential.FromFile(keyPath!)
                    });
                }
                _logger.LogInformation("🔥 Firebase Admin SDK initialized — FCM push enabled");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "🔥 Failed to initialize Firebase Admin SDK — falling back to mock mode");
                _isFirebaseConfigured = false;
            }
        }
        else
        {
            _logger.LogWarning("🔥 Firebase not configured — using mock push notifications. " +
                "Set Firebase:ServiceAccountKeyPath in appsettings.json to enable real FCM.");
        }
    }

    public async Task SendToUserAsync(string userId, string title, string body, Dictionary<string, string>? data = null)
    {
        if (_isFirebaseConfigured)
        {
            try
            {
                var message = new Message
                {
                    Topic = $"user_{userId}",
                    Notification = new Notification { Title = title, Body = body },
                    Data = data
                };

                var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
                _logger.LogInformation(
                    "📱 [FCM] Push sent to user {UserId}: {Title} — Response: {Response}",
                    userId, title, response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "📱 [FCM ERROR] Failed to push to user {UserId}: {Title}",
                    userId, title);
                // Don't throw — push failure should not break the notification pipeline
            }
        }
        else
        {
            _logger.LogInformation(
                "📱 [MOCK PUSH → User] UserId: {UserId} | Title: {Title} | Body: {Body} | Data: {Data}",
                userId, title, body, data != null ? string.Join(", ", data.Select(kv => $"{kv.Key}={kv.Value}")) : "none");
        }
    }

    public async Task SendToTopicAsync(string topic, string title, string body, Dictionary<string, string>? data = null)
    {
        if (_isFirebaseConfigured)
        {
            try
            {
                var message = new Message
                {
                    Topic = topic,
                    Notification = new Notification { Title = title, Body = body },
                    Data = data
                };

                var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
                _logger.LogInformation(
                    "📱 [FCM] Push sent to topic {Topic}: {Title} — Response: {Response}",
                    topic, title, response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "📱 [FCM ERROR] Failed to push to topic {Topic}: {Title}",
                    topic, title);
            }
        }
        else
        {
            _logger.LogInformation(
                "📱 [MOCK PUSH → Topic] Topic: {Topic} | Title: {Title} | Body: {Body} | Data: {Data}",
                topic, title, body, data != null ? string.Join(", ", data.Select(kv => $"{kv.Key}={kv.Value}")) : "none");
        }
    }
}
