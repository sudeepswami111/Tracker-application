import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'fitness_screen.dart';
import 'health_screen.dart';
import '../theme/app_colors.dart';

class HealthFitnessScreen extends StatelessWidget {
  const HealthFitnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health & Fitness'),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(icon: Icon(LucideIcons.heartPulse), text: 'Health'),
              Tab(icon: Icon(LucideIcons.dumbbell), text: 'Fitness'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HealthScreen(),
            FitnessScreen(),
          ],
        ),
      ),
    );
  }
}
