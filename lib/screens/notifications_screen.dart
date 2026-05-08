import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Activity', 'Social', 'Achievements', 'Reminders', 'Challenges'];

  List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      type: 'Achievements',
      title: 'Achievement Unlocked',
      message: 'You earned Elite Runner! Tap to view.',
      time: 'Just now',
      icon: LucideIcons.trophy,
      color: AppColors.solarAmber,
    ),
    NotificationItem(
      id: '2',
      type: 'Social',
      title: 'Community Boost',
      message: 'Alex boosted your run!',
      time: '2m ago',
      icon: LucideIcons.zap,
      color: AppColors.pulseRed,
    ),
    NotificationItem(
      id: '3',
      type: 'Reminders',
      title: 'Workout Reminder',
      message: 'Time for your workout! You\'ve trained 3 days in a row.',
      time: '1h ago',
      icon: LucideIcons.flame,
      color: AppColors.pulseRed,
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      type: 'Activity',
      title: 'PR Badge',
      message: 'New personal record! Fastest 5K: 24:10.',
      time: 'Yesterday',
      icon: LucideIcons.star,
      color: AppColors.solarAmber,
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      type: 'Reminders',
      title: 'Hydration Reminder',
      message: 'Time to hydrate! You\'re at 1.5L today.',
      time: 'Yesterday',
      icon: LucideIcons.droplets,
      color: AppColors.voltCyan,
      isRead: true,
    ),
  ];

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Activity': return AppColors.pulseRed;
      case 'Social': return AppColors.irisViolet;
      case 'Achievements': return AppColors.solarAmber;
      case 'Reminders': return AppColors.voltCyan;
      case 'Challenges': return AppColors.solarAmber;
      default: return Colors.white;
    }
  }

  void _markAllRead() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read', style: TextStyle(color: Colors.white)), backgroundColor: Colors.black87, behavior: SnackBarBehavior.floating),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _markRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredList = _activeFilter == 'All' 
        ? _notifications 
        : _notifications.where((n) => n.type == _activeFilter).toList();
    
    final unread = filteredList.where((n) => !n.isRead).toList();
    final read = filteredList.where((n) => n.isRead).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark All Read', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isActive = filter == _activeFilter;
                final filterColor = _getFilterColor(filter);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeFilter = filter);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? filterColor.withValues(alpha: 0.2) : (isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? filterColor.withValues(alpha: 0.5) : Colors.transparent),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isActive ? filterColor : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(theme)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    children: [
                      if (unread.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text('NEW', style: TextStyle(color: AppColors.solarAmber, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                        ...unread.map((n) => _buildNotificationRow(n, isDark, theme)),
                        const SizedBox(height: 24),
                      ],
                      if (read.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text('EARLIER', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                        ...read.map((n) => _buildNotificationRow(n, isDark, theme)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellOff, size: 80, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text('All caught up!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('You have no new notifications right now.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(NotificationItem n, bool isDark, ThemeData theme) {
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteNotification(n.id);
        } else {
          _markRead(n.id);
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.voltCyan, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(LucideIcons.check, color: Colors.black, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.pulseRed, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead 
            ? (isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer)
            : (isDark ? const Color(0xFF1E1E2E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: n.isRead ? Colors.transparent : AppColors.solarAmber, width: 3),
            top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
            right: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
            bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: n.color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(n.icon, color: n.color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.message, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(n.time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.solarAmber, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
