using System.Diagnostics;
using System.Text;
using System.Text.Json;
using RabbitMQ.Client;

namespace ListingsService.Services;

/// <summary>
/// RabbitMQ implementation of event bus
/// </summary>
public class RabbitMQEventBus : IEventBus, IDisposable
{
    private IConnection? _connection;
    private IModel? _channel;
    private readonly ILogger<RabbitMQEventBus> _logger;
    private const string ExchangeName = "emlaktan.events";
    private bool _isConnected = false;

    public RabbitMQEventBus(ILogger<RabbitMQEventBus> logger, IConfiguration configuration)
    {
        _logger = logger;

        var rabbitHost = configuration["RabbitMQ:Host"] ?? "localhost";
        if (rabbitHost == "disabled")
        {
            _logger.LogWarning("RabbitMQ is disabled in configuration. Events will not be published.");
            return;
        }

        var factory = new ConnectionFactory
        {
            HostName = rabbitHost,
            Port = int.Parse(configuration["RabbitMQ:Port"] ?? "5672"),
            UserName = configuration["RabbitMQ:Username"] ?? "guest",
            Password = configuration["RabbitMQ:Password"] ?? "guest",
            DispatchConsumersAsync = true,
            RequestedConnectionTimeout = TimeSpan.FromSeconds(3)
        };

        try
        {
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();

            _channel.ExchangeDeclare(
                exchange: ExchangeName,
                type: ExchangeType.Topic,
                durable: true,
                autoDelete: false
            );

            _isConnected = true;
            _logger.LogInformation("RabbitMQ connection established to {Host}:{Port}", factory.HostName, factory.Port);
        }
        catch (Exception ex)
        {
            _isConnected = false;
            _logger.LogWarning(ex, "RabbitMQ'ya baglanamadi ({Host}:{Port}). Olaylar yayinlanmayacak.", factory.HostName, factory.Port);
        }
    }

    public Task PublishAsync<T>(T @event) where T : class
    {
        if (@event == null) throw new ArgumentNullException(nameof(@event));

        if (!_isConnected || _channel == null)
        {
            _logger.LogWarning("[NoOp] RabbitMQ bagli degil, olay yayinlanamadi: {EventType}", @event.GetType().Name);
            return Task.CompletedTask;
        }

        var eventType = @event.GetType().Name.Replace("Event", "").ToLower();
        var category = @event.GetType().Namespace?.Contains("Listings") == true ? "listings" : "auth";
        var routingKey = $"{category}.{eventType}";

        var activity = Activity.Current;
        if (activity != null && @event is Shared.Events.BaseEvent baseEvent)
        {
            baseEvent.TraceId = activity.TraceId.ToString();
        }

        var message = JsonSerializer.Serialize(@event, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        var body = Encoding.UTF8.GetBytes(message);
        var properties = _channel.CreateBasicProperties();
        properties.Persistent = true;
        properties.ContentType = "application/json";
        properties.Type = eventType;

        if (activity != null)
        {
            properties.Headers = new Dictionary<string, object>
            {
                ["traceparent"] = activity.Id ?? string.Empty,
                ["tracestate"] = activity.TraceStateString ?? string.Empty
            };
        }

        try
        {
            _channel.BasicPublish(
                exchange: ExchangeName,
                routingKey: routingKey,
                basicProperties: properties,
                body: body
            );

            _logger.LogInformation("Published event {EventType} with routing key {RoutingKey}", eventType, routingKey);
            return Task.CompletedTask;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish event {EventType} to RabbitMQ", eventType);
            return Task.CompletedTask;
        }
    }

    public void Dispose()
    {
        _channel?.Close();
        _channel?.Dispose();
        _connection?.Close();
        _connection?.Dispose();
        if (_isConnected)
            _logger.LogInformation("RabbitMQ connection closed");
    }
}
