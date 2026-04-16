import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../services/messaging_service.dart';
import '../models/models.dart';
import '../models/listing_enums.dart';
import '../data/category_data.dart';
import '../theme/app_theme.dart';
import '../widgets/listing_card.dart';
import '../widgets/category_cards.dart';
import 'filter_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// PREMIUM HOME SCREEN — Stitch "Architectural Editorial" Design System
/// ═══════════════════════════════════════════════════════════════════════
///
/// Design philosophy: "The Digital Curator"
/// - Editorial-first approach treating every listing like a feature
/// - Intentional asymmetry, generous white space
/// - Tonal layering instead of borders ("No-Line Rule")
/// - Ambient shadows (blur 32px, 6% opacity, tinted on-surface)
/// - Glassmorphism for floating elements
/// - Plus Jakarta Sans for headlines, Manrope for body
///
/// Theme: Navy (#1A237E) + Gold (#FFD700) + Off-White (#F5F7FA)
/// ═══════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  // Showcase data
  Map<String, List<Listing>>? _showcaseData;
  List<Listing> _recentListings = [];
  bool _isLoading = true;
  String _selectedSiralama = 'gelismis';

  // Navigation
  int _currentIndex = 0;

  // Header animation
  double _headerOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initMessaging();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _headerOpacity = (1.0 - (offset / 120)).clamp(0.0, 1.0);
    });
  }

  void _initMessaging() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.userId != null) {
      final messaging = context.read<MessagingService>();
      messaging.connect();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final showcase = await _api.getShowcase();
      final recent = await _api.getListings(skip: 0, limit: 10);

      if (mounted) {
        setState(() {
          _showcaseData = showcase;
          _recentListings = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _currentIndex == 0
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomePage(),
            _buildSearchPage(),
            _buildAddListingPage(),
            _buildMessagesPage(),
            _buildProfilePage(),
          ],
        ),
        bottomNavigationBar: _buildPremiumBottomNav(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HOME PAGE — Main scrollable content
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHomePage() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryNavy,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Premium Header with Navy Gradient
          _buildPremiumSliverAppBar(),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Category Cards — Circular gradient icons
                _buildSectionHeader(
                  '🏠 Kategoriler',
                  onTumuTap: () => _navigateToFilter(SearchFilter()),
                ),
                const SizedBox(height: 16),
                CategoryCards(onCategoryTap: (kategori) {
                  _navigateToFilter(SearchFilter(kategori: kategori));
                }),

                const SizedBox(height: 32),

                // ═══ GÜNÜN FIRSATLARI — Hero Carousel ═══
                if (_showcaseData?['gununFirsatlari']?.isNotEmpty ?? false) ...[
                  _buildSectionHeader(
                    '🔥 Günün Fırsatları',
                    subtitle: 'Kaçırmayın!',
                    onTumuTap: () => _navigateToFilter(SearchFilter()),
                  ),
                  const SizedBox(height: 16),
                  _buildHeroCarousel(_showcaseData!['gununFirsatlari']!),
                  const SizedBox(height: 32),
                ],

                // ═══ ACİL SATILIK — Horizontal Scroll ═══
                if (_showcaseData?['acilSatiliklar']?.isNotEmpty ?? false) ...[
                  _buildSectionHeader(
                    '⚡ Acil Satılıklar',
                    subtitle: 'Fırsatlar tükenmeden!',
                    onTumuTap: () => _navigateToFilter(
                      SearchFilter(acilSatilik: true),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHorizontalShowcase(
                    _showcaseData!['acilSatiliklar']!,
                    badgeText: 'ACİL',
                    badgeColor: const Color(0xFFE53935),
                  ),
                  const SizedBox(height: 32),
                ],

                // ═══ YENİ İLANLAR ═══
                if (_showcaseData?['yeniIlanlar']?.isNotEmpty ?? false) ...[
                  _buildSectionHeader(
                    '✨ Yeni İlanlar',
                    subtitle: 'Son eklenenler',
                    onTumuTap: () => _navigateToFilter(
                      SearchFilter(siralama: 'tarihYeni'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHorizontalShowcase(
                    _showcaseData!['yeniIlanlar']!,
                  ),
                  const SizedBox(height: 32),
                ],

                // ═══ EN ÇOK GÖRÜNTÜLENEN ═══
                if (_showcaseData?['populerIlanlar']?.isNotEmpty ?? false) ...[
                  _buildSectionHeader(
                    '👀 En Çok Görüntülenen',
                    subtitle: 'Popüler ilanlar',
                    onTumuTap: () => _navigateToFilter(
                      SearchFilter(siralama: 'gelismis'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHorizontalShowcase(
                    _showcaseData!['populerIlanlar']!,
                  ),
                  const SizedBox(height: 32),
                ],

                // ═══ TÜM İLANLAR — Grid with Sort ═══
                _buildAllListingsSection(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PREMIUM SLIVER APP BAR — Navy Gradient with Decorative Elements
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPremiumSliverAppBar() {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.ad ?? 'Ziyaretçi';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Günaydın' : (hour < 18 ? 'İyi günler' : 'İyi akşamlar');

    return SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryNavy,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D1442), // primaryNavyDark
                Color(0xFF1A237E), // primaryNavy
                Color(0xFF3949AB), // primaryNavyLight
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // ─── Decorative Elements ───
              // Large circle top-right
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              // Medium circle bottom-left
              Positioned(
                bottom: 40,
                left: -50,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              // Small circle middle-right
              Positioned(
                top: 80,
                right: 60,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.goldAccent.withOpacity(0.08),
                  ),
                ),
              ),
              // Gold accent dot
              Positioned(
                top: 100,
                left: 40,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.goldAccent.withOpacity(0.35),
                  ),
                ),
              ),

              // ─── Main Content ───
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 24,
                  right: 24,
                  bottom: 76,
                ),
                child: Opacity(
                  opacity: _headerOpacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Greeting
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting 👋',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Hayalinizdeki evi bulalım',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Logo & Notifications
                          Row(
                            children: [
                              // Logo Container
                              _buildHeaderIconButton(
                                child: Image.asset(
                                  'assets/logo.png',
                                  width: 26,
                                  height: 26,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.home_work_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Notification Bell
                              Stack(
                                children: [
                                  _buildHeaderIconButton(
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  Consumer<NotificationProvider>(
                                    builder: (context, notif, _) {
                                      if (notif.unreadCount == 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.goldAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${notif.unreadCount}',
                                            style: GoogleFonts.manrope(
                                              color: AppTheme.primaryNavyDark,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
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
      ),
      // ─── Search Bar (pinned at bottom) ───
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          height: 56,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: _buildPremiumSearchBar(),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PREMIUM SEARCH BAR — Glassmorphism with filter button
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPremiumSearchBar() {
    return GestureDetector(
      onTap: () => _navigateToFilter(SearchFilter()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          // Premium ambient shadow
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1E).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: const Color(0xFF767683),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Konum, kategori veya anahtar kelime...',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF767683),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION HEADER — Editorial style with optional subtitle
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, {String? subtitle, VoidCallback? onTumuTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF767683),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTumuTap != null)
            GestureDetector(
              onTap: onTumuTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tümü',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppTheme.primaryNavy,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HERO CAROUSEL — "Günün Fırsatları" premium pageview
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHeroCarousel(List<Listing> listings) {
    return _HeroCarouselWidget(
      listings: listings,
      onListingTap: _navigateToDetail,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HORIZONTAL SHOWCASE — Compact property cards
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHorizontalShowcase(
    List<Listing> listings, {
    String? badgeText,
    Color? badgeColor,
  }) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 16),
            child: _ShowcaseCard(
              listing: listings[index],
              badgeText: badgeText,
              badgeColor: badgeColor,
              onTap: () => _navigateToDetail(listings[index]),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ALL LISTINGS — Grid with Sort Dropdown
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAllListingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tüm İlanlar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              // Sort dropdown — tonal surface, no border
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSiralama,
                    icon: Icon(Icons.sort_rounded, size: 18, color: AppTheme.primaryNavy),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF454652),
                      fontWeight: FontWeight.w600,
                    ),
                    items: SiralamaSecenekleri.secenekler.map((s) {
                      return DropdownMenuItem(
                        value: s['id']!,
                        child: Text(s['label']!, style: GoogleFonts.manrope(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedSiralama = v);
                        _sortListings();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildListingsGrid(),
      ],
    );
  }

  Widget _buildListingsGrid() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => const ListingCardShimmer(showCompact: true),
        ),
      );
    }

    if (_recentListings.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: _recentListings.length,
        itemBuilder: (context, index) {
          return ListingCard(
            listing: _recentListings[index],
            showCompact: true,
            onTap: () => _navigateToDetail(_recentListings[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppTheme.goldAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Henüz ilan yok',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni ilanlar yakında burada olacak',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF767683),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PREMIUM BOTTOM NAV — Gold + button, tonal active state
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPremiumBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // Ambient shadow upward
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.explore_outlined, Icons.explore_rounded, 'Ana Sayfa'),
              _buildNavItem(1, Icons.search_outlined, Icons.search_rounded, 'Ara'),
              // ─── Gold "İlan Ver" Button ───
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/create-listing'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldAccent.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF0F172A),
                    size: 28,
                  ),
                ),
              ),
              _buildNavItem(3, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Mesajlar'),
              _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppTheme.primaryNavy : const Color(0xFF767683),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryNavy : const Color(0xFF767683),
              ),
            ),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 4),
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: const BoxDecoration(
                color: AppTheme.primaryNavy,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NAVIGATION & SORTING HELPERS
  // ═══════════════════════════════════════════════════════════════════

  void _navigateToDetail(Listing listing) {
    Navigator.pushNamed(context, '/listing/${listing.id}');
  }

  void _navigateToFilter(SearchFilter filter) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FilterScreen(initialFilter: filter)),
    );
  }

  void _sortListings() {
    setState(() {
      switch (_selectedSiralama) {
        case 'fiyatArtan':
          _recentListings.sort((a, b) => a.fiyat.compareTo(b.fiyat));
          break;
        case 'fiyatAzalan':
          _recentListings.sort((a, b) => b.fiyat.compareTo(a.fiyat));
          break;
        case 'tarihYeni':
          _recentListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'tarihEski':
          _recentListings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'adresAZ':
          _recentListings.sort((a, b) => a.il.compareTo(b.il));
          break;
        case 'adresZA':
          _recentListings.sort((a, b) => b.il.compareTo(a.il));
          break;
        default:
          _recentListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });
  }

  // Placeholder pages for navigation
  Widget _buildSearchPage() => FilterScreen(initialFilter: SearchFilter());

  Widget _buildAddListingPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('İlan Ver')),
      body: const Center(child: Text('İlan Ekleme Sayfası')),
    );
  }

  Widget _buildMessagesPage() => const MessagesScreen();
  Widget _buildProfilePage() => const ProfileScreen();
}

// ═══════════════════════════════════════════════════════════════════════
// HERO CAROUSEL WIDGET — Stitch-inspired property hero slider
// ═══════════════════════════════════════════════════════════════════════

class _HeroCarouselWidget extends StatefulWidget {
  final List<Listing> listings;
  final Function(Listing) onListingTap;

  const _HeroCarouselWidget({
    required this.listings,
    required this.onListingTap,
  });

  @override
  State<_HeroCarouselWidget> createState() => _HeroCarouselWidgetState();
}

class _HeroCarouselWidgetState extends State<_HeroCarouselWidget> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.listings.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index).abs();
                    value = (1 - (value * 0.08)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: Curves.easeOut.transform(value),
                    child: child!,
                  );
                },
                child: _HeroPropertyCard(
                  listing: widget.listings[index],
                  onTap: () => widget.onListingTap(widget.listings[index]),
                ),
              );
            },
          ),
        ),
        // Page indicators — pill-shaped, animated
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.listings.length.clamp(0, 6),
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 28 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppTheme.primaryNavy
                    : AppTheme.primaryNavy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HERO PROPERTY CARD — Large carousel card with overlay
// ═══════════════════════════════════════════════════════════════════════

class _HeroPropertyCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const _HeroPropertyCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Ambient shadow
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1E).withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 8),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: listing.fotograflar.isNotEmpty
                    ? listing.fotograflar.first
                    : 'https://via.placeholder.com/400x240',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFE6E8EB),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFE6E8EB),
                  child: const Icon(Icons.home_rounded, size: 60, color: Color(0xFFC6C5D4)),
                ),
              ),

              // Gradient overlay — editorial depth
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),

              // Content overlay
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price tag — Navy badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        listing.formattedPrice,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      listing.baslik,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.black.withOpacity(0.5)),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Location & details row
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: GoogleFonts.manrope(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (listing.odaSayisi != null) ...[
                          const SizedBox(width: 14),
                          _buildDetailChip(Icons.bed_rounded, listing.odaSayisi!),
                        ],
                        if (listing.displayMetrekare > 0) ...[
                          const SizedBox(width: 10),
                          _buildDetailChip(Icons.square_foot_rounded, '${listing.displayMetrekare} m²'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Badges (Acil / Fiyatı Düştü) — Glass chip
              if (listing.acilSatilik || listing.fiyatiDustu)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: listing.acilSatilik
                          ? const Color(0xFFE53935).withOpacity(0.9)
                          : const Color(0xFFFB8C00).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      listing.acilSatilik ? 'ACİL SATILIK' : 'FİYAT DÜŞTÜ',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Favorite button — top right
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    color: const Color(0xFF475569),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SHOWCASE CARD — Compact horizontal scroll card
// ═══════════════════════════════════════════════════════════════════════

class _ShowcaseCard extends StatelessWidget {
  final Listing listing;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _ShowcaseCard({
    required this.listing,
    this.badgeText,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Tonal layering — no hard shadows
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1E).withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: listing.fotograflar.isNotEmpty
                        ? listing.fotograflar.first
                        : 'https://via.placeholder.com/220x120',
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 130,
                      color: const Color(0xFFE6E8EB),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 130,
                      color: const Color(0xFFE6E8EB),
                      child: const Icon(Icons.home_rounded, size: 40, color: Color(0xFFC6C5D4)),
                    ),
                  ),
                ),
                // Badge
                if (badgeText != null || listing.acilSatilik || listing.fiyatiDustu)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: listing.acilSatilik
                            ? const Color(0xFFE53935)
                            : listing.fiyatiDustu
                                ? const Color(0xFFFB8C00)
                                : (badgeColor ?? AppTheme.primaryNavy),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        listing.acilSatilik
                            ? 'ACİL'
                            : listing.fiyatiDustu
                                ? 'FİYAT DÜŞTÜ'
                                : (badgeText ?? ''),
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                // İşlem tipi
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: listing.islemTipi == 'satilik'
                          ? AppTheme.primaryNavy.withOpacity(0.85)
                          : AppTheme.accentTeal.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      listing.islemTipiLabel,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Favorite heart — top right
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: Color(0xFF475569),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),

            // Content — no divider lines
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      listing.formattedPrice,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      listing.baslik,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF767683)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: const Color(0xFF767683),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Feature chips
                    Row(
                      children: [
                        if (listing.odaSayisi != null) ...[
                          _MiniChipWidget(icon: Icons.bed_rounded, label: listing.odaSayisi!),
                          const SizedBox(width: 8),
                        ],
                        if (listing.displayMetrekare > 0)
                          _MiniChipWidget(icon: Icons.square_foot_rounded, label: '${listing.displayMetrekare} m²'),
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

// ═══════════════════════════════════════════════════════════════════════
// MINI CHIP — Tonal surface, no borders
// ═══════════════════════════════════════════════════════════════════════

class _MiniChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChipWidget({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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


