import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../services/health_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/progress_ring.dart';
import '../theme/app_colors.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool _isConnected = false;
  bool _isSyncing = false;
  DateTime? _lastSynced;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _loadConnectionState();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  // ── 3.4 Restore connection + auto-sync on startup ──
  Future<void> _loadConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    final connected = prefs.getBool('watchConnected') ?? false;
    if (connected && mounted) {
      setState(() => _isConnected = true);
      await _syncNow();
      // 3.4 — 15-minute periodic sync
      _syncTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => _syncNow(),
      );
    }
  }

  // ── 3.3 Connect button handler ──
  Future<void> _onConnectPressed() async {
    setState(() => _isSyncing = true);
    final granted = await HealthService().requestPermissions();
    if (!mounted) return;
    if (granted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('watchConnected', true);
      setState(() => _isConnected = true);
      await _syncNow();
      // Start periodic timer
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => _syncNow(),
      );
    } else {
      setState(() => _isSyncing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health permissions not granted.'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  // ── 3.3/3.4 Sync health data and push to AppProvider ──
  Future<void> _syncNow() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    final data = await HealthService().fetchTodayData();
    if (!mounted) return;
    if (data.isNotEmpty) {
      context.read<AppProvider>().updateFromHealth(data);
    }
    setState(() {
      _isSyncing = false;
      _lastSynced = DateTime.now();
    });
  }

  String _formatSynced(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Monitor', style: theme.textTheme.displayLarge),
          const SizedBox(height: 4),
          Text('Track your vitals and wellness metrics',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),

          // ── 3.3 Watch Connect Card ──
          _WatchConnectCard(
            isConnected: _isConnected,
            isSyncing: _isSyncing,
            lastSynced: _lastSynced,
            formatSynced: _formatSynced,
            onConnect: _onConnectPressed,
            onSyncNow: _syncNow,
          ),
          const SizedBox(height: 16),

          // Heart Rate
          GlassCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Row(children: [
                    Icon(LucideIcons.heart,
                        size: 18, color: AppColors.coral),
                    const SizedBox(width: 8),
                    Text('Heart Rate',
                        style: theme.textTheme.titleLarge)
                  ]),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('LIVE',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.coral,
                              fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 16),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Icon(LucideIcons.heart,
                        size: 28, color: AppColors.coral),
                    const SizedBox(width: 8),
                    Text('${app.heartRate}',
                        style: theme.textTheme.displayLarge
                            ?.copyWith(fontSize: 48)),
                    const SizedBox(width: 4),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('BPM',
                            style: theme.textTheme.bodySmall)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Resting ${app.restingHR}',
                        style: theme.textTheme.bodySmall),
                    Text('Max ${app.maxHR}',
                        style: theme.textTheme.bodySmall),
                  ]),
                ]),
                const SizedBox(height: 16),
                _zoneBar('Rest', '14h', AppColors.blue, 14 / 24, theme),
                _zoneBar(
                    'Fat Burn', '6h', AppColors.green, 6 / 24, theme),
                _zoneBar('Cardio', '3h', AppColors.yellow, 3 / 24, theme),
                _zoneBar('Peak', '1h', AppColors.coral, 1 / 24, theme),
              ])),
          const SizedBox(height: 16),

          // Sleep
          GlassCard(
              child: Column(children: [
            Row(children: [
              Icon(LucideIcons.moon, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text('Sleep', style: theme.textTheme.titleLarge)
            ]),
            const SizedBox(height: 16),
            ProgressRing(
                size: 140,
                strokeWidth: 12,
                progress: app.sleepQuality,
                color: AppColors.blue,
                label: '${app.sleepHours}h',
                sublabel: '${app.sleepQuality.toInt()}% quality',
                fontSize: 24),
            const SizedBox(height: 16),
            GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _sleepStage(
                      'Deep', '${app.sleepDeep}h', AppColors.primary, theme, isDark),
                  _sleepStage(
                      'Light', '${app.sleepLight}h', AppColors.blue, theme, isDark),
                  _sleepStage(
                      'REM', '${app.sleepREM}h', AppColors.pink, theme, isDark),
                  _sleepStage('Awake', '${app.sleepAwake}h',
                      AppColors.darkOnSurfaceVariant, theme, isDark),
                ]),
            const SizedBox(height: 12),
            SizedBox(
                height: 60,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final h = app.sleepWeekly.length > i
                          ? app.sleepWeekly[i]
                          : 0.0;
                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      return Expanded(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                        child: FractionallySizedBox(
                                            heightFactor:
                                                (h / 10).clamp(0, 1),
                                            alignment:
                                                Alignment.bottomCenter,
                                            child: Container(
                                                decoration: BoxDecoration(
                                                    color: h >= 7
                                                        ? AppColors.blue
                                                        : AppColors.coral,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4))))),
                                    const SizedBox(height: 4),
                                    Text(days[i],
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(fontSize: 9)),
                                  ])));
                    }))),
          ])),
          const SizedBox(height: 16),

          // Water
          GlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Row(children: [
                Icon(LucideIcons.droplets,
                    size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text('Water Intake', style: theme.textTheme.titleLarge)
              ]),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('${app.waterGlasses}/${app.waterGlassGoal}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 16),
            Center(
                child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                        app.waterGlasses > app.waterGlassGoal
                            ? app.waterGlasses
                            : app.waterGlassGoal,
                        (i) => Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: i < app.waterGlasses
                                    ? AppColors.secondary.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: i < app.waterGlasses
                                        ? AppColors.secondary
                                        : theme.colorScheme.outline
                                            .withValues(alpha: 0.2))),
                            child: Icon(LucideIcons.droplets,
                                size: 16,
                                color: i < app.waterGlasses
                                    ? AppColors.secondary
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.3)))))),
            const SizedBox(height: 12),
            Center(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  ElevatedButton.icon(
                      onPressed: app.removeWater,
                      icon: const Icon(LucideIcons.minus, size: 16),
                      label: const Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral.withValues(alpha: 0.1),
                        foregroundColor: AppColors.coral,
                      )),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                      onPressed: app.addWater,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Add Glass')),
                ])),
          ])),
          const SizedBox(height: 16),

          // Wellness
          GlassCard(
              child: Column(children: [
            Row(children: [
              Icon(LucideIcons.activity,
                  size: 18, color: AppColors.green),
              const SizedBox(width: 8),
              Text('Wellness Score', style: theme.textTheme.titleLarge)
            ]),
            const SizedBox(height: 16),
            Row(children: [
              ProgressRing(
                  size: 110,
                  strokeWidth: 10,
                  progress: app.wellnessScore.toDouble(),
                  color: AppColors.green,
                  label: '${app.wellnessScore}',
                  sublabel: 'Score',
                  fontSize: 28),
              const SizedBox(width: 24),
              Expanded(
                  child: Column(children: [
                Row(children: [
                  Text('Mood', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Icon(
                      app.mood == 'great'
                          ? LucideIcons.smile
                          : LucideIcons.meh,
                      size: 20,
                      color: AppColors.primary)
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Energy', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Expanded(
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: app.energy / 100,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.coral)))),
                  const SizedBox(width: 8),
                  Text('${app.energy}%',
                      style: theme.textTheme.labelSmall)
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Stress', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Expanded(
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: app.stress / 100,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation(
                                  app.stress < 50
                                      ? AppColors.green
                                      : AppColors.coral)))),
                  const SizedBox(width: 8),
                  Text('${app.stress}%',
                      style: theme.textTheme.labelSmall)
                ]),
              ])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _VitalCard(
                  icon: LucideIcons.thermometer,
                  label: 'Temp',
                  value: '${app.temperature}°F',
                  color: AppColors.coral,
                  theme: theme,
                  isDark: isDark),
              const SizedBox(width: 8),
              _VitalCard(
                  icon: LucideIcons.activity,
                  label: 'BP',
                  value: '${app.systolic}/${app.diastolic}',
                  color: AppColors.coral,
                  theme: theme,
                  isDark: isDark),
              const SizedBox(width: 8),
              _VitalCard(
                  icon: LucideIcons.wind,
                  label: 'SpO₂',
                  value: '${app.oxygenLevel}%',
                  color: AppColors.blue,
                  theme: theme,
                  isDark: isDark),
            ]),
          ])),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── 3.3 Watch Connect Card ──────────────────────────────────────────────
