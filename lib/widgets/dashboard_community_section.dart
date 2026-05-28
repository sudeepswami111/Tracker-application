import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/community_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'profile_avatar.dart';
import 'reply_bottom_sheet.dart';

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
  bool _cheered = false;
  bool _fired = false;
  List<String> _localReplies = [];

  void _showReplySheet(String authorName, String originalText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReplyBottomSheet(
        authorName: authorName,
        originalText: originalText,
        onReplySent: (String reply) {
          setState(() {
            _localReplies.add(reply);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply sent')),
          );
        },
      ),
    );
  }

  void _toggleReaction(String type) {
    setState(() {
      if (type == 'cheer') _cheered = !_cheered;
      if (type == 'fire') _fired = !_fired;
    });

    final isActive = type == 'cheer' ? _cheered : _fired;
    if (isActive) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == 'cheer' ? 'You cheered this activity! 👏' : 'You gave fire to this activity! 🔥',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
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
          if (_localReplies.isNotEmpty) ...[
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
                  ..._localReplies.map((reply) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.voltCyan)),
                        Expanded(child: Text(reply, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  )),
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
                label: 'Cheer',
                isActive: _cheered,
                activeColor: AppColors.teal,
                onTap: () => _toggleReaction('cheer'),
              ),
              const SizedBox(width: 16),
              _ReactionButton(
                icon: LucideIcons.flame,
                label: 'Fire',
                isActive: _fired,
                activeColor: AppColors.solarAmber,
                onTap: () => _toggleReaction('fire'),
              ),
              const Spacer(),
              _ReactionButton(
                icon: LucideIcons.messageSquare,
                label: _localReplies.isNotEmpty ? '${_localReplies.length} reply' : 'Reply',
                isActive: _localReplies.isNotEmpty,
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
