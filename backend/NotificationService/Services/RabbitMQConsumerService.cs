using System.Text;
using System.Text.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using Shared.Events.Auth;
using Shared.Events.Listings;
using Shared.Events.Payment;
using NotificationService.Handlers;

namespace NotificationService.Services;

/// <summary>
/// RabbitMQ consumer — listens to auth.*, listings.*, and payment.* events.
/// Dispatches to NotificationHandler for SignalR, Email, and Firebase notifications.
/// Fail-safe: if RabbitMQ is unreachable, the service starts without consuming.
/// </summary>
public class RabbitMQConsumerService : BackgroundService
{
    private IConnection? _connection;
    private IModel? _channel;
    private readonly ILogger<RabbitMQConsumerService> _logger;
    private readonly IServiceProvider _serviceProvider;
    private const string ExchangeName = "emlaktan.events";
    private const string QueueName = "emlaktan.notifications";
    private bool _isConnected;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public RabbitMQConsumerService(
        ILogger<RabbitMQConsumerService> logger,
        IConfiguration configuration,
        IServiceProvider serviceProvider)
    {
        _logger = logger;
        _serviceProvider = serviceProvider;

        var rabbitHost = configuration["RabbitMQ:Host"] ?? "localhost";
        if (rabbitHost == "disabled")
        {
            _logger.LogWarning("RabbitMQ is disabled — notifications will not be consumed from queue");
            return;
        }

        var factory = new ConnectionFactory
        {
            HostName = rabbitHost,
            Port = int.Parse(configuration["RabbitMQ:Port"] ?? "5672"),
            UserName = configuration["RabbitMQ:Username"] ?? "guest",
            Password = configuration["RabbitMQ:Password"] ?? "guest",
            DispatchConsumersAsync = true,
            RequestedConnectionTimeout = TimeSpan.FromSeconds(5)
        };

        try
        {
            _connection = factory.CreateConnection();
            _channel = _connection.CreateModel();

            // Declare queue
            _channel.QueueDeclare(
                queue: QueueName,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null
            );

            // Bind to all event categories
            _channel.QueueBind(queue: QueueName, exchange: ExchangeName, routingKey: "auth.#");
            _channel.QueueBind(queue: QueueName, exchange: ExchangeName, routingKey: "listings.#");
            _channel.QueueBind(queue: QueueName, exchange: ExchangeName, routingKey: "payment.#");

            // Prefetch 10 messages at a time
            _channel.BasicQos(prefetchSize: 0, prefetchCount: 10, global: false);

            _isConnected = true;
            _logger.LogInformation(
                "RabbitMQ consumer connected to queue: {QueueName} (auth.#, listings.#, payment.#)",
                QueueName);
        }
        catch (Exception ex)
        {
            _isConnected = false;
            _logger.LogWarning(ex, "Failed to connect to RabbitMQ — consumer will not start");
        }
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_isConnected || _channel == null)
        {
            _logger.LogWarning("RabbitMQ consumer not started (not connected)");
            return Task.CompletedTask;
        }

        var consumer = new AsyncEventingBasicConsumer(_channel);

        consumer.Received += async (model, ea) =>
        {
            var routingKey = ea.RoutingKey;
            var body = ea.Body.ToArray();
            var message = Encoding.UTF8.GetString(body);

            try
            {
                _logger.LogInformation("📨 Received event: {RoutingKey}", routingKey);

                using var scope = _serviceProvider.CreateScope();
                var handler = scope.ServiceProvider.GetRequiredService<INotificationHandler>();

                await DispatchEventAsync(handler, routingKey, message);

                _channel.BasicAck(deliveryTag: ea.DeliveryTag, multiple: false);
                _logger.LogInformation("✅ Event processed: {RoutingKey}", routingKey);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Error processing event: {RoutingKey}", routingKey);
                _channel.BasicNack(deliveryTag: ea.DeliveryTag, multiple: false, requeue: true);
            }
        };

        _channel.BasicConsume(
            queue: QueueName,
            autoAck: false,
            consumer: consumer
        );

        _logger.LogInformation("🔔 Started consuming messages from {QueueName}", QueueName);
        return Task.CompletedTask;
    }

    private static async Task DispatchEventAsync(INotificationHandler handler, string routingKey, string message)
    {
        // Auth events
        if (routingKey.StartsWith("auth.userregistered"))
        {
            var @event = JsonSerializer.Deserialize<UserRegisteredEvent>(message, JsonOptions);
            if (@event != null) await handler.HandleUserRegisteredAsync(@event);
        }
        else if (routingKey.StartsWith("auth.passwordresetrequested"))
        {
            var @event = JsonSerializer.Deserialize<PasswordResetRequestedEvent>(message, JsonOptions);
            if (@event != null) await handler.HandlePasswordResetRequestedAsync(@event);
        }
        // Listing events
        else if (routingKey.StartsWith("listings.listingcreated"))
        {
            var @event = JsonSerializer.Deserialize<ListingCreatedEvent>(message, JsonOptions);
            if (@event != null) await handler.HandleListingCreatedAsync(@event);
        }
        else if (routingKey.Contains("pricechanged"))
        {
            var @event = JsonSerializer.Deserialize<ListingPriceChangedEvent>(message, JsonOptions);
            if (@event != null) await handler.HandleListingPriceChangedAsync(@event);
        }
        // Payment events
        else if (routingKey.StartsWith("payment.paymentcompleted"))
        {
            var @event = JsonSerializer.Deserialize<PaymentCompletedEvent>(message, JsonOptions);
            if (@event != null) await handler.HandlePaymentCompletedAsync(@event);
        }
        else if (routingKey.StartsWith("payment.premiumactivated"))
        {
            var @event = JsonSerializer.Deserialize<PremiumActivatedEvent>(message, JsonOptions);
            if (@event != null) await handler.HandlePremiumActivatedAsync(@event);
        }
    }

    public override void Dispose()
    {
        _channel?.Close();
        _channel?.Dispose();
        _connection?.Close();
        _connection?.Dispose();
        if (_isConnected) _logger.LogInformation("RabbitMQ consumer connection closed");
        base.Dispose();
    }
}
