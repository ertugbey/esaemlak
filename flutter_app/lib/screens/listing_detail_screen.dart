import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../models/listing_enums.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mortgage_calculator.dart';
import 'comparison_screen.dart';

/// Premium Listing Detail Screen with photo gallery, striped table, and sticky action bar
class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Listing? _listing;
  bool _isLoading = true;
  bool _isFavorited = false;
  bool _isFavoriteLoading = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadListing();
    _checkFavorite();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadListing() async {
    try {
      final data = await _api.getListing(widget.listingId);
      if (mounted) {
        setState(() {
          _listing = Listing.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İlan yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await _api.isFavorited(widget.listingId);
    if (mounted) setState(() => _isFavorited = isFav);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;
    setState(() => _isFavoriteLoading = true);
    
    try {
      if (_isFavorited) {
        await _api.removeFavorite(widget.listingId);
        if (mounted) {
          setState(() => _isFavorited = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorilerden çıkarıldı')),
          );
        }
      } else {
        await _api.addFavorite(widget.listingId);
        if (mounted) {
          setState(() => _isFavorited = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Favorilere eklendi')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _isFavoriteLoading = false);
    }
  }

  void _shareListing() {
    if (_listing == null) return;
    
    final listing = _listing!;
    final shareText = '''
🏠 ${listing.baslik}

💰 ${listing.formattedPrice}
📍 ${listing.location}
${listing.odaSayisi != null ? '🛏️ ${listing.odaSayisi}' : ''}
📐 ${listing.displayMetrekare} m²

🔗 EsaEmlak'ta görüntüle:
https://esaemlak.com/listings/${listing.id}
''';

    Share.share(shareText, subject: listing.baslik);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listing == null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _listing != null ? _buildStickyActionBar() : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('İlan bulunamadı'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Geri Dön'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final listing = _listing!;
    
    return CustomScrollView(
      slivers: [
        // Photo Gallery in SliverAppBar
        _buildPhotoGallery(listing),
        
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price & Badges
                _buildPriceSection(listing),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  listing.baslik,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: AppTheme.accentTeal),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Quick Stats Cards
                _buildQuickStats(listing),
                
                const SizedBox(height: 24),
                
                // Property Details - Striped Table
                _buildSectionHeader('İlan Detayları'),
                const SizedBox(height: 12),
                _buildStripedDetailsTable(listing),
                
                const SizedBox(height: 24),
                
                // Features
                _buildSectionHeader('Özellikler'),
                const SizedBox(height: 12),
                _buildFeatures(listing),
                
                const SizedBox(height: 24),
                
                // Description
                _buildSectionHeader('Açıklama'),
                const SizedBox(height: 12),
                Text(
                  listing.aciklama,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
                
                const SizedBox(height: 24),
                
                // Mini Map Preview
                if (listing.latitude != null && listing.longitude != null) ...[
                  _buildSectionHeader('Konum'),
                  const SizedBox(height: 12),
                  _buildMiniMap(listing),
                  const SizedBox(height: 24),
                ],
                
                // Mortgage Calculator Button
                _buildMortgageButton(listing),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGallery(Listing listing) {
    final photos = listing.fotograflar;
    
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.black,
      leading: _buildCircleButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        _buildCircleButton(
          icon: Icons.share,
          onPressed: _shareListing,
        ),
        _buildCircleButton(
          icon: _isFavorited ? Icons.favorite : Icons.favorite_border,
          iconColor: _isFavorited ? Colors.red : Colors.white,
          onPressed: _toggleFavorite,
          isLoading: _isFavoriteLoading,
        ),
        if (_listing != null)
          CompareButton(listing: _listing!),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: photos.isEmpty
            ? Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.home, size: 80, color: Colors.grey),
                ),
              )
            : Stack(
                children: [
                  // Image PageView
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentImageIndex = index),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: photos[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 60),
                        ),
                      );
                    },
                  ),
                  
                  // Photo counter badge
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${_currentImageIndex + 1} / ${photos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Dot indicators
                  if (photos.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photos.length, (index) {
                          return Container(
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? AppTheme.goldAccent
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        onPressed: onPressed,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(icon, color: iconColor ?? Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildPriceSection(Listing listing) {
    return Row(
      children: [
        // Price
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryNavy, AppTheme.primaryNavyLight],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            listing.formattedPrice,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Badges
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                listing.islemTipiLabel,
                style: TextStyle(
                  color: AppTheme.goldAccentDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              listing.kategoriLabel,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(Listing listing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.square_foot, '${listing.displayMetrekare} m²', 'Brüt'),
          _buildStatDivider(),
          _buildStatItem(Icons.bed_outlined, listing.odaSayisi ?? '-', 'Oda'),
          _buildStatDivider(),
          _buildStatItem(Icons.calendar_today, listing.binaYasi ?? '-', 'Yaş'),
          _buildStatDivider(),
          _buildStatItem(Icons.layers_outlined, listing.bulunduguKat?.toString() ?? '-', 'Kat'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryNavy, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.grey[300],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.goldAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Premium striped details table
  Widget _buildStripedDetailsTable(Listing listing) {
    final rows = <_TableRow>[
      _TableRow('İlan No', listing.id.substring(0, 8).toUpperCase()),
      _TableRow('Kategori', listing.kategori),
      _TableRow('Alt Kategori', listing.altKategori),
      if (listing.brutMetrekare != null) _TableRow('Brüt m²', '${listing.brutMetrekare}'),
      if (listing.netMetrekare != null) _TableRow('Net m²', '${listing.netMetrekare}'),
      if (listing.odaSayisi != null) _TableRow('Oda Sayısı', listing.odaSayisi!),
      if (listing.banyoSayisi != null) _TableRow('Banyo Sayısı', '${listing.banyoSayisi}'),
      if (listing.binaYasi != null) _TableRow('Bina Yaşı', listing.binaYasi!),
      if (listing.bulunduguKat != null) _TableRow('Bulunduğu Kat', '${listing.bulunduguKat}'),
      if (listing.katSayisi != null) _TableRow('Kat Sayısı', '${listing.katSayisi}'),
      if (listing.isitmaTipi != null) _TableRow('Isıtma', listing.isitmaTipi!),
      if (listing.tapuDurumu != null) _TableRow('Tapu Durumu', listing.tapuDurumu!),
      if (listing.kimden != null) _TableRow('Kimden', listing.kimden!),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isEven = entry.key.isEven;
          final row = entry.value;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isEven 
                  ? (Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.darkCard 
                      : const Color(0xFFF8F9FA))
                  : (Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.darkSurface 
                      : Colors.white),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    row.label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    row.value,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatures(Listing listing) {
    final features = listing.activeFeatures;
    
    if (features.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
            const SizedBox(width: 12),
            Text(
              'Özellik bilgisi girilmemiş.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: features.map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentTeal.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 16, color: AppTheme.accentTeal),
              const SizedBox(width: 6),
              Text(
                feature.label,
                style: TextStyle(
                  color: AppTheme.accentTeal,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniMap(Listing listing) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(listing.latitude!, listing.longitude!),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.esaemlak.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(listing.latitude!, listing.longitude!),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: ElevatedButton.icon(
              onPressed: () => _openMaps(listing.latitude!, listing.longitude!),
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Yol Tarifi Al'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMortgageButton(Listing listing) {
    return OutlinedButton.icon(
      onPressed: () => showMortgageCalculator(
        context, 
        listing.fiyat.toDouble(), 
        listing.baslik,
      ),
      icon: Icon(Icons.calculate, color: AppTheme.primaryNavy),
      label: const Text('Kredi Hesapla'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 0),
      ),
    );
  }

  /// Sticky bottom action bar - always visible
  Widget _buildStickyActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Message button - Outline
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to messages
                },
                icon: const Icon(Icons.message_outlined),
                label: const Text('Mesaj Gönder'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppTheme.primaryNavy),
                  foregroundColor: AppTheme.primaryNavy,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Call button - Gold filled
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  // TODO: Make call
                },
                icon: const Icon(Icons.phone),
                label: const Text('Ara'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.goldAccent,
                  foregroundColor: AppTheme.primaryNavyDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

class _TableRow {
  final String label;
  final String value;
  
  _TableRow(this.label, this.value);
}
