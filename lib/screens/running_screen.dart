import 'dart:async';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/live_run_metric_panel.dart';
import '../widgets/glass_card.dart';

enum RunState { planning, countdown, running, paused, finished }

class RunningScreen extends StatefulWidget {
  final ValueChanged<bool>? onFullscreenChanged;
  const RunningScreen({super.key, this.onFullscreenChanged});
  @override State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> with TickerProviderStateMixin {
  final MapController _mapCtrl = MapController();
  double _zoom = 16;
  bool _follow = true;
  LatLng? _curPos;
  final List<LatLng> _gpsRoute = [];
  StreamSubscription<Position>? _posSub;
  
  RunState _state = RunState.planning;
  Timer? _timer;
  DateTime? _startTime;
  Duration _pausedDur = Duration.zero;
  DateTime? _pauseStart;
  
  double _distKm = 0, _speedKmh = 0, _paceMin = 0;
  int _calories = 0, _durSecs = 0;
  
  // Animation for pulsing user dot
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Countdown animation
  int _countdown = 3;
  
  // Mock Route for Pre-run
  final List<LatLng> _mockPreRunRoute = const [
    LatLng(20.5937, 78.9629),
    LatLng(20.5947, 78.9639),
    LatLng(20.5957, 78.9630),
    LatLng(20.5967, 78.9645),
  ];

  String _selectedRunType = 'Outdoor Run';
  bool _audioPrompts = true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initLocation();
  }

