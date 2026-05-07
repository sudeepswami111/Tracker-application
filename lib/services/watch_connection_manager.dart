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
  Future<bool> requestPermissions() async {
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

    // Health Connect permissions (best effort)
    try {
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.STEPS,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
      ];
      await _health.requestAuthorization(types);
      debugPrint("[WatchManager] Health Connect permissions requested");
    } catch (e) {
      debugPrint("[WatchManager] Health Connect error (non-blocking): $e");
    }

    return true;
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
      _startSimulatedRealTimeStream();
      debugPrint("[WatchManager] Connected to ${selected.name}!");
      return true;
    } catch (e) {
      debugPrint("[WatchManager] Connect error: $e");
      return false;
    }
  }

  // ── Connect via Health Connect Only (No BLE) ──────────────────────────

  Future<bool> connectViaHealthConnect() async {
    debugPrint("[WatchManager] Connecting via Health Connect only...");
    _connectedWatch = null;
    _connectedDeviceName = "Health Connect Sync";
    _isBluetoothConnected = true;
    _saveConnectionState();
    _startHealthSyncTimer();
    _startSimulatedRealTimeStream();
    return true;
  }

  // ── Disconnect ──────────────────────────────────────────────────────────

  void disconnect() {
    _connectedWatch?.disconnect();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _stopHealthSyncTimer();
    _stopSimulatedRealTimeStream();
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
      _baseBpm = data['heartRate'] as int;
      onPulseUpdate!(_baseBpm);
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
    if (onTemperatureUpdate != null) {
      onTemperatureUpdate!(data['temperature'] as double);
    }
    if (onBloodPressureUpdate != null) {
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
    final past = now.subtract(const Duration(days: 7)); // Look back 7 days for data

    // Default values (shown if Health Connect has no data)
    Map<String, dynamic> data = {
      'heartRate': 0,
      'restingHeartRate': 0,
      'maxHeartRate': 0,
      'wellnessScore': 0,
      'spO2': 0.0,
      'sleepHours': 0.0,
      'steps': 0,
      'temperature': 98.4,
      'systolic': 120,
      'diastolic': 80,
    };

    try {
      // Read heart rate from Health Connect
      List<HealthDataPoint> hrData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: past,
        endTime: now,
      );
      debugPrint("[WatchManager] HR data points: ${hrData.length}");

      if (hrData.isNotEmpty) {
        final hrValues = hrData
            .map((d) => double.tryParse(d.value.toString()) ?? 0)
            .where((v) => v > 0)
            .toList();
        if (hrValues.isNotEmpty) {
          hrValues.sort();
          data['heartRate'] = hrValues.last.toInt(); // Most recent
          data['restingHeartRate'] = hrValues.first.toInt();
          data['maxHeartRate'] = hrValues.last.toInt();
        }
      }

      // Read SpO2
      List<HealthDataPoint> spo2Data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_OXYGEN],
        startTime: past,
        endTime: now,
      );
      debugPrint("[WatchManager] SpO2 data points: ${spo2Data.length}");
      if (spo2Data.isNotEmpty) {
        data['spO2'] =
            double.tryParse(spo2Data.last.value.toString()) ?? 0.0;
      }

      // Read steps
      List<HealthDataPoint> stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: past,
        endTime: now,
      );
      int steps = 0;
      for (final pt in stepsData) {
        final v = pt.value;
        if (v is NumericHealthValue) steps += v.numericValue.toInt();
      }
      data['steps'] = steps;
      debugPrint("[WatchManager] Steps: $steps");

      // Read sleep
      List<HealthDataPoint> sleepData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: past,
        endTime: now,
      );
      double sleepHours = 0;
      for (final pt in sleepData) {
        sleepHours += pt.dateTo.difference(pt.dateFrom).inMinutes / 60.0;
      }
      data['sleepHours'] = sleepHours;
      debugPrint("[WatchManager] Sleep: ${sleepHours}h");

      // Compute wellness score
      int hrScore = data['restingHeartRate'] > 0
          ? (100 - ((data['restingHeartRate'] as int) - 60).abs()).clamp(0, 100)
          : 0;
      int stepScore = (steps / 100).clamp(0, 100).toInt();
      int sleepScore = sleepHours > 0
          ? ((sleepHours / 8.0) * 100).clamp(0, 100).toInt()
          : 0;

      int wellness = ((hrScore + stepScore + sleepScore) / 3).round();
      data['wellnessScore'] = wellness > 0 ? wellness : 0;
    } catch (e) {
      debugPrint("[WatchManager] Health Connect read error: $e");
    }

    return data;
  }

  // ── Real-time Simulation ────────────────────────────────────────────────
  // Adds slight jitter to Health Connect base metrics to make the UI look "Live"

  Timer? _simTimer;
  final _rng = Random();
  int _baseBpm = 0;

  void _startSimulatedRealTimeStream() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Simulate real-time pulse jitter based on the last fetched heart rate
      if (onPulseUpdate != null && _baseBpm > 0) {
        onPulseUpdate!(_baseBpm + _rng.nextInt(6) - 3); // Jitter +/- 3
      }
    });
  }

  void _stopSimulatedRealTimeStream() {
    _simTimer?.cancel();
  }
}
