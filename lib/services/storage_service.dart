import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_session.dart';
import '../data/bwf_routine_data.dart';

class StorageService {
  static const String _keyProgressionLevels = 'bwf_progression_levels';
  static const String _keyWorkoutHistory = 'bwf_workout_history';
  static const String _keyActiveDraft = 'bwf_active_draft';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Progression Levels: Map<ladderId, exerciseId>
  Map<String, String> getProgressionLevels() {
    final raw = _prefs.getString(_keyProgressionLevels);
    if (raw == null) {
      return _getDefaultProgressions();
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, String>{};
      for (final entry in decoded.entries) {
        result[entry.key] = entry.value.toString();
      }
      // Ensure all ladders have an entry
      for (final ladder in BwfRoutineData.allLadders) {
        if (!result.containsKey(ladder.id)) {
          result[ladder.id] = ladder.exercises.first.id;
        }
      }
      return result;
    } catch (_) {
      return _getDefaultProgressions();
    }
  }

  Map<String, String> _getDefaultProgressions() {
    final map = <String, String>{};
    for (final ladder in BwfRoutineData.allLadders) {
      map[ladder.id] = ladder.exercises.first.id;
    }
    return map;
  }

  Future<void> saveProgressionLevel(String ladderId, String exerciseId) async {
    final current = getProgressionLevels();
    current[ladderId] = exerciseId;
    await _prefs.setString(_keyProgressionLevels, jsonEncode(current));
  }

  // Workout History
  List<WorkoutSession> getWorkoutHistory() {
    final raw = _prefs.getString(_keyWorkoutHistory);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final sessions = list
          .map((item) => WorkoutSession.fromJson(item as Map<String, dynamic>))
          .toList();
      // Sort newest first
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWorkoutSession(WorkoutSession session) async {
    final history = getWorkoutHistory();
    final existingIndex = history.indexWhere((s) => s.id == session.id);
    if (existingIndex >= 0) {
      history[existingIndex] = session;
    } else {
      history.insert(0, session);
    }

    final raw = jsonEncode(history.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyWorkoutHistory, raw);
    await clearActiveDraft();
  }

  Future<void> deleteWorkoutSession(String sessionId) async {
    final history = getWorkoutHistory();
    history.removeWhere((s) => s.id == sessionId);
    final raw = jsonEncode(history.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyWorkoutHistory, raw);
  }

  // Active Draft Session
  WorkoutSession? getActiveDraft() {
    final raw = _prefs.getString(_keyActiveDraft);
    if (raw == null) return null;
    try {
      return WorkoutSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveDraft(WorkoutSession session) async {
    await _prefs.setString(_keyActiveDraft, jsonEncode(session.toJson()));
  }

  Future<void> clearActiveDraft() async {
    await _prefs.remove(_keyActiveDraft);
  }
}
