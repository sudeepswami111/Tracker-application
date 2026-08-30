import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../widgets/create_challenge_sheet.dart';
import '../services/challenge_service.dart';
import 'running/running_screen.dart';
import 'workout/fitness_screen.dart';
import 'study_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late ConfettiController _confetti;
  late AnimationController _glowController;
  final _service = ChallengeService();
  bool _isLoading = false;

  // ── Filter state (B2) ──
  String? _filterGoalType;

  List<Map<String, dynamic>> _activeChallenges = [];
  List<Map<String, dynamic>> _completedChallenges = [];
  Map<String, List<Map<String, dynamic>>> _discoverData = {};

  // Fallback local discover data (shown while Supabase loads or fails)
  final Map<String, List<Map<String, dynamic>>> _localDiscoverData = {
    'Running & Cardio': [
      {'title': 'Summer Shred', 'tier': 'Silver', 'icon': LucideIcons.activity, 'participants_count': 1200, 'color': AppColors.solarAmber, 'target_value': 100.0, 'goal_type': 'Distance'},
      {'title': 'Marathon Prep', 'tier': 'Gold', 'icon': LucideIcons.footprints, 'participants_count': 4500, 'color': AppColors.pulseRed, 'target_value': 500.0, 'goal_type': 'Distance'},
    ],
    'Fitness & Strength': [
      {'title': 'Iron Man Prep Month', 'tier': 'Diamond', 'icon': Icons.fitness_center, 'participants_count': 800, 'color': AppColors.irisViolet, 'target_value': 1000.0, 'goal_type': 'Workouts'},
      {'title': 'Daily Pushups', 'tier': 'Bronze', 'icon': LucideIcons.flame, 'participants_count': 12000, 'color': AppColors.green, 'target_value': 30.0, 'goal_type': 'Workouts'},
    ],
    'Study & Focus': [
      {'title': 'Zen Month', 'tier': 'Bronze', 'icon': LucideIcons.moon, 'participants_count': 3400, 'color': AppColors.voltCyan, 'target_value': 30.0, 'goal_type': 'Study'},
      {'title': 'Deep Work Sprint', 'tier': 'Silver', 'icon': LucideIcons.book, 'participants_count': 5200, 'color': AppColors.solarAmber, 'target_value': 60.0, 'goal_type': 'Study'},
    ],
  };

  // B3 helper: compute days left from endDate string
  String _getDaysLeft(String? endDateStr) {
    if (endDateStr == null || endDateStr.isEmpty) return 'Ongoing';
    try {
      final endDate = DateTime.parse(endDateStr);
      final days = endDate.difference(DateTime.now()).inDays;
      if (days < 0) return 'Ended';
      if (days == 0) return 'Last day!';
      return '$days days left';
    } catch (_) {
      return 'Ongoing';
    }
  }

  // B2 — filter getter
  List<Map<String, dynamic>> get _filteredActiveChallenges {
    return _activeChallenges.where((c) {
      // Support both raw local maps and Supabase nested maps
      final goalType = (c['goalType'] as String?) ?? (c['challenge']?['goal_type'] as String?);
      if (_filterGoalType != null && goalType != _filterGoalType) return false;
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _discoverData = _localDiscoverData;
    _isLoading = false;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _service.getActiveChallenges(),
        _service.getCompletedChallenges(),
        _service.getDiscoverChallenges(),
      ]);
      if (mounted) {
        setState(() {
          _activeChallenges = results[0] as List<Map<String, dynamic>>;
          _completedChallenges = results[1] as List<Map<String, dynamic>>;
          final remoteDiscover = results[2] as Map<String, List<Map<String, dynamic>>>;
          // Fall back to local discover data if Supabase table is empty
          _discoverData = remoteDiscover.isNotEmpty ? remoteDiscover : _localDiscoverData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_discoverData.isEmpty) _discoverData = _localDiscoverData;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _showLeaderboard(BuildContext context, bool isDark, String? challengeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LeaderboardSheet(isDark: isDark, challengeId: challengeId ?? ''),
    );
  }

  // B2 — functional filter sheet using StatefulBuilder
  void _showFilterSheet(BuildContext context, bool isDark) {
    String? tempGoalType = _filterGoalType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
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
              const Text('Goal Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Steps', 'Distance', 'Workouts', 'Study', 'Calories'].map((g) => ChoiceChip(
                  label: Text(g),
                  selected: tempGoalType == g,
                  onSelected: (v) => setSheetState(() => tempGoalType = v ? g : null),
                  selectedColor: AppColors.voltCyan.withValues(alpha: 0.2),
                )).toList(),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _filterGoalType = null);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _filterGoalType = tempGoalType);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.voltCyan),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _joinChallenge(Map<String, dynamic> challengeData) async {
    final challengeId = challengeData['id'] as String?;
    if (challengeId != null) {
      await _service.joinChallenge(challengeId);
    }
    setState(() {
      _activeChallenges.insert(0, {
        'title': challengeData['title'],
        'tier': challengeData['tier'],
        'current': 0.0,
        'total': (challengeData['target_value'] ?? challengeData['total'] ?? 100.0),
        'rank': 1,
        'goalType': challengeData['goal_type'] ?? 'Distance',
        'stakes': null,
        'endDate': null,
        'participantsCount': challengeData['participants_count'] ?? 0,
      });
    });
    _confetti.play();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Joined "${challengeData['title']}"! 🎉'),
        backgroundColor: AppColors.irisViolet,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.pulseRed,
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final result = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const CreateChallengeSheet(),
          );
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Challenges', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                      Row(
                        children: [
                          if (_filterGoalType != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.voltCyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text(_filterGoalType!, style: const TextStyle(color: AppColors.voltCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          IconButton(
                            icon: Icon(LucideIcons.filter,
                              color: _filterGoalType != null ? AppColors.voltCyan : theme.colorScheme.onSurfaceVariant),
                            onPressed: () => _showFilterSheet(context, isDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.voltCyan,
                    onRefresh: _loadData,
                    child: _selectedTab == 0
                        ? _buildActiveTab(theme, isDark)
                        : _selectedTab == 1
                            ? _buildDiscoverTab(theme, isDark)
                            : _buildCompletedTab(theme, isDark),
                  ),
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
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(ThemeData theme, bool isDark) {
    final filtered = _filteredActiveChallenges;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // Daily Nudge (B1 — Go button navigates)
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
                        Text(
                          _activeChallenges.isNotEmpty
                              ? 'Continue "${_getTitle(_activeChallenges.first)}" — keep your streak!'
                              : 'Run 5km to keep your streak alive.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // B1 — navigate based on goalType
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      final first = _activeChallenges.isNotEmpty ? _activeChallenges.first : null;
                      if (first == null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
                        return;
                      }
                      final goalType = (first['goalType'] as String?)
                          ?? (first['challenge']?['goal_type'] as String?)
                          ?? 'Distance';
                      if (goalType == 'Distance' || goalType == 'Steps') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
                      } else if (goalType == 'Workouts' || goalType == 'Calories') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessScreen()));
                      } else if (goalType == 'Study') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyScreen()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
                      }
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
        Row(
          children: [
            Text('My Challenges', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (_filterGoalType != null)
              Text('Filtered: $_filterGoalType', style: const TextStyle(color: AppColors.voltCyan, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Center(
              child: Text(
                _filterGoalType != null
                    ? 'No $_filterGoalType challenges. Try clearing the filter.'
                    : "You haven't joined any challenges yet.\nTap Discover to explore!",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...filtered.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildProgressCard(c, isDark, theme),
          )),
        const SizedBox(height: 100),
      ],
    );
  }

  // Helper to get title from both local and Supabase-shaped maps
  String _getTitle(Map<String, dynamic> c) {
    return (c['title'] as String?) ??
        (c['challenge']?['title'] as String?) ??
        'Challenge';
  }

  Widget _buildProgressCard(Map<String, dynamic> c, bool isDark, ThemeData theme) {
    // Support both flat local maps and Supabase nested maps
    final challenge = c['challenge'] as Map<String, dynamic>? ?? c;
    final title = (c['title'] as String?) ?? (challenge['title'] as String?) ?? 'Challenge';
    final tier = (c['tier'] as String?) ?? (challenge['tier'] as String?) ?? 'Silver';
    final current = (c['current'] as num?)?.toDouble()
        ?? (c['current_value'] as num?)?.toDouble()
        ?? 0.0;
    final total = (c['total'] as num?)?.toDouble()
        ?? (challenge['target_value'] as num?)?.toDouble()
        ?? 100.0;
    final rank = (c['rank'] as int?) ?? 1;
    final goalType = (c['goalType'] as String?) ?? (challenge['goal_type'] as String?);
    final stakes = (c['stakes'] as String?) ?? (challenge['stakes'] as String?);
    final endDate = (c['endDate'] as String?) ?? (challenge['end_date'] as String?);
    final participantsCount = (c['participantsCount'] as int?)
        ?? (challenge['participants_count'] as int?) ?? 0;
    final challengeId = (c['id'] as String?) ?? (challenge['id'] as String?);

    Gradient bgGradient;
    switch (tier) {
      case 'Bronze': bgGradient = const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFE6A869)]); break;
      case 'Silver': bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]); break;
      case 'Gold': bgGradient = const LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFFFD700)]); break;
      case 'Diamond': bgGradient = const LinearGradient(colors: [Color(0xFF4169E1), Color(0xFF00BFFF)]); break;
      default: bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]);
    }

    final pct = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    IconData typeIcon = LucideIcons.target;
    if (goalType == 'Distance') typeIcon = LucideIcons.mapPin;
    if (goalType == 'Steps') typeIcon = LucideIcons.footprints;
    if (goalType == 'Workouts') typeIcon = LucideIcons.activity;
    if (goalType == 'Calories') typeIcon = LucideIcons.flame;
    if (goalType == 'Study') typeIcon = LucideIcons.book;

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
                        // B3 — Real days left
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            _getDaysLeft(endDate),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showLeaderboard(context, isDark, challengeId),
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
                if (goalType != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(goalType, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ),
                const SizedBox(height: 20),
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
                    // B5 — Use real participantsCount
                    SizedBox(
                      width: 70,
                      height: 28,
                      child: Stack(
                        children: [
                          const Positioned(left: 0, child: CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.person, size: 16, color: Colors.black))),
                          const Positioned(left: 20, child: CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.person, size: 16, color: Colors.blue))),
                          if (participantsCount > 2)
                            Positioned(
                              left: 40,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black.withValues(alpha: 0.5),
                                child: Text(
                                  participantsCount > 2 ? '+${participantsCount - 2}' : '',
                                  style: const TextStyle(color: Colors.white, fontSize: 9),
                                ),
                              ),
                            ),
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
    final data = _discoverData.isNotEmpty ? _discoverData : _localDiscoverData;
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: data.entries.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(category.key, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 225,
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
    final diffColor = (item['color'] as Color?) ?? AppColors.voltCyan;
    final participantsCount = (item['participants_count'] as int?) ?? (item['participants'] as int?) ?? 0;

    IconData icon = LucideIcons.target;
    if (item.containsKey('icon')) {
      try { icon = item['icon'] as IconData; } catch (_) {}
    }

    return Container(
      width: 162,
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
            child: Center(child: Icon(icon, size: 36, color: Colors.white)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(item['tier'] as String? ?? 'Silver', style: TextStyle(color: diffColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  Text(item['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.users, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        participantsCount >= 1000
                            ? '${(participantsCount / 1000).toStringAsFixed(1)}k joined'
                            : '$participantsCount joined',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _joinChallenge(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: diffColor.withValues(alpha: 0.15),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTab(ThemeData theme, bool isDark) {
    if (_completedChallenges.isEmpty) {
      return Center(
        child: Text(
          "No completed challenges yet.\nKeep pushing! 💪",
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: _completedChallenges.length,
      itemBuilder: (context, index) {
        final c = _completedChallenges[index];
        final challenge = c['challenge'] as Map<String, dynamic>? ?? c;
        final title = (c['title'] as String?) ?? (challenge['title'] as String?) ?? 'Challenge';
        final tier = (c['tier'] as String?) ?? (challenge['tier'] as String?) ?? 'Silver';
        final rank = (c['rank'] as int?) ?? 1;
        final completedAt = (c['date'] as String?) ?? (c['completed_at'] as String?);
        return _completedCard(title, tier, rank, completedAt, isDark, theme);
      },
    );
  }

  Widget _completedCard(String title, String tier, int rank, String? completedAt, bool isDark, ThemeData theme) {
    Gradient bgGradient;
    switch (tier) {
      case 'Bronze': bgGradient = const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFE6A869)]); break;
      case 'Silver': bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]); break;
      case 'Gold': bgGradient = const LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFFFD700)]); break;
      case 'Diamond': bgGradient = const LinearGradient(colors: [Color(0xFF4169E1), Color(0xFF00BFFF)]); break;
      default: bgGradient = const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]);
    }

    String dateStr = 'Recently';
    if (completedAt != null && completedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(completedAt);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        dateStr = '${months[dt.month - 1]} ${dt.year}';
      } catch (_) {
        dateStr = completedAt;
      }
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
                      Text('Completed $dateStr', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
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
                // B4 — Real share functionality
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final text = 'I completed the "$title" challenge and ranked #$rank! 🏆 Powered by LifePulse 💪';
                    await Share.share(text);
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
          ),
        ],
      ),
    );
  }
}

