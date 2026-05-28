import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/create_post_sheet.dart';
import '../widgets/community_search_delegate.dart';
import '../services/community_service.dart';
import '../services/challenge_service.dart';
import 'package:intl/intl.dart';
import 'dm_chat_screen.dart';
import '../widgets/profile_avatar.dart';

// ====================================================
// PREMIUM COMMUNITY FEED
// Inspired by modern social fitness apps
// ====================================================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final List<String> _filters = ['All', 'Running', 'Nutrition', 'Study', 'Challenges'];
  String _activeFilter = 'All';

  late AnimationController _fabPulseCtrl;
  late Animation<double> _fabPulseAnim;

  @override
  void initState() {
    super.initState();
    // Glowing pulse animation for FAB
    _fabPulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fabPulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _fabPulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fabPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      // ── FLOATING ACTION BUTTON WITH GLOW ──
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // Safely above bottom nav
        child: AnimatedBuilder(
          animation: _fabPulseAnim,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.irisViolet.withValues(alpha: 0.4 * (_fabPulseAnim.value - 0.8)),
                    blurRadius: 20 * _fabPulseAnim.value,
                    spreadRadius: 10 * _fabPulseAnim.value,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final result = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const CreatePostSheet(),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
                backgroundColor: AppColors.irisViolet,
                elevation: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.irisViolet, Color(0xFF9D4EDD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.feather, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.irisViolet,
          backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
          onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // ── 1. PREMIUM HEADER ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.lg, AppSpacing.screenMargin, AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Community',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          _HeaderIconButton(
                            icon: LucideIcons.search, 
                            onTap: () {
                              showSearch(context: context, delegate: CommunitySearchDelegate());
                            }
                          ),
                          const SizedBox(width: 8),
                          _HeaderIconButton(
                            icon: LucideIcons.messageCircle,
                            hasBadge: true,
                            badgeCount: 2,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const DMListScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                                          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 350),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. ANIMATED FILTER CHIPS ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isActive = filter == _activeFilter;
                      
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _activeFilter = filter);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? AppColors.irisViolet.withValues(alpha: 0.15) 
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isActive 
                                  ? AppColors.irisViolet.withValues(alpha: 0.6) 
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: isActive ? [
                              BoxShadow(color: AppColors.irisViolet.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)
                            ] : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isActive 
                                  ? AppColors.irisViolet 
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // ── 3. ACTIVE CHALLENGES (Horizontal Scroll) ──
              if (_activeFilter == 'All' || _activeFilter == 'Challenges')
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Active Challenges', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            Text('See All', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.irisViolet, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 140,
                        child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                          future: ChallengeService().getDiscoverChallenges(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final groups = snapshot.data ?? {};
                            final challenges = groups.values.expand((x) => x).toList();
                            if (challenges.isEmpty) {
                              return const Center(child: Text('No active challenges.'));
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: challenges.length,
                              itemBuilder: (context, index) {
                                final c = challenges[index];
                                return _buildChallengeChip(c, isDark, theme);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),

              // ── 4. PREMIUM FEED ──
              FutureBuilder<List<Map<String, dynamic>>>(
                future: CommunityService().getPosts(filter: _activeFilter == 'All' ? null : _activeFilter),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final posts = snapshot.data ?? [];
                  if (posts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text('No posts yet. Be the first!', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _PremiumFeedCard(post: posts[index], index: index, isDark: isDark, theme: theme),
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                  );
                },
              ),
              
              // ── FIX FOR BOTTOM OVERFLOW ──
              const SliverSafeArea(
                top: false,
                sliver: SliverToBoxAdapter(child: SizedBox(height: 150)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeChip(Map<String, dynamic> challenge, bool isDark, ThemeData theme) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.irisViolet.withValues(alpha: 0.3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.target, color: AppColors.irisViolet, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(challenge['title'] ?? 'Challenge', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          const Spacer(),
          Text('${challenge['participants_count'] ?? 0} participants', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(color: AppColors.irisViolet.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Join', style: TextStyle(color: AppColors.irisViolet, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// PREMIUM COMPONENTS
// ====================================================

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;
  final int badgeCount;

  const _HeaderIconButton({required this.icon, required this.onTap, this.hasBadge = false, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, size: 22, color: theme.colorScheme.onSurface),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.pulseRed,
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
              ),
              child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

class _PremiumFeedCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final int index;
  final bool isDark;
  final ThemeData theme;

  const _PremiumFeedCard({required this.post, required this.index, required this.isDark, required this.theme});

  @override
  State<_PremiumFeedCard> createState() => _PremiumFeedCardState();
}

class _PremiumFeedCardState extends State<_PremiumFeedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _boostCtrl;
  late final Animation<double> _boostAnim;
  late int _boostCount;
  bool _boosted = false;

  final List<Color> _accents = [AppColors.voltCyan, AppColors.pulseRed, AppColors.irisViolet, AppColors.solarAmber];

  @override
  void initState() {
    super.initState();
    _boostCount = widget.post['likes_count'] ?? 0;
    _boostCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _boostAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _boostCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _boostCtrl.dispose();
    super.dispose();
  }

  void _onBoost() {
    if (_boosted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _boosted = true;
      _boostCount++;
    });
    CommunityService().likePost(
      widget.post['id'],
      postAuthorId: widget.post['user_id'] as String?,
    );
    _boostCtrl.forward(from: 0);
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accents[widget.index % _accents.length];

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF151515) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle glowing accent at the top edge
            Positioned(
              top: 0, left: 0, right: 0,
              height: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent.withValues(alpha: 0.1), accent, accent.withValues(alpha: 0.1)]),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 10)],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Author Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.2)]),
                        ),
                        child: ProfileAvatar(
                          imageUrl: widget.post['author']?['avatar_url'] as String?,
                          name: (widget.post['author']?['full_name'] as String?) ?? 'Anonymous',
                          radius: 20,
                          backgroundColor: widget.isDark ? AppColors.surfaceElevated : Colors.grey[200]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((widget.post['author']?['full_name'] as String?) ?? 'Anonymous', style: widget.theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            Text('${_formatTime(widget.post['created_at'])} • ${widget.post['activity_type'] ?? 'Update'}', style: widget.theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.moreHorizontal, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. Post Content
                  Text(
                    widget.post['content'] ?? '',
                    style: widget.theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontSize: 15),
                  ),
                  if (widget.post['image_url'] != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.post['image_url'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // 3. Activity Stats (Glassmorphic Pills)
                  if (widget.post['activity_type'] == 'Running')
                  Row(
                    children: [
                      _buildStatPill('10.2', 'km', LucideIcons.mapPin, accent),
                      const SizedBox(width: 10),
                      _buildStatPill('52:30', 'time', LucideIcons.timer, accent),
                      const SizedBox(width: 10),
                      _buildStatPill('5:08', '/km', LucideIcons.zap, accent),
                    ],
                  ),
                  if (widget.post['activity_type'] == 'Running')
                  const SizedBox(height: 20),
                  Divider(color: widget.theme.colorScheme.outline.withValues(alpha: 0.1), height: 1),
                  const SizedBox(height: 16),
                  
                  // 4. Reactions
                  Row(
                    children: [
                      // Boost Button (Animated)
                      GestureDetector(
                        onTap: _onBoost,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedBuilder(
                              animation: _boostAnim,
                              builder: (context, child) {
                                return Container(
                                  width: 28 + (_boostAnim.value * 40),
                                  height: 28 + (_boostAnim.value * 40),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.pulseRed.withValues(alpha: (1.0 - _boostAnim.value).clamp(0, 1)),
                                      width: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _boosted ? AppColors.pulseRed.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _boosted ? AppColors.pulseRed.withValues(alpha: 0.3) : widget.isDark ? Colors.white12 : Colors.black12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _boosted ? Icons.local_fire_department : LucideIcons.flame,
                                    size: 18,
                                    color: _boosted ? AppColors.pulseRed : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_boostCount',
                                    style: TextStyle(
                                      color: _boosted ? AppColors.pulseRed : AppColors.textSecondary,
                                      fontWeight: _boosted ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Comment Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.messageCircle, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('12', style: TextStyle(color: widget.theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Share Button
                      IconButton(
                        icon: const Icon(LucideIcons.share, size: 20, color: AppColors.textSecondary),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String val, String unit, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(height: 6),
            Text(val, style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(unit, style: widget.theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
