import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/friend_models.dart';
import '../providers/friend_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class FriendSuggestionsCard extends StatefulWidget {
  const FriendSuggestionsCard({super.key});

  @override
  State<FriendSuggestionsCard> createState() => _FriendSuggestionsCardState();
}

class _FriendSuggestionsCardState extends State<FriendSuggestionsCard> {
  @override
  void initState() {
    super.initState();
    // Trigger load after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<FriendProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('People You May Know', style: theme.textTheme.headlineSmall),
            if (!provider.isLoading)
              GestureDetector(
                onTap: provider.refreshSuggestions,
                child: Icon(LucideIcons.refreshCw, size: 16, color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Incoming Requests Badge
        if (provider.incomingRequests.isNotEmpty)
          _buildIncomingRequestsBanner(provider, theme, isDark),

        // Loading Shimmer
        if (provider.isLoading)
          _buildShimmer(theme, isDark),

        // Error State
        if (provider.state == FriendProviderState.error)
          _buildError(theme),

        // Suggestions Carousel
        if (!provider.isLoading && provider.suggestions.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                final suggestion = provider.suggestions[i];
                return _FriendSuggestionTile(
                  suggestion: suggestion,
                  isSent: provider.sentRequestIds.contains(suggestion.profile.id),
                  isDark: isDark,
                  theme: theme,
                );
              },
            ),
          ),

        // Empty State
        if (!provider.isLoading &&
            provider.state == FriendProviderState.loaded &&
            provider.suggestions.isEmpty)
          _buildEmpty(theme, isDark),
      ],
    );
  }

  Widget _buildIncomingRequestsBanner(
      FriendProvider provider, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => _showIncomingRequests(context, provider, theme, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.voltCyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.voltCyan.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.userCheck, color: AppColors.voltCyan, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${provider.incomingRequests.length} pending friend request${provider.incomingRequests.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.voltCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.voltCyan, size: 16),
          ],
        ),
      ),
    );
  }

  void _showIncomingRequests(
      BuildContext context, FriendProvider provider, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: _IncomingRequestsSheet(theme: theme, isDark: isDark),
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => _ShimmerCard(isDark: isDark),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: AppColors.coral, size: 16),
          const SizedBox(width: 8),
          Text('Could not load suggestions',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.coral)),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.users, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text('No suggestions right now',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Individual Suggestion Tile ──────────────────────────────────────────────
class _FriendSuggestionTile extends StatelessWidget {
  final FriendSuggestion suggestion;
  final bool isSent;
  final bool isDark;
  final ThemeData theme;

  const _FriendSuggestionTile({
    required this.suggestion,
    required this.isSent,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    final profile = suggestion.profile;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          _buildAvatar(profile),
          const SizedBox(height: 10),

          // Name
          Text(
            profile.fullName.isNotEmpty ? profile.fullName : profile.username,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          // Match reason chip
          if (suggestion.matchReasons.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.voltCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                suggestion.matchReasons.first,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.voltCyan,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Score badge
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.zap, size: 10, color: AppColors.solarAmber),
              const SizedBox(width: 3),
              Text(
                '${suggestion.matchScore}% match',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.solarAmber, fontSize: 10),
              ),
            ],
          ),

          const Spacer(),

          // Actions Row
          Row(
            children: [
              // Dismiss
              GestureDetector(
                onTap: () => provider.dismiss(profile.id),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.x, size: 14, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              // Add / Sent
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSent
                        ? AppColors.textSecondary.withValues(alpha: 0.1)
                        : AppColors.voltCyan,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: isSent ? null : () => provider.sendRequest(profile.id),
                      child: Center(
                        child: isSent
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.check,
                                      size: 12,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Text('Sent',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(color: AppColors.textSecondary, fontSize: 10)),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.userPlus,
                                      size: 12, color: Colors.black),
                                  const SizedBox(width: 3),
                                  Text('Add',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(FitnessProfile profile) {
    final initials = profile.fullName.isNotEmpty
        ? profile.fullName.trim().split(' ').map((e) => e[0]).take(2).join()
        : profile.username.isNotEmpty
            ? profile.username[0].toUpperCase()
            : '?';

    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(profile.avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppColors.irisViolet.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.irisViolet,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─── Incoming Requests Bottom Sheet ─────────────────────────────────────────
class _IncomingRequestsSheet extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  const _IncomingRequestsSheet({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Friend Requests', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (provider.incomingRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No pending requests',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
              ),
            ),
          ...provider.incomingRequests.map((req) {
            final p = req.senderProfile;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.irisViolet.withValues(alpha: 0.15),
                    backgroundImage: p?.avatarUrl != null
                        ? NetworkImage(p!.avatarUrl!)
                        : null,
                    child: p?.avatarUrl == null
                        ? Text(
                            (p?.fullName.isNotEmpty == true
                                ? p!.fullName[0]
                                : p?.username[0] ?? '?'),
                            style: const TextStyle(
                                color: AppColors.irisViolet,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p?.fullName ?? 'Unknown',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (p?.fitnessGoal != null)
                          Text('Goal: ${p!.fitnessGoal}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => provider.rejectRequest(req.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x,
                          size: 14, color: AppColors.coral),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => provider.acceptRequest(req.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.voltCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.check,
                          size: 14, color: AppColors.voltCyan),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─── Shimmer Placeholder ─────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  final bool isDark;
  const _ShimmerCard({required this.isDark});
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (widget.isDark ? Colors.white : Colors.black)
              .withValues(alpha: _anim.value * 0.07),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: (widget.isDark ? Colors.white : Colors.black)
                  .withValues(alpha: _anim.value * 0.1),
            ),
            const SizedBox(height: 12),
            Container(
              height: 12,
              width: 100,
              decoration: BoxDecoration(
                color: (widget.isDark ? Colors.white : Colors.black)
                    .withValues(alpha: _anim.value * 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: 70,
              decoration: BoxDecoration(
                color: (widget.isDark ? Colors.white : Colors.black)
                    .withValues(alpha: _anim.value * 0.05),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
