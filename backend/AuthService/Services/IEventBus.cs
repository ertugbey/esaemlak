using System.Diagnostics;

namespace AuthService.Services;

/// <summary>
/// Event bus interface for publishing domain events
/// </summary>
public interface IEventBus
{
    Task PublishAsync<T>(T @event) where T : class;
}
