import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

/// Real-time notification service using SignalR
class NotificationService {
  static String get _hubUrl => '${ApiService.baseUrl}/hubs/notifications';
  
  HubConnection? _hubConnection;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  
  // Callbacks for different notification types
  Function(PriceChangedNotification)? onPriceChanged;
  Function(PriceChangedNotification)? onPriceAlert;
  Function(String)? onConnectionStatusChanged;
  
  bool get isConnected => _isConnected;
  
  /// Connect to the NotificationHub with JWT token
  Future<void> connect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        debugPrint('🔔 NotificationService: No token available, skipping connection');
        return;
      }
      
      // Build connection with JWT authentication
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
            ),
          )
          .withAutomaticReconnect(retryDelays: [
            0,      // First retry immediately
            2000,   // Then wait 2 seconds
            5000,   // Then 5 seconds
            10000,  // Then 10 seconds
            30000,  // Then 30 seconds
          ])
          .build();
      
      // Setup event handlers
      _setupEventHandlers();
      
      // Start connection
      await _hubConnection!.start();
      _isConnected = true;
      _reconnectAttempts = 0;
      onConnectionStatusChanged?.call('connected');
      
      debugPrint('🔔 NotificationService: Connected to NotificationHub');
    } catch (e) {
      debugPrint('🔔 NotificationService: Connection failed - $e');
      _isConnected = false;
      onConnectionStatusChanged?.call('disconnected');
      _scheduleReconnect();
    }
  }
  
  /// Setup SignalR event handlers
  void _setupEventHandlers() {
    if (_hubConnection == null) return;
    
    // Handle connection state changes
    _hubConnection!.onclose(({error}) {
      _isConnected = false;
      onConnectionStatusChanged?.call('disconnected');
      debugPrint('🔔 NotificationService: Connection closed - $error');
      _scheduleReconnect();
    });
    
    _hubConnection!.onreconnecting(({error}) {
      _isConnected = false;
      onConnectionStatusChanged?.call('reconnecting');
      debugPrint('🔔 NotificationService: Reconnecting... - $error');
    });
    
    _hubConnection!.onreconnected(({connectionId}) {
      _isConnected = true;
      _reconnectAttempts = 0;
      onConnectionStatusChanged?.call('connected');
      debugPrint('🔔 NotificationService: Reconnected - $connectionId');
    });
    
    // Listen for PriceChanged event (targeted to subscribed listings)
    _hubConnection!.on('PriceChanged', (arguments) {
      debugPrint('🔔 Received PriceChanged: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        final notification = PriceChangedNotification.fromJson(
          arguments[0] as Map<String, dynamic>,
        );
        onPriceChanged?.call(notification);
      }
    });
    
    // Listen for PriceAlert event (broadcast to all users)
    _hubConnection!.on('PriceAlert', (arguments) {
      debugPrint('🔔 Received PriceAlert: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        final notification = PriceChangedNotification.fromJson(
          arguments[0] as Map<String, dynamic>,
        );
        onPriceAlert?.call(notification);
      }
    });
  }
  
  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('🔔 NotificationService: Max reconnect attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    
    // Exponential backoff: 2^n seconds
    final delay = Duration(seconds: (1 << _reconnectAttempts).clamp(1, 60));
    _reconnectAttempts++;
    
    debugPrint('🔔 NotificationService: Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () async {
      await connect();
    });
  }
  
  /// Subscribe to price alerts for a specific listing
  Future<void> subscribeToListing(String listingId) async {
    if (_hubConnection == null || !_isConnected) {
      debugPrint('🔔 Cannot subscribe: Not connected');
      return;
    }
    
    try {
      await _hubConnection!.invoke('SubscribeToListing', args: [listingId]);
      debugPrint('🔔 Subscribed to listing: $listingId');
    } catch (e) {
      debugPrint('🔔 Subscribe failed: $e');
    }
  }
  
  /// Unsubscribe from price alerts for a specific listing
  Future<void> unsubscribeFromListing(String listingId) async {
    if (_hubConnection == null || !_isConnected) return;
    
    try {
      await _hubConnection!.invoke('UnsubscribeFromListing', args: [listingId]);
      debugPrint('🔔 Unsubscribed from listing: $listingId');
    } catch (e) {
      debugPrint('🔔 Unsubscribe failed: $e');
    }
  }
  
  /// Disconnect from the hub
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
    }
    
    _isConnected = false;
    onConnectionStatusChanged?.call('disconnected');
    debugPrint('🔔 NotificationService: Disconnected');
  }
  
  /// Dispose resources
  void dispose() {
    disconnect();
  }
}

/// Model for price change notifications
class PriceChangedNotification {
  final String type;
  final String listingId;
  final double oldPrice;
  final double newPrice;
  final double changePercentage;
  final bool isPriceReduced;
  final DateTime timestamp;
  final String message;
  
  PriceChangedNotification({
    required this.type,
    required this.listingId,
    required this.oldPrice,
    required this.newPrice,
    required this.changePercentage,
    required this.isPriceReduced,
    required this.timestamp,
    required this.message,
  });
  
  factory PriceChangedNotification.fromJson(Map<String, dynamic> json) {
    return PriceChangedNotification(
      type: json['type'] ?? 'PRICE_CHANGED',
      listingId: json['listingId'] ?? '',
      oldPrice: (json['oldPrice'] ?? 0).toDouble(),
      newPrice: (json['newPrice'] ?? 0).toDouble(),
      changePercentage: (json['changePercentage'] ?? 0).toDouble(),
      isPriceReduced: json['isPriceReduced'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      message: json['message'] ?? '',
    );
  }
  
  @override
  String toString() => 'PriceChanged(listingId: $listingId, $oldPrice → $newPrice, ${changePercentage.toStringAsFixed(1)}%)';
}
