import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Collection of shimmer loading skeletons for various content types
class ShimmerLoading {
  ShimmerLoading._();

  /// Base colors for shimmer effect
  static Color get baseColor => Colors.grey[300]!;
  static Color get highlightColor => Colors.grey[100]!;
  static Color get baseColorDark => Colors.grey[700]!;
  static Color get highlightColorDark => Colors.grey[600]!;

  /// Builds shimmer with appropriate colors for current theme
  static Widget buildShimmer(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? baseColorDark : baseColor,
      highlightColor: isDark ? highlightColorDark : highlightColor,
      child: child,
    );
  }

  /// Generic box placeholder
  static Widget box({
    double? width,
    double? height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Circle placeholder for avatars
  static Widget circle({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Shimmer for listing cards in grid or list - Premium version
class ListingCardShimmerPremium extends StatelessWidget {
  final bool compact;
  
  const ListingCardShimmerPremium({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading.buildShimmer(
      context,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            AspectRatio(
              aspectRatio: compact ? 1.3 : 1.5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            
            // Content placeholder
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  ShimmerLoading.box(width: 100, height: 20, borderRadius: 4),
                  const SizedBox(height: 10),
                  
                  // Title
                  ShimmerLoading.box(height: 16, borderRadius: 4),
                  const SizedBox(height: 6),
                  ShimmerLoading.box(width: 150, height: 16, borderRadius: 4),
                  
                  const SizedBox(height: 10),
                  
                  // Info row
                  Row(
                    children: [
                      ShimmerLoading.box(width: 80, height: 14, borderRadius: 4),
                      const SizedBox(width: 12),
                      ShimmerLoading.box(width: 50, height: 14, borderRadius: 4),
                    ],
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

/// Shimmer for horizontal listing slider items
class SliderItemShimmer extends StatelessWidget {
  const SliderItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading.buildShimmer(
      context,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading.box(width: 80, height: 18, borderRadius: 4),
                  const SizedBox(height: 8),
                  ShimmerLoading.box(height: 14, borderRadius: 4),
                  const SizedBox(height: 4),
                  ShimmerLoading.box(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for profile header
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading.buildShimmer(
      context,
      child: Column(
        children: [
          // Cover area
          Container(
            height: 200,
            color: Colors.white,
          ),
          
          // Avatar
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                ShimmerLoading.circle(size: 80),
                const SizedBox(height: 12),
                ShimmerLoading.box(width: 150, height: 24),
                const SizedBox(height: 8),
                ShimmerLoading.box(width: 200, height: 14),
              ],
            ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < 2 ? 12 : 0,
                    ),
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Menu items
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer for detail page header/gallery
class DetailHeaderShimmer extends StatelessWidget {
  const DetailHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading.buildShimmer(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gallery
          Container(
            height: 280,
            color: Colors.white,
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price badge
                Container(
                  width: 150,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                ShimmerLoading.box(height: 24),
                const SizedBox(height: 8),
                ShimmerLoading.box(width: 200, height: 18),
                
                const SizedBox(height: 20),
                
                // Stats row
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Details section
                ShimmerLoading.box(width: 120, height: 20),
                const SizedBox(height: 12),
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ShimmerLoading.box(height: 44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer for message list items
class MessageItemShimmer extends StatelessWidget {
  const MessageItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading.buildShimmer(
      context,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            ShimmerLoading.circle(size: 50),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerLoading.box(width: 120, height: 16, borderRadius: 4),
                      ShimmerLoading.box(width: 40, height: 12, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ShimmerLoading.box(height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of shimmer cards
class ListingGridShimmer extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  
  const ListingGridShimmer({
    super.key,
    this.itemCount = 4,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const ListingCardShimmerPremium(compact: true),
    );
  }
}

/// Horizontal list of shimmer items
class HorizontalListShimmer extends StatelessWidget {
  final int itemCount;
  final double height;
  
  const HorizontalListShimmer({
    super.key,
    this.itemCount = 3,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (_, __) => const SliderItemShimmer(),
      ),
    );
  }
}
