using System.Diagnostics;

namespace ListingsService.Services;

public interface IEventBus
{
    Task PublishAsync<T>(T @event) where T : class;
}
