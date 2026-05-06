import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/watch_connection_manager.dart';

enum WatchPermissionStatus { unknown, granted, denied, permanentlyDenied }

class WatchMetricsProvider extends ChangeNotifier {
  final WatchConnectionManager _manager = WatchConnectionManager();
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

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

  WatchPermissionStatus _permissionStatus = WatchPermissionStatus.unknown;
  WatchPermissionStatus get permissionStatus => _permissionStatus;

  String? _connectError;
  String? get connectError => _connectError;

  WatchMetricsProvider() {
    _loadFromStorage();
    _manager.onPulseUpdate = (bpm) {
      _pulse = bpm;
      _isStreaming = true;
      _saveToStorage();
      notifyListeners();
    };
    _manager.onSpO2Update = (spo2) {
      _spO2 = spo2;
      _isStreaming = true;
      _saveToStorage();
      notifyListeners();
    };
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _isConnected = prefs.getBool('watch_connected') ?? false;
    _pulse = prefs.getInt('watch_pulse') ?? 0;
    _restingHeartRate = prefs.getInt('watch_rhr') ?? 0;
    _maxHeartRate = prefs.getInt('watch_mhr') ?? 0;
    _wellnessScore = prefs.getInt('watch_wellness') ?? 0;
    _spO2 = prefs.getDouble('watch_spo2') ?? 0.0;
    
    if (_isConnected) {
      reconnect();
    }
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('watch_connected', _isConnected);
    prefs.setInt('watch_pulse', _pulse);
    prefs.setInt('watch_rhr', _restingHeartRate);
    prefs.setInt('watch_mhr', _maxHeartRate);
    prefs.setInt('watch_wellness', _wellnessScore);
    prefs.setDouble('watch_spo2', _spO2);
  }

  Future<void> connectWatch() async {
    _connectError = null;
    notifyListeners();

    bool hasPermissions = await _manager.requestPermissions();
    if (!hasPermissions) {
      if (_manager.permissionDeniedPermanently) {
        _permissionStatus = WatchPermissionStatus.permanentlyDenied;
      } else {
        _permissionStatus = WatchPermissionStatus.denied;
      }
      notifyListeners();
      return;
    }
    
    _permissionStatus = WatchPermissionStatus.granted;

    bool connected = await _manager.scanAndConnect();
    if (connected) {
      _isConnected = true;
      
      // Fetch historical data
      final data = await _manager.fetchHealthData();
      _restingHeartRate = data['restingHeartRate'];
      _maxHeartRate = data['maxHeartRate'];
      _wellnessScore = data['wellnessScore'];
      _spO2 = data['spO2'];
      
      _saveToStorage();
      notifyListeners();
    } else {
      _connectError = "Could not find a watch to connect to.";
      notifyListeners();
    }
  }

  Future<void> reconnect() async {
    _connectError = null;
    bool connected = await _manager.scanAndConnect();
    if (connected) {
      _isConnected = true;
      _saveToStorage();
      notifyListeners();
    }
  }

  void resetPermissionStatus() {
    _permissionStatus = WatchPermissionStatus.unknown;
    notifyListeners();
  }

  void disconnectWatch() {
    _manager.disconnect();
    _isConnected = false;
    _isStreaming = false;
    _saveToStorage();
    notifyListeners();
  }
}
