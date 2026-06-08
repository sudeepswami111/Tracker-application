import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Discovered BLE device info for the scanner UI.
class DiscoveredDevice {
  final BluetoothDevice device;
  final String name;
  final String id;
  final int rssi;

  DiscoveredDevice({
    required this.device,
    required this.name,
    required this.id,
    required this.rssi,
  });
}

class WatchConnectionManager {
  static final WatchConnectionManager _instance =
      WatchConnectionManager._internal();
  factory WatchConnectionManager() => _instance;
  WatchConnectionManager._internal();

  final Health _health = Health();
  bool _isBluetoothConnected = false;
  bool get isBluetoothConnected => _isBluetoothConnected;

  bool _permissionDeniedPermanently = false;
  bool get permissionDeniedPermanently => _permissionDeniedPermanently;

  // Real-time metric callbacks
  void Function(int bpm)? onPulseUpdate;
  void Function(double spO2)? onSpO2Update;
  void Function(double temp)? onTemperatureUpdate;
  void Function(int systolic, int diastolic)? onBloodPressureUpdate;
  void Function(int wellnessScore)? onWellnessUpdate;
  void Function(double sleepHours)? onSleepUpdate;
  void Function(int battery)? onBatteryUpdate;
  void Function(List<DiscoveredDevice>)? onDevicesFound;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  BluetoothDevice? _connectedWatch;
  String? _connectedDeviceName;
  String? get connectedDeviceName => _connectedDeviceName;

