using System.Diagnostics;
using System.Text;
using System.Text.Json;
using RabbitMQ.Client;

namespace PaymentService.Services;

public interface IEventBus
{
    Task PublishAsync<T>(T @event) where T : class;
}

/// <summary>
/// Fail-safe RabbitMQ event publisher — if RabbitMQ is not available, logs warning and continues
/// </summary>
public class RabbitMQEventBus : IEventBus, IDisposable
{
    private IConnection? _connection;
    private IModel? _channel;
    private readonly ILogger<RabbitMQEventBus> _logger;
    private const string ExchangeName = "emlaktan.events";
    private bool _isConnected;

    public RabbitMQEventBus(ILogger<RabbitMQEventBus> logger, IConfiguration configuration)
    {
        _logger = logger;

        var rabbitHost = configuration["RabbitMQ:Host"] ?? "localhost";
        if (rabbitHost == "disabled")
        {
            _logger.LogWarning("RabbitMQ is disabled in configuration");
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
            _channel.ExchangeDeclare(ExchangeName, ExchangeType.Topic, durable: true);
            _isConnected = true;
            _logger.LogInformation("RabbitMQ connected for PaymentService at {Host}:{Port}", factory.HostName, factory.Port);
        }
        catch (Exception ex)
        {
            _isConnected = false;
            _logger.LogWarning(ex, "RabbitMQ connection failed. Events will not be published.");
        }
    }

    public Task PublishAsync<T>(T @event) where T : class
    {
        if (!_isConnected || _channel == null)
        {
            _logger.LogWarning("[NoOp] RabbitMQ not connected, skipping event: {EventType}", @event.GetType().Name);
            return Task.CompletedTask;
        }

        var routingKey = $"payment.{@event.GetType().Name.Replace("Event", "").ToLower()}";
        
        var activity = Activity.Current;
        if (activity != null && @event is Shared.Events.BaseEvent baseEvent)
        {
            baseEvent.TraceId = activity.TraceId.ToString();
        }

        var message = JsonSerializer.Serialize(@event, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        var body = Encoding.UTF8.GetBytes(message);
        var properties = _channel.CreateBasicProperties();
        properties.Persistent = true;
        properties.ContentType = "application/json";

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
            _channel.BasicPublish(ExchangeName, routingKey, properties, body);
            _logger.LogInformation("Published {EventType} with routing key {RoutingKey}", @event.GetType().Name, routingKey);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish event {EventType}", @event.GetType().Name);
        }

        return Task.CompletedTask;
    }

    public void Dispose()
    {
        _channel?.Close();
        _channel?.Dispose();
        _connection?.Close();
        _connection?.Dispose();
        if (_isConnected) _logger.LogInformation("RabbitMQ connection closed");
    }
}
