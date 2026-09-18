class ProgressionPath {
  final String id;
  final String name; // e.g. "Recommended (Weighted)", "Alternate Path (Bodyweight)"
  final String? subtitle; // e.g. "Progress with weights" or "Bodyweight leverage"
  final String? branchNote; // e.g. "Branches after 3x8 Pull-ups"
  final String? equipment;
  final List<String> exerciseIds;

  const ProgressionPath({
    required this.id,
    required this.name,
    this.subtitle,
    this.branchNote,
    this.equipment,
    required this.exerciseIds,
  });
}

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
  final String pathId; // 'main', 'alt_1', 'alt_2', etc.
  final String pathName; // e.g. 'Recommended Path', 'Alternate Path 1', etc.
  final String? branchPoint; // e.g. "After you reach 3x8 Pull-ups..."
  final bool isBranchPoint; // true if this exercise is the milestone where paths diverge

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
    this.pathId = 'main',
    this.pathName = 'Recommended Path',
    this.branchPoint,
    this.isBranchPoint = false,
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
    'pathId': pathId,
    'pathName': pathName,
    'branchPoint': branchPoint,
    'isBranchPoint': isBranchPoint,
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
    pathId: json['pathId'] as String? ?? 'main',
    pathName: json['pathName'] as String? ?? 'Recommended Path',
    branchPoint: json['branchPoint'] as String?,
    isBranchPoint: json['isBranchPoint'] as bool? ?? false,
  );
}

class ProgressionLadder {
  final String id;
  final String title;
  final String movementType; // e.g. "Vertical Pull", "Quad Dominant"
  final String pairCategory; // "First Pair", "Second Pair", "Third Pair", "Core Triplet", "Skill Work"
  final int defaultRestSeconds; // 90 for pairs, 60 for triplet
  final List<Exercise> exercises; // Complete list of all exercises for this ladder
  final List<ProgressionPath> paths; // The distinct paths (Recommended vs Alternates)
  final List<String> generalFormCues; // Official general form cues from reddit wiki
  final String? equipmentNote;

  const ProgressionLadder({
    required this.id,
    required this.title,
    required this.movementType,
    required this.pairCategory,
    required this.defaultRestSeconds,
    required this.exercises,
    this.paths = const [],
    this.generalFormCues = const [],
    this.equipmentNote,
  });

  /// Get exercises for a specific path ID
  List<Exercise> exercisesForPath(String pathId) {
    if (paths.isEmpty) return exercises;
    final path = paths.firstWhere((p) => p.id == pathId, orElse: () => paths.first);
    return exercises.where((e) => path.exerciseIds.contains(e.id)).toList();
  }
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
