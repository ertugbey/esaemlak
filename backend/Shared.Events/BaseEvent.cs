namespace Shared.Events;

/// <summary>
/// Base class for all domain events
/// </summary>
public abstract class BaseEvent
{
    public string EventId { get; set; } = Guid.NewGuid().ToString();
    public string EventType { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string TraceId { get; set; } = string.Empty;
    public Dictionary<string, string> Metadata { get; set; } = new();
}
