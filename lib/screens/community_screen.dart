import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/glass_card.dart';
import 'chat_inbox_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<String> _channels = ['All', 'Running', 'Nutrition', 'Study', 'Challenges', 'Friends'];
  String _activeChannel = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Above the glass nav bar
        child: FloatingActionButton(
          onPressed: () {
            // New Post Bottom Sheet
          },
          backgroundColor: AppColors.pulseRed,
          child: const Icon(LucideIcons.pencil, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.irisViolet,
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: CustomScrollView(
            slivers: [
              // ── 1. TOP BAR ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.md, AppSpacing.screenMargin, AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Community', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.search),
                            onPressed: () {},
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.inbox),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => const ChatInboxScreen(),
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
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppColors.pulseRed, shape: BoxShape.circle),
                                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. CHANNEL TAB ROW ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                    scrollDirection: Axis.horizontal,
                    itemCount: _channels.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final channel = _channels[index];
                      final isActive = channel == _activeChannel;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _activeChannel = channel);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.irisViolet : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isActive ? AppColors.irisViolet : theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: Text(
                              channel,
                              style: TextStyle(
                                color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // ── 3. STORIES STRIP (Optional) ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 70,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStoryAvatar('Your Story', true, null),
                      const SizedBox(width: 16),
                      _buildStoryAvatar('Alex', false, AppColors.voltCyan),
                      const SizedBox(width: 16),
                      _buildStoryAvatar('Sam', false, AppColors.pulseRed),
                      const SizedBox(width: 16),
                      _buildStoryAvatar('Jordan', false, AppColors.solarAmber),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // ── 5. CHALLENGE SECTION ──
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Challenges', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('See All', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.irisViolet, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildChallengeCard('100km Run Club', 65, 100, AppColors.gradientAmber),
                          const SizedBox(width: 16),
                          _buildChallengeCard('Meditation Streak', 4, 7, AppColors.gradientCyan),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // ── 4. FEED ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FeedCard(index: index),
                      );
                    },
                    childCount: 5, // Mock data count
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryAvatar(String name, bool isMine, Color? ringColor) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: ringColor != null ? Border.all(color: ringColor, width: 2) : null,
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceElevated,
                child: Text(name[0], style: const TextStyle(color: Colors.white)),
              ),
            ),
            if (isMine)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.irisViolet, shape: BoxShape.circle),
                  child: const Icon(Icons.add, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildChallengeCard(String title, int progress, int total, Gradient bg) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Icon(LucideIcons.medal, color: Colors.white, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  Text('$progress / $total', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress / total,
                  backgroundColor: Colors.black.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.voltCyan),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FeedCard extends StatefulWidget {
  final int index;
  const FeedCard({super.key, required this.index});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _boostCtrl;
  late final Animation<double> _boostAnim;
  int _boostCount = 12;
  bool _boosted = false;

  @override
  void initState() {
    super.initState();
    _boostCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _boostAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _boostCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _boostCtrl.dispose();
    super.dispose();
  }

  void _onBoost() {
    if (_boosted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _boosted = true;
      _boostCount++;
    });
    _boostCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Alternate activity colors
    final colors = [AppColors.voltCyan, AppColors.pulseRed, AppColors.irisViolet, AppColors.solarAmber];
    final accentColor = colors[widget.index % colors.length];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Accent Stripe
            Container(width: 4, decoration: BoxDecoration(color: accentColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(radius: 20, backgroundColor: AppColors.surfaceElevated, child: const Icon(LucideIcons.user, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Alex Runner', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('2 hours ago', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.moreHorizontal, color: theme.colorScheme.onSurfaceVariant, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Content
                    Text('Crushed my morning 10k! The new trail is amazing. 🏃💨', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    // Stat Pills
                    Row(
                      children: [
                        _statPill('10.0 km', isDark),
                        const SizedBox(width: 8),
                        _statPill('52:30', isDark),
                        const SizedBox(width: 8),
                        _statPill('5:15 /km', isDark),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Reaction Row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _onBoost,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Boost Animation Ring
                              AnimatedBuilder(
                                animation: _boostAnim,
                                builder: (context, child) {
                                  return Container(
                                    width: 24 + (_boostAnim.value * 40),
                                    height: 24 + (_boostAnim.value * 40),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.pulseRed.withValues(alpha: 1.0 - _boostAnim.value),
                                        width: 2,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  Icon(LucideIcons.zap, size: 20, color: _boosted ? AppColors.pulseRed : theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text('$_boostCount', style: TextStyle(color: _boosted ? AppColors.pulseRed : theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            Icon(LucideIcons.messageCircle, size: 20, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text('4', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Spacer(),
                        Icon(LucideIcons.share, size: 20, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
