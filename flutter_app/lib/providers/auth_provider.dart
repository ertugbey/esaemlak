import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get user => _user;
  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get userId => _user?.id;

  /// Check for existing auth session (Auto-login)
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First check if we have a stored token
      final hasSession = await SecureStorageService.hasValidSession();
      
      if (!hasSession) {
        _user = null;
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // Token exists, validate with server
      final data = await _api.getCurrentUser();
      if (data != null) {
        _user = User.fromJson(data['user'] ?? data);
        debugPrint('✅ Auto-login successful: ${_user?.email}');
      } else {
        // Token invalid, clear storage
        await SecureStorageService.clearAll();
        _user = null;
      }
    } catch (e) {
      debugPrint('❌ Auto-login failed: $e');
      // Clear invalid session
      await SecureStorageService.clearAll();
      _user = null;
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(email, password);
      
      if (data['token'] != null && data['user'] != null) {
        // Save tokens securely
        await SecureStorageService.saveToken(data['token']);
        if (data['refreshToken'] != null) {
          await SecureStorageService.saveRefreshToken(data['refreshToken']);
        }
        
        // Save user info
        _user = User.fromJson(data['user']);
        await SecureStorageService.saveUserInfo(
          userId: _user!.id,
          email: _user!.email,
        );
        
        debugPrint('✅ Login successful: ${_user?.email}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['error'] ?? data['message'] ?? 'Giriş başarısız';
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _error = _parseError(e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Register new user
  Future<bool> register({
    required String ad,
    required String soyad,
    required String email,
    required String telefon,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.register(
        ad: ad,
        soyad: soyad,
        email: email,
        telefon: telefon,
        password: password,
      );
      
      if (data['token'] != null && data['user'] != null) {
        // Save tokens securely
        await SecureStorageService.saveToken(data['token']);
        if (data['refreshToken'] != null) {
          await SecureStorageService.saveRefreshToken(data['refreshToken']);
        }
        
        _user = User.fromJson(data['user']);
        await SecureStorageService.saveUserInfo(
          userId: _user!.id,
          email: _user!.email,
        );
        
        debugPrint('✅ Registration successful: ${_user?.email}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['error'] ?? data['message'] ?? 'Kayıt başarısız';
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      _error = _parseError(e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Logout and clear all stored data
  Future<void> logout() async {
    try {
      await _api.logout(); // Call backend to invalidate refresh token
    } catch (_) {}
    await SecureStorageService.clearAll();
    await _api.clearToken();
    _user = null;
    debugPrint('👋 User logged out');
    notifyListeners();
  }

  /// Parse error to user-friendly Turkish message
  String _parseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socketexception') || errorStr.contains('connection refused') || 
        errorStr.contains('network is unreachable') || errorStr.contains('errno = 111')) {
      return 'Sunucuya bağlanılamıyor. Backend servislerinin çalıştığından emin olun.';
    }
    if (errorStr.contains('connection') || errorStr.contains('socket')) {
      return 'İnternet bağlantınızı kontrol edin';
    }
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Sunucu yanıt vermiyor, tekrar deneyin';
    }
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'E-posta veya şifre hatalı';
    }
    if (errorStr.contains('already') || errorStr.contains('exists')) {
      return 'Bu e-posta adresi zaten kayıtlı';
    }
    if (errorStr.contains('banned')) {
      return 'Hesabınız askıya alınmış';
    }
    if (errorStr.contains('handshake') || errorStr.contains('certificate')) {
      return 'SSL bağlantı hatası';
    }
    
    return 'Hata: $error';
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
