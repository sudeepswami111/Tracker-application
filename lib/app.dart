import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/theme_provider.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/running_screen.dart';
import 'screens/health_fitness_screen.dart';
import 'screens/study_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/community_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/glass_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
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
    const HealthFitnessScreen(),
    RunningScreen(onFullscreenChanged: (v) => setState(() => _isMapFullscreen = v)),
    const CommunityScreen(),
    const StudyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final app = context.watch<AppProvider>();

    return Scaffold(
      appBar: _isMapFullscreen ? null : AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, ${app.userName} 👋',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              "Here's your progress today",
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 20),
            onPressed: themeProvider.toggleTheme,
          ),
          Stack(
            children: [
              IconButton(icon: const Icon(LucideIcons.bell, size: 20), onPressed: () {
                app.markNotificationsRead();
                showModalBottomSheet(
                  context: context,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (context) => _buildNotificationCenter(context, theme, app),
                );
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
              key: ValueKey<int>(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),
          if (!_isMapFullscreen)
            Align(
              alignment: Alignment.bottomCenter,
              child: GlassNavBar(
                currentIndex: _currentIndex,
                onTap: _onTap,
              ),
            ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildNotificationCenter(BuildContext context, ThemeData theme, AppProvider app) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          if (app.notifications.isEmpty)
             const Text('No new notifications', style: TextStyle(color: Colors.grey)),
          ...app.notifications.map((n) => _NotificationTile(
            icon: n['icon'] as IconData,
            color: n['color'] as Color,
            title: n['title'] as String,
            subtitle: n['subtitle'] as String,
            theme: theme,
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon; final Color color; final String title; final String subtitle; final ThemeData theme;
  const _NotificationTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.theme});
  @override Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ])),
    ]));
  }
}
