import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

import 'my_listings_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// PREMIUM PROFILE SCREEN — Stitch "Digital Curator" Design System
/// ═══════════════════════════════════════════════════════════════════════
///
/// Features:
/// - Navy-to-indigo gradient header with decorative circles
/// - BackdropFilter blur overlay + glassmorphism
/// - Gold-bordered avatar (100px) with camera button
/// - Overlapping stat cards (-30px)
/// - "No-Line Rule" menu sections with colored icon circles
/// - Ambient shadows (blur 24px, 6% opacity)
/// - Plus Jakarta Sans + Manrope dual-font system
/// ═══════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _myListingsCount = 0;
  int _favoritesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _myListingsCount = 0;
        _favoritesCount = 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final user = auth.currentUser;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Premium Gradient Header ───
              _buildPremiumHeader(context, user),

              // ─── Overlapping Stat Cards ───
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -36),
                  child: _buildStatsRow(context),
                ),
              ),

              // ─── Menu Sections ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hesabım section
                      _buildSectionTitle('Hesabım'),
                      const SizedBox(height: 12),
                      _buildAccountMenuCard(context),

                      const SizedBox(height: 28),

                      // Tercihler section
                      _buildSectionTitle('Tercihler'),
                      const SizedBox(height: 12),
                      _buildPreferencesMenuCard(context),

                      const SizedBox(height: 32),

                      // Logout button
                      _buildLogoutButton(context),

                      const SizedBox(height: 20),

                      // Version info
                      _buildVersionInfo(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PREMIUM HEADER — Navy gradient with glassmorphism
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPremiumHeader(BuildContext context, User? user) {
    final name = user != null
        ? '${user.ad} ${user.soyad}'.trim()
        : 'Kullanıcı';
    final email = user?.email ?? '';
    final photoUrl = user?.profilFotoUrl;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.primaryNavy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        // Edit profile icon button
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _navigateToEditProfile(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
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
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              // Medium circle bottom-left
              Positioned(
                bottom: 60,
                left: -50,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              // Small circle middle-right
              Positioned(
                top: 120,
                right: 50,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.goldAccent.withOpacity(0.08),
                  ),
                ),
              ),
              // Gold accent dots
              Positioned(
                top: 90,
                left: 30,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.goldAccent.withOpacity(0.3),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                right: 100,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ),

              // ─── Blur overlay ───
              if (photoUrl != null)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: AppTheme.primaryNavy.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),

              // ─── Profile Content ───
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar with gold border ring
                      _buildAvatar(name, photoUrl),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        name.isNotEmpty ? name : 'Kullanıcı',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),

                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // "Profili Düzenle" glass pill
                      GestureDetector(
                        onTap: () => _navigateToEditProfile(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: Colors.white.withOpacity(0.9),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Profili Düzenle',
                                style: GoogleFonts.manrope(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? photoUrl) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Gold border ring
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: photoUrl != null
                ? CachedNetworkImageProvider(photoUrl)
                : null,
            child: photoUrl == null
                ? Text(
                    _getInitials(name),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNavy,
                    ),
                  )
                : null,
          ),
        ),
        // Camera icon button
        Positioned(
          bottom: 2,
          right: 2,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUICK STATS ROW — Overlapping cards
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.home_work_rounded,
              iconGradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
              value: _isLoading ? '-' : '$_myListingsCount',
              label: 'Yayındaki\nİlanlar',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyListingsScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.favorite_rounded,
              iconGradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              value: _isLoading ? '-' : '$_favoritesCount',
              label: 'Favoriler',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.visibility_rounded,
              iconGradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
              value: '256',
              label: 'Görüntülenme',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION TITLE — Editorial style
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF191C1E),
        letterSpacing: -0.2,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ACCOUNT MENU — No-Line Rule, colored icon circles
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAccountMenuCard(BuildContext context) {
    return _PremiumMenuCard(
      items: [
        _MenuItem(
          icon: Icons.home_work_outlined,
          iconGradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
          title: 'İlanlarım',
          subtitle: 'Yayındaki ve pasif ilanlar',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyListingsScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.favorite_outline_rounded,
          iconGradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          title: 'Favorilerim',
          subtitle: 'Beğendiğiniz ilanlar',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.person_outline_rounded,
          iconGradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
          title: 'Profili Düzenle',
          subtitle: 'İsim, telefon ve fotoğraf',
          onTap: () => _navigateToEditProfile(context),
        ),
      ],
    );
  }

  Widget _buildPreferencesMenuCard(BuildContext context) {
    return _PremiumMenuCard(
      items: [
        _MenuItem(
          icon: Icons.settings_outlined,
          iconGradient: const [Color(0xFF9B59B6), Color(0xFF8E44AD)],
          title: 'Ayarlar',
          subtitle: 'Bildirimler, şifre ve tema',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        _MenuItem(
          icon: Icons.help_outline_rounded,
          iconGradient: const [Color(0xFFFB8C00), Color(0xFFFF7043)],
          title: 'Yardım & Destek',
          subtitle: 'SSS ve iletişim',
          onTap: () {},
        ),
        _MenuItem(
          icon: Icons.info_outline_rounded,
          iconGradient: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
          title: 'Hakkımızda',
          subtitle: 'Gizlilik ve kullanım koşulları',
          onTap: () => _showAboutPage(context),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LOGOUT BUTTON — Outlined, red accent
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6).withOpacity(0.3), // error_container subtle
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFBA1A1A).withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Color(0xFFBA1A1A),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Çıkış Yap',
              style: GoogleFonts.manrope(
                color: const Color(0xFFBA1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Text(
        'EsaEmlak v1.0.0',
        style: GoogleFonts.manrope(
          fontSize: 12,
          color: const Color(0xFFC6C5D4), // outline_variant
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NAVIGATION & DIALOGS
  // ═══════════════════════════════════════════════════════════════════

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Çıkış Yap',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF454652),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İptal',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF767683),
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Çıkış Yap',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  void _showAboutPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            title: Text(
              'Hakkımızda',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & App Name
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryNavy.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'EsaEmlak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      Text(
                        'Versiyon 1.0.0',
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF767683),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Mission
                _aboutSectionTitle('Misyonumuz'),
                const SizedBox(height: 8),
                Text(
                  'EsaEmlak, Türkiye\'nin en güvenilir emlak platformu olma vizyonuyla yola çıkmıştır. '
                  'Kullanıcılarımıza konut, iş yeri ve arsa aramanın yanı sıra ilan verme imkânı sunarak '
                  'emlak sektörünü dijitalleştirmeyi hedefliyoruz.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    height: 1.6,
                    color: const Color(0xFF454652),
                  ),
                ),
                const SizedBox(height: 24),

                // Features
                _aboutSectionTitle('Özellikler'),
                const SizedBox(height: 12),
                _aboutFeatureItem(Icons.search_rounded, 'Gelişmiş Arama', 'Konum, kategori ve filtrelerle kolayca arayın'),
                _aboutFeatureItem(Icons.map_rounded, 'Harita Üzerinden Arama', 'Çevrenizde emlakları haritadan keşfedin'),
                _aboutFeatureItem(Icons.add_circle_rounded, 'Kolay İlan Verme', 'Adım adım wizard ile hızlıca ilan oluşturun'),
                _aboutFeatureItem(Icons.favorite_rounded, 'Favoriler', 'Beğendiğiniz ilanları kaydedin'),
                _aboutFeatureItem(Icons.chat_rounded, 'Mesajlaşma', 'İlan sahipleriyle güvenle iletişim kurun'),
                const SizedBox(height: 24),

                // Legal
                _aboutSectionTitle('Yasal'),
                const SizedBox(height: 12),
                _aboutLegalItem('Kullanım Koşulları'),
                _aboutLegalItem('Gizlilik Politikası'),
                _aboutLegalItem('KVKK Aydınlatma Metni'),
                const SizedBox(height: 24),

                // Contact
                _aboutSectionTitle('İletişim'),
                const SizedBox(height: 12),
                _aboutContactItem(Icons.email_outlined, 'destek@esaemlak.com'),
                _aboutContactItem(Icons.phone_outlined, '+90 (555) 123 45 67'),
                _aboutContactItem(Icons.language_rounded, 'www.esaemlak.com'),
                const SizedBox(height: 32),

                // Footer
                Center(
                  child: Text(
                    '© 2026 EsaEmlak. Tüm hakları saklıdır.',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFFC6C5D4),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aboutSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryNavy,
      ),
    );
  }

  Widget _aboutFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryNavy, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF191C1E),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF767683),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutLegalItem(String title) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: const Color(0xFF767683), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF191C1E),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC6C5D4), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _aboutContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryNavy, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF454652),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STAT CARD — Ambient shadow, gradient icon, tonal surface
// ═══════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.iconGradient,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Ambient shadow — per Stitch: blur 24px, 6% opacity, tinted primary
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
            BoxShadow(
              color: const Color(0xFF191C1E).withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gradient icon circle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconGradient[0].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            // Value
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: const Color(0xFF767683),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PREMIUM MENU CARD — No-Line Rule, tonal layering
// ═══════════════════════════════════════════════════════════════════════

class _MenuItem {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _PremiumMenuCard extends StatelessWidget {
  final List<_MenuItem> items;

  const _PremiumMenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Ambient shadow
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF191C1E).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              // Menu item tile
              GestureDetector(
                onTap: item.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: index == 0 ? const Radius.circular(20) : Radius.zero,
                      bottom: isLast ? const Radius.circular(20) : Radius.zero,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Gradient icon circle
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: item.iconGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: item.iconGradient[0].withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Icon(item.icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF191C1E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: const Color(0xFF767683),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Chevron
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFC6C5D4),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              // Spacing instead of dividers (No-Line Rule)
              if (!isLast)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  color: const Color(0xFFF2F4F7), // Subtle tonal shift
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
