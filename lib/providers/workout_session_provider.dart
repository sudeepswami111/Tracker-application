import 'package:flutter/material.dart';

class WorkoutSessionProvider extends ChangeNotifier {
  String? _activePlanId;
  int _currentPhaseIndex = 0;
  List<bool> _phaseCompleted = [];
  bool _isSessionRunning = false;
  bool _isCompleted = false;

  String? get activePlanId => _activePlanId;
  int get currentPhaseIndex => _currentPhaseIndex;
  List<bool> get phaseCompleted => _phaseCompleted;
  bool get isSessionRunning => _isSessionRunning;
  bool get isCompleted => _isCompleted;

  List<int> get completedPhaseIndexes {
    final List<int> indexes = [];
    for (int i = 0; i < _phaseCompleted.length; i++) {
      if (_phaseCompleted[i]) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  void startSession(String planId, int numPhases) {
    _activePlanId = planId;
    _currentPhaseIndex = 0;
    _phaseCompleted = List.generate(numPhases, (_) => false);
    _isSessionRunning = true;
    _isCompleted = false;
    notifyListeners();
  }

  void updateCurrentPhase(int index) {
    if (_activePlanId == null) return;
    _currentPhaseIndex = index;
    notifyListeners();
  }

  void markPhaseCompleted(int index, bool completed) {
    if (_activePlanId == null || index >= _phaseCompleted.length) return;
    _phaseCompleted[index] = completed;
    notifyListeners();
  }

  void completeSession() {
    _isCompleted = true;
    _isSessionRunning = false;
    notifyListeners();
  }

  void resetSession() {
    _activePlanId = null;
    _currentPhaseIndex = 0;
    _phaseCompleted = [];
    _isSessionRunning = false;
    _isCompleted = false;
    notifyListeners();
  }
}
