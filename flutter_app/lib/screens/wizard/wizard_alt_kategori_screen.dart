import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/category_data.dart';
import '../../providers/draft_listing_provider.dart';
import '../../theme/app_theme.dart';
import 'wizard_adres_screen.dart';

/// Ekran 3: Alt Kategori Seçimi
/// Seçilen kategori + işlem tipine göre alt kategoriler listelenir
class WizardAltKategoriScreen extends StatelessWidget {
  const WizardAltKategoriScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DraftListingProvider>().draft;
    final kategoriId = draft.kategoriId ?? 'konut';
    final islemTipiId = draft.islemTipiId ?? 'satilik';
    final altKategoriler = AltKategoriler.getAltKategoriler(kategoriId, islemTipiId);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('Alt Kategori', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _buildBreadcrumb(draft),

          // Alt Kategoriler
          Expanded(
            child: altKategoriler.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: altKategoriler.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final altKat = altKategoriler[index];
                      return _AltKategoriTile(
                        label: altKat,
                        onTap: () {
                          context.read<DraftListingProvider>().setAltKategori(altKat);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WizardAdresScreen(),
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
              'Kategoriler > Emlak > ${draft.kategoriLabel ?? ''} > ${draft.islemTipiLabel ?? ''}',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Bu kombinasyon için alt kategori bulunamadı',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _AltKategoriTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AltKategoriTile({
    required this.label,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.home_work_outlined, color: AppTheme.accentTeal, size: 20),
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
