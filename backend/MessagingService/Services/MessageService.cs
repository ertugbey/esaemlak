using MessagingService.Models;
using MessagingService.Repositories;

namespace MessagingService.Services;

public interface IMessageService
{
    Task<Conversation> GetConversationAsync(string id);
    Task<Conversation> GetOrCreateConversationAsync(string userId, string otherUserId, string? listingId);
    Task<List<Conversation>> GetUserConversationsAsync(string userId);
    Task<Message> SendMessageAsync(string conversationId, string senderId, string content);
    Task<List<Message>> GetMessagesAsync(string conversationId, int skip = 0, int limit = 50);
    Task MarkMessagesAsReadAsync(string conversationId, string userId);
}

public class MessageService : IMessageService
{
    private readonly IMessageRepository _repository;
    private readonly ILogger<MessageService> _logger;

    public MessageService(IMessageRepository repository, ILogger<MessageService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<Conversation> GetConversationAsync(string id)
    {
        return await _repository.GetConversationAsync(id);
    }

    public async Task<Conversation> GetOrCreateConversationAsync(string userId, string otherUserId, string? listingId)
    {
        var existing = await _repository.GetConversationByParticipantsAsync(userId, otherUserId);
        if (existing != null) return existing;

        var conversation = await _repository.CreateConversationAsync(
            new List<string> { userId, otherUserId }, listingId);

        _logger.LogInformation("Created new conversation between {User1} and {User2}", userId, otherUserId);
        return conversation;
    }

    public async Task<List<Conversation>> GetUserConversationsAsync(string userId)
    {
        return await _repository.GetUserConversationsAsync(userId);
    }

    public async Task<Message> SendMessageAsync(string conversationId, string senderId, string content)
    {
        var message = new Message
        {
            ConversationId = conversationId,
            SenderId = senderId,
            Content = content
        };

        var created = await _repository.CreateMessageAsync(message);
        await _repository.UpdateConversationLastMessageAsync(conversationId);

        _logger.LogInformation("Message sent in conversation {ConversationId}", conversationId);
        return created;
    }

    public async Task<List<Message>> GetMessagesAsync(string conversationId, int skip = 0, int limit = 50)
    {
        return await _repository.GetConversationMessagesAsync(conversationId, skip, limit);
    }

    public async Task MarkMessagesAsReadAsync(string conversationId, string userId)
    {
        await _repository.MarkMessagesAsReadAsync(conversationId, userId);
    }
}
