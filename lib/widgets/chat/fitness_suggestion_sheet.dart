import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../providers/step_tracker_provider.dart';

class FitnessSuggestionSheet extends StatefulWidget {
  final ValueChanged<String> onSelect;

  const FitnessSuggestionSheet({
    super.key,
    required this.onSelect,
  });

  @override
  State<FitnessSuggestionSheet> createState() => _FitnessSuggestionSheetState();
}

class _FitnessSuggestionSheetState extends State<FitnessSuggestionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final app = context.watch<AppProvider>();
    final stepTracker = context.watch<StepTrackerProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share Progress & Workouts',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.voltCyan,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.voltCyan,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Phrases'),
                Tab(text: 'My Stats'),
                Tab(text: 'Today\'s Plan'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildPhrasesTab(theme),
                  _buildStatsTab(theme, app, stepTracker),
                  _buildPlansTab(theme, app),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhrasesTab(ThemeData theme) {
    final phrases = [
      'Want to run together?',
      'Great workout today!',
      'Keep your streak alive 🔥',
      "Let's complete today's goal.",
      'Hydrate and keep going 💧',
    ];
    return ListView(
      children: phrases
          .map((p) => ListTile(
                leading: const Icon(LucideIcons.messageSquare, color: AppColors.primary, size: 20),
                title: Text(p),
                onTap: () => widget.onSelect(p),
              ))
          .toList(),
    );
  }

  Widget _buildStatsTab(ThemeData theme, AppProvider app, StepTrackerProvider stepTracker) {
    final stepsMsg = "I have walked ${stepTracker.steps} steps today! 🚶‍♂️";
    final streakMsg = "My workout streak is currently ${app.currentStreak} days! 🔥";
    final caloriesMsg = "I burned ${stepTracker.calories} kcal so far today! ⚡";

    return ListView(
      children: [
        ListTile(
          leading: const Icon(LucideIcons.footprints, color: AppColors.voltCyan),
          title: const Text('Share Today\'s Steps'),
          subtitle: Text('${stepTracker.steps} steps'),
          onTap: () => widget.onSelect(stepsMsg),
        ),
        ListTile(
          leading: const Icon(LucideIcons.flame, color: AppColors.solarAmber),
          title: const Text('Share My Active Streak'),
          subtitle: Text('${app.currentStreak} days'),
          onTap: () => widget.onSelect(streakMsg),
        ),
        ListTile(
          leading: const Icon(LucideIcons.zap, color: AppColors.primary),
          title: const Text('Share Calories Burned'),
          subtitle: Text('${stepTracker.calories} kcal'),
          onTap: () => widget.onSelect(caloriesMsg),
        ),
      ],
    );
  }

  Widget _buildPlansTab(ThemeData theme, AppProvider app) {
    final plans = app.dailyPlans;
    if (plans.isEmpty) {
      return const Center(
        child: Text('No active plans for today', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      children: plans.map((plan) {
        final inviteMsg = "I am doing a ${plan.title} (${plan.duration}m) workout today! Join me? 🏋️‍♂️";
        return ListTile(
          leading: Icon(
            plan.isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
            color: plan.isCompleted ? AppColors.teal : Colors.grey,
          ),
          title: Text(plan.title, style: TextStyle(decoration: plan.isCompleted ? TextDecoration.lineThrough : null)),
          subtitle: Text('${plan.duration}m  •  ${plan.kcal} kcal'),
          trailing: const Icon(LucideIcons.share2, color: AppColors.voltCyan, size: 18),
          onTap: () => widget.onSelect(inviteMsg),
        );
      }).toList(),
    );
  }
}
