using MongoDB.Driver;
using MessagingService.Models;

namespace MessagingService.Repositories;

public interface IMessageRepository
{
    Task<Conversation> GetConversationAsync(string id);
    Task<Conversation?> GetConversationByParticipantsAsync(string user1, string user2);
    Task<List<Conversation>> GetUserConversationsAsync(string userId);
    Task<Conversation> CreateConversationAsync(List<string> participants, string? listingId);
    Task<Message> CreateMessageAsync(Message message);
    Task<List<Message>> GetConversationMessagesAsync(string conversationId, int skip = 0, int limit = 50);
    Task MarkMessagesAsReadAsync(string conversationId, string userId);
    Task UpdateConversationLastMessageAsync(string conversationId);
}

public class MessageRepository : IMessageRepository
{
    private readonly IMongoCollection<Conversation> _conversations;
    private readonly IMongoCollection<Message> _messages;
    private readonly ILogger<MessageRepository> _logger;

    public MessageRepository(IMongoDatabase database, ILogger<MessageRepository> logger)
    {
        _conversations = database.GetCollection<Conversation>("conversations");
        _messages = database.GetCollection<Message>("messages");
        _logger = logger;
        CreateIndexes().Wait();
    }

    private async Task CreateIndexes()
    {
        await _conversations.Indexes.CreateOneAsync(
            new CreateIndexModel<Conversation>(
                Builders<Conversation>.IndexKeys.Ascending(c => c.Participants)));

        await _messages.Indexes.CreateOneAsync(
            new CreateIndexModel<Message>(
                Builders<Message>.IndexKeys.Ascending(m => m.ConversationId)));
    }

    public async Task<Conversation> GetConversationAsync(string id)
    {
        return await _conversations.Find(c => c.Id == id).FirstOrDefaultAsync();
    }

    public async Task<Conversation?> GetConversationByParticipantsAsync(string user1, string user2)
    {
        return await _conversations.Find(c => 
            c.Participants.Contains(user1) && c.Participants.Contains(user2))
            .FirstOrDefaultAsync();
    }

    public async Task<List<Conversation>> GetUserConversationsAsync(string userId)
    {
        return await _conversations
            .Find(c => c.Participants.Contains(userId))
            .SortByDescending(c => c.LastMessageAt)
            .ToListAsync();
    }

    public async Task<Conversation> CreateConversationAsync(List<string> participants, string? listingId)
    {
        var conversation = new Conversation
        {
            Participants = participants,
            ListingId = listingId
        };
        await _conversations.InsertOneAsync(conversation);
        return conversation;
    }

    public async Task<Message> CreateMessageAsync(Message message)
    {
        await _messages.InsertOneAsync(message);
        return message;
    }

    public async Task<List<Message>> GetConversationMessagesAsync(string conversationId, int skip = 0, int limit = 50)
    {
        return await _messages
            .Find(m => m.ConversationId == conversationId)
            .SortByDescending(m => m.CreatedAt)
            .Skip(skip)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task MarkMessagesAsReadAsync(string conversationId, string userId)
    {
        await _messages.UpdateManyAsync(
            m => m.ConversationId == conversationId && m.SenderId != userId && !m.IsRead,
            Builders<Message>.Update.Set(m => m.IsRead, true));
    }

    public async Task UpdateConversationLastMessageAsync(string conversationId)
    {
        await _conversations.UpdateOneAsync(
            c => c.Id == conversationId,
            Builders<Conversation>.Update.Set(c => c.LastMessageAt, DateTime.UtcNow));
    }
}
