import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// 3.2 — HealthService wraps Apple HealthKit / Google Health Connect.
/// On platforms that don't support health (e.g. web), every method is a no-op.
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();

  static const List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.BLOOD_OXYGEN,
  ];

  /// Configures the plugin and requests read authorisation.
  /// Returns true if all permissions were granted.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      // Request Bluetooth permissions first
      final btScan = await Permission.bluetoothScan.request();
      final btConnect = await Permission.bluetoothConnect.request();
      if (!btScan.isGranted || !btConnect.isGranted) {
        return false;
      }

      // Then request Health permissions
      await _health.configure();
      return await _health.requestAuthorization(_types);
    } catch (e) {
      debugPrint('[HealthService] requestPermissions error: $e');
      return false;
    }
  }

  /// Fetches today's health data from midnight to now.
  /// Returns a map with keys: heartRate, steps, sleepHours, oxygenLevel.
  /// Returns an empty map on any error.
  Future<Map<String, dynamic>> fetchTodayData() async {
    if (kIsWeb) return {};
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: midnight,
        endTime: now,
      );

      // ── Steps (total) ──
      int steps = 0;
      final stepsData = data.where((d) => d.type == HealthDataType.STEPS);
      for (final pt in stepsData) {
        final v = pt.value;
        if (v is NumericHealthValue) steps += v.numericValue.toInt();
      }

      // ── Heart Rate (latest BPM) ──
      int heartRate = 0;
      final hrData = data
          .where((d) => d.type == HealthDataType.HEART_RATE)
          .toList()
        ..sort((a, b) => b.dateTo.compareTo(a.dateTo));
      if (hrData.isNotEmpty) {
        final v = hrData.first.value;
        if (v is NumericHealthValue) heartRate = v.numericValue.toInt();
      }

      // ── Sleep (total hours asleep) ──
      double sleepHours = 0;
      final sleepData =
          data.where((d) => d.type == HealthDataType.SLEEP_ASLEEP);
      for (final pt in sleepData) {
        final mins = pt.dateTo.difference(pt.dateFrom).inMinutes;
        sleepHours += mins / 60.0;
      }
      sleepHours = double.parse(sleepHours.toStringAsFixed(1));

      // ── Blood Oxygen (latest SpO2 %) ──
      int oxygenLevel = 0;
      final o2Data = data
          .where((d) => d.type == HealthDataType.BLOOD_OXYGEN)
          .toList()
        ..sort((a, b) => b.dateTo.compareTo(a.dateTo));
      if (o2Data.isNotEmpty) {
        final v = o2Data.first.value;
        if (v is NumericHealthValue) oxygenLevel = v.numericValue.toInt();
      }

      return {
        'heartRate': heartRate,
        'steps': steps,
        'sleepHours': sleepHours,
        'oxygenLevel': oxygenLevel,
      };
    } catch (e) {
      debugPrint('[HealthService] fetchTodayData error: $e');
      return {};
    }
  }

  /// Fetches the last 5 minutes of heart rate data
  Future<int?> fetchLatestHeartRate() async {
    if (kIsWeb) return null;
    try {
      final now = DateTime.now();
      final fiveMinsAgo = now.subtract(const Duration(minutes: 5));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: fiveMinsAgo,
        endTime: now,
      );

      if (data.isEmpty) return null;
      
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final v = data.first.value;
      if (v is NumericHealthValue) return v.numericValue.toInt();
    } catch (e) {
      debugPrint('[HealthService] fetchLatestHeartRate error: $e');
    }
    return null;
  }
}
