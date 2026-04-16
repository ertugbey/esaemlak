import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../widgets/price_drops_slider.dart';

class ApiService {
  // ☁️ Bulut sunucusu (Fly.io) - true yapınca canlı sunucuya bağlanır
  static const bool _useCloud = true;
  
  // Android emülatörde localhost = 10.0.2.2, gerçek cihazda bilgisayarın IP'si
  // Gerçek telefon kullanıyorsanız: false, Emülatör kullanıyorsanız: true
  static const bool _isEmulator = true;

  static String get baseUrl {
    if (_useCloud) return 'https://esaemlak-api.fly.dev';
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid && _isEmulator) return 'http://10.0.2.2:5000';
    return 'http://10.0.84.125:5000'; // Gerçek cihaz (aynı WiFi'de olmalı)
  }

  String? _token;

  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Güvenli JSON parse — boş veya hatalı yanıtlarda crash yapmaz
  Map<String, dynamic> _parseResponse(http.Response res) {
    final body = res.body.trim();
    if (body.isEmpty) {
      return {'error': 'Sunucu boş yanıt döndürdü (HTTP ${res.statusCode})'};
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'error': 'Beklenmedik yanıt formatı'};
    } catch (_) {
      return {'error': 'Sunucu yanıtı işlenemedi: $body'};
    }
  }

  // AUTH
  Future<Map<String, dynamic>> register({
    required String ad,
    required String soyad,
    required String email,
    required String telefon,
    required String password,
    String rol = 'kullanici',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ad': ad, 'soyad': soyad, 'email': email,
        'telefon': telefon, 'password': password, 'rol': rol,
      }),
    );
    final data = _parseResponse(res);
    if (res.statusCode == 200 && data['token'] != null) await saveToken(data['token']);
    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      return http.Response('{"error": "Sunucuya bağlanılamadı, lütfen tekrar deneyin"}', 408);
    });
    final data = _parseResponse(res);
    if (res.statusCode == 200 && data['token'] != null) await saveToken(data['token']);
    return data;
  }

  Future<Map<String, String>> get _headers async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final t = await token;
    if (t == null) return null;
    final res = await http.get(Uri.parse('$baseUrl/api/auth/me'), headers: await _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: await _headers,
      );
    } catch (_) {}
    await clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refresh_token');
  }

  // REFRESH TOKEN
  Future<Map<String, dynamic>> refreshTokenRequest(String refreshToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    final data = _parseResponse(res);
    if (res.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', data['refreshToken'] ?? '');
    }
    return data;
  }

  // FORGOT PASSWORD
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return _parseResponse(res);
  }

  // RESET PASSWORD
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'token': token,
        'newPassword': newPassword,
      }),
    );
    return _parseResponse(res);
  }

  // CHANGE PASSWORD
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/change-password'),
      headers: await _headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    return _parseResponse(res);
  }

  // UPDATE PROFILE
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    return _parseResponse(res);
  }

  // LISTINGS
  Future<List<dynamic>> searchListings({String? q, String? il, String? emlakTipi, int skip = 0}) async {
    final params = <String, String>{'skip': '$skip', 'limit': '20'};
    if (q != null) params['q'] = q;
    if (il != null) params['il'] = il;
    if (emlakTipi != null) params['emlakTipi'] = emlakTipi;
    
    final uri = Uri.parse('$baseUrl/api/search').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers);
    final data = jsonDecode(res.body);
    return data['results'] ?? [];
  }

  // Get listings with pagination
  Future<List<Listing>> getListings({int skip = 0, int limit = 20}) async {
    try {
      final params = <String, String>{'skip': '$skip', 'limit': '$limit'};
      final uri = Uri.parse('$baseUrl/api/listings').replace(queryParameters: params);
      final res = await http.get(uri, headers: await _headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => Listing.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading listings: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getListing(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/listings/$id'), headers: await _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createListing(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/listings'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  // PRICE DROPS
  Future<List<PriceDrop>> getPriceDrops({int limit = 10}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/listings/price-drops?limit=$limit'),
        headers: await _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((json) => PriceDrop.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // SHOWCASE - Homepage vitrin sections
  Future<Map<String, List<Listing>>> getShowcase() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/listings/showcase'),
        headers: await _headers,
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        return {
          'gununFirsatlari': (data['gununFirsatlari'] as List? ?? [])
              .map((e) => Listing.fromJson(e))
              .toList(),
          'acilSatiliklar': (data['acilSatiliklar'] as List? ?? [])
              .map((e) => Listing.fromJson(e))
              .toList(),
          'yeniIlanlar': (data['sonEklenenler'] as List? ?? [])
              .map((e) => Listing.fromJson(e))
              .toList(),
          'populerIlanlar': (data['cokGoruntulenler'] as List? ?? [])
              .map((e) => Listing.fromJson(e))
              .toList(),
          'fiyatiDusenler': (data['fiyatiDusenler'] as List? ?? [])
              .map((e) => Listing.fromJson(e))
              .toList(),
        };
      }
      return {};
    } catch (e) {
      debugPrint('Error loading showcase: $e');
      return {};
    }
  }

  // MY LISTINGS - Kullanıcının kendi ilanları
  Future<List<dynamic>> getMyListings({int skip = 0, int limit = 20}) async {
    final t = await token;
    if (t == null) throw Exception('Oturum açmanız gerekiyor');
    
    final res = await http.get(
      Uri.parse('$baseUrl/api/listings/my-listings?skip=$skip&limit=$limit'),
      headers: await _headers,
    );
    
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else if (res.statusCode == 401) {
      throw Exception('Oturum süresi doldu, tekrar giriş yapın');
    }
    throw Exception('İlanlar yüklenemedi');
  }

  Future<Map<String, dynamic>> updateListing(String id, Map<String, dynamic> data) async {
    final t = await token;
    if (t == null) throw Exception('Oturum açmanız gerekiyor');
    
    final res = await http.put(
      Uri.parse('$baseUrl/api/listings/$id'),
      headers: await _headers,
      body: jsonEncode(data),
    );
    
    if (res.statusCode == 204) {
      return {'success': true};
    } else if (res.statusCode == 401) {
      throw Exception('Oturum süresi doldu');
    } else if (res.statusCode == 403) {
      throw Exception('Bu ilanı düzenleme yetkiniz yok');
    }
    
    final error = jsonDecode(res.body);
    throw Exception(error['error'] ?? 'İlan güncellenemedi');
  }

  Future<void> deleteListing(String id) async {
    final t = await token;
    if (t == null) throw Exception('Oturum açmanız gerekiyor');
    
    final res = await http.delete(
      Uri.parse('$baseUrl/api/listings/$id'),
      headers: await _headers,
    );
    
    if (res.statusCode == 204) {
      return;
    } else if (res.statusCode == 401) {
      throw Exception('Oturum süresi doldu');
    } else if (res.statusCode == 403) {
      throw Exception('Bu ilanı silme yetkiniz yok');
    }
    
    final error = jsonDecode(res.body);
    throw Exception(error['error'] ?? 'İlan silinemedi');
  }

  // PHOTO UPLOAD
  Future<List<String>> uploadPhotos(List<String> filePaths) async {
    final t = await token;
    if (t == null) throw Exception('Oturum açmanız gerekiyor');
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/listings/upload'),
    );
    
    request.headers['Authorization'] = 'Bearer $t';
    
    for (var path in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', path));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['uploadedUrls'] ?? []);
    }
    
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Fotoğraflar yüklenemedi');
  }

  // FAVORITES
  Future<List<String>> getFavorites() async {
    final t = await token;
    if (t == null) return [];
    
    final res = await http.get(
      Uri.parse('$baseUrl/api/favorites'),
      headers: await _headers,
    );
    
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((f) => f['listingId'] as String).toList();
    }
    return [];
  }

  Future<bool> addFavorite(String listingId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/favorites/$listingId'),
      headers: await _headers,
    );
    return res.statusCode == 200;
  }

  Future<bool> removeFavorite(String listingId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/favorites/$listingId'),
      headers: await _headers,
    );
    return res.statusCode == 200;
  }

  Future<bool> isFavorited(String listingId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/favorites/$listingId/check'),
      headers: await _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['isFavorited'] == true;
    }
    return false;
  }

  // ADVANCED SEARCH (POST with filters)
  Future<List<dynamic>> advancedSearch(Map<String, dynamic> filter) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/search'),
      headers: await _headers,
      body: jsonEncode(filter),
    );
    final data = jsonDecode(res.body);
    return data['results'] ?? [];
  }
}
