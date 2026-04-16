import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

/// Messaging service for real-time chat via SignalR
class MessagingService extends ChangeNotifier {
  static String get _baseUrl => '${ApiService.baseUrl}/api/messages';
  static String get _hubUrl => '${ApiService.baseUrl}/hubs/chat';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  HubConnection? _hubConnection;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  List<Conversation> _conversations = [];
  List<Conversation> get conversations => _conversations;
  
  final Map<String, List<ChatMessage>> _messages = {};
  
  // Callbacks
  Function(ChatMessage)? onMessageReceived;
  Function(String visibleConversationId)? onTypingReceived;

  /// Connect to SignalR hub
  Future<void> connect() async {
    if (_isConnected) return;
    
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      debugPrint('❌ No auth token for messaging');
      return;
    }

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          _hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    // Listen for incoming messages
    _hubConnection!.on('ReceiveMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        final message = ChatMessage.fromJson(data);
        
        // Add to local cache
        _messages.putIfAbsent(message.conversationId, () => []);
        _messages[message.conversationId]!.insert(0, message);
        
        // Update conversation last message
        final convIndex = _conversations.indexWhere((c) => c.id == message.conversationId);
        if (convIndex >= 0) {
          _conversations[convIndex] = _conversations[convIndex].copyWith(
            lastMessage: message.content,
            lastMessageAt: message.createdAt,
          );
          // Move to top
          final conv = _conversations.removeAt(convIndex);
          _conversations.insert(0, conv);
        }
        
        onMessageReceived?.call(message);
        notifyListeners();
      }
    });

    _hubConnection!.on('UserTyping', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final conversationId = arguments[0] as String;
        onTypingReceived?.call(conversationId);
      }
    });

    try {
      await _hubConnection!.start();
      _isConnected = true;
      debugPrint('✅ Connected to chat hub');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to connect to chat hub: $e');
      _isConnected = false;
    }
  }

  /// Disconnect from SignalR hub
  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Get all conversations for current user
  Future<List<Conversation>> getConversations() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _conversations = data.map((j) => Conversation.fromJson(j)).toList();
        notifyListeners();
        return _conversations;
      }
    } catch (e) {
      debugPrint('❌ Failed to get conversations: $e');
    }
    return [];
  }

  /// Get messages for a conversation
  Future<List<ChatMessage>> getMessages(String conversationId, {int skip = 0, int limit = 50}) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages?skip=$skip&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final messages = data.map((j) => ChatMessage.fromJson(j)).toList();
        _messages[conversationId] = messages;
        notifyListeners();
        return messages;
      }
    } catch (e) {
      debugPrint('❌ Failed to get messages: $e');
    }
    return [];
  }

  /// Send a message via SignalR
  Future<void> sendMessage(String conversationId, String content) async {
    if (!_isConnected || _hubConnection == null) {
      debugPrint('❌ Not connected to chat hub');
      return;
    }

    try {
      await _hubConnection!.invoke('SendMessage', args: [conversationId, content]);
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
    }
  }

  /// Start or get existing conversation
  Future<Conversation?> getOrCreateConversation(String otherUserId, {String? listingId}) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'otherUserId': otherUserId,
          'listingId': listingId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final conv = Conversation.fromJson(json.decode(response.body));
        // Add to list if not exists
        if (!_conversations.any((c) => c.id == conv.id)) {
          _conversations.insert(0, conv);
          notifyListeners();
        }
        return conv;
      }
    } catch (e) {
      debugPrint('❌ Failed to create conversation: $e');
    }
    return null;
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection!.invoke('MarkAsRead', args: [conversationId]);
      } catch (e) {
        debugPrint('❌ Failed to mark as read: $e');
      }
    }
  }

  /// Join a conversation room
  Future<void> joinConversation(String conversationId) async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection!.invoke('JoinConversation', args: [conversationId]);
      } catch (e) {
        debugPrint('❌ Failed to join conversation: $e');
      }
    }
  }

  /// Get cached messages for a conversation
  List<ChatMessage> getCachedMessages(String conversationId) {
    return _messages[conversationId] ?? [];
  }

  /// Get unread count for all conversations
  int get totalUnreadCount {
    return _conversations.fold(0, (sum, c) => sum + c.unreadCount);
  }
}

/// Conversation model
class Conversation {
  final String id;
  final List<String> participants;
  final String? listingId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? otherUserName;
  final String? otherUserAvatar;

  Conversation({
    required this.id,
    required this.participants,
    this.listingId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherUserName,
    this.otherUserAvatar,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? json['_id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      listingId: json['listingId'],
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      otherUserName: json['otherUserName'],
      otherUserAvatar: json['otherUserAvatar'],
    );
  }

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return Conversation(
      id: id,
      participants: participants,
      listingId: listingId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
    );
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['messageId'] ?? json['_id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }
}
