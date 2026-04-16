import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Map-based search screen with flutter_map integration
/// Supports list/map toggle and geo-bounding box queries
class MapSearchScreen extends StatefulWidget {
  final SearchFilter? initialFilter;

  const MapSearchScreen({super.key, this.initialFilter});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();
  
  List<Listing> _listings = [];
  bool _isLoading = true;
  bool _showMap = true; // Toggle between map and list view
  Listing? _selectedListing;
  
  // İstanbul default center
  static const _defaultCenter = LatLng(41.0082, 28.9784);
  static const _defaultZoom = 11.0;

  @override
  void initState() {
    super.initState();
    _loadListingsInBounds();
  }

  Future<void> _loadListingsInBounds() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current map bounds if map is ready
      LatLngBounds? bounds;
      try {
        bounds = _mapController.camera.visibleBounds;
      } catch (_) {
        // Map not initialized yet, use default bounds for Istanbul
        bounds = LatLngBounds(
          const LatLng(40.8, 28.5),  // SW
          const LatLng(41.3, 29.4),  // NE
        );
      }

      final filter = SearchFilter(
        northEastLat: bounds.northEast.latitude,
        northEastLon: bounds.northEast.longitude,
        southWestLat: bounds.southWest.latitude,
        southWestLon: bounds.southWest.longitude,
        limit: 100, // More results for map view
      );

      // Apply any initial filters
      if (widget.initialFilter != null) {
        filter.kategori = widget.initialFilter!.kategori;
        filter.islemTipi = widget.initialFilter!.islemTipi;
        filter.minFiyat = widget.initialFilter!.minFiyat;
        filter.maxFiyat = widget.initialFilter!.maxFiyat;
      }

      final results = await _api.searchListings(
        il: filter.il,
        emlakTipi: filter.kategori,
        skip: 0,
      );
      setState(() {
        _listings = results.map((e) => Listing.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint('Error loading map listings: $e');
    }
    
    setState(() => _isLoading = false);
  }

  void _onMapMoved() {
    // Debounce map movement to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _loadListingsInBounds();
    });
  }

  void _navigateToListing(Listing listing) {
    Navigator.pushNamed(context, '/listings/${listing.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haritada Ara'),
        actions: [
          // List/Map toggle
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            tooltip: _showMap ? 'Liste Görünümü' : 'Harita Görünümü',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadListingsInBounds,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map or List view
          _showMap ? _buildMapView() : _buildListView(),
          
          // Loading indicator
          if (_isLoading)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text('${_listings.length} ilan yükleniyor...'),
                    ],
                  ),
                ),
              ),
            ),
          
          // Results count badge
          if (!_isLoading)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_listings.length} ilan bulundu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Selected listing card
          if (_selectedListing != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildSelectedListingCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: _defaultZoom,
        onMapEvent: (event) {
          if (event is MapEventMoveEnd) {
            _onMapMoved();
          }
        },
        onTap: (_, __) => setState(() => _selectedListing = null),
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.esaemlak.app',
        ),
        // Listing markers
        MarkerLayer(
          markers: _listings
              .where((l) => l.latitude != null && l.longitude != null)
              .map((listing) => _buildMarker(listing))
              .toList(),
        ),
      ],
    );
  }

  Marker _buildMarker(Listing listing) {
    final isSelected = _selectedListing?.id == listing.id;
    
    return Marker(
      point: LatLng(listing.latitude!, listing.longitude!),
      width: isSelected ? 120 : 80,
      height: 40,
      child: GestureDetector(
        onTap: () => setState(() => _selectedListing = listing),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryBlue 
                : listing.acilSatilik 
                    ? Colors.red 
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            listing.formattedPrice,
            style: TextStyle(
              color: isSelected || listing.acilSatilik ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedListingCard() {
    final listing = _selectedListing!;
    
    return GestureDetector(
      onTap: () => _navigateToListing(listing),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: listing.fotograflar.isNotEmpty 
                    ? listing.fotograflar.first 
                    : 'https://via.placeholder.com/100',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price
                  Text(
                    listing.formattedPrice,
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    listing.baslik,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        listing.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Features
                  Row(
                    children: [
                      if (listing.odaSayisi != null) ...[
                        Icon(Icons.bed, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(listing.odaSayisi!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.square_foot, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${listing.displayMetrekare} m²', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_listings.isEmpty && !_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bu bölgede ilan bulunamadı'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _listings.length,
      itemBuilder: (context, index) {
        final listing = _listings[index];
        return _MapListingCard(
          listing: listing,
          onTap: () => _navigateToListing(listing),
        );
      },
    );
  }
}

class _MapListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const _MapListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: listing.fotograflar.isNotEmpty 
                    ? listing.fotograflar.first 
                    : 'https://via.placeholder.com/120',
                width: 120,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.formattedPrice,
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.baslik,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
