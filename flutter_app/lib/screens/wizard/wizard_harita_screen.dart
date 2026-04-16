import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/draft_listing_provider.dart';
import '../../theme/app_theme.dart';
import 'wizard_detay_screen.dart';

/// Harita Ekranı — OpenStreetMap üzerinde pin bırakma
/// Kullanıcı konum pinini sürükleyerek binanın tam lokasyonunu işaretler
class WizardHaritaScreen extends StatefulWidget {
  const WizardHaritaScreen({super.key});

  @override
  State<WizardHaritaScreen> createState() => _WizardHaritaScreenState();
}

class _WizardHaritaScreenState extends State<WizardHaritaScreen> {
  late LatLng _pinPosition;
  final MapController _mapController = MapController();

  // Türkiye büyük şehir merkezleri (yaklaşık)
  static const Map<String, LatLng> _sehirMerkezleri = {
    'İstanbul': LatLng(41.0082, 28.9784),
    'Ankara': LatLng(39.9334, 32.8597),
    'İzmir': LatLng(38.4237, 27.1428),
    'Bursa': LatLng(40.1885, 29.0610),
    'Antalya': LatLng(36.8969, 30.7133),
    'Adana': LatLng(37.0000, 35.3213),
    'Konya': LatLng(37.8746, 32.4932),
    'Gaziantep': LatLng(37.0662, 37.3833),
    'Mersin': LatLng(36.8121, 34.6415),
    'Diyarbakır': LatLng(37.9144, 40.2306),
    'Kayseri': LatLng(38.7312, 35.4787),
    'Eskişehir': LatLng(39.7767, 30.5206),
    'Samsun': LatLng(41.2867, 36.33),
    'Trabzon': LatLng(41.0027, 39.7168),
    'Denizli': LatLng(37.7765, 29.0864),
    'Malatya': LatLng(38.3552, 38.3095),
    'Erzurum': LatLng(39.9043, 41.2679),
    'Van': LatLng(38.4891, 43.3800),
    'Kocaeli': LatLng(40.7654, 29.9408),
    'Sakarya': LatLng(40.6940, 30.4358),
    'Tekirdağ': LatLng(41.0027, 27.5127),
    'Muğla': LatLng(37.2153, 28.3636),
    'Manisa': LatLng(38.6191, 27.4289),
    'Aydın': LatLng(37.8444, 27.8458),
    'Balıkesir': LatLng(39.6484, 27.8826),
    'Hatay': LatLng(36.4018, 36.3498),
    'Kahramanmaraş': LatLng(37.5858, 36.9371),
    'Şanlıurfa': LatLng(37.1591, 38.7969),
    'Mardin': LatLng(37.3212, 40.7245),
  };

  @override
  void initState() {
    super.initState();
    final draft = context.read<DraftListingProvider>().draft;

    // Eğer daha önce koordinat kaydedildiyse onu kullan
    if (draft.latitude != null && draft.longitude != null) {
      _pinPosition = LatLng(draft.latitude!, draft.longitude!);
    } else {
      // Seçilen şehrin merkezini kullan, yoksa Türkiye merkezi
      _pinPosition = _sehirMerkezleri[draft.il] ?? const LatLng(39.9334, 32.8597);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Haritada İşaretle', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Harita
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pinPosition,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() => _pinPosition = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.esaemlak.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pinPosition,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Üst bilgi kartı
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: AppTheme.primaryNavy, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Haritaya dokunarak binanızın tam konumunu işaretleyin',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Koordinat bilgisi & Onayla butonu
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Koordinat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.my_location_rounded, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '${_pinPosition.latitude.toStringAsFixed(6)}, ${_pinPosition.longitude.toStringAsFixed(6)}',
                        style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Onayla butonu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<DraftListingProvider>().setKoordinat(
                              _pinPosition.latitude,
                              _pinPosition.longitude,
                            );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WizardDetayScreen()),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Konumu Onayla ve Devam Et'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
