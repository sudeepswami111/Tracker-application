import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../services/chat_service.dart';
import '../../models/chat_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/chat/chat_segmented_control.dart';
import '../../widgets/chat/chats_tab.dart';
import '../../widgets/chat/community_tab.dart';
import '../../widgets/create_post_sheet.dart';
import '../../widgets/community_search_delegate.dart';
import 'new_message_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: Chats, 1: Community
  String _selectedCategory = 'Messages';
  final List<String> _categories = ['All', 'Messages', 'Groups', 'Requests'];
  final ChatService _chatService = ChatService();

  List<ChatRoom> _chats = [];
  bool _isLoading = true;
  RealtimeChannel? _realtimeMessagesChannel;

  // Search Chat query
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChats();

    // Real-time reloading of chat lists when any message activity happens
    try {
      _realtimeMessagesChannel = Supabase.instance.client
          .channel('chats-realtime-reload')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'messages',
            callback: (_) {
              _loadChatsSilently();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[ChatHomeScreen] Realtime reload subscription error: $e');
    }
  }

  @override
  void dispose() {
    if (_realtimeMessagesChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_realtimeMessagesChannel!);
      } catch (_) {}
    }
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    final chats = await _chatService.getMyChats();
    if (mounted) {
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
      _updateGlobalUnreadCount(chats);
    }
  }

  Future<void> _loadChatsSilently() async {
    final chats = await _chatService.getMyChats();
    if (mounted) {
      setState(() {
        _chats = chats;
      });
      _updateGlobalUnreadCount(chats);
    }
  }

  void _updateGlobalUnreadCount(List<ChatRoom> chats) {
    final totalUnread = chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);
    context.read<AppProvider>().setUnreadChatCount(totalUnread);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _openNewMessageScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewMessageScreen()),
    ).then((_) => _loadChatsSilently());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // ── FLOATING ACTION BUTTON (TEAL CIRCLE +) ──
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // Safely above bottom nav
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              if (_selectedTab == 0) {
                _openNewMessageScreen();
              } else {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CreatePostSheet(),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              }
            },
            backgroundColor: AppColors.primaryTeal,
            elevation: 0,
            child: const Icon(LucideIcons.plus, color: Colors.white, size: 26),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER: Chat & Stay connected ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                14,
                AppSpacing.screenMargin,
                10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stay connected',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.neutralGray,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _HeaderIconButton(
                        icon: LucideIcons.messageSquarePlus,
                        onTap: _openNewMessageScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── SEARCH BAR ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: 6,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.zenDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.search, size: 18, color: AppColors.neutralGray),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search messages',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.neutralGray,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                        child: const Icon(LucideIcons.x, size: 16, color: AppColors.neutralGray),
                      ),
                  ],
                ),
              ),
            ),

            // ── CATEGORY PILLS (All, Messages, Groups, Requests) ──
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isActive = _selectedCategory == cat && _selectedTab == 0;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedCategory = cat;
                          _selectedTab = 0;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryTeal
                              : (isDark ? AppColors.zenDarkCard : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primaryTeal
                                : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isActive
                                  ? AppColors.primaryTeal.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.02),
                              blurRadius: isActive ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : (isDark ? Colors.white70 : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── SEGMENTED CONTROL (Chats | Community) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: 4),
              child: ChatSegmentedControl(
                selectedIndex: _selectedTab,
                onTabSelected: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
              ),
            ),
            const SizedBox(height: 6),

            // ── BODY ──
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  ChatsTab(
                    chats: _chats,
                    isLoading: _isLoading,
                    searchQuery: _searchQuery,
                    onRefresh: _loadChatsSilently,
                    onStartNewChat: _openNewMessageScreen,
                    onOpenCommunity: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                  ),
                  const CommunityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? AppColors.zenDarkCard : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 19,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}
