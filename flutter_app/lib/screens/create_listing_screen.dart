import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../models/listing_enums.dart';
import '../data/category_data.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Multi-step listing creation wizard (Sahibinden style)
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Step 1: Kategori
  String? _kategori;
  String? _altKategori;
  String? _islemTipi;

  // Step 2: Konum
  String? _il;
  String? _ilce;
  String? _mahalle;

  // Step 3: Detaylar
  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _fiyatController = TextEditingController();
  final _brutMetrekareController = TextEditingController();
  final _netMetrekareController = TextEditingController();
  final _banyoController = TextEditingController();
  final _bulunduguKatController = TextEditingController();
  final _katSayisiController = TextEditingController();
  
  String? _odaSayisi;
  String? _binaYasi;
  String? _isitmaTipi;
  String? _tapuDurumu;
  String? _kimden;
  
  // Özellikler
  bool _esyali = false;
  bool _balkon = false;
  bool _asansor = false;
  bool _otopark = false;
  bool _siteIcerisinde = false;
  bool _havuz = false;
  bool _guvenlik = false;
  bool _krediyeUygun = false;
  bool _takasli = false;

  // ================== YENİ SAHIBINDEN ALANLARI ==================
  
  // İş Yeri Alanları
  final _girisYuksekligiController = TextEditingController();
  bool _zeminEtudu = false;
  bool _devren = false;
  bool _kiracili = false;
  String? _yapininDurumu;
  
  // Arsa Alanları
  final _adaParselController = TextEditingController();
  final _gabariController = TextEditingController();
  final _kaksEmsalController = TextEditingController();
  bool _katKarsiligi = false;
  String? _imarDurumu;
  
  // Özellik Listeleri (çoklu seçim)
  Set<String> _selectedManzara = {};
  Set<String> _selectedCephe = {};
  Set<String> _selectedUlasim = {};
  Set<String> _selectedMuhit = {};
  Set<String> _selectedIcOzellikler = {};
  Set<String> _selectedDisOzellikler = {};
  Set<String> _selectedEngelliye = {};
  
  // Promosyon
  bool _acilSatilik = false;
  bool _fiyatiDustu = false;

  // Step 4: Medya
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _fiyatController.dispose();
    _brutMetrekareController.dispose();
    _netMetrekareController.dispose();
    _banyoController.dispose();
    _bulunduguKatController.dispose();
    _katSayisiController.dispose();
    // Yeni Sahibinden alanları
    _girisYuksekligiController.dispose();
    _adaParselController.dispose();
    _gabariController.dispose();
    _kaksEmsalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Ver'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Step content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(),
              ),
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = [
      {'icon': Icons.category, 'label': 'Kategori'},
      {'icon': Icons.location_on, 'label': 'Konum'},
      {'icon': Icons.description, 'label': 'Detaylar'},
      {'icon': Icons.photo_library, 'label': 'Fotoğraf'},
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          final step = steps[index];
          
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    // Line before (except first)
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppTheme.accentTeal
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    // Circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCompleted || isActive
                            ? LinearGradient(
                                colors: isCompleted
                                    ? [AppTheme.accentTeal, AppTheme.accentTeal.withValues(alpha: 0.8)]
                                    : [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isCompleted || isActive ? null : Colors.grey[200],
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Icon(
                                step['icon'] as IconData,
                                size: 18,
                                color: isActive ? Colors.white : Colors.grey[500],
                              ),
                      ),
                    ),
                    // Line after (except last)
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: index < _currentStep
                                ? AppTheme.accentTeal
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  step['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? AppTheme.primaryBlue
                        : isCompleted
                            ? AppTheme.accentTeal
                            : Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildKategoriStep();
      case 1:
        return _buildKonumStep();
      case 2:
        return _buildDetaylarStep();
      case 3:
        return _buildMedyaStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==================== STEP 1: KATEGORİ ====================
  
  Widget _buildKategoriStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori (7 ana kategori) - Icon Grid
        _buildSectionTitle('Emlak Tipi'),
        const SizedBox(height: 16),
        _buildKategoriGrid(),

        // İşlem Tipi - kategoriye göre dinamik
        if (_kategori != null) ...[
          const SizedBox(height: 32),
          _buildSectionTitle('İşlem Tipi'),
          const SizedBox(height: 16),
          _buildIslemTipiChips(),
        ],

        // Alt Kategori - işlem tipine göre dinamik
        if (_kategori != null && _islemTipi != null && AltKategoriler.altKategoriGerekli(_kategori!)) ...[
          const SizedBox(height: 32),
          _buildSectionTitle('Alt Kategori'),
          const SizedBox(height: 16),
          _buildAltKategoriChips(),
        ],
      ],
    );
  }

  Widget _buildIslemTipiChips() {
    final islemler = IslemTipleri.kategoriIslemTipleri[_kategori] ?? [];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: islemler.map((islem) {
        final isSelected = _islemTipi == islem['label'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _islemTipi = islem['label'];
              _altKategori = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Text(
              islem['label']!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.primaryBlue,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIslemCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = _islemTipi == value;
    
    return GestureDetector(
      onTap: () => setState(() => _islemTipi = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriGrid() {
    final iconMap = {
      'konut': Icons.home_outlined,
      'isyeri': Icons.storefront,
      'arsa': Icons.landscape,
      'konutProjeleri': Icons.apartment,
      'bina': Icons.domain,
      'devreMulk': Icons.villa,
      'turistikTesis': Icons.hotel,
    };
    final colorMap = {
      'konut': AppTheme.primaryBlue,
      'isyeri': Colors.orange,
      'arsa': Colors.green,
      'konutProjeleri': Colors.purple,
      'bina': Colors.brown,
      'devreMulk': Colors.teal,
      'turistikTesis': Colors.indigo,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: KategoriTanimlari.anaKategoriler.length,
      itemBuilder: (context, index) {
        final kat = KategoriTanimlari.anaKategoriler[index];
        final katId = kat['id'] as String;
        final isSelected = _kategori == katId;
        final color = colorMap[katId] ?? AppTheme.primaryBlue;
        final icon = iconMap[katId] ?? Icons.category;

        return GestureDetector(
          onTap: () {
            setState(() {
              _kategori = katId;
              _altKategori = null;
              _islemTipi = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: isSelected ? Colors.white : Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  kat['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : Colors.grey[700],
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, size: 16, color: color),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAltKategoriChips() {
    // İşlem tipi ID'sini bul
    final islemTipleri = IslemTipleri.kategoriIslemTipleri[_kategori] ?? [];
    final islemTipiId = islemTipleri
        .where((i) => i['label'] == _islemTipi)
        .map((i) => i['id']!)
        .firstOrNull ?? 'satilik';

    final altKatList = AltKategoriler.getAltKategoriler(_kategori ?? '', islemTipiId);
    if (altKatList.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: altKatList.map((label) {
        final isSelected = _altKategori == label;
        return GestureDetector(
          onTap: () => setState(() => _altKategori = label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.primaryBlue,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================== STEP 2: KONUM ====================
  
  Widget _buildKonumStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('İl'),
        const SizedBox(height: 12),
        _buildDropdown(
          value: _il,
          hint: 'İl seçin',
          items: TurkiyeKonumlari.iller,
          onChanged: (value) {
            setState(() {
              _il = value;
              _ilce = null;
            });
          },
        ),
        
        if (_il != null) ...[
          const SizedBox(height: 20),
          _buildSectionTitle('İlçe'),
          const SizedBox(height: 12),
          _buildDropdown(
            value: _ilce,
            hint: 'İlçe seçin',
            items: TurkiyeKonumlari.getIlceler(_il!),
            onChanged: (value) => setState(() => _ilce = value),
          ),
        ],
        
        const SizedBox(height: 20),
        _buildSectionTitle('Mahalle (Opsiyonel)'),
        const SizedBox(height: 12),
        TextFormField(
          decoration: const InputDecoration(
            hintText: 'Mahalle adı girin',
            prefixIcon: Icon(Icons.location_city),
          ),
          onChanged: (value) => _mahalle = value,
        ),
      ],
    );
  }

  // ==================== STEP 3: DETAYLAR ====================
  
  Widget _buildDetaylarStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Temel Bilgiler
        _buildSectionTitle('Temel Bilgiler'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _baslikController,
          decoration: const InputDecoration(
            labelText: 'İlan Başlığı *',
            hintText: 'Örn: Deniz Manzaralı 3+1 Daire',
          ),
          validator: (v) => v?.isEmpty == true ? 'Başlık gerekli' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _aciklamaController,
          decoration: const InputDecoration(
            labelText: 'Açıklama *',
            hintText: 'İlanınızı detaylı açıklayın',
          ),
          maxLines: 4,
          validator: (v) => v?.isEmpty == true ? 'Açıklama gerekli' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fiyatController,
          decoration: const InputDecoration(
            labelText: 'Fiyat (TL) *',
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: TextInputType.number,
          validator: (v) => v?.isEmpty == true ? 'Fiyat gerekli' : null,
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('Ölçüler'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _brutMetrekareController,
                decoration: const InputDecoration(
                  labelText: 'Brüt m²',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _netMetrekareController,
                decoration: const InputDecoration(
                  labelText: 'Net m²',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('Oda & Bina'),
        const SizedBox(height: 12),
        _buildDropdown(
          value: _odaSayisi,
          hint: 'Oda Sayısı',
          items: OdaSayisi.values.map((e) => e.label).toList(),
          onChanged: (v) => setState(() => _odaSayisi = v),
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          value: _binaYasi,
          hint: 'Bina Yaşı',
          items: BinaYasi.values.map((e) => e.label).toList(),
          onChanged: (v) => setState(() => _binaYasi = v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bulunduguKatController,
                decoration: const InputDecoration(labelText: 'Bulunduğu Kat'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _katSayisiController,
                decoration: const InputDecoration(labelText: 'Kat Sayısı'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _banyoController,
                decoration: const InputDecoration(labelText: 'Banyo Sayısı'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                value: _isitmaTipi,
                hint: 'Isıtma',
                items: IsitmaTipi.values.map((e) => e.label).toList(),
                onChanged: (v) => setState(() => _isitmaTipi = v),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('Özellikler'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFeatureChip('Eşyalı', _esyali, (v) => setState(() => _esyali = v)),
            _buildFeatureChip('Balkon', _balkon, (v) => setState(() => _balkon = v)),
            _buildFeatureChip('Asansör', _asansor, (v) => setState(() => _asansor = v)),
            _buildFeatureChip('Otopark', _otopark, (v) => setState(() => _otopark = v)),
            _buildFeatureChip('Site İç.', _siteIcerisinde, (v) => setState(() => _siteIcerisinde = v)),
            _buildFeatureChip('Havuz', _havuz, (v) => setState(() => _havuz = v)),
            _buildFeatureChip('Güvenlik', _guvenlik, (v) => setState(() => _guvenlik = v)),
          ],
        ),

        // ================== İŞ YERİ ALANLARI ==================
        if (_kategori == 'isyeri') ...[
          const SizedBox(height: 24),
          _buildSectionTitle('İş Yeri Bilgileri'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _girisYuksekligiController,
            decoration: const InputDecoration(
              labelText: 'Giriş Yüksekliği (m)',
              prefixIcon: Icon(Icons.height),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            value: _yapininDurumu,
            hint: 'Yapının Durumu',
            items: YapininDurumu.values.map((e) => e.label).toList(),
            onChanged: (v) => setState(() => _yapininDurumu = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureChip('Zemin Etüdü', _zeminEtudu, (v) => setState(() => _zeminEtudu = v)),
              _buildFeatureChip('Devren', _devren, (v) => setState(() => _devren = v)),
              _buildFeatureChip('Kiracılı', _kiracili, (v) => setState(() => _kiracili = v)),
            ],
          ),
        ],

        // ================== ARSA ALANLARI ==================
        if (_kategori == 'arsa') ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Arsa Bilgileri'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _adaParselController,
            decoration: const InputDecoration(
              labelText: 'Ada / Parsel',
              prefixIcon: Icon(Icons.map),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _gabariController,
                  decoration: const InputDecoration(labelText: 'Gabari'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _kaksEmsalController,
                  decoration: const InputDecoration(labelText: 'KAKS / Emsal'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            value: _imarDurumu,
            hint: 'İmar Durumu',
            items: const ['Konut İmarlı', 'Ticaret İmarlı', 'Sanayi İmarlı', 'Tarla', 'Bağ & Bahçe', 'Zeytinlik', 'Diğer'],
            onChanged: (v) => setState(() => _imarDurumu = v),
          ),
          const SizedBox(height: 12),
          _buildFeatureChip('Kat Karşılığı', _katKarsiligi, (v) => setState(() => _katKarsiligi = v)),
        ],

        // ================== ÖZELLİK LİSTELERİ (ExpansionTiles) ==================
        const SizedBox(height: 24),
        _buildSectionTitle('Detaylı Özellikler'),
        const SizedBox(height: 8),
        
        // Manzara
        _buildMultiSelectExpansion(
          title: 'Manzara',
          icon: Icons.landscape,
          options: Manzara.values.map((e) => e.label).toList(),
          selected: _selectedManzara,
          onChanged: (set) => setState(() => _selectedManzara = set),
        ),
        
        // Cephe
        _buildMultiSelectExpansion(
          title: 'Cephe',
          icon: Icons.compass_calibration,
          options: Cephe.values.map((e) => e.label).toList(),
          selected: _selectedCephe,
          onChanged: (set) => setState(() => _selectedCephe = set),
        ),
        
        // İç Özellikler
        _buildMultiSelectExpansion(
          title: 'İç Özellikler',
          icon: Icons.chair,
          options: IcOzellik.values.map((e) => e.label).toList(),
          selected: _selectedIcOzellikler,
          onChanged: (set) => setState(() => _selectedIcOzellikler = set),
        ),
        
        // Dış Özellikler
        _buildMultiSelectExpansion(
          title: 'Dış Özellikler',
          icon: Icons.park,
          options: DisOzellik.values.map((e) => e.label).toList(),
          selected: _selectedDisOzellikler,
          onChanged: (set) => setState(() => _selectedDisOzellikler = set),
        ),
        
        // Ulaşım
        _buildMultiSelectExpansion(
          title: 'Ulaşım',
          icon: Icons.directions_bus,
          options: Ulasim.values.map((e) => e.label).toList(),
          selected: _selectedUlasim,
          onChanged: (set) => setState(() => _selectedUlasim = set),
        ),
        
        // Muhit
        _buildMultiSelectExpansion(
          title: 'Muhit / Çevre',
          icon: Icons.location_city,
          options: Muhit.values.map((e) => e.label).toList(),
          selected: _selectedMuhit,
          onChanged: (set) => setState(() => _selectedMuhit = set),
        ),
        
        // Engelliye Uygunluk
        _buildMultiSelectExpansion(
          title: 'Engelliye Uygunluk',
          icon: Icons.accessible,
          options: EngelliyeUygunluk.values.map((e) => e.label).toList(),
          selected: _selectedEngelliye,
          onChanged: (set) => setState(() => _selectedEngelliye = set),
        ),

        // ================== PROMOSYON ==================
        const SizedBox(height: 24),
        _buildSectionTitle('Öne Çıkarma'),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Acil Satılık'),
          subtitle: const Text('İlanınız "Acil" olarak işaretlenir'),
          value: _acilSatilik,
          onChanged: (v) => setState(() => _acilSatilik = v),
          activeColor: Colors.red,
          secondary: const Icon(Icons.flash_on, color: Colors.red),
        ),
        SwitchListTile(
          title: const Text('Fiyatı Düştü'),
          subtitle: const Text('İlanınız günün fırsatlarında görünür'),
          value: _fiyatiDustu,
          onChanged: (v) => setState(() => _fiyatiDustu = v),
          activeColor: Colors.green,
          secondary: const Icon(Icons.trending_down, color: Colors.green),
        ),

        const SizedBox(height: 24),
        _buildSectionTitle('Satış Detayları'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFeatureChip('Krediye Uygun', _krediyeUygun, (v) => setState(() => _krediyeUygun = v)),
            _buildFeatureChip('Takaslı', _takasli, (v) => setState(() => _takasli = v)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                value: _tapuDurumu,
                hint: 'Tapu Durumu',
                items: TapuDurumu.values.map((e) => e.label).toList(),
                onChanged: (v) => setState(() => _tapuDurumu = v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                value: _kimden,
                hint: 'Kimden',
                items: Kimden.values.map((e) => e.label).toList(),
                onChanged: (v) => setState(() => _kimden = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Multi-select expansion tile for feature categories
  Widget _buildMultiSelectExpansion({
    required String title,
    required IconData icon,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(title),
        trailing: selected.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selected.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final isSelected = selected.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (value) {
                    final newSet = Set<String>.from(selected);
                    if (value) {
                      newSet.add(option);
                    } else {
                      newSet.remove(option);
                    }
                    onChanged(newSet);
                  },
                  selectedColor: AppTheme.accentTeal.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.accentTeal,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppTheme.accentTeal.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.accentTeal,
    );
  }

  // ==================== STEP 4: MEDYA ====================
  
  Widget _buildMedyaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fotoğraflar'),
        const SizedBox(height: 8),
        Text(
          'En az 1, en fazla 10 fotoğraf yükleyebilirsiniz.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 16),
        
        // Add photo button
        InkWell(
          onTap: _pickImages,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryBlue, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: AppTheme.primaryBlue),
                  const SizedBox(height: 8),
                  Text(
                    'Fotoğraf Ekle',
                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedImages.removeAt(index));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Kapak',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          if (_selectedImages.length < 10) {
            _selectedImages.add(File(image.path));
          }
        }
      });
    }
  }

  // ==================== HELPER WIDGETS ====================
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildChoiceChips({
    required List<String> options,
    String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: AppTheme.primaryBlue,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown({
    String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Geri'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _isLoading ? null : _handleNext,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_currentStep == 3 ? 'İlanı Yayınla' : 'Devam'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    // Validate current step
    if (!_validateCurrentStep()) return;
    
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitListing();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_islemTipi == null || _kategori == null || _altKategori == null) {
          _showError('Lütfen tüm kategori seçimlerini yapın');
          return false;
        }
        return true;
      case 1:
        if (_il == null || _ilce == null) {
          _showError('Lütfen il ve ilçe seçin');
          return false;
        }
        return true;
      case 2:
        return _formKey.currentState?.validate() ?? false;
      case 3:
        if (_selectedImages.isEmpty) {
          _showError('Lütfen en az 1 fotoğraf ekleyin');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitListing() async {
    setState(() => _isLoading = true);
    
    try {
      final api = ApiService();
      
      // Step 1: Upload photos first
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          final paths = _selectedImages.map((f) => f.path).toList();
          photoUrls = await api.uploadPhotos(paths);
        } catch (e) {
          _showError('Fotoğraflar yüklenemedi: $e');
          return;
        }
      }

      // Step 2: Prepare listing data with photo URLs
      final listingData = {
        'baslik': _baslikController.text,
        'aciklama': _aciklamaController.text,
        'kategori': _kategori,
        'altKategori': _altKategori,
        'islemTipi': _islemTipi?.toLowerCase(),
        'fiyat': double.tryParse(_fiyatController.text) ?? 0,
        'brutMetrekare': int.tryParse(_brutMetrekareController.text),
        'netMetrekare': int.tryParse(_netMetrekareController.text),
        'odaSayisi': _odaSayisi,
        'binaYasi': _binaYasi,
        'banyoSayisi': int.tryParse(_banyoController.text),
        'bulunduguKat': int.tryParse(_bulunduguKatController.text),
        'katSayisi': int.tryParse(_katSayisiController.text),
        'isitmaTipi': _isitmaTipi,
        'esyali': _esyali,
        'balkon': _balkon,
        'asansor': _asansor,
        'otopark': _otopark,
        'siteIcerisinde': _siteIcerisinde,
        'havuz': _havuz,
        'guvenlik': _guvenlik,
        // İş Yeri alanları
        'girisYuksekligi': double.tryParse(_girisYuksekligiController.text),
        'zeminEtudu': _zeminEtudu,
        'devren': _devren,
        'kiracili': _kiracili,
        'yapininDurumu': _yapininDurumu,
        // Arsa alanları
        'adaParsel': _adaParselController.text.isNotEmpty ? _adaParselController.text : null,
        'gabari': double.tryParse(_gabariController.text),
        'kaksEmsal': double.tryParse(_kaksEmsalController.text),
        'katKarsiligi': _katKarsiligi,
        'imarDurumu': _imarDurumu,
        // Özellik listeleri
        'manzara': _selectedManzara.toList(),
        'cephe': _selectedCephe.toList(),
        'ulasim': _selectedUlasim.toList(),
        'muhit': _selectedMuhit.toList(),
        'icOzellikler': _selectedIcOzellikler.toList(),
        'disOzellikler': _selectedDisOzellikler.toList(),
        'engelliyeUygunluk': _selectedEngelliye.toList(),
        // Promosyon
        'acilSatilik': _acilSatilik,
        'fiyatiDustu': _fiyatiDustu,
        // Satış detayları
        'krediyeUygun': _krediyeUygun,
        'takasli': _takasli,
        'tapuDurumu': _tapuDurumu,
        'kimden': _kimden,
        'il': _il,
        'ilce': _ilce,
        'mahalle': _mahalle,
        'fotograflar': photoUrls,
      };
      
      // Step 3: Create the listing
      final response = await api.createListing(listingData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlan başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('İlan oluşturulurken bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

