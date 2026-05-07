import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/theme_provider.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/fitness_screen.dart';
import 'screens/running_screen.dart';
import 'screens/health_screen.dart';
import 'screens/study_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/chat_screen.dart';
import 'theme/app_colors.dart';

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
    const FitnessScreen(),
    RunningScreen(onFullscreenChanged: (v) => setState(() => _isMapFullscreen = v)),
    const HealthScreen(),
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
              } else if (value == 'Community Chat') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
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
              const PopupMenuItem<String>(value: 'Community Chat', child: Text('💬 Community Chat')),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _isMapFullscreen ? null : Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.95)
              : AppColors.lightSurface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard', index: 0, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: LucideIcons.dumbbell, label: 'Fitness', index: 1, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: LucideIcons.timer, label: 'Run', index: 2, current: _currentIndex, onTap: _onTap, isCenter: true),
                _NavItem(icon: LucideIcons.heartPulse, label: 'Health', index: 3, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: LucideIcons.graduationCap, label: 'Study', index: 4, current: _currentIndex, onTap: _onTap),
              ],
            ),
          ),
        ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final bool isCenter;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    final theme = Theme.of(context);

    if (isCenter) {
      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.gradientPrimary : null,
            color: isActive ? null : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          child: Icon(icon, color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant, size: 22),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            // 1.4 — Animated active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: 3,
              width: isActive ? 20 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
