class LoggedSet {
  final String exerciseId;
  final String exerciseName;
  final String ladderId;
  final int setIndex; // 0, 1, 2 (Set 1, 2, 3)
  int reps;
  double addedWeightKg;
  bool isCompleted;

  LoggedSet({
    required this.exerciseId,
    required this.exerciseName,
    required this.ladderId,
    required this.setIndex,
    required this.reps,
    this.addedWeightKg = 0.0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'ladderId': ladderId,
    'setIndex': setIndex,
    'reps': reps,
    'addedWeightKg': addedWeightKg,
    'isCompleted': isCompleted,
  };

  factory LoggedSet.fromJson(Map<String, dynamic> json) => LoggedSet(
    exerciseId: json['exerciseId'] as String,
    exerciseName: json['exerciseName'] as String,
    ladderId: json['ladderId'] as String,
    setIndex: json['setIndex'] as int,
    reps: json['reps'] as int,
    addedWeightKg: (json['addedWeightKg'] as num?)?.toDouble() ?? 0.0,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

class WorkoutSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  int durationSeconds;
  final List<String> completedWarmups;
  final List<LoggedSet> sets;
  String notes;
  bool isFinished;

  WorkoutSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    List<String>? completedWarmups,
    List<LoggedSet>? sets,
    this.notes = '',
    this.isFinished = false,
  })  : completedWarmups = completedWarmups ?? [],
        sets = sets ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationSeconds': durationSeconds,
    'completedWarmups': completedWarmups,
    'sets': sets.map((s) => s.toJson()).toList(),
    'notes': notes,
    'isFinished': isFinished,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    durationSeconds: json['durationSeconds'] as int? ?? 0,
    completedWarmups: (json['completedWarmups'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    sets: (json['sets'] as List<dynamic>?)?.map((e) => LoggedSet.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    notes: json['notes'] as String? ?? '',
    isFinished: json['isFinished'] as bool? ?? false,
  );

  int get totalReps => sets.where((s) => s.isCompleted).fold(0, (sum, s) => sum + s.reps);
  int get completedSetCount => sets.where((s) => s.isCompleted).length;
}
