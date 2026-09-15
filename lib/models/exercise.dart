class Exercise {
  final String id;
  final String name;
  final String ladderId; // e.g. 'pullup', 'squat', etc.
  final int level; // 1-indexed difficulty
  final String repRange; // e.g. "3 x 5-8" or "3 x 8-12" or "3 x 30s"
  final int minTargetReps;
  final int maxTargetReps;
  final bool isTimed;
  final String description;
  final List<String> formCues;
  final String videoSearchQuery;

  const Exercise({
    required this.id,
    required this.name,
    required this.ladderId,
    required this.level,
    this.repRange = "3 x 5-8",
    this.minTargetReps = 5,
    this.maxTargetReps = 8,
    this.isTimed = false,
    required this.description,
    required this.formCues,
    required this.videoSearchQuery,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ladderId': ladderId,
    'level': level,
    'repRange': repRange,
    'minTargetReps': minTargetReps,
    'maxTargetReps': maxTargetReps,
    'isTimed': isTimed,
    'description': description,
    'formCues': formCues,
    'videoSearchQuery': videoSearchQuery,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    ladderId: json['ladderId'] as String,
    level: json['level'] as int,
    repRange: json['repRange'] as String? ?? "3 x 5-8",
    minTargetReps: json['minTargetReps'] as int? ?? 5,
    maxTargetReps: json['maxTargetReps'] as int? ?? 8,
    isTimed: json['isTimed'] as bool? ?? false,
    description: json['description'] as String,
    formCues: (json['formCues'] as List<dynamic>).map((e) => e.toString()).toList(),
    videoSearchQuery: json['videoSearchQuery'] as String,
  );
}

class ProgressionLadder {
  final String id;
  final String title;
  final String movementType; // e.g. "Vertical Pull", "Quad Dominant"
  final String pairCategory; // "First Pair", "Second Pair", "Third Pair", "Core Triplet"
  final int defaultRestSeconds; // 90 for pairs, 60 for triplet
  final List<Exercise> exercises;

  const ProgressionLadder({
    required this.id,
    required this.title,
    required this.movementType,
    required this.pairCategory,
    required this.defaultRestSeconds,
    required this.exercises,
  });
}

class WarmupExercise {
  final String id;
  final String name;
  final String target;
  final String prescription; // e.g. "5-10 reps each side", "30-60s hold"
  final String instructions;
  final List<String> cues;

  const WarmupExercise({
    required this.id,
    required this.name,
    required this.target,
    required this.prescription,
    required this.instructions,
    required this.cues,
  });
}