class _WatchConnectCard extends StatelessWidget {
  final bool isConnected;
  final bool isSyncing;
  final DateTime? lastSynced;
  final String Function(DateTime) formatSynced;
  final VoidCallback onConnect;
  final VoidCallback onSyncNow;

  const _WatchConnectCard({
    required this.isConnected,
    required this.isSyncing,
    required this.lastSynced,
    required this.formatSynced,
    required this.onConnect,
    required this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isConnected
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.secondary.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isConnected
            ? null
            : (isDark
                ? AppColors.darkSurfaceContainer.withValues(alpha: 0.7)
                : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          // Watch icon with pulse ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04)),
                ),
              ),
              Icon(
                isConnected ? LucideIcons.watch : LucideIcons.bluetooth,
                size: 26,
                color:
                    isConnected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected
                      ? 'Syncing with Watch'
                      : 'Connect Smartwatch',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (isSyncing)
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                    if (isSyncing) const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isSyncing
                            ? 'Syncing…'
                            : (lastSynced != null
                                ? 'Last synced ${formatSynced(lastSynced!)}'
                                : 'HealthKit & Health Connect'),
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action button
          isConnected
              ? IconButton(
                  onPressed: isSyncing ? null : onSyncNow,
                  icon: Icon(
                    LucideIcons.refreshCw,
                    size: 18,
                    color: isSyncing
                        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                        : AppColors.primary,
                  ),
                  tooltip: 'Sync now',
                )
              : ElevatedButton(
                  onPressed: isSyncing ? null : onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isSyncing ? '…' : 'Connect'),
                ),
        ],
      ),
    );
  }
}

// ── Helper widgets (preserved from original) ────────────────────────────
Widget _zoneBar(String name, String time, Color color, double pct,
        ThemeData theme) =>
    Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(
              width: 55,
              child: Text(name,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10))),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(color)))),
          const SizedBox(width: 8),
          SizedBox(
              width: 24,
              child: Text(time,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                  textAlign: TextAlign.right)),
        ]));

Widget _sleepStage(String name, String value, Color color, ThemeData theme,
        bool isDark) =>
    Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(name,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 12))
        ]));

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  final bool isDark;
  const _VitalCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.theme,
      required this.isDark});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontSize: 9)),
                  Text(value,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700, fontSize: 11))
                ])
          ])));
}
