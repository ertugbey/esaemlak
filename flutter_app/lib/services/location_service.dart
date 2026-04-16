import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/turkiye_konumlari.dart';
import 'api_service.dart';

/// Konum servisi — API'den veya offline fallback'ten İl, İlçe, Semt, Mahalle verisi çeker
class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  String get _baseUrl => ApiService.baseUrl;

  // ─── İller ───
  Future<List<String>> getIller() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/locations/provinces'),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.cast<String>();
      }
    } catch (e) {
      debugPrint('LocationService: İller API hatası, offline fallback: $e');
    }
    // Offline fallback
    return TurkiyeKonumlari.iller;
  }

  // ─── İlçeler ───
  Future<List<String>> getIlceler(String il) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/locations/districts?cityName=$il'),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.cast<String>();
      }
    } catch (e) {
      debugPrint('LocationService: İlçeler API hatası, offline fallback: $e');
    }
    // Offline fallback
    return TurkiyeKonumlari.getIlceler(il);
  }

  // ─── Semtler ───
  Future<List<String>> getSemtler(String il, String ilce) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/locations/neighborhoods?cityName=$il&districtName=$ilce'),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<dynamic> semtler = data['semtler'] ?? [];
        return semtler.cast<String>();
      }
    } catch (e) {
      debugPrint('LocationService: Semtler API hatası: $e');
    }
    return [];
  }

  // ─── Mahalleler ───
  Future<List<String>> getMahalleler(String il, String ilce, String semt) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/locations/neighborhoods?cityName=$il&districtName=$ilce&semt=$semt'),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<dynamic> mahalleler = data['mahalleler'] ?? [];
        return mahalleler.cast<String>();
      }
    } catch (e) {
      debugPrint('LocationService: Mahalleler API hatası: $e');
    }
    return [];
  }
}
