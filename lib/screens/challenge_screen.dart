import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_colors.dart';
import '../widgets/create_challenge_sheet.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0=Active, 1=Discover, 2=Completed
  late ConfettiController _confetti;
  late AnimationController _glowController;

  final List<Map<String, dynamic>> _activeChallenges = [
    {
      'title': '100km Run Club',
      'tier': 'Silver',
      'current': 65.0,
      'total': 100.0,
      'rank': 4,
      'goalType': 'Distance',
      'stakes': 'If I lose, I buy my friend dinner'
    },
    {
      'title': 'Elite Focus Month',
      'tier': 'Gold',
      'current': 12.0,
      'total': 30.0,
      'rank': 1,
      'goalType': 'Workouts',
      'stakes': null
    },
  ];

  final List<Map<String, dynamic>> _completedChallenges = [
    {'title': 'Spring Steps Challenge', 'tier': 'Silver', 'rank': 2, 'date': 'Mar 2026', 'goalType': 'Steps'},
    {'title': '7 Days of Code', 'tier': 'Gold', 'rank': 1, 'date': 'Feb 2026', 'goalType': 'Study'},
  ];

  final Map<String, List<Map<String, dynamic>>> _discoverData = {
    'Running & Cardio': [
      {'title': 'Summer Shred', 'tier': 'Silver', 'icon': LucideIcons.activity, 'participants': '1.2k', 'color': AppColors.solarAmber, 'total': 100.0},
      {'title': 'Marathon Prep', 'tier': 'Gold', 'icon': LucideIcons.footprints, 'participants': '4.5k', 'color': AppColors.pulseRed, 'total': 500.0},
    ],
    'Fitness & Strength': [
      {'title': 'Iron Man Prep Month', 'tier': 'Diamond', 'icon': Icons.fitness_center, 'participants': '800', 'color': AppColors.irisViolet, 'total': 1000.0},
      {'title': 'Daily Pushups', 'tier': 'Bronze', 'icon': LucideIcons.flame, 'participants': '12k', 'color': AppColors.green, 'total': 30.0},
    ],
    'Study & Focus': [
      {'title': 'Zen Month', 'tier': 'Bronze', 'icon': LucideIcons.moon, 'participants': '3.4k', 'color': AppColors.voltCyan, 'total': 30.0},
      {'title': 'Deep Work Sprint', 'tier': 'Silver', 'icon': LucideIcons.book, 'participants': '5.2k', 'color': AppColors.solarAmber, 'total': 60.0},
    ]
  };

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _showLeaderboard(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LeaderboardSheet(isDark: isDark),
    );
  }

  void _showFilterSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : AppColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Challenges', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Status'),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: const Text('Ongoing'), backgroundColor: AppColors.voltCyan.withValues(alpha: 0.2)),
                const SizedBox(width: 8),
                const Chip(label: Text('Upcoming')),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Goal Type'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Chip(label: Text('Steps')),
                const SizedBox(width: 8),
                Chip(label: const Text('Distance'), backgroundColor: AppColors.voltCyan.withValues(alpha: 0.2)),
                const SizedBox(width: 8),
                const Chip(label: Text('Workouts')),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.voltCyan),
                child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _joinChallenge(Map<String, dynamic> challengeData) {
    setState(() {
      _activeChallenges.insert(0, {
        'title': challengeData['title'],
        'tier': challengeData['tier'],
        'current': 0.0,
        'total': challengeData['total'],
        'rank': 1,
        'goalType': 'Distance',
        'stakes': null,
      });
    });
    _confetti.play();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Joined "${challengeData['title']}"! 🎉'),
      backgroundColor: AppColors.irisViolet,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.pulseRed,
        onPressed: () {
          HapticFeedback.mediumImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CreateChallengeSheet(
              onChallengeCreated: (challenge) {
                setState(() {
                  _activeChallenges.insert(0, challenge);
                });
                _confetti.play();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Challenge "${challenge['title']}" Created! 🎉'),
                  backgroundColor: AppColors.irisViolet,
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          );
        },
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Challenges', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                      IconButton(
                        icon: Icon(LucideIcons.filter, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () => _showFilterSheet(context, isDark),
                      ),
                    ],
                  ),
                ),
                
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _tabItem('Active', 0, isDark),
                      const SizedBox(width: 24),
                      _tabItem('Discover', 1, isDark),
                      const SizedBox(width: 24),
                      _tabItem('Completed', 2, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Content
                Expanded(
                  child: _selectedTab == 0
                      ? _buildActiveTab(theme, isDark)
                      : _selectedTab == 1
                          ? _buildDiscoverTab(theme, isDark)
                          : _buildCompletedTab(theme, isDark),
                ),
              ],
            ),
          ),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [AppColors.voltCyan, AppColors.solarAmber, AppColors.pulseRed],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index, bool isDark) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedTab = index);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: active ? FontWeight.bold : FontWeight.w600,
              color: active ? (isDark ? Colors.white : Colors.black) : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (active)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(color: AppColors.solarAmber, borderRadius: BorderRadius.circular(2)),
            )
        ],
      ),
    );
  }

  Widget _buildActiveTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // 3. DAILY CHALLENGE NUDGE
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.solarAmber.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: AppColors.solarAmber.withValues(alpha: 0.15 + (_glowController.value * 0.15)), blurRadius: 16, spreadRadius: 2),
                ],
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.flame, color: AppColors.solarAmber, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Complete today's task", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Run 5km to keep your streak alive.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Tracking Started! Let's go! 🏃‍♂️"),
                        backgroundColor: AppColors.green,
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.solarAmber, foregroundColor: Colors.black, minimumSize: const Size(60, 36)),
                    child: const Text('Go', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        Text('My Challenges', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // 2. ACTIVE CHALLENGES (Cards)
        if (_activeChallenges.isEmpty)
           Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Center(
              child: Text(
                "You haven't joined any challenges yet.",
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ..._activeChallenges.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildProgressCard(
              title: c['title'] as String,
              tier: c['tier'] as String,
              current: (c['current'] as num).toDouble(),
              total: (c['total'] as num).toDouble(),
              rank: c['rank'] as int,
              goalType: c['goalType'] as String?,
              stakes: c['stakes'] as String?,
              isDark: isDark,
              theme: theme,
            ),
          )),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String tier,
    required double current,
    required double total,
    required int rank,
    String? goalType,
    String? stakes,
    required bool isDark,
    required ThemeData theme,
  }) {
    Gradient bgGradient;
    switch (tier) {
      case 'Bronze': bgGradient = const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFE6A869)]); break;
      case 'Silver': bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]); break;
      case 'Gold': bgGradient = const LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFFFD700)]); break;
      case 'Diamond': bgGradient = const LinearGradient(colors: [Color(0xFF4169E1), Color(0xFF00BFFF)]); break;
      default: bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]);
    }

    final pct = (current / total).clamp(0.0, 1.0);
    
    IconData typeIcon = LucideIcons.target;
    if (goalType == 'Distance') typeIcon = LucideIcons.mapPin;
    if (goalType == 'Steps') typeIcon = LucideIcons.footprints;
    if (goalType == 'Workouts') typeIcon = LucideIcons.activity;
    if (goalType == 'Calories') typeIcon = LucideIcons.flame;

    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: tier == 'Gold' || tier == 'Diamond'
            ? [BoxShadow(color: bgGradient.colors.first.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))]
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: Icon(typeIcon, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                          child: const Text('2 days left', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showLeaderboard(context, isDark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.solarAmber, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.barChart2, color: Colors.black, size: 12),
                            const SizedBox(width: 4),
                            Text('Rank #$rank', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${(pct * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(AppColors.voltCyan),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 28,
                      child: Stack(
                        children: [
                          const Positioned(left: 0, child: CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.person, size: 16, color: Colors.black))),
                          const Positioned(left: 20, child: CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.person, size: 16, color: Colors.blue))),
                          Positioned(left: 40, child: CircleAvatar(radius: 14, backgroundColor: Colors.black.withValues(alpha: 0.5), child: const Text('+8', style: TextStyle(color: Colors.white, fontSize: 10)))),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('${current.toInt()}/${total.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          
          if (stakes != null && stakes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.dice5, color: AppColors.solarAmber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wager: $stakes',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: _discoverData.entries.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(category.key, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: category.value.length,
                itemBuilder: (context, index) {
                  final item = category.value[index];
                  return _discoverCard(item, isDark, theme);
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _discoverCard(Map<String, dynamic> item, bool isDark, ThemeData theme) {
    final diffColor = item['color'] as Color;
    
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: diffColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [diffColor.withValues(alpha: 0.8), diffColor.withValues(alpha: 0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(child: Icon(item['icon'] as IconData, size: 36, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(item['tier'] as String, style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.users, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${item['participants']} joined', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _joinChallenge(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: diffColor.withValues(alpha: 0.1),
                      foregroundColor: diffColor,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompletedTab(ThemeData theme, bool isDark) {
    if (_completedChallenges.isEmpty) {
      return Center(
        child: Text(
          "No completed challenges yet. Keep pushing!",
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: _completedChallenges.length,
      itemBuilder: (context, index) {
        final c = _completedChallenges[index];
        return _completedCard(c['title'], c['tier'], c['rank'], c['date'], c['goalType'], isDark, theme);
      },
    );
  }

  Widget _completedCard(String title, String tier, int rank, String date, String goalType, bool isDark, ThemeData theme) {
    Gradient bgGradient;
    switch (tier) {
      case 'Bronze': bgGradient = const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFE6A869)]); break;
      case 'Silver': bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]); break;
      case 'Gold': bgGradient = const LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFFFD700)]); break;
      case 'Diamond': bgGradient = const LinearGradient(colors: [Color(0xFF4169E1), Color(0xFF00BFFF)]); break;
      default: bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgGradient.colors.first.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(color: bgGradient.colors.first.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(gradient: bgGradient, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.trophy, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Completed $date', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.solarAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text('Rank', style: TextStyle(fontSize: 10, color: AppColors.solarAmber, fontWeight: FontWeight.bold)),
                      Text('#$rank', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.solarAmber)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.grey.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.checkCircle2, size: 16, color: bgGradient.colors.first),
                    const SizedBox(width: 8),
                    const Text('Goal Reached!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing coming soon!')));
                  },
                  child: const Row(
                    children: [
                      Icon(LucideIcons.share2, size: 16, color: AppColors.voltCyan),
                      SizedBox(width: 4),
                      Text('Share', style: TextStyle(color: AppColors.voltCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _LeaderboardSheet extends StatelessWidget {
  final bool isDark;

  const _LeaderboardSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const Text('Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          // 5. Podium Widget
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _podiumBar('Sarah', 90, 2, const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)])),
              const SizedBox(width: 8),
              _podiumBar('You', 120, 1, const LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFFFD700)])),
              const SizedBox(width: 8),
              _podiumBar('Mike', 70, 3, const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFE6A869)])),
            ],
          ),
          const SizedBox(height: 32),

          // Leaderboard List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 10,
              itemBuilder: (context, index) {
                final rank = index + 4;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 24, child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                      const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('RunnerGuy22', style: TextStyle(fontWeight: FontWeight.w600))),
                      const Text('450', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      const Icon(LucideIcons.arrowUp, color: AppColors.green, size: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _podiumBar(String name, double height, int rank, Gradient gradient) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(radius: 20, child: Text('$rank')),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(child: Text('$rank', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white))),
        ),
      ],
    );
  }
}
