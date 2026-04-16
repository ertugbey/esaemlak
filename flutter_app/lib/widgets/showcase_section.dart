import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';

/// A reusable horizontal showcase section for the homepage
/// Used for "Günün Fırsatları", "Acil Satılıklar", "Son Eklenenler" etc.
class ShowcaseSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Listing> listings;
  final bool showBadge;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback? onSeeAll;
  final Function(Listing) onListingTap;
  final double cardHeight;

  const ShowcaseSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.listings,
    this.showBadge = false,
    this.badgeText,
    this.badgeColor,
    this.onSeeAll,
    required this.onListingTap,
    this.cardHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Tümünü Gör', style: TextStyle(color: theme.colorScheme.primary)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Horizontal List
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return _ShowcaseCard(
                listing: listing,
                showBadge: showBadge,
                badgeText: badgeText,
                badgeColor: badgeColor,
                onTap: () => onListingTap(listing),
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  final Listing listing;
  final bool showBadge;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;
  final bool isDark;

  const _ShowcaseCard({
    required this.listing,
    required this.showBadge,
    this.badgeText,
    this.badgeColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: listing.fotograflar.isNotEmpty 
                        ? listing.fotograflar.first 
                        : 'https://via.placeholder.com/200x120?text=No+Image',
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.home, size: 40),
                    ),
                  ),
                ),
                // Badge (Acil Satılık, Fiyatı Düştü, etc.)
                if (showBadge || listing.acilSatilik || listing.fiyatiDustu)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: listing.acilSatilik 
                            ? Colors.red 
                            : listing.fiyatiDustu 
                                ? Colors.orange 
                                : (badgeColor ?? theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        listing.acilSatilik 
                            ? 'ACİL' 
                            : listing.fiyatiDustu 
                                ? 'FİYAT DÜŞTÜ' 
                                : (badgeText ?? ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // İşlem tipi badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: listing.islemTipi == 'satilik' 
                          ? Colors.green.withOpacity(0.9) 
                          : Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.islemTipiLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
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
                    // Price
                    Text(
                      listing.formattedPrice,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      listing.baslik,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Location & Details
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Features row
                    Row(
                      children: [
                        if (listing.odaSayisi != null) ...[
                          _MiniChip(icon: Icons.bed, label: listing.odaSayisi!),
                          const SizedBox(width: 6),
                        ],
                        if (listing.displayMetrekare > 0)
                          _MiniChip(icon: Icons.square_foot, label: '${listing.displayMetrekare} m²'),
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
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
