import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../models/user_profile.dart';
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
  UserProfile? _userProfile;
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
  bool _isSessionPaused = false;

  String _globalTrackMode = 'recommended';
  ThemeMode _themeMode = ThemeMode.system;

  WorkoutController(this._storage) {
    _loadInitialData();
  }

  Map<String, String> get userProgressions => _userProgressions;
  List<WorkoutSession> get history => _history;
  WorkoutSession? get activeSession => _activeSession;
  UserProfile? get userProfile => _userProfile;
  WorkoutStage get currentStage => _currentStage;
  StorageService get storage => _storage;
  int get activePairStepIndex => _activePairStepIndex;
  String get globalTrackMode => _globalTrackMode;
  ThemeMode get themeMode => _themeMode;

  int get restRemainingSeconds => _restRemainingSeconds;
  int get restTotalSeconds => _restTotalSeconds;
  bool get isTimerRunning => _isTimerRunning;
  bool get isSessionPaused => _isSessionPaused;
  bool isOnboardingCompleted() => _storage.isOnboardingCompleted();

  DateTime get appStartDate => _storage.getAppStartDate();

  /// Week number counted from when the user started using the app (Week 1, Week 2, etc.)
  int get currentWeekNumber {
    final start = appStartDate;
    final now = DateTime.now();
    final startDay = DateTime(start.year, start.month, start.day);
    final today = DateTime(now.year, now.month, now.day);
    final diffDays = today.difference(startDay).inDays;
    if (diffDays < 0) return 1;
    return (diffDays ~/ 7) + 1;
  }

  /// Routine day in the current week cycle (1, 2, or 3 for BWF 3x/week routine)
  int get currentRoutineDay {
    final start = appStartDate;
    final currentWeek = currentWeekNumber;
    final weekStart = DateTime(start.year, start.month, start.day)
        .add(Duration(days: (currentWeek - 1) * 7));
    final workoutsThisWeek = _history
        .where((s) => !s.startTime.isBefore(weekStart))
        .length;
    return (workoutsThisWeek % 3) + 1;
  }

  /// Whether a workout session was completed on the current calendar day
  bool get isWorkoutCompletedToday {
    final now = DateTime.now();
    return _history.any((session) {
      final d = session.endTime ?? session.startTime;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    });
  }

  /// Workout session completed today (if any)
  WorkoutSession? get todaysCompletedWorkout {
    final now = DateTime.now();
    try {
      return _history.firstWhere((session) {
        final d = session.endTime ?? session.startTime;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      });
    } catch (_) {
      return null;
    }
  }

  /// Progress percent for today (0 to 100).
  /// Resets every day. If an active workout is running today, reflects completed sets %.
  /// If a workout has been completed today, returns 100%.
  /// Otherwise (new day or no workout today), returns 0%.
  int get todayProgressPercent {
    if (_activeSession != null) {
      final totalSets = _activeSession!.sets.length;
      final completedSets =
          _activeSession!.sets.where((s) => s.isCompleted).length;
      if (totalSets > 0) {
        return ((completedSets / totalSets) * 100).round();
      }
    }
    if (isWorkoutCompletedToday) {
      return 100;
    }
    return 0;
  }

  void _loadInitialData() {
    _userProgressions = _storage.getProgressionLevels();
    _history = _storage.getWorkoutHistory();
    _activeSession = _storage.getActiveDraft();
    _userProfile = _storage.getUserProfile();
    _globalTrackMode = _storage.getGlobalTrackMode();
    final modeStr = _storage.getThemeMode();
    if (modeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (modeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    if (_activeSession != null) {
      _startSessionDurationTimer();
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : (mode == ThemeMode.dark ? 'dark' : 'system');
    await _storage.setThemeMode(modeStr);
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

  Future<void> setGlobalTrackMode(String mode) async {
    _globalTrackMode = mode;
    await _storage.saveGlobalTrackMode(mode);

    for (final ladder in BwfRoutineData.allLadders) {
      if (ladder.paths.length <= 1) continue;
      final currentExercise = getSelectedExerciseForLadder(ladder.id);
      final targetPath = (mode == 'bodyweight' && ladder.paths.length > 1)
          ? ladder.paths[1]
          : ladder.paths.first;

      if (!targetPath.exerciseIds.contains(currentExercise.id)) {
        final pathExercises = ladder.exercisesForPath(targetPath.id);
        final branchIndex = pathExercises.indexWhere((e) => e.isBranchPoint);
        if (branchIndex != -1 && currentExercise.level >= pathExercises[branchIndex].level) {
          final nextIndex = (branchIndex + 1 < pathExercises.length) ? branchIndex + 1 : branchIndex;
          _userProgressions[ladder.id] = pathExercises[nextIndex].id;
          await _storage.saveProgressionLevel(ladder.id, pathExercises[nextIndex].id);
        } else {
          final matching = pathExercises.firstWhere(
            (e) => e.level == currentExercise.level,
            orElse: () => pathExercises.first,
          );
          _userProgressions[ladder.id] = matching.id;
          await _storage.saveProgressionLevel(ladder.id, matching.id);
        }
      }
    }
    notifyListeners();
  }

  // --- Profile Management ---

  Future<void> saveProfile(UserProfile profile) async {
    _userProfile = profile;
    await _storage.saveUserProfile(profile);
    await _storage.setOnboardingCompleted(true);
    notifyListeners();
  }

  Future<void> saveGuestProfile() async {
    final guestProfile = UserProfile.guest();
    await saveProfile(guestProfile);
  }

  Future<void> resetAllData() async {
    _sessionTimer?.cancel();
    _timer?.cancel();
    _activeSession = null;
    _isTimerRunning = false;
    _currentStage = WorkoutStage.warmup;
    await _storage.resetAllData();
    _loadInitialData();
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

  /// Toggles the workout session timer between paused and running.
  void togglePauseWorkout() {
    if (_activeSession == null) return;
    _isSessionPaused = !_isSessionPaused;
    if (_isSessionPaused) {
      // Stop the timer completely — no more ticks while paused
      _sessionTimer?.cancel();
      _sessionTimer = null;
    } else {
      // Restart the timer from where it left off
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_activeSession != null && !_activeSession!.isFinished) {
          _activeSession!.durationSeconds++;
          notifyListeners();
        }
      });
    }
    HapticFeedback.selectionClick();
    notifyListeners();
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
    _isSessionPaused = false;

    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  Future<void> discardWorkout() async {
    _sessionTimer?.cancel();
    _timer?.cancel();
    _activeSession = null;
    _currentStage = WorkoutStage.warmup;
    _isTimerRunning = false;
    _isSessionPaused = false;
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
