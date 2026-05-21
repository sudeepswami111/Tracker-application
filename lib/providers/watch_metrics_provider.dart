import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/watch_connection_manager.dart';

enum WatchPermissionStatus { unknown, granted, denied, permanentlyDenied }

class WatchMetricsProvider extends ChangeNotifier {
  final WatchConnectionManager _manager = WatchConnectionManager();

  // â”€â”€ Connection State â”€â”€
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  String _deviceName = '';
  String get deviceName => _deviceName;

  // â”€â”€ Discovered Devices (for scanner UI) â”€â”€
  List<DiscoveredDevice> _discoveredDevices = [];
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;

  // â”€â”€ Health Metrics â”€â”€
  int _pulse = 0;
  int get pulse => _pulse;

  int _restingHeartRate = 0;
  int get restingHeartRate => _restingHeartRate;

  int _maxHeartRate = 0;
  int get maxHeartRate => _maxHeartRate;

  int _wellnessScore = 0;
  int get wellnessScore => _wellnessScore;

  double _spO2 = 0.0;
  double get spO2 => _spO2;

  double _temperature = 98.6;
  double get temperature => _temperature;

  int _systolic = 120;
  int get systolic => _systolic;

  int _diastolic = 80;
  int get diastolic => _diastolic;

  double _sleepHours = 0.0;
  double get sleepHours => _sleepHours;

  // â”€â”€ Battery & Sync â”€â”€
  int _batteryLevel = 85;
  int get batteryLevel => _batteryLevel;

  DateTime? _lastSynced;
  DateTime? get lastSynced => _lastSynced;

