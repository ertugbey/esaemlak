import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Custom price tag marker for flutter_map
/// Shows listing price in a Material 3 styled badge
class PriceTagMarker extends StatelessWidget {
  final double price;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? listingType; // 'Satılık' or 'Kiralık'

  const PriceTagMarker({
    super.key,
    required this.price,
    this.isSelected = false,
    this.onTap,
    this.listingType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRental = listingType == 'Kiralık';
    
    final primaryColor = isSelected 
        ? theme.colorScheme.primary
        : isRental 
            ? theme.colorScheme.tertiary
            : theme.colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price tag body
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatPrice(price),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '₺',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Arrow pointer
            CustomPaint(
              size: const Size(12, 8),
              painter: _ArrowPainter(color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return NumberFormat('#,###', 'tr_TR').format(price);
  }
}

/// Arrow painter for price tag pointer
class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cluster marker for multiple listings in same area
class ClusterMarker extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const ClusterMarker({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : count.toString(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
