import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Premium listing card with Stitch "Architectural Editorial" design system
/// Features: tonal layering, ambient shadows, glassmorphism badges, no hard borders
class ListingCard extends StatefulWidget {
  final Listing listing;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final bool showCompact;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.showCompact = false,
  });

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            // Ambient shadow — per Stitch design: blur 32px, 6% opacity, no pure black
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF191C1E).withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: const Color(0xFF191C1E).withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with glassmorphism overlays
              _buildImageSection(context),

              // Content - NO divider lines, use spacing + weight for hierarchy
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price - Premium highlight with Gold accent
                    _buildPriceRow(context),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      widget.listing.baslik,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: widget.showCompact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Location and features row
                    _buildInfoRow(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final imageUrl = widget.listing.fotograflar.isNotEmpty
        ? widget.listing.fotograflar.first
        : null;

    return Stack(
      children: [
        // Image with smooth rounded top
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AspectRatio(
            aspectRatio: widget.showCompact ? 1.3 : 1.5,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildBlurHashOrShimmer(),
                    errorWidget: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),

        // Subtle gradient vignette at bottom of image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.15),
                ],
              ),
            ),
          ),
        ),

        // Favorite button — Glassmorphism style
        Positioned(
          top: 10,
          right: 10,
          child: _buildFavoriteButton(context),
        ),

        // Image count badge — glass chip
        if (widget.listing.fotograflar.length > 1)
          Positioned(
            bottom: 10,
            right: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.listing.fotograflar.length}',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Transaction type badge — Floating Glass Chip
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.listing.islemTipi == 'satilik'
                  ? AppTheme.primaryNavy.withOpacity(0.85)
                  : AppTheme.accentTeal.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.listing.islemTipiLabel,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.onFavorite,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          // Ambient shadow
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1E).withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(widget.isFavorite),
            color: widget.isFavorite ? const Color(0xFFE53935) : const Color(0xFF475569),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.listing.formattedPrice,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryNavy,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (widget.listing.kategori.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.listing.kategoriLabel,
              style: GoogleFonts.manrope(
                color: AppTheme.goldAccentDark,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    final features = <Widget>[];

    // Location
    features.add(
      Expanded(
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, size: 14, color: const Color(0xFF767683)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.listing.shortLocation,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF454652),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Rooms
    if (widget.listing.odaSayisi != null) {
      features.add(
        _FeatureChip(icon: Icons.bed_outlined, label: widget.listing.odaSayisi!),
      );
      features.add(const SizedBox(width: 8));
    }

    // Size
    features.add(
      _FeatureChip(
        icon: Icons.square_foot_rounded,
        label: '${widget.listing.displayMetrekare} m²',
      ),
    );

    return Row(children: features);
  }

  /// Uses BlurHash for premium placeholder if available, falls back to shimmer
  Widget _buildBlurHashOrShimmer() {
    final hash = widget.listing.blurHashler.isNotEmpty
        ? widget.listing.blurHashler.first
        : null;
    if (hash != null && hash.length >= 6) {
      return BlurHash(hash: hash, imageFit: BoxFit.cover);
    }
    return _buildShimmer();
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6E8EB),
      highlightColor: const Color(0xFFF2F4F7),
      child: Container(color: Colors.white),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFECEEF1),
      child: Center(
        child: Icon(Icons.home_outlined, size: 48, color: const Color(0xFFC6C5D4)),
      ),
    );
  }
}

/// Small feature chip (no borders - "No-Line Rule")
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF767683)),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: const Color(0xFF454652),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension for short location
extension on Listing {
  String get shortLocation {
    if (ilce.isNotEmpty && il.isNotEmpty) {
      return '$ilce, $il';
    }
    return location;
  }
}

/// Shimmer loading placeholder for listing card
class ListingCardShimmer extends StatelessWidget {
  final bool showCompact;

  const ListingCardShimmer({super.key, this.showCompact = false});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6E8EB),
      highlightColor: const Color(0xFFF2F4F7),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            AspectRatio(
              aspectRatio: showCompact ? 1.3 : 1.5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
