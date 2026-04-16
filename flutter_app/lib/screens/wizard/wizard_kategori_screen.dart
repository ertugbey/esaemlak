import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/category_data.dart';
import '../../providers/draft_listing_provider.dart';
import '../../theme/app_theme.dart';
import 'wizard_islem_tipi_screen.dart';

/// Ekran 1: Ana Kategori Seçimi
/// Kullanıcı 7 ana kategoriden birini seçer ve Ekran 2'ye yönlendirilir
class WizardKategoriScreen extends StatelessWidget {
  const WizardKategoriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Yeni wizard başlatırken draft'ı sıfırla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DraftListingProvider>().resetDraft();
    });

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('İlan Ver', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryNavy, AppTheme.primaryNavyLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori Seçin',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'İlanınızın ana kategorisini belirleyin',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Kategori Listesi
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: KategoriTanimlari.anaKategoriler.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final kat = KategoriTanimlari.anaKategoriler[index];
                return _KategoriTile(
                  id: kat['id'] as String,
                  label: kat['label'] as String,
                  icon: _getKategoriIcon(kat['id'] as String),
                  color: _getKategoriColor(index),
                  onTap: () {
                    context.read<DraftListingProvider>().setKategori(
                          kat['id'] as String,
                          kat['label'] as String,
                        );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WizardIslemTipiScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static IconData _getKategoriIcon(String id) {
    switch (id) {
      case 'konut': return Icons.home_rounded;
      case 'isyeri': return Icons.store_rounded;
      case 'arsa': return Icons.terrain_rounded;
      case 'konut_projeleri': return Icons.apartment_rounded;
      case 'bina': return Icons.business_rounded;
      case 'devre_mulk': return Icons.calendar_month_rounded;
      case 'turistik_tesis': return Icons.hotel_rounded;
      default: return Icons.category_rounded;
    }
  }

  static Color _getKategoriColor(int index) {
    final colors = [
      const Color(0xFF1A237E),
      const Color(0xFF00897B),
      const Color(0xFF4CAF50),
      const Color(0xFF3F51B5),
      const Color(0xFF795548),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
    ];
    return colors[index % colors.length];
  }
}

class _KategoriTile extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KategoriTile({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
