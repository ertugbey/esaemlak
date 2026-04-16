import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Premium Category cards with vibrant circular icons — Stitch-inspired design
/// "The Digital Curator" aesthetic with gradient circles and tonal layering
class CategoryCards extends StatelessWidget {
  final Function(String kategori) onCategoryTap;

  const CategoryCards({super.key, required this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final categories = [
      _CategoryItem(
        icon: Icons.home_rounded,
        label: 'Konut',
        gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        value: 'Konut',
      ),
      _CategoryItem(
        icon: Icons.store_rounded,
        label: 'İş Yeri',
        gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
        value: 'IsYeri',
      ),
      _CategoryItem(
        icon: Icons.landscape_rounded,
        label: 'Arsa',
        gradient: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
        value: 'Arsa',
      ),
      _CategoryItem(
        icon: Icons.apartment_rounded,
        label: 'Bina',
        gradient: [const Color(0xFFF093FB), const Color(0xFFF5576C)],
        value: 'Bina',
      ),
      _CategoryItem(
        icon: Icons.villa_rounded,
        label: 'Villa',
        gradient: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
        value: 'Villa',
      ),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _CategoryCircle(
            item: cat,
            onTap: () => onCategoryTap(cat.value),
          );
        },
      ),
    );
  }
}

class _CategoryCircle extends StatefulWidget {
  final _CategoryItem item;
  final VoidCallback onTap;

  const _CategoryCircle({required this.item, required this.onTap});

  @override
  State<_CategoryCircle> createState() => _CategoryCircleState();
}

class _CategoryCircleState extends State<_CategoryCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular gradient icon with ambient shadow
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.item.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.item.gradient[0].withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                widget.item.icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 10),
            // Label with Poppins font
            Text(
              widget.item.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final String value;

  _CategoryItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.value,
  });
}
