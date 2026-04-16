import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/service_status_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/draft_listing_provider.dart';
import 'services/messaging_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/listing_detail_screen.dart';
import 'screens/filter_screen.dart';
import 'screens/register_screen.dart';
import 'screens/my_listings_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/map_search_screen.dart';
import 'screens/comparison_screen.dart';
import 'screens/store_page_screen.dart';
import 'screens/wizard/wizard_kategori_screen.dart';
import 'providers/comparison_provider.dart';
import 'models/models.dart';
import 'theme/app_theme.dart';

/// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const EmlaktanApp());
}

class EmlaktanApp extends StatelessWidget {
  const EmlaktanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ServiceStatusProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MessagingService()),
        ChangeNotifierProvider(create: (_) => ComparisonProvider()),
        ChangeNotifierProvider(create: (_) => DraftListingProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'EsaEmlak',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // Wrap home with MaintenanceOverlay
            home: const MaintenanceOverlay(child: AuthWrapper()),
            // Named routes for navigation
            onGenerateRoute: (settings) {
              // Listing detail route
              if (settings.name?.startsWith('/listings/') == true) {
                final listingId = settings.name!.replaceFirst('/listings/', '');
                return MaterialPageRoute(
                  builder: (_) => ListingDetailScreen(listingId: listingId),
                );
              }
              
              // Named routes
              switch (settings.name) {
                case '/create-listing':
                  return MaterialPageRoute(
                    builder: (_) => const WizardKategoriScreen(),
                  );
                case '/filter':
                  final filter = settings.arguments as SearchFilter? ?? SearchFilter();
                  return MaterialPageRoute(
                    builder: (_) => FilterScreen(initialFilter: filter),
                  );
                case '/register':
                  return MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  );
                case '/my-listings':
                  return MaterialPageRoute(
                    builder: (_) => const MyListingsScreen(),
                  );
                case '/map-search':
                  final filter = settings.arguments as SearchFilter?;
                  return MaterialPageRoute(
                    builder: (_) => MapSearchScreen(initialFilter: filter),
                  );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Defer auth check to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthProvider>();
    await auth.checkAuth();
    
    // If user is already logged in, connect to notifications
    if (auth.isLoggedIn) {
      _connectNotifications();
    }
    
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  /// Connect to notification hub when user is authenticated
  void _connectNotifications() {
    final notificationProvider = context.read<NotificationProvider>();
    
    // Setup navigation callback
    notificationProvider.onNavigateToListing = (listingId) {
      navigatorKey.currentState?.pushNamed('/listings/$listingId');
    };
    
    notificationProvider.connect();
    debugPrint('🔔 Notification connection initiated');
  }

  /// Disconnect from notification hub on logout
  void _disconnectNotifications() {
    final notificationProvider = context.read<NotificationProvider>();
    notificationProvider.disconnect();
    debugPrint('🔔 Notification connection terminated');
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Listen for auth state changes
        if (auth.isLoggedIn) {
          // Ensure notifications are connected when logged in
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final notificationProvider = context.read<NotificationProvider>();
            if (!notificationProvider.isConnected) {
              _connectNotifications();
            }
            // Set global context for toast notifications
            setGlobalContext(context);
          });
          return const HomeScreen();
        } else {
          // Disconnect notifications when logged out
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _disconnectNotifications();
          });
          return const LoginScreen();
        }
      },
    );
  }
}
