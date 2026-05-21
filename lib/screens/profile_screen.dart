import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/follow_service.dart'; // adjust import path as needed

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PROFILE SCREEN
// Shows: avatar, full name, username, bio, followers, following.
// Followers / Following are live from Supabase and tappable to
// open a list sheet.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ProfileScreen extends StatefulWidget {
  /// If null â†’ show the current user's own profile.
  /// If provided â†’ show another user's profile.
  final String? targetUserId;

  const ProfileScreen({super.key, this.targetUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _supabase      = Supabase.instance.client;
  final _followService = FollowService();

  late final ScrollController _scroll;
  late final AnimationController _shimmer;

  Map<String, dynamic>? _profile;
  bool _loading = true;

  // Follow state (only relevant when viewing another user's profile)
  FollowStatus _followStatus = FollowStatus.none;
  bool _followActionLoading  = false;

  RealtimeChannel? _profileChannel;

  bool get _isOwnProfile =>
      widget.targetUserId == null ||
      widget.targetUserId == _supabase.auth.currentUser?.id;

  String get _userId =>
      widget.targetUserId ?? _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _scroll   = ScrollController();
    _shimmer  = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', _userId)
          .single();
      if (mounted) setState(() { _profile = data; _loading = false; });

      if (!_isOwnProfile) {
        final status = await _followService.getFollowStatus(_userId);
        if (mounted) setState(() => _followStatus = status);
      }

      // Realtime updates for follower/following counts
      _profileChannel = _followService.subscribeToProfile(
        _userId,
        onUpdate: (row) {
          if (mounted) setState(() => _profile = {...?_profile, ...row});
        },
      );
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _shimmer.dispose();
    _profileChannel?.unsubscribe();
    super.dispose();
  }

  // â”€â”€ Follow / Unfollow button action â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _handleFollowAction() async {
    if (_followActionLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _followActionLoading = true);

    if (_followStatus == FollowStatus.none) {
      final id = await _followService.sendFollowRequest(_userId);
      if (id != null && mounted) setState(() => _followStatus = FollowStatus.pending);
    } else if (_followStatus == FollowStatus.pending) {
      await _followService.unfollow(_userId);
      if (mounted) setState(() => _followStatus = FollowStatus.none);
    } else if (_followStatus == FollowStatus.accepted) {
      await _followService.unfollow(_userId);
      if (mounted) {
        setState(() {
          _followStatus = FollowStatus.none;
          if (_profile != null) {
            _profile!['followers_count'] =
                ((_profile!['followers_count'] as int?) ?? 1) - 1;
          }
        });
      }
    }

    if (mounted) setState(() => _followActionLoading = false);
  }

  // â”€â”€ Open Followers list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showFollowersList() {
    _showFollowSheet(
      title: 'Followers',
      future: _followService.getFollowers(_userId),
    );
  }

  void _showFollowingList() {
    _showFollowSheet(
      title: 'Following',
      future: _followService.getFollowing(_userId),
    );
  }

  void _showFollowSheet({
    required String title,
    required Future<List<FollowUser>> future,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowListSheet(title: title, future: future),
    );
  }

  // â”€â”€ Edit profile sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showEditProfile(AppProvider app) {
    final nameCtrl = TextEditingController(
        text: _profile?['full_name'] as String? ?? '');
    final bioCtrl  = TextEditingController(
        text: _profile?['bio'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? AppColors.backgroundDeep
                : AppColors.lightBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Edit Profile',
                style: Theme.of(ctx)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: bioCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _supabase.from('profiles').update({
                    'full_name': nameCtrl.text.trim(),
                    'bio':       bioCtrl.text.trim(),
                  }).eq('id', _userId);
                  await _loadProfile();
                  app.updateUserName(nameCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.voltCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final app    = context.watch<AppProvider>();

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final fullName       = _profile?['full_name'] as String? ?? 'User';
    final username       = _profile?['username']  as String? ?? '';
    final bio            = _profile?['bio']        as String? ?? '';
    final avatarUrl      = _profile?['avatar_url'] as String?;
    final followersCount = (_profile?['followers_count'] as num?)?.toInt() ?? 0;
    final followingCount = (_profile?['following_count'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.backgroundDeep : AppColors.lightBg,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => Navigator.pop(context))
                : null,
            actions: _isOwnProfile
                ? [
                    IconButton(
                      icon: const Icon(LucideIcons.edit2),
                      onPressed: () => _showEditProfile(app),
                    ),
                    const SizedBox(width: 8),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.7),
                      AppColors.irisViolet.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // â”€â”€ Avatar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // â”€â”€ Name & Username â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Text(fullName,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (username.isNotEmpty)
                    Text('@$username',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(bio,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],

                  const SizedBox(height: 20),

                  // â”€â”€ Followers / Following counts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatButton(
                        label: 'Followers',
                        count: followersCount,
                        onTap: _showFollowersList,
                        theme: theme,
                      ),
                      Container(
                          height: 40,
                          width: 1,
                          color: theme.colorScheme.outlineVariant,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 24)),
                      _StatButton(
                        label: 'Following',
                        count: followingCount,
                        onTap: _showFollowingList,
                        theme: theme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // â”€â”€ Follow / Unfollow button (other profiles) â”€
                  if (!_isOwnProfile)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _followActionLoading ? null : _handleFollowAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _followStatus == FollowStatus.accepted
                                  ? Colors.grey.shade700
                                  : _followStatus == FollowStatus.pending
                                      ? AppColors.solarAmber
                                      : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _followActionLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                _followStatus == FollowStatus.accepted
                                    ? 'Unfollow'
                                    : _followStatus == FollowStatus.pending
                                        ? 'Requested'
                                        : 'Follow',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// STAT BUTTON â€” tappable follower/following count
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StatButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  final ThemeData theme;

  const _StatButton({
    required this.label,
    required this.count,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Text(
          count.toString(),
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// FOLLOW LIST SHEET â€” shown when user taps Followers / Following
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FollowListSheet extends StatelessWidget {
  final String title;
  final Future<List<FollowUser>> future;

  const _FollowListSheet({required this.title, required this.future});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text(title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          Expanded(
            child: FutureBuilder<List<FollowUser>>(
              future: future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final users = snap.data ?? [];
                if (users.isEmpty) {
                  return Center(
                    child: Text('No $title yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color:
                                theme.colorScheme.onSurfaceVariant)),
                  );
                }
                return ListView.separated(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 4),
                  itemBuilder: (_, i) => _UserTile(user: users[i]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final FollowUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final initials = user.fullName.trim().isEmpty
        ? user.username.isNotEmpty
            ? user.username[0].toUpperCase()
            : '?'
        : user.fullName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundImage:
            user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
            ? Text(initials,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold))
            : null,
      ),
      title: Text(user.fullName.isNotEmpty ? user.fullName : user.username,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('@${user.username}',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      onTap: () {
        // Navigate to that user's profile
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProfileScreen(targetUserId: user.id)),
        );
      },
    );
  }
}
