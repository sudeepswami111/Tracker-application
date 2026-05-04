import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/running_provider.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';
class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});
  @override State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  int _tabIndex = 0;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RunningProvider>().initLocationService();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final run = context.watch<RunningProvider>();

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Running Tracker', style: theme.textTheme.displayLarge),
        const SizedBox(height: 4),
        Text('Track your runs with real-time GPS', style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Row(children: [
          _Tab('Live Tracker', 0, _tabIndex, (i) => setState(() => _tabIndex = i)),
          const SizedBox(width: 8),
          _Tab('History', 1, _tabIndex, (i) => setState(() => _tabIndex = i)),
          const SizedBox(width: 8),
          _Tab('Records', 2, _tabIndex, (i) => setState(() => _tabIndex = i)),
        ]),
      ])),
      const SizedBox(height: 12),
      Expanded(child: _tabIndex == 0 ? _TrackerTab(run: run, isDark: isDark, theme: theme, mapController: _mapController, onMapCreated: (c) => _mapController = c)
        : _tabIndex == 1 ? _HistoryTab(run: run, theme: theme, isDark: isDark)
        : _RecordsTab(run: run, theme: theme)),
    ]);
  }
}

class _Tab extends StatelessWidget {
  final String label; final int index; final int current; final ValueChanged<int> onTap;
  const _Tab(this.label, this.index, this.current, this.onTap);
  @override Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(onTap: () => onTap(index), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(20),
        border: active ? null : Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: active ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13))));
  }
}

class _TrackerTab extends StatelessWidget {
  final RunningProvider run; final bool isDark; final ThemeData theme;
  final GoogleMapController? mapController; final ValueChanged<GoogleMapController> onMapCreated;
  const _TrackerTab({required this.run, required this.isDark, required this.theme, this.mapController, required this.onMapCreated});

  @override Widget build(BuildContext context) {
    final initialPos = run.currentPosition != null
        ? LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude)
        : const LatLng(20.5937, 78.9629); // Default to India center

    final polylines = <Polyline>{};
    if (run.routeCoordinates.length > 1) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: run.routeCoordinates.map((c) => LatLng(c.latitude, c.longitude)).toList(),
        color: isDark ? AppColors.secondary : AppColors.primary,
        width: 5,
        patterns: [PatternItem.dot, PatternItem.gap(8)],
      ));
    }

    final markers = <Marker>{};
    if (run.currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('current'),
        position: LatLng(run.currentPosition!.latitude, run.currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    if (run.startPosition != null && run.isTracking) {
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: LatLng(run.startPosition!.latitude, run.startPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      // Map
      ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(height: 320, child: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialPos, zoom: 15),
        style: isDark ? _darkMapStyle : null,
        onMapCreated: (controller) {
          onMapCreated(controller);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        polylines: polylines,
        markers: markers,
        mapType: MapType.normal,
      ))),
      const SizedBox(height: 12),

      // Live Stats
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer.withValues(alpha: 0.55) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _LiveStat(value: run.currentDistance.toStringAsFixed(2), label: 'km'),
          Container(width: 1, height: 40, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          _LiveStat(value: run.currentPace, label: 'min/km'),
          Container(width: 1, height: 40, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          _LiveStat(value: run.formatDuration(run.currentDuration), label: 'time'),
          Container(width: 1, height: 40, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          _LiveStat(value: '${run.currentCalories}', label: 'kcal'),
        ])),
      const SizedBox(height: 16),

      // Controls
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (!run.isTracking) GestureDetector(onTap: () => run.startRun(), child: Container(width: 72, height: 72, decoration: BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 6))]),
          child: const Icon(LucideIcons.play, color: Colors.white, size: 30)))
        else ...[
          GestureDetector(onTap: () => run.isPaused ? run.resumeRun() : run.pauseRun(), child: Container(width: 56, height: 56, decoration: BoxDecoration(gradient: AppColors.gradientPrimary, shape: BoxShape.circle),
            child: Icon(run.isPaused ? LucideIcons.play : LucideIcons.pause, color: Colors.white, size: 24))),
          const SizedBox(width: 20),
          GestureDetector(onTap: () { run.stopRun(); run.resetRun(); }, child: Container(width: 56, height: 56, decoration: const BoxDecoration(gradient: AppColors.gradientCoral, shape: BoxShape.circle),
            child: const Icon(LucideIcons.square, color: Colors.white, size: 24))),
        ],
      ]),
      const SizedBox(height: 16),

      // Speed
      GlassCard(child: Column(children: [
        Row(children: [Icon(LucideIcons.zap, size: 18, color: AppColors.secondary), const SizedBox(width: 8), Text('Current Speed', style: theme.textTheme.titleMedium)]),
        const SizedBox(height: 12),
        RichText(text: TextSpan(children: [
          TextSpan(text: run.currentSpeed.toStringAsFixed(1), style: theme.textTheme.displayLarge?.copyWith(fontSize: 48, color: AppColors.secondary)),
          TextSpan(text: ' km/h', style: theme.textTheme.bodyMedium),
        ])),
      ])),
      const SizedBox(height: 16),

      // Personal Records
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.trophy, size: 18, color: AppColors.yellow), const SizedBox(width: 8), Text('Personal Records', style: theme.textTheme.titleMedium)]),
        const SizedBox(height: 12),
        ...run.personalRecords.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(e.key, style: theme.textTheme.bodySmall), Text(e.value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.secondary))])))),
      ])),
      const SizedBox(height: 100),
    ]));
  }
}

class _LiveStat extends StatelessWidget {
  final String value; final String label;
  const _LiveStat({required this.value, required this.label});
  @override Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
    Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, letterSpacing: 0.5)),
  ]);
}

class _HistoryTab extends StatelessWidget {
  final RunningProvider run; final ThemeData theme; final bool isDark;
  const _HistoryTab({required this.run, required this.theme, required this.isDark});
  @override Widget build(BuildContext context) {
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: run.history.length, itemBuilder: (_, i) {
      final r = run.history[i]; final date = DateTime.tryParse(r.date);
      return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceContainer.withValues(alpha: 0.55) : AppColors.lightSurface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06))),
        child: Row(children: [
          Container(width: 48, padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Text(date != null ? '${date.day}' : '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(date != null ? ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month] : '', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontSize: 9)),
            ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.route, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text('${r.distance} km · ${r.duration} · ${r.pace} min/km', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ])),
          Row(children: [Icon(LucideIcons.flame, size: 14, color: AppColors.coral), const SizedBox(width: 4), Text('${r.calories}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.coral))]),
        ]));
    });
  }
}

class _RecordsTab extends StatelessWidget {
  final RunningProvider run; final ThemeData theme;
  const _RecordsTab({required this.run, required this.theme});
  @override Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.trophy, size: 18, color: AppColors.yellow), const SizedBox(width: 8), Text('Personal Bests', style: theme.textTheme.titleLarge)]),
        const SizedBox(height: 16),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.8, crossAxisSpacing: 8, mainAxisSpacing: 8,
          children: run.personalRecords.entries.map((e) => Container(decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(e.value, style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w800)),
              Text(e.key, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
            ]))).toList()),
      ])),
      const SizedBox(height: 100),
    ]));
  }
}

const String _darkMapStyle = '''[{"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},{"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},{"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0e1626"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]}]''';
