import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../screens/challenge_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'daily_plan_tile.dart';

class ViewAllPlansSheet extends StatelessWidget {
  const ViewAllPlansSheet({super.key});

  Color _getAccentColor(String type) {
    switch (type) {
      case 'Run':
        return AppColors.pulseRed;
      case 'Yoga':
      case 'Swim':
        return AppColors.voltCyan;
      case 'Gym':
        return AppColors.solarAmber;
      case 'Cycle':
        return AppColors.irisViolet;
      default:
        return AppColors.pulseRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppProvider>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('All Plans', style: theme.textTheme.headlineMedium),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: app.dailyPlans.isEmpty
                ? const Center(child: Text('No plans available.'))
                : ListView.builder(
                    itemCount: app.dailyPlans.length,
                    itemBuilder: (context, index) {
                      final plan = app.dailyPlans[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: DailyPlanTile(
                          activityName: plan.title,
                          durationOrReps: plan.duration,
                          kcal: plan.kcal,
                          imageUrl: plan.imageUrl,
                          isCompleted: plan.isCompleted,
                          accentColor: _getAccentColor(plan.type),
                          onStart: () {
                            app.togglePlanComplete(plan.id);
                            if (!plan.isCompleted) {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeScreen()));
                            }
                          },
                          onDelete: () {
                            app.removeDailyPlan(plan.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
