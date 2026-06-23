import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../services/follow_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/profile_avatar.dart';
import '../../screens/profile_screen.dart';
import 'recent_chat_tile.dart';

class ChatsTab extends StatefulWidget {
  final List<ChatRoom> chats;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onStartNewChat;
  final VoidCallback onOpenCommunity;
  final String searchQuery;

  const ChatsTab({
    super.key,
    required this.chats,
    required this.isLoading,
    required this.onRefresh,
    required this.onStartNewChat,
    required this.onOpenCommunity,
    required this.searchQuery,
  });

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  final FollowService _followService = FollowService();
  final ChatService _chatService = ChatService();
  List<FollowUser> _following = [];
  bool _loadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final myId = _chatService.currentUserId;
    if (myId.isEmpty) return;
    try {
      final following = await _followService.getFollowing(myId);
      if (mounted) {
        setState(() {
          _following = following;
          _loadingFollowing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingFollowing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter chats locally based on search query (name or last message)
    final filteredChats = widget.chats.where((chat) {
      if (widget.searchQuery.trim().isEmpty) return true;
      final q = widget.searchQuery.toLowerCase();
      final nameMatches = chat.friend.displayName.toLowerCase().contains(q);
      final msgMatches = chat.lastMessage != null && chat.lastMessage!.toLowerCase().contains(q);
      return nameMatches || msgMatches;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
        await _loadFollowing();
      },
      color: AppColors.irisViolet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Active Friends Row (Online Status) ──
            if (!_loadingFollowing && _following.isNotEmpty && widget.searchQuery.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: AppSpacing.sm),
                child: Text(
                  'Active Friends',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                  itemCount: _following.length,
                  itemBuilder: (context, index) {
                    final friend = _following[index];
                    final name = friend.fullName.isNotEmpty ? friend.fullName : friend.username;
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(targetUserId: friend.id),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            ProfileAvatar(
                              imageUrl: friend.avatarUrl,
                              name: name,
                              radius: 24,
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 64,
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'Active recently',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 8,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Chats List ──
            if (widget.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppColors.irisViolet),
                ),
              )
            else if (filteredChats.isEmpty)
              _buildEmptyState(theme, isDark)
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: AppSpacing.sm),
                child: Text(
                  'Recent Chats',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: filteredChats.length,
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];
                  return RecentChatTile(
                    chat: chat,
                    onRefresh: widget.onRefresh,
                  );
                },
              ),
            ],

            // ── Community Preview Card at bottom ──
            if (!widget.isLoading && widget.chats.isNotEmpty && widget.searchQuery.isEmpty)
              _buildCommunityPreview(theme, isDark),
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
            'Start chatting with your fitness friends\nand share your goals!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: widget.onStartNewChat,
            icon: const Icon(LucideIcons.messageSquarePlus, size: 18),
            label: const Text('Start New Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.irisViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildCommunityPreview(theme, isDark),
        ],
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
                onPressed: widget.onOpenCommunity,
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
}
