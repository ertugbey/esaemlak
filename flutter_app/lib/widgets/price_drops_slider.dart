import 'package:flutter/material.dart';

/// Model for price drop listings
class PriceDrop {
  final String id;
  final String baslik;
  final String emlakTipi;
  final String islemTipi;
  final double fiyat;
  final double oldPrice;
  final double discountPercent;
  final String il;
  final String ilce;
  final double? metrekare;
  final String? odaSayisi;
  final List<String> fotograflar;
  final DateTime priceUpdatedAt;

  PriceDrop({
    required this.id,
    required this.baslik,
    required this.emlakTipi,
    required this.islemTipi,
    required this.fiyat,
    required this.oldPrice,
    required this.discountPercent,
    required this.il,
    required this.ilce,
    this.metrekare,
    this.odaSayisi,
    required this.fotograflar,
    required this.priceUpdatedAt,
  });

  factory PriceDrop.fromJson(Map<String, dynamic> json) {
    return PriceDrop(
      id: json['id'] ?? '',
      baslik: json['baslik'] ?? '',
      emlakTipi: json['emlakTipi'] ?? '',
      islemTipi: json['islemTipi'] ?? '',
      fiyat: (json['fiyat'] ?? 0).toDouble(),
      oldPrice: (json['oldPrice'] ?? 0).toDouble(),
      discountPercent: (json['discountPercent'] ?? 0).toDouble(),
      il: json['il'] ?? '',
      ilce: json['ilce'] ?? '',
      metrekare: json['metrekare']?.toDouble(),
      odaSayisi: json['odaSayisi'],
      fotograflar: List<String>.from(json['fotograflar'] ?? []),
      priceUpdatedAt: DateTime.tryParse(json['priceUpdatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedPrice {
    if (fiyat >= 1000000) {
      return '${(fiyat / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M TL';
    } else if (fiyat >= 1000) {
      return '${(fiyat / 1000).toStringAsFixed(0)}K TL';
    }
    return '${fiyat.toStringAsFixed(0)} TL';
  }

  String get formattedOldPrice {
    if (oldPrice >= 1000000) {
      return '${(oldPrice / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M TL';
    } else if (oldPrice >= 1000) {
      return '${(oldPrice / 1000).toStringAsFixed(0)}K TL';
    }
    return '${oldPrice.toStringAsFixed(0)} TL';
  }

  String get location => '$ilce, $il';
}

/// Horizontal slider widget for showing price drop listings
class PriceDropsSlider extends StatelessWidget {
  final List<PriceDrop> priceDrops;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(PriceDrop)? onTap;

  const PriceDropsSlider({
    super.key,
    required this.priceDrops,
    this.isLoading = false,
    this.onRefresh,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (priceDrops.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Günün Fırsatları 🔥',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Son 24 saatte fiyatı düşen ilanlar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: onRefresh,
                ),
            ],
          ),
        ),
        
        // Horizontal slider
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: priceDrops.length,
            itemBuilder: (context, index) {
              return _PriceDropCard(
                priceDrop: priceDrops[index],
                onTap: () => onTap?.call(priceDrops[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(width: 20, height: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 140, height: 16, color: Colors.grey[300]),
                  const SizedBox(height: 4),
                  Container(width: 180, height: 12, color: Colors.grey[200]),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) => _buildShimmerCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _PriceDropCard extends StatelessWidget {
  final PriceDrop priceDrop;
  final VoidCallback? onTap;

  const _PriceDropCard({
    required this.priceDrop,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: priceDrop.fotograflar.isNotEmpty
                        ? Image.network(
                            priceDrop.fotograflar.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                // Discount badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_down, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '%${priceDrop.discountPercent.toStringAsFixed(0)} İNDİRİM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      priceDrop.baslik,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            priceDrop.location,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Price comparison
                    Row(
                      children: [
                        Text(
                          priceDrop.formattedOldPrice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          priceDrop.formattedPrice,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.home, size: 36, color: Colors.grey),
      ),
    );
  }
}
