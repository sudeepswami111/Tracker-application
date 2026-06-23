import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';
import '../services/follow_service.dart';
import 'community_screen.dart';
import 'dm_chat_screen.dart';
import '../widgets/profile_avatar.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  int _selectedTab = 0; // 0: Chats, 1: Community
  final ChatService _chatService = ChatService();
  final FollowService _followService = FollowService();
  
  List<ChatRoom> _chats = [];
  bool _isLoading = true;
  RealtimeChannel? _realtimeMessagesChannel;

  // Search & Filter State
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';
  List<FollowUser> _searchResults = [];
  bool _loadingSearch = false;
  Timer? _searchDebounce;
  String? _activeFilter; // null or 'unread' or 'online' or 'streak' or 'buddies'

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
    _searchDebounce?.cancel();
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
    }
  }

  Future<void> _loadChatsSilently() async {
    final chats = await _chatService.getMyChats();
    if (mounted) {
      setState(() {
        _chats = chats;
      });
    }
  }

  // Debounced search for starting new chats with users
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _loadingSearch = false;
      });
      return;
    }
    setState(() => _loadingSearch = true);
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _followService.searchUsers(value.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _loadingSearch = false;
        });
      }
    });
  }

  bool _isFriendOnline(ChatRoom chat) {
    // Stable hash-based online check for consistent presentation across lists/chats
    return chat.friend.id.hashCode % 3 == 0 || (chat.unreadCount > 0);
  }

  bool _isStreakFriend(ChatRoom chat) {
    // Determine active streak friends deterministically
    return chat.friend.id.hashCode % 2 == 0;
  }

  void _showNewMessageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewMessageSheet(
        chatService: _chatService,
        followService: _followService,
      ),
    ).then((_) => _loadChatsSilently());
  }

  void _openChatWithUser(FollowUser user) async {
    final supabase = Supabase.instance.client;
    final me = supabase.auth.currentUser?.id ?? '';
    if (me.isEmpty) return;

    final u1 = me.compareTo(user.id) < 0 ? me : user.id;
    final u2 = me.compareTo(user.id) < 0 ? user.id : me;

    try {
      final res = await supabase
          .from('chats')
          .select('id')
          .eq('user1_id', u1)
          .eq('user2_id', u2)
          .maybeSingle();

      if (res == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              user.followStatus == FollowStatus.accepted
                  ? 'Waiting for ${user.username} to follow you back to unlock chat.'
                  : 'Follow @${user.username} and wait for them to accept to start chatting.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.irisViolet,
          ));
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DMChatScreen(
              chatId: res['id'] as String,
              otherUserName: user.fullName.isNotEmpty ? user.fullName : '@${user.username}',
              otherUserId: user.id,
            ),
          ),
        ).then((_) => _loadChatsSilently());
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
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
                                hintText: 'Search chats or username...',
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
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) {
                              _searchCtrl.clear();
                              _searchQuery = '';
                              _searchResults = [];
                            }
                          });
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _HeaderIconButton(
                        icon: LucideIcons.messageSquarePlus,
                        onTap: _showNewMessageSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── SEGMENTED CONTROL ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevated : Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton('Chats', 0),
                    _buildSegmentButton('Community', 1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── BODY ──
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildChatsTab(theme, isDark),
                  const CommunityScreen(isEmbedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String title, int index) {
    final isSelected = _selectedTab == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.irisViolet : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatsTab(ThemeData theme, bool isDark) {
    if (_showSearch && _searchQuery.trim().isNotEmpty) {
      return _buildSearchResultsTab(theme, isDark);
    }

    final filteredChats = _chats.where((chat) {
      if (_activeFilter == 'unread') {
        return chat.unreadCount > 0;
      }
      if (_activeFilter == 'buddies') {
        return chat.lastMessage != null;
      }
      if (_activeFilter == 'online') {
        return _isFriendOnline(chat);
      }
      if (_activeFilter == 'streak') {
        return _isStreakFriend(chat);
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: AppColors.irisViolet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SMART SHORTCUTS ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Row(
                children: [
                  _buildShortcutChip('Workout Buddies', LucideIcons.dumbbell, isDark, 'buddies'),
                  const SizedBox(width: 8),
                  _buildShortcutChip('Unread', LucideIcons.mail, isDark, 'unread'),
                  const SizedBox(width: 8),
                  _buildShortcutChip('Online', LucideIcons.circleDot, isDark, 'online', isOnline: true),
                  const SizedBox(width: 8),
                  _buildShortcutChip('Streak Friends', LucideIcons.flame, isDark, 'streak'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── CHATS LIST ──
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppColors.irisViolet),
                ),
              )
            else if (filteredChats.isEmpty)
              _buildEmptyState(theme, isDark)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: filteredChats.length,
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];
                  return _buildChatTile(chat, theme, isDark);
                },
              ),

            // ── COMMUNITY PREVIEW (Only if there are chats to show it at bottom) ──
            if (!_isLoading && _chats.isNotEmpty)
              _buildCommunityPreview(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsTab(ThemeData theme, bool isDark) {
    final localMatches = _chats.where((chat) =>
        chat.friend.displayName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (localMatches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: 12),
              child: Text(
                'Existing Chats',
                style: theme.textTheme.titleSmall?.copyWith(color: AppColors.voltCyan, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: localMatches.length,
              itemBuilder: (context, index) {
                return _buildChatTile(localMatches[index], theme, isDark);
              },
            ),
          ],
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: 12),
            child: Text(
              'Search Users by @username',
              style: theme.textTheme.titleSmall?.copyWith(color: AppColors.irisViolet, fontWeight: FontWeight.bold),
            ),
          ),
          
          if (_loadingSearch)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: AppColors.irisViolet),
              ),
            )
          else if (_searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              child: Center(
                child: Text(
                  'No users found for "${_searchQuery}"',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          imageUrl: user.avatarUrl,
                          name: user.fullName.isNotEmpty ? user.fullName : user.username,
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName.isNotEmpty ? user.fullName : user.username,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '@${user.username}',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.messageCircle, color: AppColors.voltCyan),
                          onPressed: () => _openChatWithUser(user),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatRoom chat, ThemeData theme, bool isDark) {
    final isOnline = _isFriendOnline(chat);
    final isStreak = _isStreakFriend(chat);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DMChatScreen(
              chatId: chat.chatId,
              otherUserId: chat.friend.id,
              otherUserName: chat.friend.displayName,
            ),
          ),
        ).then((_) => _loadChatsSilently());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin, vertical: AppSpacing.md),
        child: Row(
          children: [
            // Avatar with dynamic online indicator
            Stack(
              children: [
                ProfileAvatar(
                  imageUrl: chat.friend.avatarUrl,
                  name: chat.friend.displayName,
                  radius: 28,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.voltCyan,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            chat.friend.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: chat.unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
                            ),
                          ),
                          if (isStreak) ...[
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.flame, size: 14, color: AppColors.solarAmber),
                          ],
                        ],
                      ),
                      Text(
                        _formatMessageTime(chat.lastMessageAt ?? chat.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: chat.unreadCount > 0 
                              ? AppColors.voltCyan 
                              : (isDark ? Colors.white38 : Colors.black38),
                          fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'Tap to view conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: chat.unreadCount > 0 
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white60 : Colors.black54),
                            fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.voltCyan,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.messageCircle,
              size: 48,
              color: AppColors.irisViolet.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No conversations found',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start a chat with your fitness friends\nor use an icebreaker below!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildIcebreakerChip('How was your workout?', theme, isDark),
              _buildIcebreakerChip('Want to run together?', theme, isDark),
              _buildIcebreakerChip('Keep your streak alive 🔥', theme, isDark),
              _buildIcebreakerChip('Great progress today 💪', theme, isDark),
            ],
          ),
          const SizedBox(height: 60),
          _buildCommunityPreview(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildIcebreakerChip(String text, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCommunityPreview(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.irisViolet.withValues(alpha: 0.15),
              AppColors.voltCyan.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.irisViolet.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.irisViolet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.globe, color: AppColors.irisViolet),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Hub',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Join challenges, share progress, and cheer others',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedTab = 1;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Open Community'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0 && now.day == dateTime.day) {
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $amPm';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != dateTime.day)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  Widget _buildShortcutChip(String label, IconData icon, bool isDark, String filterKey, {bool isOnline = false}) {
    final isSelected = _activeFilter == filterKey;
    final activeColor = filterKey == 'online' ? AppColors.voltCyan : AppColors.irisViolet;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_activeFilter == filterKey) {
            _activeFilter = null; // Toggle off
          } else {
            _activeFilter = filterKey;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withValues(alpha: 0.2) 
              : (isDark ? AppColors.surfaceElevated : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : (isOnline ? AppColors.voltCyan : (isDark ? Colors.white54 : Colors.black54)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white70 : Colors.black87),
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

class _NewMessageSheet extends StatefulWidget {
  final ChatService chatService;
  final FollowService followService;

  const _NewMessageSheet({
    required this.chatService,
    required this.followService,
  });

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<FollowUser> _following = [];
  List<FollowUser> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadFollowing() async {
    final myId = widget.chatService.currentUserId;
    final following = await widget.followService.getFollowing(myId);
    if (mounted) {
      setState(() {
        _following = following;
        _filtered = following;
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _following.where((user) {
        return user.fullName.toLowerCase().contains(query) ||
            user.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'New Message',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search followed friends...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              filled: true,
              fillColor: isDark ? AppColors.surfaceElevated : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.irisViolet))
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'Follow friends to start chatting'
                              : 'No friends found matching query',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final user = _filtered[index];
                          final name = user.fullName.isNotEmpty ? user.fullName : user.username;
                          return ListTile(
                            leading: ProfileAvatar(
                              imageUrl: user.avatarUrl,
                              name: name,
                              radius: 20,
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('@${user.username}'),
                            trailing: const Icon(LucideIcons.messageCircle, color: AppColors.voltCyan, size: 20),
                            onTap: () async {
                              Navigator.pop(context);
                              try {
                                final chatId = await widget.chatService.getOrCreateDmChat(user.id);
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DMChatScreen(
                                        chatId: chatId,
                                        otherUserId: user.id,
                                        otherUserName: name,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Failed to start chat: $e'),
                                    backgroundColor: AppColors.pulseRed,
                                  ));
                                }
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
