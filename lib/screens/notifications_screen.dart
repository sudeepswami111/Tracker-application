import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/follow_service.dart';
import '../providers/app_provider.dart';
import '../screens/profile_screen.dart';
import '../screens/challenge_screen.dart';
import '../screens/history_screen.dart';
import '../screens/dm_chat_screen.dart';

// ─────────────────────────────────────────────────────────────────
// NOTIFICATIONS SCREEN
// Shows incoming follow requests (accept / reject) + app notifications.
// ─────────────────────────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase      = Supabase.instance.client;
  final _followService = FollowService();

  List<Map<String, dynamic>> _requests      = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  RealtimeChannel? _channel;
  RealtimeChannel? _notifChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _notifChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([_loadRequests(), _loadNotifications()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadRequests() async {
    final data = await _followService.getIncomingRequests();
    if (mounted) setState(() => _requests = data);
  }

  Future<void> _loadNotifications() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final res = await _supabase
          .from('notifications')
          .select('''
            *,
            actor:profiles!notifications_actor_id_fkey(
              id, username, full_name, avatar_url
            )
          ''')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(60);
      if (mounted) {
        setState(() =>
            _notifications = List<Map<String, dynamic>>.from(res as List));

        // Update unread count — user is now on the screen
        final unreadCount = _notifications
            .where((n) => !(n['is_read'] as bool? ?? false))
            .length;
        context.read<AppProvider>().setUnreadCount(unreadCount);
      }
    } catch (_) {}
  }

  void _subscribeRealtime() {
    // Existing: follow requests
    _channel = _followService.subscribeToIncomingRequests(
      onAnyChange: _loadRequests,
    );

    // NEW: notifications table realtime
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    _notifChannel = _supabase
        .channel('notifs-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (mounted) {
              setState(() => _notifications.insert(0, newRow));
              context.read<AppProvider>().setUnreadCount(
                _notifications
                    .where((n) => !(n['is_read'] as bool? ?? false))
                    .length,
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> _accept(String followId, String name) async {
    HapticFeedback.mediumImpact();
    final ok = await _followService.acceptFollowRequest(followId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You accepted $name\'s follow request! 🎉'),
        backgroundColor: AppColors.irisViolet,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Say Hi →',
          textColor: Colors.white,
          onPressed: () async {
            final uid = _supabase.auth.currentUser?.id;
            if (uid == null) return;
            try {
              final chats = await _supabase
                  .from('chat_participants')
                  .select('chat_id')
                  .eq('participant_id', uid)
                  .order('created_at', ascending: false)
                  .limit(1);
              if ((chats as List).isNotEmpty && mounted) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DMChatScreen(
                    chatId: chats.first['chat_id'] as String,
                    otherUserId: 'unknown',
                    otherUserName: name,
                  ),
                ));
              }
            } catch (_) {}
          },
        ),
      ));
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Failed to accept request. Please try again.'),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _reject(String followId) async {
    HapticFeedback.lightImpact();
    await _followService.deleteFollow(followId);
    _loadRequests();
  }

  Future<void> _markAllRead() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
    await _loadNotifications();
  }

  Future<void> _clearRead() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    await _supabase
        .from('notifications')
        .delete()
        .eq('user_id', uid)
        .eq('is_read', true);
    setState(() => _notifications.removeWhere((n) => n['is_read'] as bool? ?? false));
  }

  void _handleTap(Map<String, dynamic> notif) {
    final id = notif['id'];
    final type = notif['type'] as String? ?? '';

    // Optimistic UI update
    setState(() {
      final idx = _notifications.indexWhere((n) => n['id'] == id);
      if (idx != -1) {
        _notifications[idx] = Map<String, dynamic>.from(_notifications[idx])..['is_read'] = true;
      }
    });

    // Update unread count
    final unreadCount = _notifications.where((n) => !(n['is_read'] as bool? ?? false)).length;
    context.read<AppProvider>().setUnreadCount(unreadCount);

    // Fire-and-forget DB update
    _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);

    // Route based on type
    if (type == 'follow_request' || type == 'follow_accepted' || type == 'new_follower') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProfileScreen(targetUserId: notif['actor_id'] as String?),
      ));
    } else if (type == 'message') {
      final chatId = notif['reference_id'] as String?;
      if (chatId != null) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DMChatScreen(
            chatId: chatId,
            otherUserId: notif['actor_id'] as String? ?? 'unknown',
            otherUserName: (notif['actor_details'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'User',
          ),
        ));
      }
    } else if (type == 'challenge' || type == 'challenge_complete') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const ChallengeScreen(),
      ));
    } else if (type == 'community_post' || type == 'post_like') {
      context.read<AppProvider>().setTabIndex(3);
      Navigator.pop(context);
    } else if (type == 'run_complete') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const HistoryScreen(),
      ));
    } else if (type == 'achievement' || type == 'goal_reached' || type == 'streak') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final unread = _notifications.where((n) => !(n['is_read'] as bool? ?? false)).toList();
    final read   = _notifications.where((n)  =>  (n['is_read'] as bool? ?? false)).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          if (read.isNotEmpty)
            TextButton(
              onPressed: _clearRead,
              child: Text(
                'Clear read',
                style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
            ),
          if (unread.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // ── Follow Requests ───────────────────────────
                  if (_requests.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _RequestsSection(
                        requests: _requests,
                        isDark: isDark,
                        theme: theme,
                        onAccept: _accept,
                        onReject: _reject,
                      ),
                    ),

                  // ── Notification list ─────────────────────────
                  if (_notifications.isEmpty && _requests.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyState(theme: theme),
                    )
                  else ...[
                    if (unread.isNotEmpty) ...[
                      _SectionHeader(label: 'NEW', color: AppColors.solarAmber),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Dismissible(
                            key: ValueKey(unread[i]['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              decoration: BoxDecoration(
                                color: AppColors.pulseRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(LucideIcons.trash2, color: AppColors.pulseRed),
                            ),
                            onDismissed: (_) async {
                              final id = unread[i]['id'] as String;
                              setState(() => _notifications.removeWhere((n) => n['id'] == id));
                              await _supabase.from('notifications').delete().eq('id', id);
                              if (mounted) {
                                final unreadCount = _notifications
                                    .where((n) => !(n['is_read'] as bool? ?? false))
                                    .length;
                                context.read<AppProvider>().setUnreadCount(unreadCount);
                              }
                            },
                            child: _NotifTile(
                              data: unread[i],
                              theme: theme,
                              isDark: isDark,
                              onTap: () => _handleTap(unread[i]),
                            ),
                          ),
                          childCount: unread.length,
                        ),
                      ),
                    ],
                    if (read.isNotEmpty) ...[
                      _SectionHeader(label: 'EARLIER', color: Colors.grey),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Dismissible(
                            key: ValueKey(read[i]['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              decoration: BoxDecoration(
                                color: AppColors.pulseRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(LucideIcons.trash2, color: AppColors.pulseRed),
                            ),
                            onDismissed: (_) async {
                              final id = read[i]['id'] as String;
                              setState(() => _notifications.removeWhere((n) => n['id'] == id));
                              await _supabase.from('notifications').delete().eq('id', id);
                            },
                            child: _NotifTile(
                              data: read[i],
                              theme: theme,
                              isDark: isDark,
                              onTap: () => _handleTap(read[i]),
                            ),
                          ),
                          childCount: read.length,
                        ),
                      ),
                    ],
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Follow Requests Section
// ─────────────────────────────────────────────────────────────────
class _RequestsSection extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final bool isDark;
  final ThemeData theme;
  final Future<void> Function(String id, String name) onAccept;
  final Future<void> Function(String id) onReject;

  const _RequestsSection({
    required this.requests,
    required this.isDark,
    required this.theme,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.irisViolet.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.irisViolet.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            const Icon(LucideIcons.userPlus,
                color: AppColors.irisViolet, size: 16),
            const SizedBox(width: 8),
            Text(
              'Follow Requests  •  ${requests.length}',
              style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.irisViolet,
                  fontWeight: FontWeight.bold),
            ),
          ]),
        ),
        ...requests.map((req) {
          final follower  = req['follower'] as Map<String, dynamic>?;
          final name      = (follower?['full_name'] as String?)?.isNotEmpty == true
              ? follower!['full_name'] as String
              : follower?['username'] as String? ?? 'Someone';
          final username  = follower?['username'] as String? ?? '';
          final avatarUrl = follower?['avatar_url'] as String?;
          final initials  = name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

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
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.irisViolet.withValues(alpha: 0.15),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(initials,
                          style: const TextStyle(
                              color: AppColors.irisViolet,
                              fontWeight: FontWeight.bold,
                              fontSize: 13))
                      : null,
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (username.isNotEmpty)
                          Text('@$username',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                      ]),
                ),
                // Reject
                GestureDetector(
                  onTap: () => onReject(req['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.coral.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(LucideIcons.x,
                        size: 14, color: AppColors.coral),
                  ),
                ),
                const SizedBox(width: 8),
                // Accept
                GestureDetector(
                  onTap: () => onAccept(req['id'] as String, name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.voltCyan,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Accept',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section header sliver
// ─────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Single notification tile
// ─────────────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onTap;

  const _NotifTile({
    required this.data,
    required this.theme,
    required this.isDark,
    required this.onTap,
  });

  IconData _icon() {
    switch (data['type'] as String?) {
      case 'follow_request':       return LucideIcons.userPlus;
      case 'follow_accepted':      return LucideIcons.userCheck;
      case 'new_follower':         return LucideIcons.users;
      case 'message':              return LucideIcons.messageCircle;
      case 'challenge':
      case 'challenge_complete':   return LucideIcons.trophy;
      case 'post_like':            return LucideIcons.heart;
      case 'community_post':       return LucideIcons.fileText;
      case 'run_complete':         return LucideIcons.mapPin;
      case 'achievement':          return LucideIcons.medal;
      case 'streak':               return LucideIcons.flame;
      case 'goal_reached':         return LucideIcons.target;
      default:                     return LucideIcons.bell;
    }
  }

  Color _color() {
    switch (data['type'] as String?) {
      case 'follow_request':
      case 'follow_accepted':
      case 'new_follower':         return AppColors.irisViolet;
      case 'message':              return AppColors.voltCyan;
      case 'challenge':
      case 'challenge_complete':   return AppColors.solarAmber;
      case 'post_like':            return AppColors.pulseRed;
      case 'community_post':       return AppColors.primary;
      case 'run_complete':         return const Color(0xFF00C853);
      case 'achievement':          return AppColors.solarAmber;
      case 'streak':               return AppColors.solarAmber;
      case 'goal_reached':         return AppColors.voltCyan;
      default:                     return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead  = data['is_read'] as bool? ?? false;
    final body    = data['body'] as String? ?? '';
    final title   = data['title'] as String? ?? '';
    final created = data['created_at'] as String?;

    String timeLabel = '';
    if (created != null) {
      final dt  = DateTime.tryParse(created)?.toLocal();
      final now = DateTime.now();
      if (dt != null) {
        final diff = now.difference(dt);
        if (diff.inMinutes < 60) {
          timeLabel = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeLabel = '${diff.inHours}h ago';
        } else {
          timeLabel = '${diff.inDays}d ago';
        }
      }
    }

    final color = _color();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: isRead
            ? (isDark
                ? AppColors.surfaceElevated
                : AppColors.lightSurfaceContainer)
            : (isDark ? const Color(0xFF1E1E2E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
              color: isRead ? Colors.transparent : AppColors.solarAmber,
              width: 3),
          top:    BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
          right:  BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon(), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (title.isNotEmpty)
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
              if (body.isNotEmpty)
                Text(body,
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.8))),
              const SizedBox(height: 4),
              Text(timeLabel,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                  color: AppColors.solarAmber, shape: BoxShape.circle),
            ),
          ]),
        ),
      ),
    ),
  );
}
}

// ─────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(LucideIcons.bellOff,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.25)),
          const SizedBox(height: 24),
          Text('All caught up!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('No notifications yet.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]),
      );
}