// M4 — Leaderboard Sheet now loads real data from Supabase
class _LeaderboardSheet extends StatefulWidget {
  final bool isDark;
  final String challengeId;

  const _LeaderboardSheet({required this.isDark, required this.challengeId});

  @override
  State<_LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<_LeaderboardSheet> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    if (widget.challengeId.isEmpty) {
      // No ID — show mock
      setState(() {
        _rows = [];
        _loading = false;
      });
      return;
    }
    try {
      final data = await ChallengeService().getLeaderboard(widget.challengeId);
      if (mounted) setState(() { _rows = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
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
          const SizedBox(height: 24),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_rows.isEmpty)
            // Podium with mock fallback
            Expanded(
              child: Column(
                children: [
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
                  const SizedBox(height: 24),
                  const Text('Join this challenge to see the real leaderboard!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Podium top 3
                  if (_rows.length >= 3)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _podiumBarFromRow(_rows[1], 2, 90),
                        const SizedBox(width: 8),
                        _podiumBarFromRow(_rows[0], 1, 120),
                        const SizedBox(width: 8),
                        _podiumBarFromRow(_rows[2], 3, 70),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _rows.length > 3 ? _rows.length - 3 : 0,
                      itemBuilder: (context, index) {
                        final row = _rows[index + 3];
                        final user = row['user'] as Map<String, dynamic>? ?? {};
                        final name = (user['full_name'] as String?) ?? 'User';
                        final value = (row['current_value'] as num?)?.toInt() ?? 0;
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
                              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
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
            ),
        ],
      ),
    );
  }

  Widget _podiumBarFromRow(Map<String, dynamic> row, int rank, double height) {
    final user = row['user'] as Map<String, dynamic>? ?? {};
    final name = (user['full_name'] as String?) ?? 'User';
    const gradients = {
      1: LinearGradient(colors: [Color(0xFFB8860B), Color(0xFFFFD700)]),
      2: LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]),
      3: LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFE6A869)]),
    };
    return _podiumBar(name, height, rank, gradients[rank] ?? const LinearGradient(colors: [Color(0xFF708090), Color(0xFFC0C0C0)]));
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