  Timer? _syncTimer;
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isBluetoothConnected = prefs.getBool('watch_connected') ?? false;
    _connectedDeviceName = prefs.getString('watch_device_name');
    final lastSyncMs = prefs.getInt('watch_last_sync');
    if (lastSyncMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }
  }

  /// Request all needed permissions.
  Future<String?> requestPermissions() async {
    debugPrint("[WatchManager] Requesting permissions...");

    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      if (statuses.values.any((s) => s.isPermanentlyDenied)) {
        _permissionDeniedPermanently = true;
      }
      debugPrint("[WatchManager] BT permissions done");
    } catch (e) {
      debugPrint("[WatchManager] BT permission error: $e");
    }

    // Optional permissions
    try {
      await [Permission.sensors, Permission.activityRecognition].request();
    } catch (e) {
      debugPrint("[WatchManager] Optional permissions error: $e");
    }

    // Health Connect permissions
    try {
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.STEPS,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      ];
      final permissions = types.map((e) => HealthDataAccess.READ).toList();
      await _health.requestAuthorization(types, permissions: permissions);
      debugPrint("[WatchManager] Health Connect permissions requested");
    } catch (e) {
      debugPrint("[WatchManager] Health Connect error: $e");
      return "Health Connect Error: $e";
    }

    return null; // Success
  }

  // ── BLE Device Scanner ──────────────────────────────────────────────────

  /// Scan for ALL nearby BLE devices and return them via [onDevicesFound].
  /// Does NOT auto-connect. The user picks a device from the list.
  Future<void> scanForDevices() async {
    debugPrint("[WatchManager] scanForDevices started");
    _isScanning = true;

    final Map<String, DiscoveredDevice> deviceMap = {};

    try {
      final adapterState = await FlutterBluePlus.adapterState.first
          .timeout(const Duration(seconds: 3));
      debugPrint("[WatchManager] Adapter: $adapterState");

      if (adapterState != BluetoothAdapterState.on) {
        debugPrint("[WatchManager] Bluetooth OFF");
        _isScanning = false;
        return;
      }

      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          final name = r.device.platformName;
          final id = r.device.remoteId.toString();
          // Only show devices that have a name (skip unnamed)
          if (name.isNotEmpty) {
            deviceMap[id] = DiscoveredDevice(
              device: r.device,
              name: name,
              id: id,
              rssi: r.rssi,
            );
            // Notify UI with updated list
            onDevicesFound?.call(deviceMap.values.toList());
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      // Wait for scan to finish
      await Future.delayed(const Duration(seconds: 9));
    } catch (e) {
      debugPrint("[WatchManager] Scan error: $e");
    }

    _isScanning = false;
    // Final notify
    onDevicesFound?.call(deviceMap.values.toList());
    debugPrint("[WatchManager] Scan complete, found ${deviceMap.length} devices");
  }

  /// Stop an ongoing BLE scan.
  void stopScan() {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("[WatchManager] Stop scan error: $e");
    }
    _scanSubscription?.cancel();
    _isScanning = false;
  }

  // ── Connect to a specific device the user picked ────────────────────────

  /// Connect to a user-selected BLE device.
  Future<bool> connectToSelectedDevice(DiscoveredDevice selected) async {
    debugPrint("[WatchManager] Connecting to: ${selected.name} (${selected.id})");

    try {
      stopScan();

      await selected.device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      _connectedWatch = selected.device;
      _connectedDeviceName = selected.name;

      // Listen for disconnection
      _connectionSubscription?.cancel();
      _connectionSubscription =
          selected.device.connectionState.listen((BluetoothConnectionState state) {
        debugPrint("[WatchManager] Connection state: $state");
        if (state == BluetoothConnectionState.disconnected) {
          _isBluetoothConnected = false;
          _stopHealthSyncTimer();
          _saveConnectionState();
        }
      });

      // Discover services (for debugging — Mi Band has proprietary services)
      try {
        List<BluetoothService> services =
            await selected.device.discoverServices();
        for (BluetoothService service in services) {
          debugPrint("[WatchManager] Service: ${service.uuid}");
          for (var c in service.characteristics) {
            debugPrint("  Char: ${c.uuid} props=${c.properties}");
          }
        }
      } catch (e) {
        debugPrint("[WatchManager] Service discovery error: $e");
      }

      _isBluetoothConnected = true;
      _saveConnectionState();
      _startHealthSyncTimer();
      debugPrint("[WatchManager] Connected to ${selected.name}!");
      return true;
    } catch (e) {
      debugPrint("[WatchManager] Connect error: $e");
      return false;
    }
  }

  // ── Connect via Health Connect Only (No BLE) ──────────────────────────

  Future<String?> connectViaHealthConnect() async {
    debugPrint("[WatchManager] Connecting via Health Connect only...");
    _connectedWatch = null;
    _connectedDeviceName = "Health Connect Sync";
    _isBluetoothConnected = true;
    _saveConnectionState();
    _startHealthSyncTimer();
    return null;
  }

  // ── Disconnect ──────────────────────────────────────────────────────────

  void disconnect() {
    _connectedWatch?.disconnect();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _stopHealthSyncTimer();
    _isBluetoothConnected = false;
    _connectedDeviceName = null;
    _saveConnectionState();
  }

  Future<void> _saveConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('watch_connected', _isBluetoothConnected);
    if (_connectedDeviceName != null) {
      prefs.setString('watch_device_name', _connectedDeviceName!);
    } else {
      prefs.remove('watch_device_name');
    }
    if (_lastSyncTime != null) {
      prefs.setInt('watch_last_sync', _lastSyncTime!.millisecondsSinceEpoch);
    }
  }

  // ── Health Connect Data Sync ────────────────────────────────────────────
  // Mi Band 5 → Mi Fitness / Zepp Life app → Health Connect → Our app

  void _startHealthSyncTimer() {
    _syncTimer?.cancel();
    _performHealthSync(); // Sync immediately
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _performHealthSync();
    });
  }

  void _stopHealthSyncTimer() {
    _syncTimer?.cancel();
  }

  Future<void> _performHealthSync() async {
    debugPrint("[WatchManager] Performing Health Connect sync...");
    _lastSyncTime = DateTime.now();
    final data = await fetchHealthData();

    if (onPulseUpdate != null && data['heartRate'] != null) {
      onPulseUpdate!(data['heartRate'] as int);
    }
    if (onSpO2Update != null && data['spO2'] != null) {
      onSpO2Update!(data['spO2'] as double);
    }
    if (onWellnessUpdate != null && data['wellnessScore'] != null) {
      onWellnessUpdate!(data['wellnessScore'] as int);
    }
    if (onSleepUpdate != null && data['sleepHours'] != null) {
      onSleepUpdate!(data['sleepHours'] as double);
    }
    if (onTemperatureUpdate != null && data['temperature'] != null) {
      onTemperatureUpdate!(data['temperature'] as double);
    }
    if (onBloodPressureUpdate != null && data['systolic'] != null && data['diastolic'] != null) {
      onBloodPressureUpdate!(
        data['systolic'] as int,
        data['diastolic'] as int,
      );
    }
    if (onBatteryUpdate != null) {
      // Battery estimation (Mi Band doesn't expose battery via Health Connect)
      final now = DateTime.now();
      int battery = 100 - (now.hour * 2 + now.minute ~/ 30);
      onBatteryUpdate!(battery.clamp(20, 100));
    }

    _saveConnectionState();
  }

  /// Fetch health data from Health Connect.
  /// Health Connect reads data that Mi Fitness / Zepp Life app synced from the band.
  Future<Map<String, dynamic>> fetchHealthData() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayEvening = DateTime(now.year, now.month, now.day - 1, 18);
    final pastWeek = now.subtract(const Duration(days: 7));

    // Null by default
    Map<String, dynamic> data = {
      'heartRate': null,
      'restingHeartRate': null,
      'maxHeartRate': null,
      'wellnessScore': null,
      'spO2': null,
      'sleepHours': null,
      'steps': null,
      'temperature': null,
      'systolic': null,
      'diastolic': null,
      'totalRecords': 0,
    };

    int totalRecords = 0;

    // 1. Heart Rate (Latest today)
    try {
      List<HealthDataPoint> hrData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: todayStart,
        endTime: now,
      );
      totalRecords += hrData.length;
      if (hrData.isNotEmpty) {
        final hrValues = hrData
            .map((d) {
              final v = d.value;
              return v is NumericHealthValue ? v.numericValue.toDouble() : 0.0;
            })
            .where((v) => v > 0)
            .toList();
        if (hrValues.isNotEmpty) {
          hrValues.sort();
          data['heartRate'] = hrValues.last.toInt(); 
          data['restingHeartRate'] = hrValues.first.toInt();
          data['maxHeartRate'] = hrValues.last.toInt();
        }
      }
    } catch (e) {
      debugPrint("[WatchManager] Heart Rate read error: $e");
    }

    // 2. SpO2 (Latest today)
    try {
      List<HealthDataPoint> spo2Data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_OXYGEN],
        startTime: todayStart,
        endTime: now,
      );
      totalRecords += spo2Data.length;
      if (spo2Data.isNotEmpty) {
        spo2Data.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
        final v = spo2Data.last.value;
        data['spO2'] = v is NumericHealthValue ? v.numericValue.toDouble() : null;
      }
    } catch (e) {
      debugPrint("[WatchManager] SpO2 read error: $e");
    }

    // 3. Blood Pressure (Latest last 7 days)
    try {
      List<HealthDataPoint> bpSysData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
        startTime: pastWeek,
        endTime: now,
      );
      List<HealthDataPoint> bpDiaData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
        startTime: pastWeek,
        endTime: now,
      );
      totalRecords += bpSysData.length + bpDiaData.length;
      if (bpSysData.isNotEmpty && bpDiaData.isNotEmpty) {
        bpSysData.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
        bpDiaData.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
        final sysV = bpSysData.last.value;
        final diaV = bpDiaData.last.value;
        data['systolic'] = sysV is NumericHealthValue ? sysV.numericValue.toInt() : null;
        data['diastolic'] = diaV is NumericHealthValue ? diaV.numericValue.toInt() : null;
      }
    } catch (e) {
      debugPrint("[WatchManager] Blood Pressure read error: $e");
    }

    // 4. Steps (Today)
    try {
      List<HealthDataPoint> stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: todayStart,
        endTime: now,
      );
      totalRecords += stepsData.length;
      int steps = 0;
      for (final pt in stepsData) {
        final v = pt.value;
        if (v is NumericHealthValue) steps += v.numericValue.toInt();
      }
      data['steps'] = steps > 0 ? steps : null;
    } catch (e) {
      debugPrint("[WatchManager] Steps read error: $e");
    }

    // 5. Sleep (Yesterday evening to now)
    try {
      List<HealthDataPoint> sleepData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: yesterdayEvening,
        endTime: now,
      );
      totalRecords += sleepData.length;
      double sleepHours = 0;
      for (final pt in sleepData) {
        sleepHours += pt.dateTo.difference(pt.dateFrom).inMinutes / 60.0;
      }
      data['sleepHours'] = sleepHours > 0 ? sleepHours : null;
    } catch (e) {
      debugPrint("[WatchManager] Sleep read error: $e");
    }

    // Compute wellness score ONLY if enough data exists
    int wellnessScore = 0;
    int metricsCount = 0;
    if (data['restingHeartRate'] != null) {
      int hrScore = (100 - ((data['restingHeartRate'] as int) - 60).abs()).clamp(0, 100);
      wellnessScore += hrScore;
      metricsCount++;
    }
    if (data['steps'] != null) {
      int stepScore = ((data['steps'] as int) / 100).clamp(0, 100).toInt();
      wellnessScore += stepScore;
      metricsCount++;
    }
    if (data['sleepHours'] != null) {
      int sleepScore = (((data['sleepHours'] as double) / 8.0) * 100).clamp(0, 100).toInt();
      wellnessScore += sleepScore;
      metricsCount++;
    }
    
    data['wellnessScore'] = metricsCount >= 2 ? (wellnessScore / metricsCount).round() : null;
    data['totalRecords'] = totalRecords;

    return data;
  }
}
