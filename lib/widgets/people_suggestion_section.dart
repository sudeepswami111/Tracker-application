import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../services/follow_service.dart'; // adjust path

// ─────────────────────────────────────────────────────────────────
// PEOPLE SUGGESTION SECTION
// Instagram-style horizontal scroll of suggested users.
// Shows: avatar, name, username, follow status button.
// ─────────────────────────────────────────────────────────────────
class PeopleSuggestionSection extends StatefulWidget {
  const PeopleSuggestionSection({super.key});

  @override
  State<PeopleSuggestionSection> createState() =>
      _PeopleSuggestionSectionState();
}

class _PeopleSuggestionSectionState extends State<PeopleSuggestionSection> {
  final _followService = FollowService();
  List<FollowUser> _suggestions = [];
  bool _loading = true;

  // Track which user IDs are mid-request
  final Set<String> _pendingActions = {};
  // Local override of follow status (so UI responds instantly)
  final Map<String, FollowStatus> _statusOverride = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await _followService.getSuggestions(limit: 20);
    if (mounted) setState(() { _suggestions = s; _loading = false; });
  }

  FollowStatus _statusFor(FollowUser u) =>
      _statusOverride[u.id] ?? u.followStatus;

  Future<void> _handleFollow(FollowUser user) async {
    if (_pendingActions.contains(user.id)) return;
    HapticFeedback.mediumImpact();

    setState(() => _pendingActions.add(user.id));

    final current = _statusFor(user);

    if (current == FollowStatus.none) {
      final id = await _followService.sendFollowRequest(user.id);
      if (id != null && mounted) {
        setState(() => _statusOverride[user.id] = FollowStatus.pending);
      }
    } else if (current == FollowStatus.pending ||
        current == FollowStatus.accepted) {
      await _followService.unfollow(user.id);
      if (mounted) {
        setState(() {
          _statusOverride[user.id] = FollowStatus.none;
          // Remove from suggestions list after unfollow if we want to keep it clean
        });
      }
    }

    if (mounted) setState(() => _pendingActions.remove(user.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return SizedBox(
        height: 200,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'People suggestions',
                  style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TextButton(
              onPressed: _load,
              child: Text('Refresh',
                  style: TextStyle(
                      color: AppColors.primary, fontSize: 13)),
            ),
          ],
        ),
      ),

      // Horizontal scroll
      SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final user   = _suggestions[i];
            final status = _statusFor(user);
            final name   = user.fullName.isNotEmpty
                ? user.fullName
                : user.username;
            final initials = name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

            return Container(
              width: 150,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevated
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: theme.colorScheme.outline
                        .withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: user.avatarUrl != null &&
                            user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null ||
                            user.avatarUrl!.isEmpty
                        ? Text(initials,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18))
                        : null,
                  ),
                  const SizedBox(height: 10),

                  // Name
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),

                  // Username
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),

                  // Follower count
                  if (user.followersCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${user.followersCount} followers',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Follow button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pendingActions.contains(user.id)
                          ? null
                          : () => _handleFollow(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            status == FollowStatus.accepted
                                ? Colors.grey.shade600
                                : status == FollowStatus.pending
                                    ? AppColors.solarAmber
                                    : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _pendingActions.contains(user.id)
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : Text(
                              status == FollowStatus.accepted
                                  ? 'Following'
                                  : status == FollowStatus.pending
                                      ? 'Requested'
                                      : 'Follow'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }
}
