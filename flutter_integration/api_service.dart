// Flutter API Service Example for Emlaktan
// Copy this to your Flutter project: lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change to your server URL for production
  static const String baseUrl = 'http://localhost:5000';
  
  String? _token;

  // Get stored token
  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token;
  }

  // Save token
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Headers with auth
  Future<Map<String, String>> get headers async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  // ================= AUTH =================
  
  Future<Map<String, dynamic>> register({
    required String ad,
    required String soyad,
    required String email,
    required String telefon,
    required String password,
    String rol = 'kullanici',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ad': ad,
        'soyad': soyad,
        'email': email,
        'telefon': telefon,
        'password': password,
        'rol': rol,
      }),
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveToken(data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveToken(data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: await headers,
    );
    return jsonDecode(response.body);
  }

  // ================= LISTINGS =================

  Future<Map<String, dynamic>> getListing(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/listings/$id'),
      headers: await headers,
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> searchListings({
    String? query,
    String? il,
    String? emlakTipi,
    double? minFiyat,
    double? maxFiyat,
    int skip = 0,
    int limit = 20,
  }) async {
    final params = <String, String>{};
    if (query != null) params['q'] = query;
    if (il != null) params['il'] = il;
    if (emlakTipi != null) params['emlakTipi'] = emlakTipi;
    if (minFiyat != null) params['minFiyat'] = minFiyat.toString();
    if (maxFiyat != null) params['maxFiyat'] = maxFiyat.toString();
    params['skip'] = skip.toString();
    params['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/api/search').replace(queryParameters: params);
    final response = await http.get(uri, headers: await headers);
    final data = jsonDecode(response.body);
    return data['results'] ?? [];
  }

  Future<Map<String, dynamic>> createListing({
    required String baslik,
    required String aciklama,
    required String emlakTipi,
    required String islemTipi,
    required double fiyat,
    required String il,
    required String ilce,
    double? metrekare,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/listings'),
      headers: await headers,
      body: jsonEncode({
        'baslik': baslik,
        'aciklama': aciklama,
        'emlakTipi': emlakTipi,
        'islemTipi': islemTipi,
        'fiyat': fiyat,
        'il': il,
        'ilce': ilce,
        'metrekare': metrekare,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return jsonDecode(response.body);
  }

  // ================= PAYMENTS =================

  Future<Map<String, dynamic>> createPayment({
    required double amount,
    required String paymentType, // 'premium' or 'featured_listing'
    String? listingId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/payments'),
      headers: await headers,
      body: jsonEncode({
        'amount': amount,
        'paymentType': paymentType,
        'listingId': listingId,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>?> getSubscription() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/payments/subscription'),
      headers: await headers,
    );
    if (response.statusCode == 404) return null;
    return jsonDecode(response.body);
  }
}

// Usage example:
// final api = ApiService();
// await api.login('user@example.com', 'password123');
// final listings = await api.searchListings(il: 'Istanbul', emlakTipi: 'ev');
