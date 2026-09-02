import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Detailed audit data model for debugging step discrepancy
class StepAuditInfo {
  final DateTime startTime;
  final DateTime endTime;
  final bool hasPermission;
  final int? aggregatedSteps;
  final int rawRecordCount;
  final Map<String, int> stepsBySource;
  final int hardwarePedometerSteps;
  final int displayedSteps;
  final String? error;

  StepAuditInfo({
    required this.startTime,
    required this.endTime,
    required this.hasPermission,
    required this.aggregatedSteps,
    required this.rawRecordCount,
    required this.stepsBySource,
    required this.hardwarePedometerSteps,
    required this.displayedSteps,
    this.error,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('\n========== STEP DEBUG ==========');
    buffer.writeln('Date: ${startTime.toLocal().toIso8601String().substring(0, 10)}');
    buffer.writeln('Start: ${startTime.toLocal()}');
    buffer.writeln('End: ${endTime.toLocal()}');
    buffer.writeln('Health Connect permission: ${hasPermission ? "GRANTED" : "DENIED / NOT REQUESTED"}');
    buffer.writeln('Aggregated total (Health Connect): ${aggregatedSteps ?? "N/A"}');
    buffer.writeln('Raw records found: $rawRecordCount');
    if (stepsBySource.isNotEmpty) {
      buffer.writeln('Sources:');
      stepsBySource.forEach((source, count) {
        buffer.writeln('  - $source: $count steps');
      });
    }
    buffer.writeln('Hardware Pedometer live delta: $hardwarePedometerSteps');
    buffer.writeln('Final displayed steps: $displayedSteps');
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    buffer.writeln('================================\n');
    return buffer.toString();
  }
}

class HealthStepService {
  static final HealthStepService _instance = HealthStepService._internal();
  factory HealthStepService() => _instance;
  HealthStepService._internal();

  final Health _health = Health();
  bool _isConfigured = false;
  bool _isHealthConnectAvailable = true;
  bool get isHealthConnectAvailable => _isHealthConnectAvailable;

  Future<void> init() async {
    if (_isConfigured) return;
    try {
      await _health.configure();
      _isConfigured = true;
      try {
        final status = await _health.getHealthConnectSdkStatus();
        debugPrint('[HealthStepService] HC SDK status: $status');
        // On Android 14+ HC is built-in — sdkAvailable or sdkNotSupported are both valid outcomes.
        // We treat anything except sdkUnavailable as "available enough to try".
        _isHealthConnectAvailable =
            status != HealthConnectSdkStatus.sdkNotSupported;
      } catch (e) {
        // If the SDK status API itself fails (e.g. on very old Android), assume available and let
        // the permission request determine the real outcome.
        debugPrint('[HealthStepService] HC SDK status check error (treating as available): $e');
        _isHealthConnectAvailable = true;
      }
    } catch (e) {
      debugPrint('[HealthStepService] Configure error: $e');
    }
  }

  /// Request Health Connect STEPS read permission
  Future<bool> requestStepPermission() async {
    await init();
    try {
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      // Check if already granted first to avoid unnecessary intent launch
      final hasPerm = await _health.hasPermissions(types, permissions: permissions);
      if (hasPerm == true) return true;

      final granted = await _health.requestAuthorization(types, permissions: permissions);
      return granted;
    } catch (e) {
      debugPrint('[HealthStepService] Permission request error: $e');
      return false;
    }
  }

  /// Check whether Health Connect STEPS permission is granted
  Future<bool> hasStepPermission() async {
    await init();
    try {
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];
      final hasPerm = await _health.hasPermissions(types, permissions: permissions);
      return hasPerm ?? false;
    } catch (e) {
      debugPrint('[HealthStepService] Permission check error: $e');
      return false;
    }
  }

  /// Fetches today's authoritative aggregated step count from Health Connect.
  /// Queries the local midnight (00:00:00) to current time range.
  /// Health Connect automatically merges and deduplicates overlapping sources (phone + watch).
  Future<int?> fetchTodayAggregatedSteps() async {
    await init();
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);

      // Verify permission
      bool hasPerm = await hasStepPermission();
      if (!hasPerm) {
        hasPerm = await requestStepPermission();
      }

      if (!hasPerm) {
        debugPrint('[HealthStepService] Step permission not granted');
        return null;
      }

      // Query native aggregated steps
      final steps = await _health.getTotalStepsInInterval(todayStart, now);
      debugPrint('[HealthStepService] Health Connect aggregated steps: $steps');
      return steps;
    } catch (e) {
      debugPrint('[HealthStepService] fetchTodayAggregatedSteps error: $e');
      return null;
    }
  }

  /// Detailed audit method for debugging and comparison
  Future<StepAuditInfo> auditTodaySteps({
    int hardwarePedometerSteps = 0,
    int displayedSteps = 0,
  }) async {
    await init();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    bool hasPerm = false;
    int? aggSteps;
    int rawCount = 0;
    final Map<String, int> sourceMap = {};
    String? err;

    try {
      hasPerm = await hasStepPermission();
      if (!hasPerm) {
        hasPerm = await requestStepPermission();
      }

      if (hasPerm) {
        aggSteps = await _health.getTotalStepsInInterval(todayStart, now);

        // Also fetch raw points to analyze sources
        final rawData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: todayStart,
          endTime: now,
        );
        rawCount = rawData.length;

        for (final pt in rawData) {
          final src = pt.sourceName.isNotEmpty
              ? pt.sourceName
              : (pt.sourceId.isNotEmpty ? pt.sourceId : 'Unknown Source');
          final v = pt.value;
          final numSteps = (v is NumericHealthValue) ? v.numericValue.toInt() : 0;
          sourceMap[src] = (sourceMap[src] ?? 0) + numSteps;
        }
      }
    } catch (e) {
      err = e.toString();
      debugPrint('[HealthStepService] auditTodaySteps error: $e');
    }

    final audit = StepAuditInfo(
      startTime: todayStart,
      endTime: now,
      hasPermission: hasPerm,
      aggregatedSteps: aggSteps,
      rawRecordCount: rawCount,
      stepsBySource: sourceMap,
      hardwarePedometerSteps: hardwarePedometerSteps,
      displayedSteps: displayedSteps,
      error: err,
    );

    // Print the structured debug log
    debugPrint(audit.toString());

    return audit;
  }
}
