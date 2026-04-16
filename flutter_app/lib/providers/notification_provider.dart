import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../widgets/notification_toast.dart';

/// Global context key for showing toasts
BuildContext? _globalContext;

void setGlobalContext(BuildContext context) {
  _globalContext = context;
}

/// Provider for managing real-time notifications
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  final List<AppNotification> _notifications = [];
  String _connectionStatus = 'disconnected';
  int _unreadCount = 0;
  
  // Getters
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  String get connectionStatus => _connectionStatus;
  int get unreadCount => _unreadCount;
  bool get isConnected => _connectionStatus == 'connected';
  
  // Callback for navigation (set from main.dart)
  void Function(String listingId)? onNavigateToListing;
  
  /// Initialize and connect to notification hub
  Future<void> connect() async {
    // Setup callbacks
    _notificationService.onConnectionStatusChanged = (status) {
      _connectionStatus = status;
      notifyListeners();
    };
    
    _notificationService.onPriceChanged = (notification) {
      _handlePriceNotification(notification, isPriceAlert: false);
    };
    
    _notificationService.onPriceAlert = (notification) {
      _handlePriceNotification(notification, isPriceAlert: true);
    };
    
    await _notificationService.connect();
  }
  
  /// Handle price notification and show toast
  void _handlePriceNotification(PriceChangedNotification notification, {required bool isPriceAlert}) {
    // Add to notification list
    _addNotification(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: isPriceAlert ? NotificationType.priceAlert : NotificationType.priceChanged,
      title: notification.isPriceReduced ? '📉 Fiyat Düştü!' : '📈 Fiyat Arttı',
      message: notification.message,
      data: {
        'listingId': notification.listingId,
        'oldPrice': notification.oldPrice,
        'newPrice': notification.newPrice,
        'changePercentage': notification.changePercentage,
      },
      timestamp: notification.timestamp,
      isRead: false,
    ));
    
    // Show toast notification if context is available
    if (_globalContext != null) {
      NotificationToastService.showPriceAlert(
        context: _globalContext!,
        listingId: notification.listingId,
        listingTitle: notification.message.split(':').last.trim(), // Extract title from message
        oldPrice: notification.oldPrice,
        newPrice: notification.newPrice,
        isPriceReduced: notification.isPriceReduced,
        onViewPressed: () {
          // Navigate to listing detail
          onNavigateToListing?.call(notification.listingId);
        },
      );
    }
  }
  
  /// Add a new notification
  void _addNotification(AppNotification notification) {
    _notifications.insert(0, notification); // Add to beginning
    _unreadCount++;
    
    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
    
    notifyListeners();
    debugPrint('🔔 New notification added: ${notification.title}');
  }
  
  /// Mark a notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      notifyListeners();
    }
  }
  
  /// Mark all notifications as read
  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();
  }
  
  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }
  
  /// Subscribe to a specific listing's price alerts
  Future<void> subscribeToListing(String listingId) async {
    await _notificationService.subscribeToListing(listingId);
  }
  
  /// Unsubscribe from a listing's price alerts
  Future<void> unsubscribeFromListing(String listingId) async {
    await _notificationService.unsubscribeFromListing(listingId);
  }
  
  /// Disconnect from notification hub
  Future<void> disconnect() async {
    await _notificationService.disconnect();
    _connectionStatus = 'disconnected';
    notifyListeners();
  }
  
  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}

/// Notification types
enum NotificationType {
  priceChanged,
  priceAlert,
  newListing,
  message,
  system,
}

/// App notification model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.timestamp,
    required this.isRead,
  });
  
  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
  
  /// Get icon based on notification type
  IconData get icon {
    switch (type) {
      case NotificationType.priceChanged:
        return Icons.trending_down;
      case NotificationType.priceAlert:
        return Icons.notifications_active;
      case NotificationType.newListing:
        return Icons.home;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.system:
        return Icons.info;
    }
  }
  
  /// Get color based on notification type
  Color get color {
    switch (type) {
      case NotificationType.priceChanged:
        return Colors.green;
      case NotificationType.priceAlert:
        return Colors.orange;
      case NotificationType.newListing:
        return Colors.blue;
      case NotificationType.message:
        return Colors.purple;
      case NotificationType.system:
        return Colors.grey;
    }
  }
  
  /// Format relative time
  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}
