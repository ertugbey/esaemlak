import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/draft_listing_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import 'wizard_harita_screen.dart';
import 'wizard_detay_screen.dart';

/// Ekran 4: Kaskad Adres Seçimi
/// İl → İlçe → Semt → Mahalle → Haritada İşaretle
class WizardAdresScreen extends StatefulWidget {
  const WizardAdresScreen({super.key});

  @override
  State<WizardAdresScreen> createState() => _WizardAdresScreenState();
}

class _WizardAdresScreenState extends State<WizardAdresScreen> {
  final LocationService _locationService = LocationService();

  List<String> _iller = [];
  List<String> _ilceler = [];
  List<String> _semtler = [];
  List<String> _mahalleler = [];

  bool _illerLoading = true;
  bool _ilcelerLoading = false;
  bool _semtlerLoading = false;
  bool _mahallelerLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIller();
  }

  Future<void> _loadIller() async {
    setState(() => _illerLoading = true);
    final iller = await _locationService.getIller();
    if (mounted) {
      setState(() {
        _iller = iller;
        _illerLoading = false;
      });
    }
  }

  Future<void> _loadIlceler(String il) async {
    setState(() => _ilcelerLoading = true);
    final ilceler = await _locationService.getIlceler(il);
    if (mounted) {
      setState(() {
        _ilceler = ilceler;
        _ilcelerLoading = false;
      });
    }
  }

  Future<void> _loadSemtler(String il, String ilce) async {
    setState(() => _semtlerLoading = true);
    final semtler = await _locationService.getSemtler(il, ilce);
    if (mounted) {
      setState(() {
        _semtler = semtler;
        _semtlerLoading = false;
      });
    }
  }

  Future<void> _loadMahalleler(String il, String ilce, String semt) async {
    setState(() => _mahallelerLoading = true);
    final mahalleler = await _locationService.getMahalleler(il, ilce, semt);
    if (mounted) {
      setState(() {
        _mahalleler = mahalleler;
        _mahallelerLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DraftListingProvider>().draft;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('Adres Bilgileri', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Breadcrumb
          _buildBreadcrumb(draft),

          // Adres Seçim Alanı
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ülke (sabit)
                  _buildFixedField('Ülke', 'Türkiye', Icons.flag_rounded),
                  const SizedBox(height: 12),

                  // İl
                  _buildSectionLabel('İl (Şehir)'),
                  const SizedBox(height: 6),
                  _illerLoading
                      ? _buildShimmer()
                      : _buildSearchableDropdown(
                          value: draft.il,
                          hint: 'İl seçin',
                          items: _iller,
                          onChanged: (val) {
                            if (val != null) {
                              context.read<DraftListingProvider>().setIl(val);
                              setState(() {
                                _ilceler = [];
                                _semtler = [];
                                _mahalleler = [];
                                _ilcelerLoading = true;
                                _semtlerLoading = false;
                                _mahallelerLoading = false;
                              });
                              _loadIlceler(val);
                            }
                          },
                        ),
                  const SizedBox(height: 16),

                  // İlçe
                  if (draft.il != null) ...[
                    _buildSectionLabel('İlçe'),
                    const SizedBox(height: 6),
                    _ilcelerLoading
                        ? _buildShimmer()
                        : _buildSearchableDropdown(
                            value: draft.ilce,
                            hint: 'İlçe seçin',
                            items: _ilceler,
                            onChanged: (val) {
                              if (val != null) {
                                context.read<DraftListingProvider>().setIlce(val);
                                setState(() {
                                  _semtler = [];
                                  _mahalleler = [];
                                  _semtlerLoading = true;
                                  _mahallelerLoading = false;
                                });
                                _loadSemtler(draft.il!, val);
                              }
                            },
                          ),
                    const SizedBox(height: 16),
                  ],

                  // Semt
                  if (draft.ilce != null) ...[
                    _buildSectionLabel('Semt / Bucak'),
                    const SizedBox(height: 6),
                    _semtlerLoading
                        ? _buildShimmer()
                        : _semtler.isEmpty
                            ? _buildInfoBox('Semt verisi bulunamadı. Bu alanı atlayabilirsiniz.')
                            : _buildSearchableDropdown(
                                value: draft.semt,
                                hint: 'Semt seçin',
                                items: _semtler,
                                onChanged: (val) {
                                  if (val != null) {
                                    context.read<DraftListingProvider>().setSemt(val);
                                    setState(() {
                                      _mahalleler = [];
                                      _mahallelerLoading = true;
                                    });
                                    _loadMahalleler(draft.il!, draft.ilce!, val);
                                  }
                                },
                              ),
                    const SizedBox(height: 16),
                  ],

                  // Mahalle
                  if (draft.semt != null && _semtler.isNotEmpty) ...[
                    _buildSectionLabel('Mahalle'),
                    const SizedBox(height: 6),
                    _mahallelerLoading
                        ? _buildShimmer()
                        : _mahalleler.isEmpty
                            ? _buildInfoBox('Mahalle verisi bulunamadı.')
                            : _buildSearchableDropdown(
                                value: draft.mahalle,
                                hint: 'Mahalle seçin',
                                items: _mahalleler,
                                onChanged: (val) {
                                  if (val != null) {
                                    context.read<DraftListingProvider>().setMahalle(val);
                                  }
                                },
                              ),
                    const SizedBox(height: 16),
                  ],

                  // Site İçerisinde
                  if (draft.ilce != null) ...[
                    const Divider(height: 32),
                    _buildSiteToggle(draft),
                  ],

                  const SizedBox(height: 24),

                  // Haritada İşaretle
                  _buildHaritaButonu(draft),

                  const SizedBox(height: 12),

                  // Devam Et (haritayı atla)
                  _buildDevamButonu(draft),

                  const SizedBox(height: 32),
                ],
              ),
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
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.navigate_next_rounded, color: Colors.white54, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              draft.breadcrumb,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightDivider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryNavy, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildSearchableDropdown({
    String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightDivider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value != null && items.contains(value) ? value : null,
          hint: Text(hint, style: TextStyle(color: AppTheme.textSecondary)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber[800], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: Colors.amber[900])),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteToggle(DraftListing draft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightDivider),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Site İçerisinde', style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text('İlan bir site/toplu konut içerisinde mi?',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        value: draft.siteIcerisinde,
        activeColor: AppTheme.primaryNavy,
        onChanged: (val) {
          context.read<DraftListingProvider>().setSiteIcerisinde(val);
        },
      ),
    );
  }

  Widget _buildHaritaButonu(DraftListing draft) {
    final adresSecildi = draft.ilce != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: adresSecildi
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WizardHaritaScreen()),
                );
              }
            : null,
        icon: const Icon(Icons.map_rounded),
        label: const Text('Haritada İşaretle'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryNavy,
          side: BorderSide(
            color: adresSecildi ? AppTheme.primaryNavy : Colors.grey[300]!,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDevamButonu(DraftListing draft) {
    final adresSecildi = draft.il != null && draft.ilce != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: adresSecildi
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WizardDetayScreen()),
                );
              }
            : null,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Devam Et'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.goldAccent,
          foregroundColor: AppTheme.primaryNavyDark,
          disabledBackgroundColor: Colors.grey[200],
          disabledForegroundColor: Colors.grey[500],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }
}
