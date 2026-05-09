import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_colors.dart';


class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0=Active, 1=Discover, 2=Completed
  late ConfettiController _confetti;
  late AnimationController _glowController;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.pulseRed,
        onPressed: () {},
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
                        onPressed: () {},
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
                    onPressed: () {},
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
        _buildProgressCard('100km Run Club', 'Silver', 65, 100, 4, isDark, theme),
        const SizedBox(height: 16),
        _buildProgressCard('Elite Focus Month', 'Gold', 12, 30, 1, isDark, theme),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildProgressCard(String title, String tier, double current, double total, int rank, bool isDark, ThemeData theme) {
    Gradient bgGradient;
    switch (tier) {
      case 'Bronze': bgGradient = const LinearGradient(colors: [Color(0xFF8B4513), Color(0xFFCD853F)]); break;
      case 'Silver': bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]); break;
      case 'Gold': bgGradient = const LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFFFD700)]); break;
      case 'Diamond': bgGradient = const LinearGradient(colors: [Color(0xFF4169E1), Color(0xFF00BFFF)]); break;
      default: bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]);
    }

    final pct = (current / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: tier == 'Gold' || tier == 'Diamond'
            ? [BoxShadow(color: bgGradient.colors.first.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                child: const Text('2 days left', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildDiscoverTab(ThemeData theme, bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: const [
              Chip(label: Text('All'), backgroundColor: AppColors.solarAmber, labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Chip(label: Text('Running')),
              SizedBox(width: 8),
              Chip(label: Text('Fitness')),
              SizedBox(width: 8),
              Chip(label: Text('Study')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
            children: [
              _discoverCard('Summer Shred', 'Medium', AppColors.solarAmber, LucideIcons.activity, isDark, theme),
              _discoverCard('Marathon Prep', 'Hard', AppColors.pulseRed, LucideIcons.footprints, isDark, theme),
              _discoverCard('Zen Month', 'Easy', AppColors.voltCyan, LucideIcons.moon, isDark, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _discoverCard(String title, String diff, Color diffColor, IconData icon, bool isDark, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [diffColor.withValues(alpha: 0.6), diffColor.withValues(alpha: 0.2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(child: Icon(icon, size: 32, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(diff, style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.users, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('1.2k joined', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompletedTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _completedCard('Spring Steps Challenge', 'Silver', 2, isDark, theme),
        const SizedBox(height: 12),
        _completedCard('7 Days of Code', 'Gold', 1, isDark, theme),
      ],
    );
  }

  Widget _completedCard(String title, String tier, int rank, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(LucideIcons.trophy, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Completed Mar 2026', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
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
              _podiumBar('Mike', 70, 3, const LinearGradient(colors: [Color(0xFF8B4513), Color(0xFFCD853F)])),
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
