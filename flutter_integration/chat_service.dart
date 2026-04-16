// Flutter SignalR Chat Service Example
// Copy to: lib/services/chat_service.dart
// Add dependency: signalr_netcore: ^1.3.8

import 'package:signalr_netcore/signalr_netcore.dart';

class ChatService {
  static const String hubUrl = 'http://localhost:5000/hubs/chat';
  
  HubConnection? _connection;
  final String _token;
  
  Function(Map<String, dynamic>)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;

  ChatService(this._token);

  Future<void> connect() async {
    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => _token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final message = arguments[0] as Map<String, dynamic>;
        onMessageReceived?.call(message);
      }
    });

    _connection!.onclose(({error}) {
      onDisconnected?.call();
    });

    await _connection!.start();
    onConnected?.call();
  }

  Future<void> sendMessage(String conversationId, String content) async {
    await _connection?.invoke('SendMessage', args: [conversationId, content]);
  }

  Future<void> joinConversation(String conversationId) async {
    await _connection?.invoke('JoinConversation', args: [conversationId]);
  }

  Future<void> markAsRead(String conversationId) async {
    await _connection?.invoke('MarkAsRead', args: [conversationId]);
  }

  Future<void> disconnect() async {
    await _connection?.stop();
  }
}

// Usage:
// final chat = ChatService(jwtToken);
// chat.onMessageReceived = (msg) => print('New: ${msg['content']}');
// await chat.connect();
// await chat.sendMessage('conv123', 'Merhaba!');
