import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'providers/app_provider.dart';
import 'providers/running_provider.dart';
import 'providers/watch_metrics_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/step_tracker_provider.dart';
import 'theme/app_theme.dart';
import 'app.dart';
import 'screens/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final prefs = await SharedPreferences.getInstance();
  await NotificationService.init();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Handle OAuth deep links (e.g. after Google sign-in redirects back to the app).
  // supabase_flutter v2 uses PKCE — the redirect URL contains a one-time code
  // that must be exchanged for a session.
  final appLinks = AppLinks();

  // Cold-start: app was opened directly by the deep link
  try {
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
    }
  } catch (_) {}

  // Warm-start: app was already running when the deep link arrived
  appLinks.uriLinkStream.listen((uri) async {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_) {}
  });
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider(prefs)..startLiveSimulation()),
        ChangeNotifierProvider(create: (_) => RunningProvider()),
        ChangeNotifierProvider(create: (_) => WatchMetricsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProxyProvider<AppProvider, StepTrackerProvider>(
          create: (context) => StepTrackerProvider(),
          update: (context, appProvider, stepTracker) {
            stepTracker?.setAppProvider(appProvider);
            return stepTracker ?? StepTrackerProvider();
          },
        ),
      ],
      child: const LifePulseApp(),
    ),
  );
}

class LifePulseApp extends StatelessWidget {
  const LifePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDark;
        // Sync status bar icon brightness with theme
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
          ),
        );
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'LifePulse',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return auth.isAuthenticated ? const AppShell() : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
