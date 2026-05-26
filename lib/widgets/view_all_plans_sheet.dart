import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../screens/challenge_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../providers/weather_provider.dart';
import 'smart_today_plan_card.dart';

class ViewAllPlansSheet extends StatelessWidget {
  const ViewAllPlansSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppProvider>();
    final weather = context.watch<WeatherProvider>().weather;

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
                        child: SmartTodayPlanCard(
                          plan: plan,
                          weather: weather,
                          app: app,
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
