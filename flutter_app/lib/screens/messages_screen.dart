import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/messaging_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// PREMIUM MESSAGES SCREEN — Stitch "Digital Curator" Design System
/// ═══════════════════════════════════════════════════════════════════════
///
/// WhatsApp/Telegram premium style with:
/// - Tonal layering (No-Line Rule) instead of dividers
/// - Gold accent bar for unread conversations
/// - Ambient shadows, glassmorphism FAB
/// - Plus Jakarta Sans headlines, Manrope body
/// - Navy (#1A237E) unread badges
/// ═══════════════════════════════════════════════════════════════════════

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;
  String? _error;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messagingService = context.read<MessagingService>();
      await messagingService.connect();
      await messagingService.getConversations();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Premium Header ───
            _buildHeader(),
            
            // ─── Search Bar (collapsible) ───
            _buildSearchBar(),
            
            // ─── Conversation List ───
            Expanded(
              child: Consumer<MessagingService>(
                builder: (context, messagingService, child) {
                  if (_isLoading) return _buildLoadingState();
                  if (_error != null) return _buildErrorState();
                  if (messagingService.conversations.isEmpty) return _buildEmptyState();

                  return RefreshIndicator(
                    onRefresh: _loadConversations,
                    color: AppTheme.primaryNavy,
                    backgroundColor: Colors.white,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                      itemCount: messagingService.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = messagingService.conversations[index];
                        return _PremiumConversationTile(
                          conversation: conversation,
                          onTap: () => _openChat(conversation),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // ─── Navy Gradient FAB ───
      floatingActionButton: _buildPremiumFAB(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HEADER — Clean, editorial style
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'Mesajlar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF191C1E),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Search toggle
          _buildHeaderAction(
            icon: Icons.search_rounded,
            onTap: () => setState(() => _showSearch = !_showSearch),
          ),
          const SizedBox(width: 8),
          // More options
          _buildHeaderAction(
            icon: Icons.more_vert_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF454652),
          size: 20,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEARCH BAR — Tonal surface, ghost border on focus
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: _showSearch ? 60 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showSearch ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFECEEF1), // surface_container
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF767683), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Sohbet ara...',
                      hintStyle: GoogleFonts.manrope(
                        color: const Color(0xFF767683),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LOADING, ERROR, EMPTY STATES
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mesajlar yükleniyor...',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF767683),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium icon container
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0FF), // primary_fixed
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz mesajınız yok',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlan sahipleriyle iletişime geçtiğinizde\nmesajlarınız burada görünecek',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF767683),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Eski Konuşmalar hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 16, color: const Color(0xFF767683)),
                  const SizedBox(width: 8),
                  Text(
                    'Arşivlediğiniz mesajlar burada görünmez',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF767683),
                      fontWeight: FontWeight.w500,
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6), // error_container
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Color(0xFFBA1A1A),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Mesajlar yüklenemedi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bağlantınızı kontrol edip tekrar deneyin',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF767683),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadConversations,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Tekrar Dene',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PREMIUM FAB — Navy gradient with new chat icon
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPremiumFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: const Icon(
        Icons.chat_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════

  void _openChat(Conversation conversation) {
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.currentUser?.id ?? '';
    final otherUserName = conversation.otherUserName ?? 'Kullanıcı';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation.id,
          otherUserName: otherUserName,
          otherUserAvatar: conversation.otherUserAvatar,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PREMIUM CONVERSATION TILE — Stitch "Digital Curator" style
// ═══════════════════════════════════════════════════════════════════════

class _PremiumConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _PremiumConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          // Tonal surface shift for unread items
          color: hasUnread
              ? const Color(0xFFFFFFFF) // surface_container_lowest — "lifted"
              : const Color(0xFFF2F4F7), // surface_container_low — "recessed"
          borderRadius: BorderRadius.circular(16),
          // Ambient shadow for unread
          boxShadow: hasUnread
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ─── Gold accent bar for unread ───
              if (hasUnread)
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

              // ─── Avatar with online indicator ───
              Padding(
                padding: EdgeInsets.fromLTRB(
                  hasUnread ? 12 : 16,
                  14,
                  12,
                  14,
                ),
                child: _buildAvatar(),
              ),

              // ─── Content area ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top row: Name + Timestamp
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.otherUserName ?? 'Kullanıcı',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                color: const Color(0xFF191C1E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.lastMessageAt != null)
                            Text(
                              _formatTime(conversation.lastMessageAt!),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: hasUnread
                                    ? AppTheme.primaryNavy
                                    : const Color(0xFF767683),
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Bottom row: Message preview + Unread badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage ?? 'Yeni sohbet',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: hasUnread
                                    ? const Color(0xFF454652)
                                    : const Color(0xFF767683),
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            // Navy unread badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryNavy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildAvatar() {
    final name = conversation.otherUserName ?? 'U';
    final hasAvatar = conversation.otherUserAvatar != null;

    // Generate gradient for initials avatar
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
    ];
    final gradientIndex = name.hashCode.abs() % gradients.length;

    return Stack(
      children: [
        // Avatar circle
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: !hasAvatar
                ? LinearGradient(
                    colors: gradients[gradientIndex],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF191C1E).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: hasAvatar
              ? ClipOval(
                  child: Image.network(
                    conversation.otherUserAvatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitialsAvatar(name, gradients[gradientIndex]),
                  ),
                )
              : _buildInitialsAvatar(name, gradients[gradientIndex]),
        ),
        // Online status dot
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF43A047), // success green
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String name, List<Color> gradient) {
    return Center(
      child: Text(
        _getInitials(name),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inDays > 1) {
      return '${difference.inDays}g önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inHours > 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d önce';
    }
    return 'Şimdi';
  }
}
