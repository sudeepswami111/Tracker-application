import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/workout_phase.dart';
import '../../providers/app_provider.dart';
import '../../providers/step_tracker_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/botanical_decorations.dart';
import 'plan_route_screen.dart';

class RunningScreen extends StatefulWidget {
  final ValueChanged<bool>? onFullscreenChanged;
  final List<WorkoutPhase>? phases;
  final DailyPlan? plan;

  const RunningScreen({
    super.key,
    this.onFullscreenChanged,
    this.phases,
    this.plan,
  });

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  final MapController _mapController = MapController();
  int _selectedMode = 0; // 0: Outdoor, 1: Indoor
  bool _isRunning = false;
  Timer? _runTimer;
  int _secondsElapsed = 68 * 60;
  double _distanceKm = 5.4;

  final LatLng _startPos = const LatLng(12.9716, 77.5946);
  final List<LatLng> _routePoints = const [
    LatLng(12.9716, 77.5946),
    LatLng(12.9730, 77.5980),
    LatLng(12.9750, 77.6020),
    LatLng(12.9780, 77.6050),
    LatLng(12.9820, 77.6080),
    LatLng(12.9860, 77.6120),
  ];

  @override
  void dispose() {
    _runTimer?.cancel();
    super.dispose();
  }

  void _toggleRun() {
    HapticFeedback.heavyImpact();
    if (_isRunning) {
      _runTimer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _runTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _secondsElapsed++;
          _distanceKm += 0.003;
        });
      });
    }
  }

  String _formatDuration(int totalSecs) {
    final m = totalSecs ~/ 60;
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final stepTracker = context.watch<StepTrackerProvider>();
    final steps = stepTracker.steps > 0 ? stepTracker.steps : 7842;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Running',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // ── 1. Outdoor / Indoor Segmented Toggle ──
            Center(
              child: SegmentedPillTabs(
                tabs: const ['Outdoor', 'Indoor'],
                selectedIndex: _selectedMode,
                onTabSelected: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMode = index);
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. Interactive Map Container ──
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _startPos,
                        initialZoom: 14.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.lifepulse.tracker',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4.5,
                              color: AppColors.skyBlue,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _routePoints.first,
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.sageGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                              ),
                            ),
                            Marker(
                              point: _routePoints.last,
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.accentPeach,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flag, color: Colors.white, size: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Compass / Location reposition button
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: GestureDetector(
                        onTap: () {
                          _mapController.move(_startPos, 14.5);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: const Icon(LucideIcons.navigation, size: 16, color: AppColors.forestGreen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 3. Metric Bar Card (Distance: 5.4 km, Time: 68 min, Steps: 7,842) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRunMetricItem('${_distanceKm.toStringAsFixed(1)} km', 'Distance'),
                  Container(width: 1, height: 36, color: AppColors.cardBorder),
                  _buildRunMetricItem(_formatDuration(_secondsElapsed), 'Time'),
                  Container(width: 1, height: 36, color: AppColors.cardBorder),
                  _buildRunMetricItem('$steps', 'Steps'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 4. Big Dark Forest Green Pill Button: Start Run ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _toggleRun,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? AppColors.accentPeach : AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isRunning ? 'Pause Run' : 'Start Run',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── 5. Plan a Route Card ──
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanRouteScreen()));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Plan a Route',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.neutralGray),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoutePreviewChip('2 km', 'Easy', AppColors.sageGreen),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRoutePreviewChip('5 km', 'Moderate', AppColors.skyBlue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRoutePreviewChip('10 km', 'Challenging', AppColors.accentOrange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRunMetricItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRoutePreviewChip(String distance, String difficulty, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                distance,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            difficulty,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
