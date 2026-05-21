import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/follow_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ─────────────────────────────────────────────────────────────────
// PROFILE SCREEN
// Shows: avatar, full name, username, bio, followers, following.
// Followers / Following are live from Supabase and tappable to
// open a list sheet.
// ─────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  /// If null → show the current user's own profile.
  /// If provided → show another user's profile.
  final String? targetUserId;

  const ProfileScreen({super.key, this.targetUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _followService = FollowService();

  late final ScrollController _scroll;
  late final AnimationController _shimmer;

  Map<String, dynamic>? _profile;
  bool _loading = true;

  // Follow state (only relevant when viewing another user's profile)
  FollowStatus _followStatus = FollowStatus.none;
  bool _followActionLoading = false;

  RealtimeChannel? _profileChannel;

  bool get _isOwnProfile =>
      widget.targetUserId == null ||
      widget.targetUserId == _supabase.auth.currentUser?.id;

  String get _userId =>
      widget.targetUserId ?? _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
      if (mounted)
        setState(() {
          _profile = data;
          _loading = false;
        });

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

  Future<void> _pickImage(AppProvider app) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      app.updateProfileImagePath(image.path);
    }
  }

  // ── Follow / Unfollow button action ──────────────────────────
  Future<void> _handleFollowAction() async {
    if (_followActionLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _followActionLoading = true);

    if (_followStatus == FollowStatus.none) {
      final id = await _followService.sendFollowRequest(_userId);
      if (id != null && mounted)
        setState(() => _followStatus = FollowStatus.pending);
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

  // ── Open Followers list ───────────────────────────────────────
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

  // ── Edit profile sheet ────────────────────────────────────────
  void _showEditProfile(AppProvider app) {
    final nameCtrl = TextEditingController(
      text: _profile?['full_name'] as String? ?? '',
    );
    final bioCtrl = TextEditingController(
      text: _profile?['bio'] as String? ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? AppColors.backgroundDeep
                : AppColors.lightBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _supabase
                        .from('profiles')
                        .update({
                          'full_name': nameCtrl.text.trim(),
                          'bio': bioCtrl.text.trim(),
                        })
                        .eq('id', _userId);
                    await _loadProfile();
                    app.updateUserName(nameCtrl.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.voltCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final app = context.watch<AppProvider>();

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final fullName = _profile?['full_name'] as String? ?? 'User';
    final username = _profile?['username'] as String? ?? '';
    final bio = _profile?['bio'] as String? ?? '';
    final avatarUrl = _profile?['avatar_url'] as String?;
    final followersCount = (_profile?['followers_count'] as num?)?.toInt() ?? 0;
    final followingCount = (_profile?['following_count'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          // ΓöÇΓöÇ 1. HERO SECTION ΓöÇΓöÇ
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            stretch: true,
            backgroundColor: isDark
                ? AppColors.backgroundDeep
                : AppColors.lightBg,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.pencil,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => _showEditProfile(app),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Gradient Banner
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.voltCyan.withValues(alpha: 0.4),
                          isDark ? AppColors.backgroundDeep : AppColors.lightBg,
                        ],
                      ),
                    ),
                  ),
                  // Avatar & Info
                  Positioned(
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(app),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.voltCyan.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.surfaceElevated,
                              backgroundImage:
                                  avatarUrl != null && avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null || avatarUrl.isEmpty
                                  ? Text(
                                      fullName.isNotEmpty
                                          ? fullName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bio.isNotEmpty
                              ? bio
                              : 'Chasing the next personal best.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.voltCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _showFollowersList,
                              child: Text(
                                '${followersCount} Followers',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _showFollowingList,
                              child: Text(
                                '${followingCount} Following',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        if (!_isOwnProfile)
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: _followActionLoading
                                  ? null
                                  : _handleFollowAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _followStatus == FollowStatus.accepted
                                    ? Colors.grey.shade700
                                    : _followStatus == FollowStatus.pending
                                    ? AppColors.solarAmber
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _followActionLoading
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _followStatus == FollowStatus.accepted
                                          ? 'Unfollow'
                                          : _followStatus ==
                                                FollowStatus.pending
                                          ? 'Requested'
                                          : 'Follow',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ΓöÇΓöÇ 2. STAT PILLS ROW ΓöÇΓöÇ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statPill(
                        LucideIcons.footprints,
                        '34',
                        'Runs',
                        theme,
                        isDark,
                      ),
                      _statPill(
                        LucideIcons.bookOpen,
                        '142h',
                        'Study',
                        theme,
                        isDark,
                      ),
                      _statPill(
                        LucideIcons.messageSquare,
                        '89',
                        'Posts',
                        theme,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 3. STREAK OVERVIEW ΓöÇΓöÇ
                  Text(
                    'Active Streaks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _streakBadgeCard(
                          'Fitness',
                          app.longestStreak,
                          42,
                          AppColors.pulseRed,
                          isDark,
                        ), // Mock values
                        const SizedBox(width: 12),
                        _streakBadgeCard(
                          'Study',
                          app.studyStreak,
                          app.longestStreak,
                          AppColors.irisViolet,
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        _streakBadgeCard(
                          'Nutrition',
                          7,
                          14,
                          AppColors.solarAmber,
                          isDark,
                        ), // Mock values
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 4. ACHIEVEMENTS SECTION ΓöÇΓöÇ
                  Row(
                    children: [
                      Text(
                        'Trophies',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.voltCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${app.achievements.where((a) => a['unlocked'] == true).length}',
                          style: const TextStyle(
                            color: AppColors.voltCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: app.achievements.length,
                    itemBuilder: (context, index) {
                      final badge = app.achievements[index];
                      return _achievementBadge(badge, theme, isDark);
                    },
                  ),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 5. MODULE STATS (ACCORDION) ΓöÇΓöÇ
                  Text(
                    'Detailed Stats',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAccordionStat(
                    'Fitness',
                    LucideIcons.activity,
                    AppColors.pulseRed,
                    {
                      'Total Distance': '${app.distance} km',
                      'Workouts': '112',
                      'PR Badges': '4',
                    },
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildAccordionStat(
                    'Study',
                    LucideIcons.bookOpen,
                    AppColors.irisViolet,
                    {
                      'Focus Hours':
                          '${(app.totalStudyMinutes / 60).toStringAsFixed(1)} h',
                      'Tasks Completed': '342',
                      'Best Streak': '${app.longestStreak} days',
                    },
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildAccordionStat(
                    'Nutrition',
                    LucideIcons.apple,
                    AppColors.solarAmber,
                    {'Avg Calories': '2,450', 'Macro Adherence': '88%'},
                    isDark,
                  ),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 6. CONNECTED DEVICES ΓöÇΓöÇ
                  Text(
                    'Connected Devices',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDeviceRow(
                    'Mi Band 5',
                    LucideIcons.watch,
                    84,
                    true,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildDeviceRow(
                    'Smart Scale X',
                    LucideIcons.scale,
                    0,
                    false,
                    isDark,
                  ),
                  const SizedBox(height: 24),

                  // ΓöÇΓöÇ 7. SOCIAL LINKS ΓöÇΓöÇ
                  Row(
                    children: [
                      _socialPill('Strava', AppColors.solarAmber),
                      const SizedBox(width: 8),
                      _socialPill('Instagram', AppColors.pulseRed),
                      const SizedBox(width: 8),
                      _socialPill('Share Profile', AppColors.voltCyan),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(
    IconData icon,
    String value,
    String label,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated
            : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.voltCyan),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakBadgeCard(
    String label,
    int streak,
    int best,
    Color accent,
    bool isDark,
  ) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        // Trigger share intent logic here
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.flame, color: accent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '$streak',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  height: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                'Best: $best days',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _achievementBadge(
    Map<String, dynamic> badge,
    ThemeData theme,
    bool isDark,
  ) {
    final unlocked = badge['unlocked'] as bool;
    final icon = badge['icon'] as IconData;
    final title = badge['title'] as String;

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated
            : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.voltCyan.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: unlocked ? AppColors.voltCyan : Colors.grey,
                ),
              ),
              if (!unlocked)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      size: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (unlocked) ...[
            const SizedBox(height: 4),
            Text(
              'Earned',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.voltCyan,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );

    if (unlocked) {
      // Add metallic sheen to unlocked badges
      return AnimatedBuilder(
        animation: _shimmer,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              final val = _shimmer.value;
              return LinearGradient(
                begin: Alignment(-2.0 + (val * 4), -2.0 + (val * 4)),
                end: Alignment(-1.0 + (val * 4), -1.0 + (val * 4)),
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.plus,
            child: child,
          );
        },
        child: card,
      );
    } else {
      // Greyscale for locked
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: card,
      );
    }
  }

  Widget _buildAccordionStat(
    String title,
    IconData icon,
    Color accent,
    Map<String, String> stats,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated
            : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: stats.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      e.value,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDeviceRow(
    String name,
    IconData icon,
    int battery,
    bool connected,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated
            : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: connected ? AppColors.voltCyan : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (connected)
                  Text(
                    'Battery: $battery%',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: connected
                  ? AppColors.voltCyan.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              connected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: connected ? AppColors.voltCyan : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialPill(String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STAT BUTTON — tappable follower/following count
// ─────────────────────────────────────────────────────────────────
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
      child: Column(
        children: [
          Text(
            count.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// FOLLOW LIST SHEET — shown when user taps Followers / Following
// ─────────────────────────────────────────────────────────────────
class _FollowListSheet extends StatelessWidget {
  final String title;
  final Future<List<FollowUser>> future;

  const _FollowListSheet({required this.title, required this.future});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: FutureBuilder<List<FollowUser>>(
                future: future,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  final users = snap.data ?? [];
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        'No $title yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => _UserTile(user: users[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final FollowUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = user.fullName.trim().isEmpty
        ? user.username.isNotEmpty
              ? user.username[0].toUpperCase()
              : '?'
        : user.fullName
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
            ? Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user.fullName.isNotEmpty ? user.fullName : user.username,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '@${user.username}',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      onTap: () {
        // Navigate to that user's profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(targetUserId: user.id),
          ),
        );
      },
    );
  }
}
