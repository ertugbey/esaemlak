import 'package:flutter/material.dart';

/// Tracks backend service status and displays maintenance mode when needed
class ServiceStatusProvider extends ChangeNotifier {
  bool _isMaintenanceMode = false;
  String _maintenanceMessage = '';
  int _errorCode = 0;
  DateTime? _lastErrorTime;
  int _consecutiveErrors = 0;
  
  bool get isMaintenanceMode => _isMaintenanceMode;
  String get maintenanceMessage => _maintenanceMessage;
  int get errorCode => _errorCode;
  
  /// Called when API returns error codes indicating service issues
  void handleApiError(int statusCode, {String? message}) {
    _errorCode = statusCode;
    _consecutiveErrors++;
    _lastErrorTime = DateTime.now();
    
    switch (statusCode) {
      case 429: // Rate Limited
        _isMaintenanceMode = true;
        _maintenanceMessage = 'Çok fazla istek gönderildi. Lütfen biraz bekleyin.';
        break;
      case 502: // Bad Gateway
      case 503: // Service Unavailable
      case 504: // Gateway Timeout
        _isMaintenanceMode = true;
        _maintenanceMessage = 'Servislerimiz şu an bakımdadır. Kısa süre içinde geri döneceğiz.';
        break;
      case 500: // Internal Server Error
        if (_consecutiveErrors >= 3) {
          _isMaintenanceMode = true;
          _maintenanceMessage = 'Teknik bir sorun yaşıyoruz. Lütfen daha sonra tekrar deneyin.';
        }
        break;
      default:
        // Don't trigger maintenance mode for other errors
        break;
    }
    
    notifyListeners();
  }
  
  /// Called when API returns successful response
  void handleApiSuccess() {
    _consecutiveErrors = 0;
    
    // Clear maintenance mode after some time if success
    if (_isMaintenanceMode && _lastErrorTime != null) {
      final elapsed = DateTime.now().difference(_lastErrorTime!);
      if (elapsed.inSeconds > 5) {
        _isMaintenanceMode = false;
        _maintenanceMessage = '';
        _errorCode = 0;
        notifyListeners();
      }
    }
  }
  
  /// Manually dismiss maintenance mode (for user action)
  void dismissMaintenance() {
    _isMaintenanceMode = false;
    _maintenanceMessage = '';
    _errorCode = 0;
    _consecutiveErrors = 0;
    notifyListeners();
  }
  
  /// Force maintenance mode (for testing)
  void forceMaintenanceMode(String message) {
    _isMaintenanceMode = true;
    _maintenanceMessage = message;
    notifyListeners();
  }
}
