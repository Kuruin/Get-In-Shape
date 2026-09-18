import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../services/storage_service.dart';
import '../data/bwf_routine_data.dart';

enum WorkoutStage {
  warmup,
  firstPair,
  secondPair,
  thirdPair,
  coreTriplet,
  completed,
}

class WorkoutController extends ChangeNotifier {
  final StorageService _storage;

  Map<String, String> _userProgressions = {};
  List<WorkoutSession> _history = [];
  WorkoutSession? _activeSession;
  WorkoutStage _currentStage = WorkoutStage.warmup;

  // Active workout set tracker
  int _activePairStepIndex = 0; // 0 to 5 for pairs (A1, B1, A2, B2, A3, B3), 0 to 8 for triplet

  // Rest Timer
  Timer? _timer;
  int _restRemainingSeconds = 0;
  int _restTotalSeconds = 0;
  bool _isTimerRunning = false;

  // Session timer (total duration)
  Timer? _sessionTimer;

  WorkoutController(this._storage) {
    _loadInitialData();
  }

  Map<String, String> get userProgressions => _userProgressions;
  List<WorkoutSession> get history => _history;
  WorkoutSession? get activeSession => _activeSession;
  WorkoutStage get currentStage => _currentStage;
  StorageService get storage => _storage;
  int get activePairStepIndex => _activePairStepIndex;

  int get restRemainingSeconds => _restRemainingSeconds;
  int get restTotalSeconds => _restTotalSeconds;
  bool get isTimerRunning => _isTimerRunning;

  void _loadInitialData() {
    _userProgressions = _storage.getProgressionLevels();
    _history = _storage.getWorkoutHistory();
    _activeSession = _storage.getActiveDraft();
    if (_activeSession != null) {
      _startSessionDurationTimer();
    }
    notifyListeners();
  }

  Exercise getSelectedExerciseForLadder(String ladderId) {
    final selectedId = _userProgressions[ladderId];
    if (selectedId != null) {
      return BwfRoutineData.getExercise(selectedId);
    }
    return BwfRoutineData.getLadder(ladderId).exercises.first;
  }

  Future<void> setProgression(String ladderId, String exerciseId) async {
    _userProgressions[ladderId] = exerciseId;
    await _storage.saveProgressionLevel(ladderId, exerciseId);
    notifyListeners();
  }

  // --- Workout Session Lifecycle ---

  void startWorkout() {
    final now = DateTime.now();
    final newSession = WorkoutSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      startTime: now,
      completedWarmups: [],
      sets: _initializeSetsForActiveRoutine(),
    );

