import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/progress_ring.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    // Generate or refresh challenges on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().generateWeeklyChallenges();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _onClaim(AppProvider app, ChallengeModel c) {
    if (!c.isCompleted) return;
    app.claimChallenge(c);
    _confetti.play();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final challenges = app.activeChallenges;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? AppColors.darkBg
          : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('7-Day Challenges'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Regenerate',
            onPressed: () => app.generateWeeklyChallenges(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Confetti overlay
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
            colors: const [
              AppColors.primary,
              AppColors.coral,
              AppColors.green,
              AppColors.yellow,
              AppColors.secondary,
            ],
          ),

          challenges.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.trophy,
                            size: 64,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white24
                                : Colors.black12),
                        const SizedBox(height: 16),
                        Text('No challenges yet',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Complete at least a few days of tracking to generate personalised challenges.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => app.generateWeeklyChallenges(),
                          icon: const Icon(LucideIcons.zap, size: 16),
                          label: const Text('Generate now'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${challenges.where((c) => c.isCompleted).length}/${challenges.length} completed',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ...challenges.map((c) => _ChallengeCard(
                          challenge: c,
                          onClaim: () => _onClaim(app, c),
                        )),
                    const SizedBox(height: 100),
                  ],
                ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback onClaim;

  const _ChallengeCard({required this.challenge, required this.onClaim});

  Color _accentColor() {
    switch (challenge.metric) {
      case 'steps':
        return AppColors.primary;
      case 'calories':
        return AppColors.coral;
      case 'sleepHours':
        return AppColors.green;
      case 'waterGlasses':
        return AppColors.secondary;
      case 'studyHrs':
        return AppColors.pink;
      default:
        return AppColors.primary;
    }
  }

  String _formatValue(double v, String metric) {
    switch (metric) {
      case 'steps':
        return '${v.toInt()} steps';
      case 'calories':
        return '${v.toInt()} kcal';
      case 'sleepHours':
        return '${v.toStringAsFixed(1)} hrs sleep';
      case 'waterGlasses':
        return '${v.toInt()} glasses';
      case 'studyHrs':
        return '${v.toStringAsFixed(1)} hrs study';
      default:
        return v.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _accentColor();
    final pct = (c.currentValue / c.targetValue).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer.withValues(alpha: 0.7)
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: c.isCompleted
              ? color.withValues(alpha: 0.4)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06)),
          width: c.isCompleted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Progress ring
          ProgressRing(
            size: 72,
            strokeWidth: 6,
            progress: pct * 100,
            color: color,
            label: '${(pct * 100).round()}%',
            sublabel: '',
            fontSize: 14,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (c.isCompleted && !c.claimed)
                      GestureDetector(
                        onTap: onClaim,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text('Claim 🏅',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (c.claimed)
                      Icon(LucideIcons.badgeCheck, color: color, size: 22),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatValue(c.currentValue, c.metric)} / ${_formatValue(c.targetValue, c.metric)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.isCompleted
                      ? '✅ Challenge complete!'
                      : '${c.daysLeft} days left',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: c.isCompleted ? AppColors.green : null,
                    fontWeight:
                        c.isCompleted ? FontWeight.w700 : FontWeight.normal,
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
