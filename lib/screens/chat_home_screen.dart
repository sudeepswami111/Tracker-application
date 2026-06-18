import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';
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
  List<ChatRoom> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
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
                  Text(
                    'Chat',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      _HeaderIconButton(
                        icon: LucideIcons.search,
                        onTap: () {
                          // Search logic
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _HeaderIconButton(
                        icon: LucideIcons.messageSquarePlus,
                        onTap: () {
                          // New message logic
                        },
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
    return RefreshIndicator(
      onRefresh: _loadChats,
      color: AppColors.irisViolet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 140), // Safe bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SMART SHORTCUTS ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Row(
                children: [
                  _buildShortcutChip('Workout Buddies', LucideIcons.dumbbell, isDark),
                  const SizedBox(width: 8),
                  _buildShortcutChip('Unread', LucideIcons.mail, isDark),
                  const SizedBox(width: 8),
                  _buildShortcutChip('Online', LucideIcons.circleDot, isDark, isOnline: true),
                  const SizedBox(width: 8),
                  _buildShortcutChip('Streak Friends', LucideIcons.flame, isDark),
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
            else if (_chats.isEmpty)
              _buildEmptyState(theme, isDark)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
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

  Widget _buildChatTile(ChatRoom chat, ThemeData theme, bool isDark) {
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
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin, vertical: AppSpacing.md),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                ProfileAvatar(
                  imageUrl: chat.friend.avatarUrl,
                  name: chat.friend.displayName,
                  radius: 28,
                ),
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
                      Text(
                        chat.friend.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: chat.unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
                        ),
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
            'No conversations yet',
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
          // Icebreakers
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
      // Same day
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

  Widget _buildShortcutChip(String label, IconData icon, bool isDark, {bool isOnline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isOnline ? AppColors.voltCyan : (isDark ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
