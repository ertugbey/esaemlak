import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Reusable Empty State widget for various empty screens
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.iconBackgroundColor,
  });

  /// Preset for empty favorites
  factory EmptyState.favorites({VoidCallback? onExplore}) {
    return EmptyState(
      icon: Icons.favorite_outline,
      iconColor: Colors.pink,
      iconBackgroundColor: Colors.pink.withOpacity(0.1),
      title: 'Favori ilan bulunamadı',
      description: 'Beğendiğiniz ilanları favorilerinize ekleyin',
      buttonText: 'İlanları Keşfet',
      onButtonPressed: onExplore,
    );
  }

  /// Preset for empty search results
  factory EmptyState.searchResults({VoidCallback? onClearFilters}) {
    return EmptyState(
      icon: Icons.search_off,
      iconColor: AppTheme.goldAccent,
      iconBackgroundColor: AppTheme.goldAccent.withOpacity(0.1),
      title: 'Sonuç bulunamadı',
      description: 'Arama kriterlerinizi değiştirerek tekrar deneyin',
      buttonText: 'Filtreleri Temizle',
      onButtonPressed: onClearFilters,
    );
  }

  /// Preset for empty messages
  factory EmptyState.messages({VoidCallback? onExplore}) {
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      iconColor: AppTheme.accentTeal,
      iconBackgroundColor: AppTheme.accentTeal.withOpacity(0.1),
      title: 'Henüz mesaj yok',
      description: 'İlan sahipleriyle iletişime geçin',
      buttonText: 'İlan Ara',
      onButtonPressed: onExplore,
    );
  }

  /// Preset for empty listings (my listings)
  factory EmptyState.myListings({VoidCallback? onAddListing}) {
    return EmptyState(
      icon: Icons.add_home_outlined,
      iconColor: AppTheme.primaryNavy,
      iconBackgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
      title: 'Henüz ilan eklemediniz',
      description: 'İlk ilanınızı oluşturarak satışa başlayın',
      buttonText: 'İlan Ekle',
      onButtonPressed: onAddListing,
    );
  }

  /// Preset for empty notifications
  factory EmptyState.notifications() {
    return const EmptyState(
      icon: Icons.notifications_none,
      iconColor: Colors.orange,
      title: 'Bildirim yok',
      description: 'Yeni bildirimleriniz burada görünecek',
    );
  }

  /// Preset for comparison list
  factory EmptyState.comparison({VoidCallback? onExplore}) {
    return EmptyState(
      icon: Icons.compare_arrows,
      iconColor: AppTheme.primaryNavyLight,
      iconBackgroundColor: AppTheme.primaryNavyLight.withOpacity(0.1),
      title: 'Karşılaştırma listesi boş',
      description: 'İlan detayından "Karşılaştır" butonuna tıklayın',
      buttonText: 'İlan Ara',
      onButtonPressed: onExplore,
    );
  }

  /// Preset for error state
  factory EmptyState.error({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.error_outline,
      iconColor: AppTheme.errorRed,
      iconBackgroundColor: AppTheme.errorRed.withOpacity(0.1),
      title: 'Bir hata oluştu',
      description: 'Lütfen daha sonra tekrar deneyin',
      buttonText: 'Tekrar Dene',
      onButtonPressed: onRetry,
    );
  }

  /// Preset for no internet connection
  factory EmptyState.noConnection({VoidCallback? onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off,
      iconColor: Colors.grey,
      iconBackgroundColor: Colors.grey.withOpacity(0.1),
      title: 'İnternet bağlantısı yok',
      description: 'Lütfen bağlantınızı kontrol edin',
      buttonText: 'Tekrar Dene',
      onButtonPressed: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppTheme.goldAccent;
    final effectiveBgColor = iconBackgroundColor ?? effectiveIconColor.withOpacity(0.15);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.8, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: effectiveBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 56,
                  color: effectiveIconColor,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Description
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(buttonText!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
