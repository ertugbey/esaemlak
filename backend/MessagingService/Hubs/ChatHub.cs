using Microsoft.AspNetCore.SignalR;
using MessagingService.Services;

namespace MessagingService.Hubs;

public class ChatHub : Hub
{
    private readonly IMessageService _messageService;
    private readonly ILogger<ChatHub> _logger;

    public ChatHub(IMessageService messageService, ILogger<ChatHub> logger)
    {
        _messageService = messageService;
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.UserIdentifier;
        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
            _logger.LogInformation("User {UserId} connected to chat", userId);
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.UserIdentifier;
        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
            _logger.LogInformation("User {UserId} disconnected from chat", userId);
        }
        await base.OnDisconnectedAsync(exception);
    }

    public async Task SendMessage(string conversationId, string content)
    {
        var userId = Context.UserIdentifier;
        if (string.IsNullOrEmpty(userId))
        {
            throw new HubException("Unauthorized");
        }

        var message = await _messageService.SendMessageAsync(conversationId, userId, content);

        // Get other participants and notify them
        var conversation = await _messageService.GetConversationAsync(conversationId);
        foreach (var participantId in conversation.Participants)
        {
            await Clients.Group($"user_{participantId}").SendAsync("ReceiveMessage", new
            {
                messageId = message.Id,
                conversationId = message.ConversationId,
                senderId = message.SenderId,
                content = message.Content,
                createdAt = message.CreatedAt
            });
        }

        _logger.LogInformation("Message sent from {SenderId} in conversation {ConversationId}", userId, conversationId);
    }

    public async Task JoinConversation(string conversationId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"conversation_{conversationId}");
        _logger.LogInformation("User joined conversation {ConversationId}", conversationId);
    }

    public async Task MarkAsRead(string conversationId)
    {
        var userId = Context.UserIdentifier;
        if (!string.IsNullOrEmpty(userId))
        {
            await _messageService.MarkMessagesAsReadAsync(conversationId, userId);
        }
    }
}
