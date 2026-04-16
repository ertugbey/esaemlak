import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/listing_enums.dart';
import '../../data/category_data.dart';
import '../../providers/draft_listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Ekran 5: İlan Detayları + Medya + Yayınla
/// Wizard'ın son adımı — önceki ekranlardan gelen verilerle birleştirilir
class WizardDetayScreen extends StatefulWidget {
  const WizardDetayScreen({super.key});

  @override
  State<WizardDetayScreen> createState() => _WizardDetayScreenState();
}

class _WizardDetayScreenState extends State<WizardDetayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  // Controllers
  final _baslik = TextEditingController();
  final _aciklama = TextEditingController();
  final _fiyat = TextEditingController();
  final _brutM2 = TextEditingController();
  final _netM2 = TextEditingController();
  final _banyo = TextEditingController();
  final _kat = TextEditingController();
  final _katSayisi = TextEditingController();

  // İş Yeri
  final _girisYuksekligi = TextEditingController();

  // Arsa
  final _adaParsel = TextEditingController();

  @override
  void dispose() {
    _baslik.dispose();
    _aciklama.dispose();
    _fiyat.dispose();
    _brutM2.dispose();
    _netM2.dispose();
    _banyo.dispose();
    _kat.dispose();
    _katSayisi.dispose();
    _girisYuksekligi.dispose();
    _adaParsel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DraftListingProvider>().draft;
    final kategoriId = draft.kategoriId ?? 'konut';

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text('İlan Detayları', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seçim Özeti
              _buildSelectionSummary(draft),
              const SizedBox(height: 20),

              // ─── TEMEL BİLGİLER ───
              _sectionTitle('Temel Bilgiler'),
              const SizedBox(height: 8),
              _textField(_baslik, 'İlan Başlığı', Icons.title, required: true, maxLength: 100),
              const SizedBox(height: 12),
              _textField(_aciklama, 'Açıklama', Icons.description, maxLines: 4),
              const SizedBox(height: 12),
              _textField(_fiyat, 'Fiyat (TL)', Icons.monetization_on, keyboardType: TextInputType.number, required: true),
              const SizedBox(height: 12),

              // Kimden
              _sectionTitle('Kimden'),
              const SizedBox(height: 8),
              _dropdown(
                value: draft.kimden,
                hint: 'Kimden seçin',
                items: Kimden.values.map((k) => k.label).toList(),
                onChanged: (val) => setState(() => draft.kimden = val),
              ),
              const SizedBox(height: 16),

              // ─── METREKARE ───
              if (kategoriId != 'devre_mulk' && kategoriId != 'turistik_tesis') ...[
                _sectionTitle('Metrekare'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _textField(_brutM2, 'Brüt m²', Icons.square_foot, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _textField(_netM2, 'Net m²', Icons.square_foot, keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 16),
              ],

              // ─── ODA SAYISI & BİNA YAŞI (Konut, Bina) ───
              if (kategoriId == 'konut' || kategoriId == 'konut_projeleri' || kategoriId == 'bina') ...[
                _sectionTitle('Oda Sayısı'),
                const SizedBox(height: 8),
                _dropdown(
                  value: draft.odaSayisi,
                  hint: 'Oda sayısı seçiniz',
                  items: ['Stüdyo (1+0)', '1+1', '2+1', '3+1', '3+2', '4+1', '4+2', '5+1', '5+2', '6+'],
                  onChanged: (val) => setState(() => draft.odaSayisi = val),
                ),
                const SizedBox(height: 16),

                _sectionTitle('Bina Yaşı'),
                const SizedBox(height: 8),
                _dropdown(
                  value: draft.binaYasi,
                  hint: 'Bina yaşı seçiniz',
                  items: BinaYasi.values.map((b) => b.label).toList(),
                  onChanged: (val) => setState(() => draft.binaYasi = val),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(child: _textField(_kat, 'Bulunduğu Kat', Icons.layers, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _textField(_katSayisi, 'Kat Sayısı', Icons.apartment, keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                _textField(_banyo, 'Banyo Sayısı', Icons.bathtub, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
              ],

              // ─── ISITMA ───
              if (kategoriId != 'arsa') ...[
                _sectionTitle('Isıtma Tipi'),
                const SizedBox(height: 8),
                _dropdown(
                  value: draft.isitmaTipi,
                  hint: 'Isıtma seçin',
                  items: IsitmaTipi.labels,
                  onChanged: (val) => setState(() => draft.isitmaTipi = val),
                ),
                const SizedBox(height: 16),
              ],

              // ─── TAPU ───
              _sectionTitle('Tapu Durumu'),
              const SizedBox(height: 8),
              _dropdown(
                value: draft.tapuDurumu,
                hint: 'Tapu durumu seçin',
                items: TapuDurumu.labels,
                onChanged: (val) => setState(() => draft.tapuDurumu = val),
              ),
              const SizedBox(height: 16),

              // ─── ÖZELLİKLER ───
              if (kategoriId != 'arsa') ...[
                _sectionTitle('Özellikler'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  _featureChip('Eşyalı', draft.esyali, (v) => setState(() => draft.esyali = v)),
                  _featureChip('Balkon', draft.balkon, (v) => setState(() => draft.balkon = v)),
                  _featureChip('Asansör', draft.asansor, (v) => setState(() => draft.asansor = v)),
                  _featureChip('Otopark', draft.otopark, (v) => setState(() => draft.otopark = v)),
                  _featureChip('Havuz', draft.havuz, (v) => setState(() => draft.havuz = v)),
                  _featureChip('Güvenlik', draft.guvenlik, (v) => setState(() => draft.guvenlik = v)),
                  _featureChip('Krediye Uygun', draft.krediyeUygun, (v) => setState(() => draft.krediyeUygun = v)),
                  _featureChip('Takaslı', draft.takasli, (v) => setState(() => draft.takasli = v)),
                ]),
                const SizedBox(height: 16),
              ],

              // ─── İŞ YERİ ÖZEL ───
              if (kategoriId == 'isyeri') ...[
                _sectionTitle('İş Yeri Özellikleri'),
                const SizedBox(height: 8),
                _textField(_girisYuksekligi, 'Giriş Yüksekliği (m)', Icons.height, keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  _featureChip('Zemin Etüdü', draft.zeminEtudu, (v) => setState(() => draft.zeminEtudu = v)),
                  _featureChip('Devren', draft.devren, (v) => setState(() => draft.devren = v)),
                  _featureChip('Kiracılı', draft.kiracili, (v) => setState(() => draft.kiracili = v)),
                ]),
                const SizedBox(height: 16),
              ],

              // ─── ARSA ÖZEL ───
              if (kategoriId == 'arsa') ...[
                _sectionTitle('Arsa Özellikleri'),
                const SizedBox(height: 8),
                _textField(_adaParsel, 'Ada / Parsel', Icons.map, maxLength: 20),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  _featureChip('Kat Karşılığı', draft.katKarsiligi, (v) => setState(() => draft.katKarsiligi = v)),
                ]),
                const SizedBox(height: 16),
              ],

              // ─── PROMOSYON ───
              _sectionTitle('Promosyon'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                _featureChip('Acil Satılık', draft.acilSatilik, (v) => setState(() => draft.acilSatilik = v)),
                _featureChip('Fiyat Düştü', draft.fiyatiDustu, (v) => setState(() => draft.fiyatiDustu = v)),
              ]),
              const SizedBox(height: 20),

              // ─── FOTOĞRAFLAR ───
              _sectionTitle('Fotoğraflar'),
              const SizedBox(height: 8),
              _buildPhotoSection(draft),
              const SizedBox(height: 24),

              // ─── YAYINLA ───
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _submitListing(draft),
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.publish_rounded),
                  label: Text(_isSubmitting ? 'Yayınlanıyor...' : 'İlanı Yayınla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldAccent,
                    foregroundColor: AppTheme.primaryNavyDark,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Seçim Özeti kartı ───
  Widget _buildSelectionSummary(DraftListing draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryNavy.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18),
            const SizedBox(width: 8),
            Text('Seçimleriniz', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          const Divider(height: 16),
          _summaryRow('Kategori', draft.kategoriLabel ?? '-'),
          _summaryRow('İşlem', draft.islemTipiLabel ?? '-'),
          if (draft.altKategori != null) _summaryRow('Tür', draft.altKategori!),
          _summaryRow('Konum', draft.adresOzet.isNotEmpty ? draft.adresOzet : '-'),
          if (draft.latitude != null)
            _summaryRow('Koordinat', '${draft.latitude!.toStringAsFixed(4)}, ${draft.longitude!.toStringAsFixed(4)}'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // ─── UI Helpers ───
  Widget _sectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
  }

  Widget _textField(TextEditingController controller, String label, IconData icon,
      {bool required = false, int maxLines = 1, int? maxLength, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required ? (v) => v == null || v.isEmpty ? '$label gerekli' : null : null,
    );
  }


  Widget _dropdown({String? value, required String hint, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightDivider),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _featureChip(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightDivider),
        color: Colors.white,
      ),
      child: SwitchListTile(
        title: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: (v) => onChanged(v),
        activeColor: AppTheme.primaryNavy,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Fotoğraf bölümü ───
  Widget _buildPhotoSection(DraftListing draft) {
    return Column(
      children: [
        // Mevcut fotoğraflar
        if (draft.images.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: draft.images.length,
              itemBuilder: (_, i) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(draft.images[i]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => setState(() => draft.images.removeAt(i)),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Fotoğraf ekle butonu
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_a_photo_rounded),
          label: Text('Fotoğraf Ekle (${draft.images.length}/20)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryNavy,
            side: BorderSide(color: AppTheme.primaryNavy.withOpacity(0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final draft = context.read<DraftListingProvider>().draft;
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        for (var img in images) {
          if (draft.images.length < 20) {
            draft.images.add(File(img.path));
          }
        }
      });
    }
  }

  // ─── Submit ───
  Future<void> _submitListing(DraftListing draft) async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yapın')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Form verilerini draft'a aktar
      draft.baslik = _baslik.text.trim();
      draft.aciklama = _aciklama.text.trim();
      draft.fiyat = double.tryParse(_fiyat.text.trim());
      draft.brutMetrekare = int.tryParse(_brutM2.text.trim());
      draft.netMetrekare = int.tryParse(_netM2.text.trim());
      draft.banyoSayisi = int.tryParse(_banyo.text.trim());
      draft.bulunduguKat = int.tryParse(_kat.text.trim());
      draft.katSayisi = int.tryParse(_katSayisi.text.trim());
      draft.girisYuksekligi = double.tryParse(_girisYuksekligi.text.trim());
      draft.adaParsel = _adaParsel.text.trim().isNotEmpty ? _adaParsel.text.trim() : null;

      // Fotoğraf yükleme
      if (draft.images.isNotEmpty) {
        final urls = await _api.uploadPhotos(draft.images.map((f) => f.path).toList());
        draft.uploadedImageUrls = urls;
      }

      // İlan oluştur
      final result = await _api.createListing(draft.toJson());

      if (mounted) {
        // Draft'ı sıfırla
        context.read<DraftListingProvider>().resetDraft();

        // Wizard'daki tüm ekranları kapat ve ana sayfaya dön
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 İlan başarıyla yayınlandı!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
