import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/running/running_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/glass_nav_bar.dart';

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
    const ExploreScreen(),
    RunningScreen(onFullscreenChanged: (v) => setState(() => _isMapFullscreen = v)),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      resizeToAvoidBottomInset: false,
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
              padding: EdgeInsets.only(bottom: _isMapFullscreen ? 0.0 : 80.0),
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
