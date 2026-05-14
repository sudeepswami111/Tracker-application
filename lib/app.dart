import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/running_screen.dart';
import 'screens/health_screen.dart';
import 'screens/study_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/community_screen.dart';
import 'screens/notifications_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/glass_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isMapFullscreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Permission.notification.request();
      context.read<AppProvider>().syncProfileWithSupabase();
    });
  }

  List<Widget> get _screens => [
    const DashboardScreen(),
    const HealthScreen(),
    RunningScreen(onFullscreenChanged: (v) => setState(() => _isMapFullscreen = v)),
    const CommunityScreen(),
    const StudyScreen(),
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppProvider>();

    return Scaffold(
      appBar: _isMapFullscreen ? null : AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${_getGreeting()}, ${app.userName} 👋',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Ready to crush your goals?",
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(LucideIcons.bell, size: 20), onPressed: () {
                app.markNotificationsRead();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              }),
              if (app.hasUnreadNotifications)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'Profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (value == 'Challenges') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeScreen()));
              } else if (value == 'History') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
              } else if (value == 'Settings') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else if (value == 'Logout') {
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () async {
                      Navigator.pop(ctx);
                      await context.read<AuthProvider>().signOut();
                    }, child: const Text('Logout')),
                  ],
                ));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'Profile', child: Text('Profile')),
              const PopupMenuItem<String>(value: 'Challenges', child: Text('🏅 Challenges')),
              const PopupMenuItem<String>(value: 'History', child: Text('History')),
              const PopupMenuItem<String>(value: 'Settings', child: Text('Settings')),
              const PopupMenuItem<String>(value: 'Logout', child: Text('Logout')),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(app.userName[0].toUpperCase(), style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(app.currentTabIndex),
              child: _screens[app.currentTabIndex],
            ),
          ),
          if (!_isMapFullscreen)
            Align(
              alignment: Alignment.bottomCenter,
              child: GlassNavBar(
                currentIndex: app.currentTabIndex,
                onTap: (index) => app.setTabIndex(index),
              ),
            ),
        ],
      ),
    );
  }

}
