import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_provider.dart';
import '../services/health_service.dart';
import '../widgets/progress_ring.dart';
import '../theme/app_colors.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});
  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> with TickerProviderStateMixin {
  bool _isSyncing = false;
  DateTime? _lastSynced;
  Timer? _syncTimer;
  // Stagger controllers for metric cards
  late List<AnimationController> _stagger;
  late List<Animation<double>> _staggerFade;
  bool _metricsBuilt = false;

  @override
  void initState() {
    super.initState();
    _stagger = List.generate(4, (i) => AnimationController(
      vsync: this, duration: Duration(milliseconds: 380 + i * 90)));
    _staggerFade = _stagger.map((c) =>
      CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connected = context.read<AppProvider>().isWatchConnected;
      if (connected) _playStagger();
    });
  }

  void _playStagger() async {
    if (_metricsBuilt) return;
    _metricsBuilt = true;
    for (final c in _stagger) { c.reset(); }
    for (int i = 0; i < _stagger.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 100));
      if (mounted) _stagger[i].forward();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    for (final c in _stagger) { c.dispose(); }
    super.dispose();
  }

  Future<void> _onConnect() async {
    setState(() => _isSyncing = true);
    final granted = await HealthService().requestPermissions();
    if (!mounted) return;
    if (granted) {
      context.read<AppProvider>().setWatchConnected(true);
      await _syncNow();
      _metricsBuilt = false;
      _playStagger();
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) => _syncNow());
    } else {
      setState(() => _isSyncing = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
                'LifePulse needs Bluetooth to find your watch, and Health permissions to read your heart rate, blood oxygen, and sleep data. Please grant these to unlock the health cards.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'))
            ],
          ),
        );
      }
    }
  }

  Future<void> _syncNow() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    final data = await HealthService().fetchTodayData();
    if (!mounted) return;
    if (data.isNotEmpty) context.read<AppProvider>().updateFromHealth(data);
    setState(() { _isSyncing = false; _lastSynced = DateTime.now(); });
  }

  String _fmtSynced(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  // Stagger-animated card wrapper
  Widget _staggerCard(Widget child, int idx) => FadeTransition(
    opacity: _staggerFade[idx],
    child: AnimatedBuilder(
      animation: _staggerFade[idx],
      builder: (_, c) => Transform.translate(
        offset: Offset(0, (1 - _staggerFade[idx].value) * 22),
        child: c),
      child: child));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Health Monitor', style: theme.textTheme.displayLarge),
        const SizedBox(height: 4),
        Text('Track your vitals and wellness metrics', style: theme.textTheme.bodySmall),
        const SizedBox(height: 20),

        // ── Main animated switcher ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child)),
          child: app.isWatchConnected
            ? _buildConnected(app, theme, isDark)
            : _buildDisconnected(theme, isDark),
        ),

        const SizedBox(height: 16),
        // Sleep and Water are always visible
        _sleepCard(app, theme, isDark),
        const SizedBox(height: 16),
        _waterCard(app, theme),
        const SizedBox(height: 100),
      ]),
    );
  }

  // ── Disconnected state ──────────────────────────────────────────────
  Widget _buildDisconnected(ThemeData theme, bool isDark) => Column(
    key: const ValueKey('disconnected'),
    children: [
      _WatchConnectCard(
        isSyncing: _isSyncing,
        isConnected: false,
        lastSynced: null,
        onConnect: _onConnect,
        onSyncNow: _syncNow,
        fmtSynced: _fmtSynced,
        theme: theme, isDark: isDark),
      const SizedBox(height: 16),
      _lockedBanner(theme, isDark, LucideIcons.heart, 'Heart Rate', 'Connect to see live BPM'),
      const SizedBox(height: 10),
      _lockedBanner(theme, isDark, LucideIcons.activity, 'Pulse Score', 'Connect to unlock'),
      const SizedBox(height: 10),
      _lockedBanner(theme, isDark, LucideIcons.wind, 'SpO₂ & Wellness', 'Connect to unlock'),
    ]);

  Widget _lockedBanner(ThemeData theme, bool isDark, IconData icon, String title, String sub) =>
    Opacity(
      opacity: 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainer.withValues(alpha: 0.5)
                       : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05))),
        child: Row(children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700)),
            Text(sub, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
          ]),
          const Spacer(),
          Icon(LucideIcons.lock, size: 16, color: theme.colorScheme.onSurfaceVariant),
        ])));

  // ── Connected state ─────────────────────────────────────────────────
  Widget _buildConnected(AppProvider app, ThemeData theme, bool isDark) => Column(
    key: const ValueKey('connected'),
    children: [
      _WatchConnectCard(
        isSyncing: _isSyncing,
        isConnected: true,
        lastSynced: _lastSynced,
        onConnect: _onConnect,
        onSyncNow: _syncNow,
        fmtSynced: _fmtSynced,
        theme: theme, isDark: isDark),
      const SizedBox(height: 16),
      _staggerCard(_heartRateCard(app, theme, isDark), 0),
      const SizedBox(height: 16),
      _staggerCard(_pulseRingCard(app, theme, isDark), 1),
      const SizedBox(height: 16),
      _staggerCard(_wellnessCard(app, theme, isDark), 2),
      const SizedBox(height: 16),
      _staggerCard(_vitalsCard(app, theme, isDark), 3),
    ]);

  // ── Heart Rate ──────────────────────────────────────────────────────
  Widget _heartRateCard(AppProvider app, ThemeData theme, bool isDark) =>
    _card(isDark, theme, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(LucideIcons.heart, size: 18, color: AppColors.coral),
          const SizedBox(width: 8),
          Text('Heart Rate', style: theme.textTheme.titleLarge),
        ]),
        _liveBadge(theme),
      ]),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Icon(LucideIcons.heart, size: 28, color: AppColors.coral),
          const SizedBox(width: 8),
          Text('${app.heartRate}', style: theme.textTheme.displayLarge?.copyWith(fontSize: 48)),
          const SizedBox(width: 4),
          Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text('BPM', style: theme.textTheme.bodySmall)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Resting ${app.restingHR}', style: theme.textTheme.bodySmall),
          Text('Max ${app.maxHR}', style: theme.textTheme.bodySmall),
        ]),
      ]),
      const SizedBox(height: 16),
      _zoneBar('Rest',     '14h', AppColors.blue,    14/24, theme, isDark),
      _zoneBar('Fat Burn', '6h',  AppColors.green,    6/24, theme, isDark),
      _zoneBar('Cardio',   '3h',  AppColors.yellow,   3/24, theme, isDark),
      _zoneBar('Peak',     '1h',  AppColors.coral,    1/24, theme, isDark),
    ]));

  // ── Pulse Score Ring ────────────────────────────────────────────────
  Widget _pulseRingCard(AppProvider app, ThemeData theme, bool isDark) =>
    _card(isDark, theme, Column(children: [
      Row(children: [
        Icon(LucideIcons.activity, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('Pulse Score', style: theme.textTheme.titleLarge),
      ]),
      const SizedBox(height: 16),
      ProgressRing(
        size: 120, strokeWidth: 10,
        progress: app.pulseScore.toDouble(),
        color: Color.lerp(AppColors.primary, AppColors.secondary,
          app.pulseScore / 100)!,
        label: '${app.pulseScore}',
        sublabel: _pulseLabel(app.pulseScore),
        fontSize: 32),
    ]));

  String _pulseLabel(int s) {
    if (s >= 80) return 'Excellent 🔥';
    if (s >= 60) return 'Good 💪';
    if (s >= 40) return 'Getting there';
    return "Let's go!";
  }

  // ── Wellness ────────────────────────────────────────────────────────
  Widget _wellnessCard(AppProvider app, ThemeData theme, bool isDark) =>
    _card(isDark, theme, Column(children: [
      Row(children: [
        Icon(LucideIcons.smile, size: 18, color: AppColors.green),
        const SizedBox(width: 8),
        Text('Wellness Score', style: theme.textTheme.titleLarge),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        ProgressRing(size: 100, strokeWidth: 9,
          progress: app.wellnessScore.toDouble(),
          color: AppColors.green,
          label: '${app.wellnessScore}', sublabel: 'Score', fontSize: 26),
        const SizedBox(width: 20),
        Expanded(child: Column(children: [
          _wellRow('Mood', Icon(app.mood == 'great' ? LucideIcons.smile
            : LucideIcons.meh, size: 18, color: AppColors.primary), theme),
          const SizedBox(height: 8),
          _barRow('Energy', app.energy / 100, AppColors.coral, theme, isDark),
          const SizedBox(height: 8),
          _barRow('Stress', app.stress / 100,
            app.stress < 50 ? AppColors.green : AppColors.coral, theme, isDark),
        ])),
      ]),
    ]));

  Widget _wellRow(String lbl, Widget icon, ThemeData theme) =>
    Row(children: [
      Text(lbl, style: theme.textTheme.bodySmall),
      const Spacer(), icon]);

  Widget _barRow(String lbl, double v, Color c, ThemeData theme, bool isDark) =>
    Row(children: [
      SizedBox(width: 42, child: Text(lbl, style: theme.textTheme.bodySmall)),
      const SizedBox(width: 6),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: v, minHeight: 6,
          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.06),
          valueColor: AlwaysStoppedAnimation(c)))),
      const SizedBox(width: 6),
      Text('${(v * 100).round()}%', style: theme.textTheme.labelSmall),
    ]);

  // ── SpO2 / Vitals ───────────────────────────────────────────────────
  Widget _vitalsCard(AppProvider app, ThemeData theme, bool isDark) =>
    _card(isDark, theme, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(LucideIcons.wind, size: 18, color: AppColors.blue),
        const SizedBox(width: 8),
        Text('Vitals', style: theme.textTheme.titleLarge),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        _vitalTile(LucideIcons.thermometer, 'Temp', '${app.temperature}°F', AppColors.coral, theme, isDark),
        const SizedBox(width: 8),
        _vitalTile(LucideIcons.activity, 'BP', '${app.systolic}/${app.diastolic}', AppColors.coral, theme, isDark),
        const SizedBox(width: 8),
        _vitalTile(LucideIcons.wind, 'SpO₂', '${app.oxygenLevel}%', AppColors.blue, theme, isDark),
      ]),
    ]));

  Widget _vitalTile(IconData icon, String lbl, String val, Color c,
      ThemeData theme, bool isDark) =>
    Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lbl, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
          Text(val, style: theme.textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
      ])));

  // ── Sleep ───────────────────────────────────────────────────────────
  Widget _sleepCard(AppProvider app, ThemeData theme, bool isDark) =>
    _card(isDark, theme, Column(children: [
      Row(children: [
        Icon(LucideIcons.moon, size: 18, color: AppColors.blue),
        const SizedBox(width: 8),
        Text('Sleep', style: theme.textTheme.titleLarge),
      ]),
      const SizedBox(height: 16),
      ProgressRing(size: 130, strokeWidth: 11,
        progress: app.sleepQuality,
        color: AppColors.blue,
        label: '${app.sleepHours}h',
        sublabel: '${app.sleepQuality.toInt()}% quality',
        fontSize: 24),
      const SizedBox(height: 16),
      GridView.count(crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 3.5, crossAxisSpacing: 8, mainAxisSpacing: 8,
        children: [
          _sleepStage('Deep',  '${app.sleepDeep}h',  AppColors.primary, theme, isDark),
          _sleepStage('Light', '${app.sleepLight}h', AppColors.blue,    theme, isDark),
          _sleepStage('REM',   '${app.sleepREM}h',   AppColors.pink,    theme, isDark),
          _sleepStage('Awake', '${app.sleepAwake}h', AppColors.darkOnSurfaceVariant, theme, isDark),
        ]),
    ]));

  Widget _sleepStage(String n, String v, Color c, ThemeData theme, bool isDark) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Container(width: 8, height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(n, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        const Spacer(),
        Text(v, style: theme.textTheme.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
      ]));

  // ── Water ───────────────────────────────────────────────────────────
  Widget _waterCard(AppProvider app, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return _card(isDark, theme, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(LucideIcons.droplets, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text('Water Intake', style: theme.textTheme.titleLarge),
        ]),
        _badge('${app.waterGlasses}/${app.waterGlassGoal}', AppColors.primary, theme),
      ]),
      const SizedBox(height: 14),
      Center(child: Wrap(spacing: 8, runSpacing: 8,
        children: List.generate(
          app.waterGlasses > app.waterGlassGoal ? app.waterGlasses : app.waterGlassGoal,
          (i) => Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: i < app.waterGlasses
                ? AppColors.secondary.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: i < app.waterGlasses
                ? AppColors.secondary
                : theme.colorScheme.outline.withValues(alpha: 0.2))),
            child: Icon(LucideIcons.droplets, size: 16,
              color: i < app.waterGlasses ? AppColors.secondary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)))))),
      const SizedBox(height: 12),
      Center(child: ElevatedButton.icon(
        onPressed: app.addWater,
        icon: const Icon(LucideIcons.plus, size: 16),
        label: const Text('Add Glass'))),
    ]));
  }

  // ── Shared helpers ──────────────────────────────────────────────────
  Widget _card(bool isDark, ThemeData theme, Widget child) =>
    Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer.withValues(alpha: 0.7)
                      : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06))),
      child: child);

  Widget _liveBadge(ThemeData theme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.coral.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8)),
    child: Text('LIVE', style: theme.textTheme.labelSmall?.copyWith(
      color: AppColors.coral, fontWeight: FontWeight.w700)));

  Widget _badge(String text, Color c, ThemeData theme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: theme.textTheme.labelSmall
      ?.copyWith(color: c, fontWeight: FontWeight.w700)));

  Widget _zoneBar(String name, String time, Color color, double pct,
      ThemeData theme, bool isDark) =>
    Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 55, child: Text(name,
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: pct, minHeight: 6,
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(color)))),
        const SizedBox(width: 8),
        SizedBox(width: 24, child: Text(time,
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
          textAlign: TextAlign.right)),
      ]));
}

