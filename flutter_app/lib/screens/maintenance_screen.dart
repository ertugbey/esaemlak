import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/service_status_provider.dart';

/// Beautiful maintenance mode screen with Material 3 design
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusProvider = context.watch<ServiceStatusProvider>();
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.9),
              theme.colorScheme.secondary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated maintenance icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(seconds: 1),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForError(statusProvider.errorCode),
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                _getTitleForError(statusProvider.errorCode),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  statusProvider.maintenanceMessage.isNotEmpty
                      ? statusProvider.maintenanceMessage
                      : 'Servislerimiz şu an bakımdadır.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Retry button
              FilledButton.tonal(
                onPressed: () {
                  statusProvider.dismissMaintenance();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Tekrar Dene'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Error code (subtle)
              if (statusProvider.errorCode != 0)
                Text(
                  'Hata Kodu: ${statusProvider.errorCode}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getIconForError(int errorCode) {
    switch (errorCode) {
      case 429:
        return Icons.hourglass_empty;
      case 502:
      case 503:
      case 504:
        return Icons.engineering;
      case 500:
        return Icons.error_outline;
      default:
        return Icons.cloud_off;
    }
  }
  
  String _getTitleForError(int errorCode) {
    switch (errorCode) {
      case 429:
        return 'Çok Hızlı! 🚀';
      case 502:
      case 503:
      case 504:
        return 'Bakım Modu 🔧';
      case 500:
        return 'Bir Sorun Oluştu';
      default:
        return 'Bağlantı Sorunu';
    }
  }
}

/// Overlay widget that wraps the app and shows maintenance screen when needed
class MaintenanceOverlay extends StatelessWidget {
  final Widget child;
  
  const MaintenanceOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceStatusProvider>(
      builder: (context, statusProvider, _) {
        if (statusProvider.isMaintenanceMode) {
          return const MaintenanceScreen();
        }
        return child;
      },
    );
  }
}