  String get lastSyncedText {
    if (_lastSynced == null) return 'Never';
    final diff = DateTime.now().difference(_lastSynced!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // â”€â”€ Permissions â”€â”€
  WatchPermissionStatus _permissionStatus = WatchPermissionStatus.unknown;
  WatchPermissionStatus get permissionStatus => _permissionStatus;

  String? _connectError;
  String? get connectError => _connectError;

  WatchMetricsProvider() {
    _loadFromStorage();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _manager.onPulseUpdate = (bpm) {
      _pulse = bpm;
      _isStreaming = true;
      _lastSynced = DateTime.now();
      _saveToStorage();
      notifyListeners();
    };
    _manager.onSpO2Update = (spo2) {
      _spO2 = spo2;
      _saveToStorage();
      notifyListeners();
    };
    _manager.onTemperatureUpdate = (temp) {
      _temperature = double.parse(temp.toStringAsFixed(1));
      _saveToStorage();
      notifyListeners();
    };
    _manager.onBloodPressureUpdate = (sys, dia) {
      _systolic = sys;
      _diastolic = dia;
      _saveToStorage();
      notifyListeners();
    };
    _manager.onWellnessUpdate = (score) {
      _wellnessScore = score;
      _saveToStorage();
      notifyListeners();
    };
    _manager.onSleepUpdate = (hours) {
      _sleepHours = hours;
      _saveToStorage();
      notifyListeners();
    };
    _manager.onBatteryUpdate = (battery) {
      _batteryLevel = battery;
      notifyListeners();
    };
    // Device scanner callback
    _manager.onDevicesFound = (devices) {
      _discoveredDevices = devices;
      notifyListeners();
    };
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _isConnected = prefs.getBool('watch_connected') ?? false;
    _deviceName = prefs.getString('watch_device_name') ?? '';
    _pulse = prefs.getInt('watch_pulse') ?? 0;
    _restingHeartRate = prefs.getInt('watch_rhr') ?? 0;
    _maxHeartRate = prefs.getInt('watch_mhr') ?? 0;
    _wellnessScore = prefs.getInt('watch_wellness') ?? 0;
    _spO2 = prefs.getDouble('watch_spo2') ?? 0.0;
    _temperature = prefs.getDouble('watch_temperature') ?? 98.6;
    _systolic = prefs.getInt('watch_systolic') ?? 120;
    _diastolic = prefs.getInt('watch_diastolic') ?? 80;
    _sleepHours = prefs.getDouble('watch_sleep') ?? 0.0;
    _batteryLevel = prefs.getInt('watch_battery') ?? 85;

    final lastSyncMs = prefs.getInt('watch_last_sync');
    if (lastSyncMs != null) {
      _lastSynced = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }

    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('watch_connected', _isConnected);
    prefs.setString('watch_device_name', _deviceName);
    prefs.setInt('watch_pulse', _pulse);
    prefs.setInt('watch_rhr', _restingHeartRate);
    prefs.setInt('watch_mhr', _maxHeartRate);
    prefs.setInt('watch_wellness', _wellnessScore);
    prefs.setDouble('watch_spo2', _spO2);
    prefs.setDouble('watch_temperature', _temperature);
    prefs.setInt('watch_systolic', _systolic);
    prefs.setInt('watch_diastolic', _diastolic);
    prefs.setDouble('watch_sleep', _sleepHours);
    prefs.setInt('watch_battery', _batteryLevel);
    if (_lastSynced != null) {
      prefs.setInt('watch_last_sync', _lastSynced!.millisecondsSinceEpoch);
    }
  }

  // â”€â”€ Step 1: Request permissions & start scanning â”€â”€
  Future<void> requestPermissionsAndScan() async {
    _connectError = null;
    _discoveredDevices = [];
    notifyListeners();

    try {
      debugPrint("[WatchProvider] Requesting permissions...");
      final error = await _manager.requestPermissions();
      if (error != null) {
        _connectError = error;
        _isScanning = false;
        notifyListeners();
        return;
      }
      _permissionStatus = WatchPermissionStatus.granted;

      // Start scanning for devices
      _isScanning = true;
      notifyListeners();

      debugPrint("[WatchProvider] Starting device scan...");
      await _manager.scanForDevices();

      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint("[WatchProvider] Scan error: $e");
      _connectError = "Failed to scan. Make sure Bluetooth is on.";
      _isScanning = false;
      notifyListeners();
    }
  }

  // â”€â”€ Step 2: Connect to user-selected device â”€â”€
  Future<void> connectToDevice(DiscoveredDevice device) async {
    _connectError = null;
    _isConnecting = true;
    notifyListeners();

    try {
      debugPrint("[WatchProvider] Connecting to ${device.name}...");
      bool success = await _manager.connectToSelectedDevice(device);

      if (success) {
        _isConnected = true;
        _deviceName = device.name;

        // Fetch initial health data from Health Connect
        final data = await _manager.fetchHealthData();
        _pulse = data['heartRate'] ?? 0;
        _restingHeartRate = data['restingHeartRate'] ?? 0;
        _maxHeartRate = data['maxHeartRate'] ?? 0;
        _wellnessScore = data['wellnessScore'] ?? 0;
        _spO2 = (data['spO2'] ?? 0.0).toDouble();
        _temperature = (data['temperature'] ?? 98.4).toDouble();
        _systolic = data['systolic'] ?? 120;
        _diastolic = data['diastolic'] ?? 80;
        _sleepHours = (data['sleepHours'] ?? 0.0).toDouble();
        _lastSynced = DateTime.now();
        _isStreaming = true;

        _saveToStorage();
        _isConnecting = false;
        notifyListeners();
        debugPrint("[WatchProvider] Connected to ${device.name}!");
      } else {
        _connectError = "Failed to connect to ${device.name}. Try again.";
        _isConnecting = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("[WatchProvider] Connect error: $e");
      _connectError = "Connection error. Please try again.";
      _isConnecting = false;
      notifyListeners();
    }
  }

  // â”€â”€ Step 3: Connect via Health Connect (No BLE) â”€â”€
  Future<void> connectViaHealthConnect() async {
    _connectError = null;
    _isConnecting = true;
    notifyListeners();

    try {
      debugPrint("[WatchProvider] Syncing via Health Connect...");
      final permError = await _manager.requestPermissions();
      if (permError != null) {
        _connectError = permError;
        _isConnecting = false;
        notifyListeners();
        return;
      }

      final successError = await _manager.connectViaHealthConnect();
      if (successError == null) {
        _isConnected = true;
        _deviceName = "Health Connect Sync";

        // Fetch initial health data
        final data = await _manager.fetchHealthData();
        _pulse = data['heartRate'] ?? 0;
        _restingHeartRate = data['restingHeartRate'] ?? 0;
        _maxHeartRate = data['maxHeartRate'] ?? 0;
        _wellnessScore = data['wellnessScore'] ?? 0;
        _spO2 = (data['spO2'] ?? 0.0).toDouble();
        _temperature = (data['temperature'] ?? 98.4).toDouble();
        _systolic = data['systolic'] ?? 120;
        _diastolic = data['diastolic'] ?? 80;
        _sleepHours = (data['sleepHours'] ?? 0.0).toDouble();
        _lastSynced = DateTime.now();
        _isStreaming = true; // Still true to show the dashboard properly

        final totalRecords = data['totalRecords'] ?? 0;
        if (totalRecords == 0) {
          _connectError = "Connected, but Health Connect is empty! Please sync Google Fit.";
        }

        _saveToStorage();
        _isConnecting = false;
        notifyListeners();
        debugPrint("[WatchProvider] Connected via Health Connect! Records: $totalRecords");
      } else {
        _connectError = successError;
        _isConnecting = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("[WatchProvider] Connect error: $e");
      _connectError = "Connection error. Please try again.";
      _isConnecting = false;
      notifyListeners();
    }
  }

  void stopScanning() {
    _manager.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  void resetPermissionStatus() {
    _permissionStatus = WatchPermissionStatus.unknown;
    notifyListeners();
  }

  void disconnectWatch() {
    _manager.disconnect();
    _isConnected = false;
    _isStreaming = false;
    _deviceName = '';
    _discoveredDevices = [];
    _saveToStorage();
    notifyListeners();
  }
}
