import 'package:flutter/material.dart';
import 'package:hybrid_tab_bar/hybrid_tab_bar.dart';

void main() {
  runApp(const HybridTabBarExampleApp());
}

class HybridTabBarExampleApp extends StatelessWidget {
  const HybridTabBarExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hybrid Tab Bar Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF212B6E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HybridTabBarScaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      bottomItems: const [
        // "Assistant" has NO segmented sub-tabs
        HybridNavItem(
          icon: Icons.auto_awesome,
          label: "Assistant",
        ),
        // "Explore" has segmented tabs
        HybridNavItem(
          icon: Icons.explore,
          label: "Explore",
          segmentedTabs: ["Rooms", "Inspiration", "Profiles"],
        ),
        // "Configs" has NO segmented tabs
        HybridNavItem(
          icon: Icons.settings,
          label: "Configs",
        ),
      ],
      style: HybridTabStyle.light,
      bodyBuilder: (bottomIndex, segmentedIndex) {
        switch (bottomIndex) {
          case 0:
            // "Explore" sub-tabs
            return [
              const _DemoPage(
                title: "Rooms",
                subtitle: "Explore available rooms",
                icon: Icons.meeting_room_outlined,
                gradient: [Color(0xFFE8EAF6), Color(0xFFF0F2F8)],
              ),
              const _DemoPage(
                title: "Inspiration",
                subtitle: "Discover new ideas",
                icon: Icons.lightbulb_outline,
                gradient: [Color(0xFFF3E5F5), Color(0xFFF0F2F8)],
              ),
              const _DemoPage(
                title: "Profiles",
                subtitle: "Browse user profiles",
                icon: Icons.person_outline,
                gradient: [Color(0xFFE0F2F1), Color(0xFFF0F2F8)],
              ),
            ][segmentedIndex];
          case 1:
            return const _DemoPage(
              title: "Assistant",
              subtitle: "Your AI assistant",
              icon: Icons.auto_awesome,
              gradient: [Color(0xFFFFF3E0), Color(0xFFF0F2F8)],
            );
          case 2:
            return const _DemoPage(
              title: "Configs",
              subtitle: "Settings & preferences",
              icon: Icons.settings,
              gradient: [Color(0xFFEDE7F6), Color(0xFFF0F2F8)],
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _DemoPage extends StatelessWidget {
  const _DemoPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 72,
                color: const Color(0xFF212B6E).withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF212B6E),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF8090A0),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
