import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/category_data.dart';
import '../../providers/draft_listing_provider.dart';
import '../../theme/app_theme.dart';
import 'wizard_alt_kategori_screen.dart';
import 'wizard_adres_screen.dart';

/// Ekran 2: İşlem Tipi Seçimi
/// Seçilen kategoriye göre işlem tipleri listelenir
class WizardIslemTipiScreen extends StatelessWidget {
  const WizardIslemTipiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DraftListingProvider>().draft;
    final kategoriId = draft.kategoriId ?? 'konut';
    final islemler = IslemTipleri.kategoriIslemTipleri[kategoriId] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('İşlem Tipi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb Header
          _buildBreadcrumb(draft),

          // İşlem Tipleri
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: islemler.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final islem = islemler[index];
                return _IslemTipiTile(
                  label: islem['label']!,
                  icon: _getIslemIcon(islem['id']!),
                  onTap: () {
                    context.read<DraftListingProvider>().setIslemTipi(
                          islem['id']!,
                          islem['label']!,
                        );
                    // Alt kategori gerekli mi?
                    if (AltKategoriler.altKategoriGerekli(kategoriId)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WizardAltKategoriScreen(),
                        ),
                      );
                    } else {
                      // Alt kategori gerekmiyorsa direkt adrese git
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WizardAdresScreen(),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(DraftListing draft) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryNavy, AppTheme.primaryNavyLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.navigate_next_rounded, color: Colors.white54, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Kategoriler > Emlak > ${draft.kategoriLabel ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _getIslemIcon(String id) {
    switch (id) {
      case 'satilik': return Icons.sell_rounded;
      case 'kiralik': return Icons.key_rounded;
      case 'gunluk_kiralik': return Icons.today_rounded;
      case 'devren_satilik': return Icons.swap_horiz_rounded;
      case 'devren_kiralik': return Icons.repeat_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }
}

class _IslemTipiTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _IslemTipiTile({
    required this.label,
    required this.icon,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryNavy, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
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
