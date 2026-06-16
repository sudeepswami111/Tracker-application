import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'widgets/profile_avatar.dart';
import 'widgets/profile_quick_panel.dart';


class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isMapFullscreen = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<AppProvider>().currentTabIndex;
    _pageController = PageController(initialPage: initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Permission.notification.request();
      context.read<AppProvider>().syncProfileWithSupabase();
      _loadInitialUnreadCount();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUnreadCount() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final res = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false);
      if (!mounted) return;
      context.read<AppProvider>().setUnreadCount((res as List).length);
    } catch (_) {}
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
      resizeToAvoidBottomInset: false,
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              }),
              if (app.hasUnreadNotifications)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      app.unreadNotificationCount > 99 ? '99+' : '${app.unreadNotificationCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => showProfileQuickPanel(context),
            child: ProfileAvatar(
              imageUrl: app.avatarUrl,
              name: app.userName,
              radius: 18,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              final app = context.read<AppProvider>();
              if (app.currentTabIndex != index) {
                app.setTabIndex(index);
                HapticFeedback.selectionClick();
              }
            },
            children: _screens.map((screen) => Padding(
              padding: EdgeInsets.only(bottom: _isMapFullscreen ? 0.0 : 110.0),
              child: screen,
            )).toList(),
          ),
          if (!_isMapFullscreen)
            Align(
              alignment: Alignment.bottomCenter,
              child: GlassNavBar(
                currentIndex: app.currentTabIndex,
                onTap: (index) {
                  app.setTabIndex(index);
                  _pageController.jumpToPage(index);
                },
              ),
            ),
        ],
      ),
    );
  }

}
