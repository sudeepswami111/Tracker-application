import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/watch_connection_manager.dart';

enum WatchPermissionStatus { unknown, granted, denied, permanentlyDenied }

class WatchMetricsProvider extends ChangeNotifier {
  final WatchConnectionManager _manager = WatchConnectionManager();

  // ── Connection State ──
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  String _deviceName = '';
  String get deviceName => _deviceName;

  // ── Discovered Devices (for scanner UI) ──
  List<DiscoveredDevice> _discoveredDevices = [];
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices;

  // ── Health Metrics ──
  int? _pulse;
  int? get pulse => _pulse;

  int? _restingHeartRate;
  int? get restingHeartRate => _restingHeartRate;

  int? _maxHeartRate;
  int? get maxHeartRate => _maxHeartRate;

  int? _wellnessScore;
  int? get wellnessScore => _wellnessScore;

  double? _spO2;
  double? get spO2 => _spO2;
  double? get spo2 => _spO2;
  int? get stressLevel => _wellnessScore != null ? (100 - _wellnessScore!).clamp(0, 100) : null;

  double? _temperature;
  double? get temperature => _temperature;

  int? _systolic;
  int? get systolic => _systolic;

  int? _diastolic;
  int? get diastolic => _diastolic;

  double? _sleepHours;
  double? get sleepHours => _sleepHours;

  // ── Battery & Sync ──
  int? _batteryLevel;
  int? get batteryLevel => _batteryLevel;

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

  // ── Permissions ──
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
    _pulse = prefs.getInt('watch_pulse');
    _restingHeartRate = prefs.getInt('watch_rhr');
    _maxHeartRate = prefs.getInt('watch_mhr');
    _wellnessScore = prefs.getInt('watch_wellness');
    _spO2 = prefs.getDouble('watch_spo2');
    _temperature = prefs.getDouble('watch_temperature');
    _systolic = prefs.getInt('watch_systolic');
    _diastolic = prefs.getInt('watch_diastolic');
    _sleepHours = prefs.getDouble('watch_sleep');
    _batteryLevel = prefs.getInt('watch_battery');

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
    if (_pulse != null) prefs.setInt('watch_pulse', _pulse!);
    if (_restingHeartRate != null) prefs.setInt('watch_rhr', _restingHeartRate!);
    if (_maxHeartRate != null) prefs.setInt('watch_mhr', _maxHeartRate!);
    if (_wellnessScore != null) prefs.setInt('watch_wellness', _wellnessScore!);
    if (_spO2 != null) prefs.setDouble('watch_spo2', _spO2!);
    if (_temperature != null) prefs.setDouble('watch_temperature', _temperature!);
    if (_systolic != null) prefs.setInt('watch_systolic', _systolic!);
    if (_diastolic != null) prefs.setInt('watch_diastolic', _diastolic!);
    if (_sleepHours != null) prefs.setDouble('watch_sleep', _sleepHours!);
    if (_batteryLevel != null) prefs.setInt('watch_battery', _batteryLevel!);
    if (_lastSynced != null) {
      prefs.setInt('watch_last_sync', _lastSynced!.millisecondsSinceEpoch);
    }
  }

  // ── Step 1: Request permissions & start scanning ──
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

  // ── Step 2: Connect to user-selected device ──
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
        _isFetching = true;
        notifyListeners();
        final data = await _manager.fetchHealthData();
        _pulse = data['heartRate'];
        _restingHeartRate = data['restingHeartRate'];
        _maxHeartRate = data['maxHeartRate'];
        _wellnessScore = data['wellnessScore'];
        _spO2 = data['spO2'];
        _temperature = data['temperature'];
        _systolic = data['systolic'];
        _diastolic = data['diastolic'];
        _sleepHours = data['sleepHours'];
        _lastSynced = DateTime.now();
        _isStreaming = true;
        _isFetching = false;

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

  // ── Step 3: Connect via Health Connect (No BLE) ──
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
        _isFetching = true;
        notifyListeners();
        final data = await _manager.fetchHealthData();
        _pulse = data['heartRate'];
        _restingHeartRate = data['restingHeartRate'];
        _maxHeartRate = data['maxHeartRate'];
        _wellnessScore = data['wellnessScore'];
        _spO2 = data['spO2'];
        _temperature = data['temperature'];
        _systolic = data['systolic'];
        _diastolic = data['diastolic'];
        _sleepHours = data['sleepHours'];
        _lastSynced = DateTime.now();
        _isStreaming = true; // Still true to show the dashboard properly
        _isFetching = false;

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

  Future<void> refresh() async {
    if (!_isConnected) return;
    _isFetching = true;
    notifyListeners();
    try {
      final data = await _manager.fetchHealthData();
      _pulse = data['heartRate'];
      _restingHeartRate = data['restingHeartRate'];
      _maxHeartRate = data['maxHeartRate'];
      _wellnessScore = data['wellnessScore'];
      _spO2 = data['spO2'];
      _temperature = data['temperature'];
      _systolic = data['systolic'];
      _diastolic = data['diastolic'];
      _sleepHours = data['sleepHours'];
      _lastSynced = DateTime.now();
      _saveToStorage();
    } catch (e) {
      debugPrint("[WatchProvider] Refresh error: $e");
    } finally {
      _isFetching = false;
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
