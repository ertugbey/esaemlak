import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/listing_enums.dart';
import '../data/category_data.dart';
import '../theme/app_theme.dart';

/// Advanced filtering screen with dynamic category-based filter visibility
class FilterScreen extends StatefulWidget {
  final SearchFilter? initialFilter;
  final String? initialKategori;

  const FilterScreen({
    super.key,
    this.initialFilter,
    this.initialKategori,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late SearchFilter _filter;
  String _selectedKategori = 'konut';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? SearchFilter();
    _selectedKategori = _filter.kategori ?? widget.initialKategori ?? 'konut';
    _filter.kategori = _selectedKategori;
  }

  /// Belirli bir filtrenin seçilen kategoride görünüp görünmeyeceğini kontrol eder
  bool _filtreGorunurMu(String filtreAdi) {
    return FiltreProfilleri.filtreGorunurMu(_selectedKategori, filtreAdi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Gelişmiş Filtreler'),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Sıfırla', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== SIRALAMA ====================
            _buildSection(
              title: 'Sıralama',
              child: _buildDropdown(
                value: _filter.siralama,
                hint: 'Gelişmiş Sıralama',
                items: SiralamaSecenekleri.secenekler.map((s) => s['id']!).toList(),
                displayItems: SiralamaSecenekleri.secenekler.map((s) => s['label']!).toList(),
                onChanged: (v) => setState(() => _filter.siralama = v),
              ),
            ),

            // ==================== İŞLEM TİPİ ====================
            _buildSection(
              title: 'İşlem Tipi',
              child: _buildIslemTipiFilter(),
            ),

            // ==================== KATEGORİ ====================
            _buildSection(
              title: 'Kategori',
              child: _buildKategoriFilter(),
            ),

            // ==================== ALT KATEGORİ ====================
            if (AltKategoriler.altKategoriGerekli(_selectedKategori) && _filter.islemTipi != null)
              _buildSection(
                title: 'Alt Kategori',
                child: _buildAltKategoriFilter(),
              ),

            // ==================== KONUM ====================
            _buildSection(
              title: 'Konum',
              child: _buildKonumFilter(),
            ),

            // ==================== FİYAT ====================
            if (_filtreGorunurMu('fiyat'))
              _buildSection(
                title: 'Fiyat Aralığı',
                child: _buildFiyatFilter(),
              ),

            // ==================== METREKARE ====================
            if (_filtreGorunurMu('brutMetrekare'))
              _buildSection(
                title: 'Metrekare (m²)',
                child: _buildMetrekareFilter(),
              ),

            // ==================== ODA SAYISI ====================
            if (_filtreGorunurMu('odaSayisi'))
              _buildSection(
                title: 'Oda Sayısı',
                child: _buildOdaSayisiFilter(),
              ),

            // ==================== BİNA YAŞI ====================
            if (_filtreGorunurMu('binaYasi'))
              _buildSection(
                title: 'Bina Yaşı',
                child: _buildBinaYasiFilter(),
              ),

            // ==================== BULUNDUĞU KAT ====================
            if (_filtreGorunurMu('bulunduguKat'))
              _buildSection(
                title: 'Bulunduğu Kat',
                child: _buildDropdown(
                  value: _filter.bulunduguKatStr,
                  hint: 'Kat seçin',
                  items: BulunduguKat.labels,
                  onChanged: (v) => setState(() => _filter.bulunduguKatStr = v),
                ),
              ),

            // ==================== BANYO SAYISI ====================
            if (_filtreGorunurMu('banyoSayisi'))
              _buildSection(
                title: 'Banyo Sayısı',
                child: _buildMinMaxRow(
                  minValue: _filter.minBanyoSayisi?.toString(),
                  maxValue: _filter.maxBanyoSayisi?.toString(),
                  items: List.generate(6, (i) => '${i + 1}'),
                  onMinChanged: (v) => setState(() => _filter.minBanyoSayisi = v != null ? int.tryParse(v) : null),
                  onMaxChanged: (v) => setState(() => _filter.maxBanyoSayisi = v != null ? int.tryParse(v) : null),
                ),
              ),

            // ==================== KAT SAYISI ====================
            if (_filtreGorunurMu('katSayisi'))
              _buildSection(
                title: 'Kat Sayısı',
                child: _buildMinMaxRow(
                  minValue: _filter.minKatSayisi?.toString(),
                  maxValue: _filter.maxKatSayisi?.toString(),
                  items: List.generate(30, (i) => '${i + 1}'),
                  onMinChanged: (v) => setState(() => _filter.minKatSayisi = v != null ? int.tryParse(v) : null),
                  onMaxChanged: (v) => setState(() => _filter.maxKatSayisi = v != null ? int.tryParse(v) : null),
                ),
              ),

            // ==================== MUTFAK TİPİ ====================
            if (_filtreGorunurMu('mutfakTipi'))
              _buildSection(
                title: 'Mutfak',
                child: _buildDropdown(
                  value: _filter.mutfakTipi,
                  hint: 'Mutfak tipi seçin',
                  items: MutfakTipi.labels,
                  onChanged: (v) => setState(() => _filter.mutfakTipi = v),
                ),
              ),

            // ==================== OTOPARK TİPİ ====================
            if (_filtreGorunurMu('otoparkTipi'))
              _buildSection(
                title: 'Otopark',
                child: _buildDropdown(
                  value: _filter.otoparkTipi,
                  hint: 'Otopark tipi seçin',
                  items: OtoparkTipi.labels,
                  onChanged: (v) => setState(() => _filter.otoparkTipi = v),
                ),
              ),

            // ==================== KONUT TİPİ ====================
            if (_filtreGorunurMu('konutTipi'))
              _buildSection(
                title: 'Konut Tipi',
                child: _buildDropdown(
                  value: _filter.konutTipi,
                  hint: 'Konut tipi seçin',
                  items: KonutTipi.labels,
                  onChanged: (v) => setState(() => _filter.konutTipi = v),
                ),
              ),

            // ==================== KULLANIM DURUMU ====================
            if (_filtreGorunurMu('kullanimDurumu'))
              _buildSection(
                title: 'Kullanım Durumu',
                child: _buildDropdown(
                  value: _filter.kullanimDurumu,
                  hint: 'Kullanım durumu seçin',
                  items: KullanimDurumu.labels,
                  onChanged: (v) => setState(() => _filter.kullanimDurumu = v),
                ),
              ),

            // ==================== ISITMA TİPİ ====================
            if (_filtreGorunurMu('isitmaTipi'))
              _buildSection(
                title: 'Isıtma Tipi',
                child: _buildDropdown(
                  value: _filter.isitmaTipi,
                  hint: 'Isıtma tipi seçin',
                  items: IsitmaTipi.labels,
                  onChanged: (v) => setState(() => _filter.isitmaTipi = v),
                ),
              ),

            // ==================== TAPU DURUMU ====================
            if (_filtreGorunurMu('tapuDurumu'))
              _buildSection(
                title: 'Tapu Durumu',
                child: _buildDropdown(
                  value: _filter.kategori != null ? null : null,
                  hint: 'Tapu durumu seçin',
                  items: TapuDurumu.labels,
                  onChanged: (v) => setState(() {}),
                ),
              ),

            // ==================== KİMDEN ====================
            if (_filtreGorunurMu('kimden'))
              _buildSection(
                title: 'Kimden',
                child: _buildKimdenFilter(),
              ),

            // ==================== EŞYALI / BALKON / ASANSÖR ====================
            if (_filtreGorunurMu('esyali') || _filtreGorunurMu('balkon') || _filtreGorunurMu('asansor'))
              _buildSection(
                title: 'Temel Özellikler',
                child: _buildFeaturesFilter(),
              ),

            // ==================== SİTE İÇERİSİNDE / KREDİYE UYGUN / TAKASLI ====================
            if (_filtreGorunurMu('siteIcerisinde') || _filtreGorunurMu('krediyeUygun') || _filtreGorunurMu('takasli'))
              _buildSection(
                title: 'Ek Özellikler',
                child: _buildMultiSelectPicker(
                  hint: 'Ek özellik seçiniz',
                  options: [
                    if (_filtreGorunurMu('siteIcerisinde')) 'Site İçerisinde',
                    if (_filtreGorunurMu('krediyeUygun')) 'Krediye Uygun',
                    if (_filtreGorunurMu('takasli')) 'Takaslı',
                  ],
                  selected: {
                    if (_filter.siteIcerisinde == true) 'Site İçerisinde',
                    if (_filter.krediyeUygun == true) 'Krediye Uygun',
                    if (_filter.takasli == true) 'Takaslı',
                  },
                  onChanged: (set) {
                    setState(() {
                      _filter.siteIcerisinde = set.contains('Site İçerisinde') ? true : null;
                      _filter.krediyeUygun = set.contains('Krediye Uygun') ? true : null;
                      _filter.takasli = set.contains('Takaslı') ? true : null;
                    });
                  },
                ),
              ),

            // ==================== İŞ YERİ ÖZEL: GİRİŞ YÜKSEKLİĞİ ====================
            if (_filtreGorunurMu('girisYuksekligi'))
              _buildSection(
                title: 'Giriş Yüksekliği (m)',
                child: _buildMinMaxRow(
                  minValue: _filter.girisYuksekligiMin?.toString(),
                  maxValue: _filter.girisYuksekligiMax?.toString(),
                  items: ['2', '3', '4', '5', '6', '7', '8', '9', '10'],
                  onMinChanged: (v) => setState(() => _filter.girisYuksekligiMin = v != null ? double.tryParse(v) : null),
                  onMaxChanged: (v) => setState(() => _filter.girisYuksekligiMax = v != null ? double.tryParse(v) : null),
                ),
              ),

            // ==================== İŞ YERİ ÖZEL: ZEMİN ETÜDÜ & YAPININ DURUMU ====================
            if (_filtreGorunurMu('zeminEtudu') || _filtreGorunurMu('yapininDurumu'))
              _buildSection(
                title: 'Yapı Bilgileri',
                child: Column(
                  children: [
                    if (_filtreGorunurMu('zeminEtudu'))
                      _buildMultiSelectPicker(
                        hint: 'Zemin etüdü seçiniz',
                        options: const ['Zemin Etüdü Var'],
                        selected: const {},
                        onChanged: (set) => setState(() {}),
                      ),
                    if (_filtreGorunurMu('yapininDurumu'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildDropdown(
                          value: null,
                          hint: 'Yapının Durumu',
                          items: YapininDurumu.labels,
                          onChanged: (v) => setState(() {}),
                        ),
                      ),
                  ],
                ),
              ),

            // ==================== İLAN TARİHİ ====================
            if (_filtreGorunurMu('ilanTarihi'))
              _buildSection(
                title: 'İlan Tarihi',
                child: _buildDropdown(
                  value: _filter.ilanTarihi,
                  hint: 'İlan tarih aralığı',
                  items: IlanTarihi.labels,
                  onChanged: (v) => setState(() => _filter.ilanTarihi = v),
                ),
              ),

            // ==================== FOTOĞRAF/VİDEO ====================
            if (_filtreGorunurMu('fotoVideo'))
              _buildSection(
                title: 'Fotoğraf / Video',
                child: _buildMultiSelectPicker(
                  hint: 'Video filtresi seçiniz',
                  options: const ['Videolu İlanlar'],
                  selected: _filter.videoVar == true ? {'Videolu İlanlar'} : {},
                  onChanged: (set) => setState(() => _filter.videoVar = set.contains('Videolu İlanlar') ? true : null),
                ),
              ),

            // ==================== CEPHE ====================
            if (_filtreGorunurMu('cephe'))
              _buildSection(
                title: 'Cephe',
                child: _buildMultiSelectPicker(
                  hint: 'Cephe seçiniz',
                  options: Cephe.labels,
                  selected: _filter.cephe?.toSet() ?? {},
                  onChanged: (set) => setState(() => _filter.cephe = set.isEmpty ? null : set.toList()),
                ),
              ),

            // ==================== MANZARA ====================
            if (_filtreGorunurMu('manzara'))
              _buildSection(
                title: 'Manzara',
                child: _buildMultiSelectPicker(
                  hint: 'Manzara seçiniz',
                  options: Manzara.labels,
                  selected: _filter.manzara?.toSet() ?? {},
                  onChanged: (set) => setState(() => _filter.manzara = set.isEmpty ? null : set.toList()),
                ),
              ),

            // ==================== İÇ ÖZELLİKLER ====================
            if (_filtreGorunurMu('icOzellikler'))
              _buildSection(
                title: 'İç Özellikler',
                child: _buildMultiSelectPicker(
                  hint: 'İç özellik seçiniz',
                  options: IcOzellik.labels,
                  selected: _filter.icOzellikler?.toSet() ?? {},
                  onChanged: (set) => setState(() => _filter.icOzellikler = set.isEmpty ? null : set.toList()),
                ),
              ),

            // ==================== DIŞ ÖZELLİKLER ====================
            if (_filtreGorunurMu('disOzellikler'))
              _buildSection(
                title: 'Dış Özellikler',
                child: _buildMultiSelectPicker(
                  hint: 'Dış özellik seçiniz',
                  options: DisOzellik.labels,
                  selected: _filter.disOzellikler?.toSet() ?? {},
                  onChanged: (set) => setState(() => _filter.disOzellikler = set.isEmpty ? null : set.toList()),
                ),
              ),

            // ==================== MUHİT ====================
            if (_filtreGorunurMu('muhit'))
              _buildSection(
                title: 'Muhit',
                child: _buildMultiSelectPicker(
                  hint: 'Muhit seçiniz',
                  options: Muhit.labels,
                  selected: _filter.muhit?.toSet() ?? {},
                  onChanged: (set) => setState(() => _filter.muhit = set.isEmpty ? null : set.toList()),
                ),
              ),

            // ==================== ULAŞIM ====================
            if (_filtreGorunurMu('ulasim'))
              _buildSection(
                title: 'Ulaşım',
                child: _buildMultiSelectPicker(
                  hint: 'Ulaşım seçiniz',
                  options: Ulasim.labels,
                  selected: _filter.ulasim?.toSet() ?? {},
                  onChanged: (set) => setState(() => _filter.ulasim = set.isEmpty ? null : set.toList()),
                ),
              ),

            // ==================== ENGELLİYE UYGUNLUK ====================
            if (_filtreGorunurMu('engelliyeUygunluk'))
              _buildSection(
                title: 'Engelliye Uygunluk',
                child: _buildMultiSelectPicker(
                  hint: 'Engelliye uygunluk seçiniz',
                  options: EngelliyeUygunluk.labels,
                  selected: _filter.engelliyeUygunluk?.toSet() ?? {},
                  onChanged: (set) => setState(() => _filter.engelliyeUygunluk = set.isEmpty ? null : set.toList()),
                ),
              ),

            // ==================== PROMOSYON ====================
            _buildSection(
              title: 'Promosyon',
              child: _buildPromosyonFilter(),
            ),

            const SizedBox(height: 16),
            _buildApplyButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET BUILDERS ====================

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildIslemTipiFilter() {
    final islemler = IslemTipleri.kategoriIslemTipleri[_selectedKategori] ?? [];
    return _buildDropdown(
      value: _filter.islemTipi,
      hint: 'İşlem tipi seçiniz',
      items: islemler.map((i) => i['id']!).toList(),
      displayItems: islemler.map((i) => i['label']!).toList(),
      onChanged: (v) {
        setState(() {
          _filter.islemTipi = v;
          _filter.altKategori = null;
        });
      },
    );
  }

  Widget _buildKategoriFilter() {
    final kategoriler = KategoriTanimlari.anaKategoriler;
    return _buildDropdown(
      value: _selectedKategori,
      hint: 'Kategori seçiniz',
      items: kategoriler.map((k) => k['id'] as String).toList(),
      displayItems: kategoriler.map((k) => k['label'] as String).toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() {
            _selectedKategori = v;
            _filter.kategori = _selectedKategori;
            _filter.altKategori = null;
            _filter.islemTipi = null;
          });
        }
      },
    );
  }

  Widget _buildAltKategoriFilter() {
    final altKategoriler = AltKategoriler.getAltKategoriler(
      _selectedKategori, _filter.islemTipi ?? 'satilik');
    if (altKategoriler.isEmpty) return const SizedBox.shrink();

    return _buildDropdown(
      value: _filter.altKategori,
      hint: 'Alt kategori seçin',
      items: altKategoriler,
      onChanged: (v) => setState(() => _filter.altKategori = v),
    );
  }

  Widget _buildKonumFilter() {
    return Column(
      children: [
        _buildDropdown(
          value: _filter.il,
          hint: 'İl seçin',
          items: TurkiyeKonumlari.iller,
          onChanged: (v) {
            setState(() {
              _filter.il = v;
              _filter.ilce = null;
            });
          },
        ),
        if (_filter.il != null) ...[
          const SizedBox(height: 8),
          _buildDropdown(
            value: _filter.ilce,
            hint: 'İlçe seçin',
            items: TurkiyeKonumlari.getIlceler(_filter.il!),
            onChanged: (v) => setState(() => _filter.ilce = v),
          ),
        ],
      ],
    );
  }

  Widget _buildFiyatFilter() {
    final fiyatlar = _filter.islemTipi == 'kiralik'
        ? FiyatAraligi.kiralikFiyatlar
        : FiyatAraligi.satilikFiyatlar;
    return _buildMinMaxRow(
      minValue: _filter.minFiyat?.toInt().toString(),
      maxValue: _filter.maxFiyat?.toInt().toString(),
      items: fiyatlar.map((f) => f.toString()).toList(),
      displayItems: fiyatlar.map((f) => '${FiyatAraligi.format(f)} TL').toList(),
      onMinChanged: (v) => setState(() => _filter.minFiyat = v != null ? double.tryParse(v) : null),
      onMaxChanged: (v) => setState(() => _filter.maxFiyat = v != null ? double.tryParse(v) : null),
    );
  }

  Widget _buildMetrekareFilter() {
    return _buildMinMaxRow(
      minValue: _filter.minMetrekare?.toString(),
      maxValue: _filter.maxMetrekare?.toString(),
      items: MetrekareAraligi.degerler.map((m) => m.toString()).toList(),
      displayItems: MetrekareAraligi.degerler.map((m) => '$m m²').toList(),
      onMinChanged: (v) => setState(() => _filter.minMetrekare = v != null ? int.tryParse(v) : null),
      onMaxChanged: (v) => setState(() => _filter.maxMetrekare = v != null ? int.tryParse(v) : null),
    );
  }

  Widget _buildOdaSayisiFilter() {
    final populerOdalar = ['Stüdyo (1+0)', '1+1', '2+1', '3+1', '3+2', '4+1', '4+2', '5+1', '5+2', '6+1'];
    return _buildMultiSelectPicker(
      hint: 'Oda sayısı seçiniz',
      options: populerOdalar,
      selected: _filter.odaSayilari?.toSet() ?? {},
      onChanged: (set) => setState(() => _filter.odaSayilari = set.isEmpty ? null : set.toList()),
    );
  }

  Widget _buildBinaYasiFilter() {
    return _buildMultiSelectPicker(
      hint: 'Bina yaşı seçiniz',
      options: BinaYasi.values.map((b) => b.label).toList(),
      selected: _filter.binaYaslari?.toSet() ?? {},
      onChanged: (set) => setState(() => _filter.binaYaslari = set.isEmpty ? null : set.toList()),
    );
  }

  Widget _buildFeaturesFilter() {
    final features = <String, bool>{};
    if (_filtreGorunurMu('esyali')) features['Eşyalı'] = _filter.esyali ?? false;
    if (_filtreGorunurMu('balkon')) features['Balkon'] = _filter.balkon ?? false;
    if (_filtreGorunurMu('asansor')) features['Asansör'] = _filter.asansor ?? false;
    features['Otopark'] = _filter.otopark ?? false;
    features['Havuz'] = _filter.havuz ?? false;
    features['Güvenlik'] = _filter.guvenlik ?? false;

    final selected = features.entries.where((e) => e.value).map((e) => e.key).toSet();
    return _buildMultiSelectPicker(
      hint: 'Özellik seçiniz',
      options: features.keys.toList(),
      selected: selected,
      onChanged: (set) {
        setState(() {
          _filter.esyali = set.contains('Eşyalı') ? true : null;
          _filter.balkon = set.contains('Balkon') ? true : null;
          _filter.asansor = set.contains('Asansör') ? true : null;
          _filter.otopark = set.contains('Otopark') ? true : null;
          _filter.havuz = set.contains('Havuz') ? true : null;
          _filter.guvenlik = set.contains('Güvenlik') ? true : null;
        });
      },
    );
  }

  Widget _buildKimdenFilter() {
    return _buildDropdown(
      value: _filter.kimden,
      hint: 'Kimden seçiniz',
      items: Kimden.labels,
      onChanged: (v) => setState(() => _filter.kimden = v),
    );
  }

  Widget _buildPromosyonFilter() {
    final features = <String, bool>{
      'Acil Satılık': _filter.acilSatilik ?? false,
      'Fiyatı Düştü': _filter.fiyatiDustu ?? false,
    };
    final selected = features.entries.where((e) => e.value).map((e) => e.key).toSet();
    return _buildMultiSelectPicker(
      hint: 'Promosyon seçiniz',
      options: features.keys.toList(),
      selected: selected,
      onChanged: (set) {
        setState(() {
          _filter.acilSatilik = set.contains('Acil Satılık') ? true : null;
          _filter.fiyatiDustu = set.contains('Fiyatı Düştü') ? true : null;
        });
      },
    );
  }

  /// Bottom-sheet multi select picker that looks like a dropdown field
  Widget _buildMultiSelectPicker({
    required String hint,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
  }) {
    final displayText = selected.isEmpty
        ? hint
        : selected.length <= 2
            ? selected.join(', ')
            : '${selected.length} seçili';

    return InkWell(
      onTap: () => _showMultiSelectSheet(hint, options, selected, onChanged),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.lightDivider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: selected.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showMultiSelectSheet(
    String title,
    List<String> options,
    Set<String> currentSelection,
    ValueChanged<Set<String>> onChanged,
  ) {
    final tempSelection = Set<String>.from(currentSelection);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              maxChildSize: 0.85,
              minChildSize: 0.3,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(title, style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          TextButton(
                            onPressed: () {
                              setSheetState(() => tempSelection.clear());
                            },
                            child: const Text('Temizle'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Options list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: options.length,
                        itemBuilder: (_, i) {
                          final option = options[i];
                          final isSelected = tempSelection.contains(option);
                          return CheckboxListTile(
                            title: Text(option, style: const TextStyle(fontSize: 14)),
                            value: isSelected,
                            activeColor: AppTheme.primaryNavy,
                            onChanged: (v) {
                              setSheetState(() {
                                if (v == true) {
                                  tempSelection.add(option);
                                } else {
                                  tempSelection.remove(option);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    // Apply button
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              onChanged(tempSelection);
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNavy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              tempSelection.isEmpty ? 'Kapat' : 'Uygula (${tempSelection.length} seçili)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown({
    String? value,
    required String hint,
    required List<String> items,
    List<String>? displayItems,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightDivider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: AppTheme.textSecondary)),
          items: List.generate(items.length, (i) {
            return DropdownMenuItem(
              value: items[i],
              child: Text(displayItems != null ? displayItems[i] : items[i]),
            );
          }),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMinMaxRow({
    String? minValue,
    String? maxValue,
    required List<String> items,
    List<String>? displayItems,
    required ValueChanged<String?> onMinChanged,
    required ValueChanged<String?> onMaxChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            value: minValue,
            hint: 'Min',
            items: items,
            displayItems: displayItems,
            onChanged: onMinChanged,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('-', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: _buildDropdown(
            value: maxValue,
            hint: 'Max',
            items: items,
            displayItems: displayItems,
            onChanged: onMaxChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, _filter),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Text(
              _filter.activeFilterCount > 0
                  ? 'Filtrele (${_filter.activeFilterCount} filtre aktif)'
                  : 'Filtrele',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _filter.reset();
      _selectedKategori = 'konut';
      _filter.kategori = _selectedKategori;
    });
  }
}