// ── Watch Connect Card ────────────────────────────────────────────────
class _WatchConnectCard extends StatelessWidget {
  final bool isConnected, isSyncing;
  final DateTime? lastSynced;
  final VoidCallback onConnect, onSyncNow;
  final String Function(DateTime) fmtSynced;
  final ThemeData theme;
  final bool isDark;

  const _WatchConnectCard({
    required this.isConnected, required this.isSyncing,
    required this.lastSynced, required this.onConnect,
    required this.onSyncNow, required this.fmtSynced,
    required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isConnected ? LinearGradient(colors: [
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.secondary.withValues(alpha: 0.10)]) : null,
        color: isConnected ? null
          : (isDark ? AppColors.darkSurfaceContainer.withValues(alpha: 0.7)
                    : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
            ? AppColors.primary.withValues(alpha: 0.3)
            : (isDark ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06)),
          width: isConnected ? 1.5 : 1)),
      child: Row(children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: isConnected ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04))),
          child: Icon(isConnected ? LucideIcons.watch : LucideIcons.bluetooth,
            size: 24,
            color: isConnected ? AppColors.primary
              : theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isConnected ? 'Syncing with Watch' : 'Connect Smartwatch',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            if (isSyncing) ...[
              SizedBox(width: 10, height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5,
                  color: AppColors.primary)),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(
              isSyncing ? 'Syncing…'
                : (lastSynced != null ? 'Last synced ${fmtSynced(lastSynced!)}'
                    : 'HealthKit & Health Connect'),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ])),
        const SizedBox(width: 10),
        isConnected
          ? IconButton(
              onPressed: isSyncing ? null : onSyncNow,
              icon: Icon(LucideIcons.refreshCw, size: 18,
                color: isSyncing
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                  : AppColors.primary),
              tooltip: 'Sync now')
          : ElevatedButton(
              onPressed: isSyncing ? null : onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isSyncing
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Connect')),
      ]),
    );
  }
}
