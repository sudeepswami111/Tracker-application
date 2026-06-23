import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';
import '../providers/app_provider.dart';
import '../widgets/chat/chat_segmented_control.dart';
import '../widgets/chat/chats_tab.dart';
import '../widgets/chat/community_tab.dart';
import '../widgets/create_post_sheet.dart';
import '../widgets/community_search_delegate.dart';
import 'new_message_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: Chats, 1: Community
  final ChatService _chatService = ChatService();

  List<ChatRoom> _chats = [];
  bool _isLoading = true;
  RealtimeChannel? _realtimeMessagesChannel;

  // Search Chat query
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';

  // Floating Action Button pulse animations (for Community compose)
  late AnimationController _fabPulseCtrl;
  late Animation<double> _fabPulseAnim;

  @override
  void initState() {
    super.initState();
    _loadChats();

    // Pulse animation for Community compose FAB
    _fabPulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fabPulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _fabPulseCtrl, curve: Curves.easeInOut));

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
    _fabPulseCtrl.dispose();
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
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      // ── CONDITIONAL FLOATING ACTION BUTTON FOR COMMUNITY ──
      floatingActionButton: _selectedTab == 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90.0), // Safely above bottom nav
              child: AnimatedBuilder(
                animation: _fabPulseAnim,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.irisViolet.withValues(alpha: 0.4 * (_fabPulseAnim.value - 0.8)),
                          blurRadius: 20 * _fabPulseAnim.value,
                          spreadRadius: 10 * _fabPulseAnim.value,
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const CreatePostSheet(),
                        );
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                      backgroundColor: AppColors.irisViolet,
                      elevation: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.irisViolet, Color(0xFF9D4EDD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.feather, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin, AppSpacing.lg, AppSpacing.screenMargin, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _showSearch
                      ? Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              onChanged: _onSearchChanged,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Search chats or messages...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'Chat',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                  Row(
                    children: [
                      _HeaderIconButton(
                        icon: _showSearch ? LucideIcons.x : LucideIcons.search,
                        onTap: () {
                          if (_selectedTab == 1) {
                            // Community tab active: delegate to CommunitySearchDelegate
                            showSearch(context: context, delegate: CommunitySearchDelegate());
                          } else {
                            // Chats tab active: toggle inline text field search
                            setState(() {
                              _showSearch = !_showSearch;
                              if (!_showSearch) {
                                _searchCtrl.clear();
                                _searchQuery = '';
                              }
                            });
                          }
                        },
                      ),
                      if (_selectedTab == 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _HeaderIconButton(
                          icon: LucideIcons.messageSquarePlus,
                          onTap: _openNewMessageScreen,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── SEGMENTED CONTROL ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: ChatSegmentedControl(
                selectedIndex: _selectedTab,
                onTabSelected: (index) {
                  setState(() {
                    _selectedTab = index;
                    _showSearch = false;
                    _searchCtrl.clear();
                    _searchQuery = '';
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
