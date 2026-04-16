import 'dart:async';
import 'package:flutter/material.dart';

/// Global key for showing notification toasts from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Service for showing in-app notification toasts
class NotificationToastService {
  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;

  /// Show a price change notification toast
  static void showPriceAlert({
    required BuildContext context,
    required String listingId,
    required String listingTitle,
    required double oldPrice,
    required double newPrice,
    required bool isPriceReduced,
    VoidCallback? onViewPressed,
  }) {
    _dismissCurrentOverlay();

    final overlay = Overlay.of(context);
    final changePercent = ((newPrice - oldPrice).abs() / oldPrice * 100);

    _currentOverlay = OverlayEntry(
      builder: (context) => _NotificationToastWidget(
        listingTitle: listingTitle,
        oldPrice: oldPrice,
        newPrice: newPrice,
        changePercent: changePercent,
        isPriceReduced: isPriceReduced,
        onViewPressed: () {
          _dismissCurrentOverlay();
          onViewPressed?.call();
        },
        onDismiss: _dismissCurrentOverlay,
      ),
    );

    overlay.insert(_currentOverlay!);

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _dismissCurrentOverlay();
    });
  }

  static void _dismissCurrentOverlay() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _NotificationToastWidget extends StatefulWidget {
  final String listingTitle;
  final double oldPrice;
  final double newPrice;
  final double changePercent;
  final bool isPriceReduced;
  final VoidCallback? onViewPressed;
  final VoidCallback? onDismiss;

  const _NotificationToastWidget({
    required this.listingTitle,
    required this.oldPrice,
    required this.newPrice,
    required this.changePercent,
    required this.isPriceReduced,
    this.onViewPressed,
    this.onDismiss,
  });

  @override
  State<_NotificationToastWidget> createState() => _NotificationToastWidgetState();
}

class _NotificationToastWidgetState extends State<_NotificationToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M TL';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K TL';
    }
    return '${price.toStringAsFixed(0)} TL';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPriceDown = widget.isPriceReduced;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPriceDown
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isPriceDown ? Colors.green : Colors.orange).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPriceDown ? Icons.trending_down : Icons.trending_up,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPriceDown ? '📉 Fiyat Düştü!' : '📈 Fiyat Güncellendi',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                widget.listingTitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Close button
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Price change row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatPrice(widget.oldPrice),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _formatPrice(widget.newPrice),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${isPriceDown ? '-' : '+'}${widget.changePercent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onViewPressed,
                        icon: const Icon(Icons.visibility, size: 18),
                        label: Text(isPriceDown ? 'İndirimi Gör' : 'İlanı Gör'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isPriceDown 
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
