class UserProfile {
  final String email;
  final String name;
  final String firstName;
  final String lastName;
  final int level;
  final int experience;
  final int streak;
  final DateTime lastLogin;
  final DateTime createdAt;
  final List<String> completedLessons;
  final Map<String, double> lessonProgress;
  final int dailyGoal;
  final int todayProgress;
  final String profilePicture;
  final bool isGuest;

  UserProfile({
    required this.email,
    this.name = '',
    this.firstName = '',
    this.lastName = '',
    this.level = 1,
    this.experience = 0,
    this.streak = 0,
    DateTime? lastLogin,
    DateTime? createdAt,
    List<String>? completedLessons,
    Map<String, double>? lessonProgress,
    this.dailyGoal = 5,
    this.todayProgress = 0,
    this.profilePicture = '',
    this.isGuest = false,
  })  : lastLogin = lastLogin ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        completedLessons = completedLessons ?? [],
        lessonProgress = lessonProgress ?? {};

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      streak: json['streak'] ?? 0,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedLessons: json['completedLessons'] != null
          ? (json['completedLessons'] as List).map((e) => e.toString()).toList()
          : [],
      lessonProgress: json['lessonProgress'] != null
          ? Map<String, double>.from(json['lessonProgress'])
          : {},
      dailyGoal: json['dailyGoal'] ?? 5,
      todayProgress: json['todayProgress'] ?? 0,
      profilePicture: json['profilePicture'] ?? '',
      isGuest: json['isGuest'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'level': level,
      'experience': experience,
      'streak': streak,
      'lastLogin': lastLogin.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedLessons': completedLessons,
      'lessonProgress': lessonProgress,
      'dailyGoal': dailyGoal,
      'todayProgress': todayProgress,
      'profilePicture': profilePicture,
      'isGuest': isGuest,
    };
  }

  UserProfile copyWith({
    String? email,
    String? name,
    String? firstName,
    String? lastName,
    int? level,
    int? experience,
    int? streak,
    DateTime? lastLogin,
    DateTime? createdAt,
    List<String>? completedLessons,
    Map<String, double>? lessonProgress,
    int? dailyGoal,
    int? todayProgress,
    String? profilePicture,
    bool? isGuest,
  }) {
    return UserProfile(
      email: email ?? this.email,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      streak: streak ?? this.streak,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      completedLessons: completedLessons ?? this.completedLessons,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      todayProgress: todayProgress ?? this.todayProgress,
      profilePicture: profilePicture ?? this.profilePicture,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
