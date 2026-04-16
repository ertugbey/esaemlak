using System.Diagnostics;
using System.Text;
using System.Text.Json;
using RabbitMQ.Client;

namespace AuthService.Services;

/// <summary>
/// RabbitMQ implementation of event bus
/// </summary>
public class RabbitMQEventBus : IEventBus, IDisposable
{
    private readonly IConnection? _connection;
    private readonly IModel? _channel;
    private readonly ILogger<RabbitMQEventBus> _logger;
    private readonly bool _connected;
    private const string ExchangeName = "emlaktan.events";

    public RabbitMQEventBus(ILogger<RabbitMQEventBus> logger, IConfiguration configuration)
    {
        _logger = logger;
        _connected = false;

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
            DispatchConsumersAsync = true
        };

        try
        {
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();

            // Declare topic exchange (if it doesn't exist)
            _channel.ExchangeDeclare(
                exchange: ExchangeName,
                type: ExchangeType.Topic,
                durable: true,
                autoDelete: false
            );

            _connected = true;
            _logger.LogInformation("RabbitMQ connection established to {Host}:{Port}", factory.HostName, factory.Port);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to connect to RabbitMQ at {Host}:{Port}. Events will not be published.", factory.HostName, factory.Port);
        }
    }

    public Task PublishAsync<T>(T @event) where T : class
    {
        if (@event == null)
        {
            throw new ArgumentNullException(nameof(@event));
        }

        if (!_connected || _channel == null)
        {
            _logger.LogDebug("RabbitMQ not connected, skipping event publish for {EventType}", typeof(T).Name);
            return Task.CompletedTask;
        }

        var eventType = @event.GetType().Name.Replace("Event", "").ToLower();
        var routingKey = $"auth.{eventType}"; // e.g., "auth.userregistered"

        // Add current TraceId to event for correlation
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

        // Propagate TraceId in message headers
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

            _logger.LogInformation(
                "Published event {EventType} to RabbitMQ with routing key {RoutingKey}. TraceId: {TraceId}",
                eventType,
                routingKey,
                activity?.TraceId.ToString() ?? "N/A"
            );

            return Task.CompletedTask;
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Failed to publish event {EventType} to RabbitMQ",
                eventType
            );
            throw;
        }
    }

    public void Dispose()
    {
        _channel?.Close();
        _channel?.Dispose();
        _connection?.Close();
        _connection?.Dispose();
        _logger.LogInformation("RabbitMQ connection closed");
    }
}