    _activeSession = newSession;
    _currentStage = WorkoutStage.warmup;
    _activePairStepIndex = 0;
    _storage.saveActiveDraft(newSession);
    _startSessionDurationTimer();
    notifyListeners();
  }

  void _startSessionDurationTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_activeSession != null && !_activeSession!.isFinished) {
        _activeSession!.durationSeconds++;
        notifyListeners();
      }
    });
  }

  List<LoggedSet> _initializeSetsForActiveRoutine() {
    final sets = <LoggedSet>[];

    void addSetsForLadder(ProgressionLadder ladder) {
      final exercise = getSelectedExerciseForLadder(ladder.id);
      for (int i = 0; i < 3; i++) {
        sets.add(LoggedSet(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          ladderId: ladder.id,
          setIndex: i,
          reps: 0,
        ));
      }
    }

    // First pair
    addSetsForLadder(BwfRoutineData.pullupLadder);
    addSetsForLadder(BwfRoutineData.squatLadder);

    // Second pair
    addSetsForLadder(BwfRoutineData.dipLadder);
    addSetsForLadder(BwfRoutineData.hingeLadder);

    // Third pair
    addSetsForLadder(BwfRoutineData.rowLadder);
    addSetsForLadder(BwfRoutineData.pushupLadder);

    // Core Triplet
    addSetsForLadder(BwfRoutineData.antiExtensionLadder);
    addSetsForLadder(BwfRoutineData.antiRotationLadder);
    addSetsForLadder(BwfRoutineData.extensionLadder);

    return sets;
  }

  void toggleWarmup(String warmupId) {
    if (_activeSession == null) return;
    if (_activeSession!.completedWarmups.contains(warmupId)) {
      _activeSession!.completedWarmups.remove(warmupId);
    } else {
      _activeSession!.completedWarmups.add(warmupId);
      HapticFeedback.lightImpact();
    }
    _storage.saveActiveDraft(_activeSession!);
    notifyListeners();
  }

  void markAllWarmupsCompleted() {
    if (_activeSession == null) return;
    for (final w in BwfRoutineData.warmups) {
      if (!_activeSession!.completedWarmups.contains(w.id)) {
        _activeSession!.completedWarmups.add(w.id);
      }
    }
    HapticFeedback.mediumImpact();
    _storage.saveActiveDraft(_activeSession!);
    notifyListeners();
  }

  void advanceStage() {
    switch (_currentStage) {
      case WorkoutStage.warmup:
        _currentStage = WorkoutStage.firstPair;
        _activePairStepIndex = 0;
        break;
      case WorkoutStage.firstPair:
        _currentStage = WorkoutStage.secondPair;
        _activePairStepIndex = 0;
        break;
      case WorkoutStage.secondPair:
        _currentStage = WorkoutStage.thirdPair;
        _activePairStepIndex = 0;
        break;
      case WorkoutStage.thirdPair:
        _currentStage = WorkoutStage.coreTriplet;
        _activePairStepIndex = 0;
        break;
      case WorkoutStage.coreTriplet:
        _currentStage = WorkoutStage.completed;
        break;
      case WorkoutStage.completed:
        break;
    }
    stopRestTimer();
    HapticFeedback.mediumImpact();
    if (_activeSession != null) {
      _storage.saveActiveDraft(_activeSession!);
    }
    notifyListeners();
  }

  void setStage(WorkoutStage stage) {
    _currentStage = stage;
    _activePairStepIndex = 0;
    stopRestTimer();
    notifyListeners();
  }

  // --- Active Pair Logging & Progression ---

  List<LoggedSet> getSetsForLadder(String ladderId) {
    if (_activeSession == null) return [];
    return _activeSession!.sets.where((s) => s.ladderId == ladderId).toList();
  }

  LoggedSet? getSet(String ladderId, int setIndex) {
    if (_activeSession == null) return null;
    return _activeSession!.sets.firstWhere(
      (s) => s.ladderId == ladderId && s.setIndex == setIndex,
      orElse: () => LoggedSet(
        exerciseId: '',
        exerciseName: '',
        ladderId: ladderId,
        setIndex: setIndex,
        reps: 0,
      ),
    );
  }

  void updateSetReps(String ladderId, int setIndex, int reps) {
    if (_activeSession == null) return;
    final set = _activeSession!.sets.firstWhere(
      (s) => s.ladderId == ladderId && s.setIndex == setIndex,
    );
    set.reps = reps < 0 ? 0 : reps;
    _storage.saveActiveDraft(_activeSession!);
    notifyListeners();
  }

  void updateSetWeight(String ladderId, int setIndex, double weight) {
    if (_activeSession == null) return;
    final set = _activeSession!.sets.firstWhere(
      (s) => s.ladderId == ladderId && s.setIndex == setIndex,
    );
    set.addedWeightKg = weight;
    _storage.saveActiveDraft(_activeSession!);
    notifyListeners();
  }

  void completeSetAndTriggerRest({
    required String ladderId,
    required int setIndex,
    required int restSeconds,
  }) {
    if (_activeSession == null) return;
    final set = _activeSession!.sets.firstWhere(
      (s) => s.ladderId == ladderId && s.setIndex == setIndex,
    );
    set.isCompleted = true;
    HapticFeedback.heavyImpact();

    // Advance step index inside the pair
    _activePairStepIndex++;

    _storage.saveActiveDraft(_activeSession!);
    startRestTimer(restSeconds);
    notifyListeners();
  }

  // --- Rest Timer ---

  void startRestTimer(int seconds) {
    _timer?.cancel();
    _restTotalSeconds = seconds;
    _restRemainingSeconds = seconds;
    _isTimerRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemainingSeconds > 0) {
        _restRemainingSeconds--;
        if (_restRemainingSeconds == 3 || _restRemainingSeconds == 2 || _restRemainingSeconds == 1) {
          HapticFeedback.lightImpact();
        }
        notifyListeners();
      } else {
        // Finished
        timer.cancel();
        _isTimerRunning = false;
        HapticFeedback.vibrate();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pauseResumeTimer() {
    if (!_isTimerRunning && _restRemainingSeconds > 0) {
      _isTimerRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_restRemainingSeconds > 0) {
          _restRemainingSeconds--;
          notifyListeners();
        } else {
          timer.cancel();
          _isTimerRunning = false;
          HapticFeedback.vibrate();
          notifyListeners();
        }
      });
    } else {
      _timer?.cancel();
      _isTimerRunning = false;
    }
    notifyListeners();
  }

  void addTimerSeconds(int seconds) {
    _restRemainingSeconds += seconds;
    _restTotalSeconds += seconds;
    notifyListeners();
  }

  void stopRestTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
    _restRemainingSeconds = 0;
    notifyListeners();
  }

  // --- Session Completion ---

  Future<void> finishWorkout({String notes = ''}) async {
    if (_activeSession == null) return;
    _sessionTimer?.cancel();
    _timer?.cancel();

    _activeSession!.endTime = DateTime.now();
    _activeSession!.notes = notes;
    _activeSession!.isFinished = true;

    await _storage.saveWorkoutSession(_activeSession!);
    _history = _storage.getWorkoutHistory();
    _activeSession = null;
    _currentStage = WorkoutStage.warmup;
    _isTimerRunning = false;

    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  Future<void> discardWorkout() async {
    _sessionTimer?.cancel();
    _timer?.cancel();
    _activeSession = null;
    _currentStage = WorkoutStage.warmup;
    _isTimerRunning = false;
    await _storage.clearActiveDraft();
    notifyListeners();
  }

  Future<void> deleteHistorySession(String sessionId) async {
    await _storage.deleteWorkoutSession(sessionId);
    _history = _storage.getWorkoutHistory();
    notifyListeners();
  }

  // Check if user reached 3 sets of max target reps (e.g. 3x8)
  bool checkProgressionReady(String ladderId) {
    final sets = getSetsForLadder(ladderId);
    if (sets.length < 3) return false;
    final exercise = getSelectedExerciseForLadder(ladderId);
    return sets.take(3).every((s) => s.isCompleted && s.reps >= exercise.maxTargetReps);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }
}
