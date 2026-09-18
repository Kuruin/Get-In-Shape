class UserProfile {
  final String name;
  final bool isGuest;
  final String fitnessGoal;
  final DateTime createdAt;

  const UserProfile({
    required this.name,
    this.isGuest = false,
    this.fitnessGoal = 'Build Strength & Master Calisthenics',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'isGuest': isGuest,
        'fitnessGoal': fitnessGoal,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? 'Athlete',
        isGuest: json['isGuest'] as bool? ?? false,
        fitnessGoal: json['fitnessGoal'] as String? ??
            'Build Strength & Master Calisthenics',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  factory UserProfile.guest() => UserProfile(
        name: 'Guest Athlete',
        isGuest: true,
        fitnessGoal: 'Full Body Routine Progression',
        createdAt: DateTime.now(),
      );

  UserProfile copyWith({
    String? name,
    bool? isGuest,
    String? fitnessGoal,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      isGuest: isGuest ?? this.isGuest,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
