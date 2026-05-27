import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/step_tracker_provider.dart';
import '../providers/watch_metrics_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../screens/profile_screen.dart';
import '../widgets/device_scanner_sheet.dart';
import '../widgets/permission_request_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local calorie budget (could be customized later)
  final double _calorieBudget = 2400;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDeep : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // 2. ACCOUNT SECTION
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: app.profileImagePath.isNotEmpty
                          ? DecorationImage(image: FileImage(File(app.profileImagePath)), fit: BoxFit.cover)
                          : null,
                      color: AppColors.surfaceElevated,
                    ),
                    child: app.profileImagePath.isEmpty
                        ? Center(child: Text(app.userName.isNotEmpty ? app.userName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.userName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          Supabase.instance.client.auth.currentUser?.email ?? 'No email',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurfaceVariant, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. HEALTH & DEVICES
          _sectionHeader('Health & Devices'),
          Consumer<WatchMetricsProvider>(
            builder: (context, watch, _) {
              return GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _settingsRow(LucideIcons.heartPulse, 'Health Connect', Switch.adaptive(
                      value: app.healthConnectEnabled,
                      activeTrackColor: AppColors.voltCyan,
                      onChanged: (v) => app.setHealthConnectEnabled(v),
                    )),
                    _divider(),
                    _settingsRow(LucideIcons.bluetooth, 'Bluetooth Devices', GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const DeviceScannerSheet(),
                        );
                      },
                      child: _chevronRow(
                        watch.isConnected
                            ? (watch.deviceName.isNotEmpty ? watch.deviceName : 'Connected')
                            : 'Disconnected',
                      ),
                    )),
                    _divider(),
                    _settingsRow(LucideIcons.shieldCheck, 'Data Permissions', GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const PermissionRequestSheet(),
                        );
                      },
                      child: _chevronRow(''),
                    )),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 4. MODULES
          _sectionHeader('Modules'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.footprints, size: 20, color: Colors.grey),
                          const SizedBox(width: 12),
                          const Text('Daily Steps Goal'),
                          const Spacer(),
                          Text('${app.dailyStepsGoal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider.adaptive(
                        value: app.dailyStepsGoal,
                        min: 1000,
                        max: 100000,
                        divisions: 99,
                        activeColor: AppColors.voltCyan,
                        onChanged: (v) => app.setDailyStepsGoal(v),
                        onChangeEnd: (v) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Daily step goal updated to ${v.toInt()}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _divider(),
                _settingsRow(LucideIcons.bookOpen, 'Pomodoro Duration', 
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(LucideIcons.minusCircle, color: Colors.grey), onPressed: () {
                        if (app.pomodoroDuration > 5) app.setPomodoroDuration(app.pomodoroDuration - 5);
                      }),
                      SizedBox(width: 40, child: Text('${app.pomodoroDuration} m', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(LucideIcons.plusCircle, color: Colors.grey), onPressed: () {
                        if (app.pomodoroDuration < 60) app.setPomodoroDuration(app.pomodoroDuration + 5);
                      }),
                    ],
                  )
                ),
                _divider(),
                _settingsRow(LucideIcons.apple, 'Calorie Budget', _chevronRow('${_calorieBudget.toInt()} kcal')),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. NOTIFICATIONS
          _sectionHeader('Notifications'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _settingsRow(LucideIcons.bell, 'Master Toggle', Switch.adaptive(
                  value: app.masterNotifications,
                  activeTrackColor: AppColors.voltCyan,
                  onChanged: (v) => app.setMasterNotifications(v),
                )),
                if (app.masterNotifications) ...[
                  _divider(),
                  _settingsRow(LucideIcons.activity, 'Workout Reminders', Switch.adaptive(
                    value: app.workoutReminders,
                    activeTrackColor: AppColors.voltCyan,
                    onChanged: (v) => app.setWorkoutReminders(v),
                  )),
                  _divider(),
                  _settingsRow(LucideIcons.bookOpen, 'Study Reminders', Switch.adaptive(
                    value: app.studyReminders,
                    activeTrackColor: AppColors.voltCyan,
                    onChanged: (v) => app.setStudyReminders(v),
                  )),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 6. APPEARANCE
          _sectionHeader('Appearance'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _themeSegment(ThemeMode.light, 'Light', themeProvider.themeMode),
                      _themeSegment(ThemeMode.system, 'System', themeProvider.themeMode),
                      _themeSegment(ThemeMode.dark, 'Dark', themeProvider.themeMode),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Accent Override', style: TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        _accentSwatch(AppColors.voltCyan, true),
                        const SizedBox(width: 12),
                        _accentSwatch(AppColors.pulseRed, false),
                        const SizedBox(width: 12),
                        _accentSwatch(AppColors.irisViolet, false),
                        const SizedBox(width: 12),
                        _accentSwatch(AppColors.solarAmber, false),
                        const SizedBox(width: 12),
                        _accentSwatch(Colors.white, false),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 7. DATA & PRIVACY
          _sectionHeader('Data & Privacy'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.download, color: AppColors.voltCyan, size: 20),
                  title: const Text('Export My Data', style: TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final app = context.read<AppProvider>();
                    final data = {
                      'exported_at': DateTime.now().toIso8601String(),
                      'steps_today': context.read<StepTrackerProvider>().steps,
                      'current_streak': app.currentStreak,
                      'distance_km': app.distance,
                      'study_minutes': app.totalStudyMinutes,
                      'daily_plans': app.dailyPlans.map((p) => p.toJson()).toList(),
                    };
                    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/lifepulse_export.json');
                    await file.writeAsString(jsonStr);
                    await Share.shareXFiles([XFile(file.path)], text: 'My LifePulse Data Export');
                  },
                ),
                _divider(),
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: AppColors.pulseRed, size: 20),
                  title: const Text('Delete Account', style: TextStyle(color: AppColors.pulseRed, fontWeight: FontWeight.bold)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Account'),
                        content: const Text(
                          'This will permanently delete your account and all your data. This cannot be undone.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                final supabase = Supabase.instance.client;
                                final uid = supabase.auth.currentUser?.id;
                                if (uid != null) {
                                  await supabase.from('profiles').delete().eq('id', uid);
                                }
                                await context.read<AuthProvider>().signOut();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error deleting account: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pulseRed),
                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _divider(),
                ListTile(
                  leading: const Icon(LucideIcons.shield, color: Colors.grey, size: 20),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(LucideIcons.externalLink, size: 16, color: Colors.grey),
                  onTap: () async {
                    const url = 'https://example.com/privacy';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 8. ABOUT
          _sectionHeader('About'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.info, color: Colors.grey, size: 20),
                  title: const Text('Version'),
                  trailing: const Text('v2.4.0 (Build 342)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                _divider(),
                ListTile(
                  leading: const Icon(LucideIcons.star, color: Colors.grey, size: 20),
                  title: const Text('Rate App'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                  onTap: () async {
                    const url = 'https://play.google.com/store/apps/details?id=com.yourapp.lifepulse';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // 9. SIGN OUT
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await context.read<AuthProvider>().signOut();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.pulseRed),
                        child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.pulseRed,
                side: const BorderSide(color: AppColors.pulseRed, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _settingsRow(IconData icon, String title, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          trailing,
        ],
      ),
    );
  }

  Widget _chevronRow(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 8),
        const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 16),
      ],
    );
  }

  Widget _divider() {
    return Divider(height: 1, indent: 52, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1));
  }

  Widget _themeSegment(ThemeMode mode, String label, ThemeMode currentMode) {
    final isSelected = mode == currentMode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<ThemeProvider>().setThemeMode(mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accentSwatch(Color color, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<ThemeProvider>().setAccentColor(color),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: context.watch<ThemeProvider>().accentColor == color
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: context.watch<ThemeProvider>().accentColor == color
            ? const Icon(Icons.check, color: Colors.black, size: 14)
            : null,
      ),
    );
  }
}
