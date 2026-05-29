import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_provider.dart';
import '../services/community_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../models/community_reply.dart';
import '../models/community_reaction.dart';
import 'profile_avatar.dart';

class DashboardCommunitySection extends StatelessWidget {
  const DashboardCommunitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Community", style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        
        FutureBuilder<List<Map<String, dynamic>>>(
          future: CommunityService().getPosts(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildLoadingState(theme, isDark);
            }

            final posts = snap.data ?? [];
            if (posts.isEmpty) {
              return _buildEmptyState(theme, isDark, context);
            }

            // Calculate pulse
            final activeUsers = posts.map((p) => (p['author'] as Map?)?['id']).toSet().length;
            final workoutsShared = posts.length;

            return Column(
              children: [
                _CommunityPulseCard(
                  activeUsers: activeUsers,
                  workoutsShared: workoutsShared,
                ),
                const SizedBox(height: AppSpacing.md),
                ...posts.take(2).map((post) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _CommunityFeedCard(post: post),
                )),
              ],
            );
          },
        ),

        const SizedBox(height: AppSpacing.sm),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              context.read<AppProvider>().setTabIndex(3);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: isDark ? AppColors.borderSubtle : AppColors.lightOutline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'Open Community Hub',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Join challenges, posts, and friends',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.arrowRight, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.users, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            "No community updates yet",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Follow more people or share your progress.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<AppProvider>().setTabIndex(3),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.voltCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Explore Community', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _CommunityPulseCard extends StatelessWidget {
  final int activeUsers;
  final int workoutsShared;

  const _CommunityPulseCard({
    required this.activeUsers,
    required this.workoutsShared,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.voltCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.voltCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.activity, size: 18, color: AppColors.voltCyan),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activeUsers > 0 
                ? "$activeUsers people active · $workoutsShared workouts shared today"
                : "Community is warming up today",
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.voltCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityFeedCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const _CommunityFeedCard({required this.post});

  @override
  State<_CommunityFeedCard> createState() => _CommunityFeedCardState();
}

class _CommunityFeedCardState extends State<_CommunityFeedCard> {
  ReactionSummary _reactionSummary = const ReactionSummary();
  List<CommunityReply> _replies = [];
  RealtimeChannel? _reactionChannel;
  RealtimeChannel? _replyChannel;

  @override
  void initState() {
    super.initState();
    _loadReactions();
    _loadReplies();
    _setupRealtime();
  }

  Future<void> _loadReactions() async {
    final summary = await CommunityService().fetchReactionSummary(widget.post['id']);
    if (mounted) setState(() => _reactionSummary = summary);
  }

  Future<void> _loadReplies() async {
    final replies = await CommunityService().fetchRepliesForPost(widget.post['id']);
    if (mounted) setState(() => _replies = replies);
  }

  void _setupRealtime() {
    final postId = widget.post['id'];
    final client = Supabase.instance.client;

    _reactionChannel = client
      .channel('reactions_dash_$postId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'community_reactions',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'post_id', value: postId),
        callback: (payload) => _loadReactions(),
      )
      .subscribe();

    _replyChannel = client
      .channel('replies_dash_$postId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'community_replies',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'post_id', value: postId),
        callback: (payload) => _loadReplies(),
      )
      .subscribe();
  }

  @override
  void dispose() {
    _reactionChannel?.unsubscribe();
    _replyChannel?.unsubscribe();
    super.dispose();
  }

  void _showReplySheet(String authorName, String originalText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReplyBottomSheet(
        authorName: authorName,
        originalText: originalText,
        onReplySent: (String reply) async {
          final authorId = widget.post['user_id'];
          final added = await CommunityService().addReply(widget.post['id'], reply, postAuthorId: authorId);
          if (added != null && mounted) {
            setState(() {
              if (!_replies.any((r) => r.id == added.id)) {
                _replies.add(added);
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reply sent', style: TextStyle(color: Colors.white))),
            );
          }
        },
      ),
    );
  }

  void _showReplyOptions(CommunityReply reply) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != reply.userId) return; // Only allow delete for own replies

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppColors.pulseRed),
              title: const Text('Delete Reply', style: TextStyle(color: AppColors.pulseRed)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  setState(() => _replies.removeWhere((r) => r.id == reply.id));
                  await CommunityService().deleteReply(reply.id);
                } catch (_) {}
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReaction(String type) async {
    final wasCheered = _reactionSummary.hasCurrentUserCheered;
    final wasFired = _reactionSummary.hasCurrentUserFired;
    
    // Optimistic update
    setState(() {
      if (type == 'cheer') {
        _reactionSummary = _reactionSummary.copyWith(
          hasCurrentUserCheered: !wasCheered,
          cheerCount: _reactionSummary.cheerCount + (wasCheered ? -1 : 1),
        );
      } else {
        _reactionSummary = _reactionSummary.copyWith(
          hasCurrentUserFired: !wasFired,
          fireCount: _reactionSummary.fireCount + (wasFired ? -1 : 1),
        );
      }
    });

    try {
      final authorId = widget.post['user_id'];
      await CommunityService().toggleReaction(widget.post['id'], type, postAuthorId: authorId);
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          if (type == 'cheer') {
            _reactionSummary = _reactionSummary.copyWith(
              hasCurrentUserCheered: wasCheered,
              cheerCount: _reactionSummary.cheerCount + (wasCheered ? 1 : -1),
            );
          } else {
            _reactionSummary = _reactionSummary.copyWith(
              hasCurrentUserFired: wasFired,
              fireCount: _reactionSummary.fireCount + (wasFired ? 1 : -1),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authorMap = widget.post['author'] as Map<String, dynamic>?;
    final authorAvatar = authorMap?['avatar_url'] as String?;
    final authorName = authorMap?['full_name'] as String? ?? 'Someone';
    final rawContent = widget.post['content'] as String? ?? '';
    
    final parsedContent = _formatFeedText(rawContent, authorName);
    final badgeInfo = _buildActivityBadge(rawContent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              ProfileAvatar(
                imageUrl: authorAvatar,
                name: authorName,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Today', // Time fallback
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (badgeInfo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeInfo.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(badgeInfo.emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        badgeInfo.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: badgeInfo.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Content
          Text(
            parsedContent,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
          ),
          
          // Stats Row Mock (if it matches a workout)
          if (badgeInfo != null && ['Running', 'Workout', 'Yoga'].contains(badgeInfo.label)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.timer, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('30 min', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                const Icon(LucideIcons.zap, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('320 kcal', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          
          // Local Replies Preview
          if (_replies.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Replies', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._replies.take(2).map((reply) {
                    final isMe = reply.userId == Supabase.instance.client.auth.currentUser?.id;
                    final displayName = isMe ? 'You' : (reply.userName ?? 'User');
                    return GestureDetector(
                      onLongPress: () => _showReplyOptions(reply),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$displayName: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: isMe ? AppColors.voltCyan : AppColors.textPrimary)),
                            Expanded(child: Text(reply.replyText, style: theme.textTheme.bodyMedium)),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_replies.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: GestureDetector(
                        onTap: () => _showReplySheet(authorName, parsedContent),
                        child: Text('View all ${_replies.length} replies', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.voltCyan, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reactions
          Row(
            children: [
              _ReactionButton(
                icon: LucideIcons.thumbsUp,
                label: _reactionSummary.cheerCount > 0 ? '${_reactionSummary.cheerCount} Cheer' : 'Cheer',
                isActive: _reactionSummary.hasCurrentUserCheered,
                activeColor: AppColors.teal,
                onTap: () => _toggleReaction('cheer'),
              ),
              const SizedBox(width: 16),
              _ReactionButton(
                icon: LucideIcons.flame,
                label: _reactionSummary.fireCount > 0 ? '${_reactionSummary.fireCount} Fire' : 'Fire',
                isActive: _reactionSummary.hasCurrentUserFired,
                activeColor: AppColors.solarAmber,
                onTap: () => _toggleReaction('fire'),
              ),
              const Spacer(),
              _ReactionButton(
                icon: LucideIcons.messageSquare,
                label: _replies.isNotEmpty ? '${_replies.length} reply' : 'Reply',
                isActive: _replies.isNotEmpty,
                activeColor: AppColors.voltCyan,
                onTap: () => _showReplySheet(authorName, parsedContent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Parsing Helpers ---
  
  String _formatFeedText(String rawContent, String username) {
    // If the text starts with "username: ", strip it out
    String lowerRaw = rawContent.toLowerCase();
    String lowerName = username.toLowerCase();
    
    String cleanContent = rawContent;
    if (lowerRaw.startsWith('$lowerName:')) {
      cleanContent = rawContent.substring(lowerName.length + 1).trim();
    }

    if (cleanContent.toLowerCase() == 'running') return 'Completed a running workout';
    if (cleanContent.toLowerCase() == 'cycling') return 'Completed a cycling session';
    
    // Capitalize first letter
    if (cleanContent.isNotEmpty) {
      cleanContent = cleanContent[0].toUpperCase() + cleanContent.substring(1);
    }
    
    return cleanContent;
  }

  _BadgeInfo? _buildActivityBadge(String rawContent) {
    final lower = rawContent.toLowerCase();
    
    if (lower.contains('run')) {
      return _BadgeInfo('Running', '🏃', AppColors.pulseRed);
    }
    if (lower.contains('cycle') || lower.contains('bike')) {
      return _BadgeInfo('Cycling', '🚴', AppColors.irisViolet);
    }
    if (lower.contains('swim')) {
      return _BadgeInfo('Swimming', '🏊', AppColors.voltCyan);
    }
    if (lower.contains('yoga')) {
      return _BadgeInfo('Yoga', '🧘', AppColors.teal);
    }
    if (lower.contains('workout') || lower.contains('gym')) {
      return _BadgeInfo('Workout', '💪', AppColors.solarAmber);
    }
    if (lower.contains('study') || lower.contains('read')) {
      return _BadgeInfo('Study', '📚', AppColors.irisViolet);
    }
    if (lower.contains('streak')) {
      return _BadgeInfo('Streak', '🔥', AppColors.solarAmber);
    }
    if (lower.contains('water') || lower.contains('hydrate')) {
      return _BadgeInfo('Hydration', '💧', AppColors.voltCyan);
    }
    
    return null;
  }
}

class _BadgeInfo {
  final String label;
  final String emoji;
  final Color color;
  _BadgeInfo(this.label, this.emoji, this.color);
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : AppColors.textSecondary;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(
            icon, 
            size: 16, 
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
