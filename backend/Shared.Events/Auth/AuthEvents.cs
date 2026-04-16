namespace Shared.Events.Auth;

/// <summary>
/// Published when a new user registers
/// </summary>
public class UserRegisteredEvent : BaseEvent
{
    public UserRegisteredEvent()
    {
        EventType = "auth.user.registered";
    }

    public string UserId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public bool RequiresApproval { get; set; }
}

/// <summary>
/// Published when a user logs in successfully
/// </summary>
public class UserLoggedInEvent : BaseEvent
{
    public UserLoggedInEvent()
    {
        EventType = "auth.user.loggedin";
    }

    public string UserId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

/// <summary>
/// Published when user is banned by admin
/// </summary>
public class UserBannedEvent : BaseEvent
{
    public UserBannedEvent()
    {
        EventType = "auth.user.banned";
    }

    public string UserId { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public DateTime BannedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// Published when user is approved (for emlakci role)
/// </summary>
public class UserApprovedEvent : BaseEvent
{
    public UserApprovedEvent()
    {
        EventType = "auth.user.approved";
    }

    public string UserId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
}

/// <summary>
/// Published when a user requests a password reset.
/// NotificationService listens for this event and sends the reset code via email.
/// </summary>
public class PasswordResetRequestedEvent : BaseEvent
{
    public PasswordResetRequestedEvent()
    {
        EventType = "auth.passwordresetrequested";
    }

    public string UserId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string ResetCode { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
}
