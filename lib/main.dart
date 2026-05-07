import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'providers/app_provider.dart';
import 'providers/running_provider.dart';
import 'providers/watch_metrics_provider.dart';
import 'providers/auth_provider.dart';
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
