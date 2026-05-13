import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/friend_provider.dart';
import '../models/friend_models.dart';
import '../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Activity', 'Social', 'Achievements', 'Reminders', 'Challenges'];

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Activity':     return AppColors.pulseRed;
      case 'Social':       return AppColors.irisViolet;
      case 'Achievements': return AppColors.solarAmber;
      case 'Reminders':    return AppColors.voltCyan;
      case 'Challenges':   return AppColors.solarAmber;
      default:             return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allNotifications = app.notifications;

    final filtered = _activeFilter == 'All'
        ? allNotifications
        : allNotifications.where((n) => n['type'] == _activeFilter).toList();

    final unread = filtered.where((n) => !(n['isRead'] as bool)).toList();
    final read   = filtered.where((n)  =>  (n['isRead'] as bool)).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (allNotifications.any((n) => !(n['isRead'] as bool)))
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                app.markAllNotificationsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${unread.length} notification${unread.length == 1 ? '' : 's'} marked as read'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                  ),
                );
              },
              child: Text(
                'Mark All Read',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Incoming Friend Requests ──
          Consumer<FriendProvider>(
            builder: (context, friends, _) {
              if (friends.incomingRequests.isEmpty) return const SizedBox.shrink();
              return _IncomingRequestsSection(
                requests: friends.incomingRequests,
                isDark: isDark,
                theme: theme,
              );
            },
          ),

          // ── Filter Tabs ──
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = _filters[i];
                final isActive = filter == _activeFilter;
                final accent = _getFilterColor(filter);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeFilter = filter);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accent.withValues(alpha: 0.18)
                          : (isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? accent.withValues(alpha: 0.5) : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isActive ? accent : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Content ──
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(theme)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      if (unread.isNotEmpty) ...[
                        _sectionLabel('NEW', AppColors.solarAmber),
                        ...unread.map((n) => _NotificationRow(
                          data: n,
                          isDark: isDark,
                          theme: theme,
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              app.removeNotification(n['id'] as String);
                            } else {
                              app.markNotificationRead(n['id'] as String);
                            }
                          },
                        )),
                        const SizedBox(height: 20),
                      ],
                      if (read.isNotEmpty) ...[
                        _sectionLabel('EARLIER', Colors.grey),
                        ...read.map((n) => _NotificationRow(
                          data: n,
                          isDark: isDark,
                          theme: theme,
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              app.removeNotification(n['id'] as String);
                            } else {
                              app.markNotificationRead(n['id'] as String);
                            }
                          },
                        )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellOff, size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25)),
          const SizedBox(height: 24),
          Text('All caught up!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'No notifications in this category.',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Individual Dismissible Row ──────────────────────────────────────────────

class _NotificationRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  final ThemeData theme;
  final void Function(DismissDirection) onDismissed;

  const _NotificationRow({
    required this.data,
    required this.isDark,
    required this.theme,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final icon  = data['icon']  as IconData;
    final color = data['color'] as Color;
    final isRead = data['isRead'] as bool;

    return Dismissible(
      key: ValueKey(data['id']),
      direction: DismissDirection.horizontal,
      onDismissed: onDismissed,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.voltCyan,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(LucideIcons.check, color: Colors.black, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.pulseRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer)
              : (isDark ? const Color(0xFF1E1E2E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: isRead ? Colors.transparent : AppColors.solarAmber,
              width: 3,
            ),
            top:    BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
            right:  BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
            bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['message'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['time'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.solarAmber,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Incoming Friend Requests Section ──────────────────────────────────────────
class _IncomingRequestsSection extends StatelessWidget {
  final List<FriendRequest> requests;
  final bool isDark;
  final ThemeData theme;

  const _IncomingRequestsSection({
    required this.requests,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final friends = context.read<FriendProvider>();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.irisViolet.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.irisViolet.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(LucideIcons.userPlus, color: AppColors.irisViolet, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Friend Requests  •  ${requests.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.irisViolet,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...requests.map((req) {
            final p = req.senderProfile;
            final name = p?.fullName.isNotEmpty == true ? p!.fullName : p?.username ?? 'Unknown';
            final initials = name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.irisViolet.withValues(alpha: 0.15),
                      backgroundImage: p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty
                          ? NetworkImage(p.avatarUrl!)
                          : null,
                      child: p?.avatarUrl == null || p!.avatarUrl!.isEmpty
                          ? Text(initials,
                              style: const TextStyle(
                                  color: AppColors.irisViolet,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          if (p?.fitnessGoal != null)
                            Text(
                              p!.fitnessGoal!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    // Reject
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        friends.rejectRequest(req.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(LucideIcons.x, size: 14, color: AppColors.coral),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Accept
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        friends.acceptRequest(req.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You are now friends with $name! 🎉'),
                            backgroundColor: AppColors.irisViolet,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.voltCyan,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
