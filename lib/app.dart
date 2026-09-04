import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/running/running_screen.dart';
import 'screens/health_screen.dart';
import 'screens/study_screen.dart';
import 'screens/history_screen.dart';
import 'screens/chat/chat_home_screen.dart';
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
    const ChatHomeScreen(),
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
        backgroundColor: AppColors.lightBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, ${app.userName.isNotEmpty ? app.userName : "Sudeep"}! 👋',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Ready to crush your goals today?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(LucideIcons.bell, size: 18, color: AppColors.textPrimary),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  },
                ),
                if (app.hasUnreadNotifications)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accentCoral,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => showProfileQuickPanel(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ProfileAvatar(
                imageUrl: app.avatarUrl,
                name: app.userName,
                radius: 17,
              ),
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