  Future<void> _initLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) return;
    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
      setState(() => _curPos = LatLng(p.latitude, p.longitude));
      _mapCtrl.move(_curPos!, _zoom);
    } catch (_) {}
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 5)
    ).listen(_onPos);
  }

  void _onPos(Position p) {
    final pt = LatLng(p.latitude, p.longitude);
    setState(() => _curPos = pt);
    if (_follow && _curPos != null) _mapCtrl.move(_curPos!, _zoom);
    if (_state == RunState.running) {
      _gpsRoute.add(pt);
      _calcStats(p);
    }
  }

  void _calcStats(Position p) {
    double d = 0;
    for (int i = 1; i < _gpsRoute.length; i++) {
      d += const Distance().as(LengthUnit.Kilometer, _gpsRoute[i - 1], _gpsRoute[i]);
    }
    final spd = p.speed * 3.6;
    setState(() {
      _distKm = d;
      _speedKmh = spd;
      _paceMin = spd > 0.5 ? 60.0 / spd : 0;
      _calories = (d * 65).round();
    });
  }

  Duration _elapsed() {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!) - _pausedDur;
  }

  void _startCountdown() {
    HapticFeedback.heavyImpact();
    setState(() {
      _state = RunState.countdown;
      _countdown = 3;
    });
    
    // Hide bottom nav by triggering callback
    widget.onFullscreenChanged?.call(true);

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        HapticFeedback.heavyImpact();
        setState(() => _countdown--);
      } else {
        HapticFeedback.vibrate();
        timer.cancel();
        _startRun();
      }
    });
  }

  void _startRun() {
    setState(() {
      _state = RunState.running;
      _startTime = DateTime.now();
      _gpsRoute.clear();
      if (_curPos != null) _gpsRoute.add(_curPos!);
      _follow = true;
    });
    if (_curPos != null) _mapCtrl.move(_curPos!, 18); // Zoom in on start
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _durSecs = _elapsed().inSeconds);
    });
  }

  void _pauseRun() {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = RunState.paused;
      _pauseStart = DateTime.now();
    });
    _timer?.cancel();
  }

  void _resumeRun() {
    HapticFeedback.lightImpact();
    if (_pauseStart != null) {
      _pausedDur += DateTime.now().difference(_pauseStart!);
      _pauseStart = null;
    }
    setState(() => _state = RunState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _durSecs = _elapsed().inSeconds);
    });
  }

  void _finishRun() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    setState(() => _state = RunState.finished);
    _showSummary();
  }

  void _resetRun() {
    widget.onFullscreenChanged?.call(false);
    setState(() {
      _state = RunState.planning;
      _gpsRoute.clear();
      _distKm = 0;
      _speedKmh = 0;
      _paceMin = 0;
      _calories = 0;
      _durSecs = 0;
      _pausedDur = Duration.zero;
      _startTime = null;
    });
    if (_curPos != null) _mapCtrl.move(_curPos!, 16); // Reset zoom
  }

  String _fmtDur(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _fmtPace(double p) {
    if (p <= 0 || p > 60) return '--:--';
    final m = p.floor();
    final s = ((p - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;
    
    // Map URL
    const mapUrl = 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';

    final isRunningPhase = _state == RunState.running || _state == RunState.paused || _state == RunState.countdown;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: Stack(
        children: [
          // ── 1. MAP BACKGROUND ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // Pre-run: 220dp tall map (+ status bar). Active: Full bleed
            height: isRunningPhase ? size.height : 220.0 + MediaQuery.of(context).padding.top,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                borderRadius: isRunningPhase 
                    ? BorderRadius.zero 
                    : const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: _curPos ?? const LatLng(20.5937, 78.9629),
                  initialZoom: _zoom,
                  interactionOptions: InteractionOptions(
                    // Disable interactions during active run to keep hero map static relative to user
                    flags: isRunningPhase ? InteractiveFlag.none : InteractiveFlag.all,
                  ),
                  onPositionChanged: (cam, gesture) {
                    if (gesture && _follow) setState(() => _follow = false);
                    _zoom = cam.zoom ?? _zoom;
                  },
                ),
                children: [
                  TileLayer(urlTemplate: mapUrl, maxZoom: 19),
                  
                  // Pre-run Route Suggestion (Cyan)
                  if (!isRunningPhase)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: _mockPreRunRoute,
                        strokeWidth: 4,
                        color: AppColors.voltCyan,
                      ),
                    ]),

                  // Active Live Route (Pulse Red) - Ideally this would be gradient based on pace
                  if (isRunningPhase && _gpsRoute.length > 1)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: _gpsRoute,
                        strokeWidth: 6,
                        color: AppColors.pulseRed,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white.withValues(alpha: 0.3),
                      )
                    ]),

                  // User Location Marker
                  MarkerLayer(markers: [
                    if (_curPos != null)
                      Marker(
                        point: _curPos!,
                        width: 48,
                        height: 48,
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, c) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: c,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.pulseRed.withValues(alpha: 0.2),
                                ),
                              ),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.pulseRed,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.pulseRed.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ),

          // ── 2. PRE-RUN UI ──
          if (_state == RunState.planning)
            Positioned.fill(
              top: 220.0 + MediaQuery.of(context).padding.top + 16,
              child: _buildPreRunUI(theme, isDark),
            ),

          // ── 3. ACTIVE RUN UI ──
          if (_state == RunState.running || _state == RunState.paused) ...[
            // Floating Pause/End Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _buildFloatingPauseBtn(),
            ),

            // Mini Elevation Strip (Anchored above metric panel)
            Positioned(
              left: 16,
              right: 16,
              bottom: size.height * 0.4, // Right above the metric panel
              child: ElevationStripWidget(
                data: const [0, 5, 12, 10, 25, 30, 28, 45, 40, 35, 15, 0], // Mock elevation
                theme: theme,
              ),
            ),

            // Metric Panel (Bottom 40%)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size.height * 0.4,
              child: LiveRunMetricPanel(
                pace: _fmtPace(_paceMin),
                distance: _distKm.toStringAsFixed(2),
                bpm: 145, // Mock BPM
                duration: _fmtDur(_durSecs),
              ),
            ),
            
            // Paused Overlay
            if (_state == RunState.paused)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('PAUSED', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _actionBtn(Icons.stop, 'FINISH', AppColors.pulseRed, _finishRun),
                            const SizedBox(width: 32),
                            _actionBtn(Icons.play_arrow, 'RESUME', AppColors.voltCyan, _resumeRun),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],

          // ── 4. COUNTDOWN OVERLAY ──
          if (_state == RunState.countdown)
            Positioned.fill(
              child: Container(
                color: AppColors.backgroundDeep.withValues(alpha: 0.85),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_countdown),
                    tween: Tween(begin: 1.4, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Text(
                          _countdown.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 120,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreRunUI(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route info pill row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoPill('Distance', '5.2 km'),
              _infoPill('Est. Time', '28:40'),
              _infoPill('Elevation', '42 m'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Run type selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _typeChip('Outdoor Run', Icons.directions_run),
                _typeChip('Treadmill', Icons.fitness_center),
                _typeChip('Trail Run', Icons.park),
                _typeChip('Cycling', Icons.directions_bike),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Target pace / distance input row
          Row(
            children: [
              Expanded(child: _ghostInput('Target Pace', '5:30 /km')),
              const SizedBox(width: 16),
              Expanded(child: _ghostInput('Distance', '5.0 km')),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Music / audio cue row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.irisViolet,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.music, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Running Mix 2026', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Audio Prompts', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _audioPrompts,
                  onChanged: (v) => setState(() => _audioPrompts = v),
                  activeColor: AppColors.pulseRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // START RUN button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startCountdown,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pulseRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.pillRadius)),
              ),
              child: const Text('START RUN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 100), // Padding for bottom nav
        ],
      ),
    );
  }

  Widget _infoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _typeChip(String label, IconData icon) {
    final isActive = _selectedRunType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedRunType = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.pulseRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.pulseRed : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _ghostInput(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFloatingPauseBtn() {
    return GestureDetector(
      onLongPress: () {
        // Mock End Run
        _finishRun();
      },
      onTap: () {
        if (_state == RunState.running) _pauseRun();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              _state == RunState.running ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 4),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  void _showSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.backgroundDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text('POST-RUN SUMMARY', style: TextStyle(color: AppColors.pulseRed, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14))),
            const SizedBox(height: 24),
            // Replay Map
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white10),
              clipBehavior: Clip.antiAlias,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _gpsRoute.isNotEmpty ? _gpsRoute.last : const LatLng(20.5937, 78.9629),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'),
                    if (_gpsRoute.isNotEmpty)
                      PolylineLayer(polylines: [
                        Polyline(points: _gpsRoute, strokeWidth: 4, color: AppColors.voltCyan),
                      ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Stats Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _statCard('Distance', '${_distKm.toStringAsFixed(2)} km', AppColors.voltCyan),
                  _statCard('Duration', _fmtDur(_durSecs), Colors.white),
                  _statCard('Avg Pace', '${_fmtPace(_paceMin)} /km', AppColors.solarAmber),
                  _statCard('Calories', '$_calories', AppColors.pulseRed),
                ],
              ),
            ),
            // CTAs
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.voltCyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('SHARE', style: TextStyle(color: AppColors.voltCyan, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetRun();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pulseRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('SAVE RUN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetRun();
                },
                child: const Text('Discard Run', style: TextStyle(color: Colors.white38, decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _timer?.cancel();
    _pulseCtrl.dispose();
    widget.onFullscreenChanged?.call(false);
    super.dispose();
  }
}
