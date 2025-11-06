class CompleteLessonRequest {
  final int lessonId;
  final String lessonName;
  final String category;
  final int score;
  final int totalPoints;
  final int timeSpentMinutes;
  final int exercisesCompleted;
  final int experiencePoints;

  CompleteLessonRequest({
    required this.lessonId,
    required this.lessonName,
    required this.category,
    required this.score,
    required this.totalPoints,
    required this.timeSpentMinutes,
    required this.exercisesCompleted,
    required this.experiencePoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'lessonName': lessonName,
      'category': category,
      'score': score,
      'totalPoints': totalPoints,
      'timeSpentMinutes': timeSpentMinutes,
      'exercisesCompleted': exercisesCompleted,
      'experiencePoints': experiencePoints,
    };
  }
}

class UserStats {
  final int totalLessonsCompleted;
  final int totalExperienceGained;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActiveDate;
  final int averageScore;
  final Map<String, int> categoryProgress;
  final DateTime memberSince;
  final int totalPracticeSessions;
  final int totalMinutesPracticed;

  UserStats({
    this.totalLessonsCompleted = 0,
    this.totalExperienceGained = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastActiveDate,
    this.averageScore = 0,
    Map<String, int>? categoryProgress,
    DateTime? memberSince,
    this.totalPracticeSessions = 0,
    this.totalMinutesPracticed = 0,
  })  : lastActiveDate = lastActiveDate ?? DateTime.now(),
        categoryProgress = categoryProgress ?? {},
        memberSince = memberSince ?? DateTime.now();

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalLessonsCompleted: json['totalLessonsCompleted'] ?? 0,
      totalExperienceGained: json['totalExperienceGained'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'])
          : DateTime.now(),
      averageScore: json['averageScore'] ?? 0,
      categoryProgress: json['categoryProgress'] != null
          ? Map<String, int>.from(json['categoryProgress'])
          : {},
      memberSince: json['memberSince'] != null
          ? DateTime.parse(json['memberSince'])
          : DateTime.now(),
      totalPracticeSessions: json['totalPracticeSessions'] ?? 0,
      totalMinutesPracticed: json['totalMinutesPracticed'] ?? 0,
    );
  }
}

class LessonRecord {
  final int lessonId;
  final String lessonName;
  final String category;
  final int score;
  final int totalPoints;
  final int timeSpentMinutes;
  final bool isPerfect;
  final DateTime completedAt;
  final int exercisesCompleted;

  LessonRecord({
    required this.lessonId,
    required this.lessonName,
    required this.category,
    this.score = 0,
    this.totalPoints = 0,
    this.timeSpentMinutes = 0,
    this.isPerfect = false,
    DateTime? completedAt,
    this.exercisesCompleted = 0,
  }) : completedAt = completedAt ?? DateTime.now();

  factory LessonRecord.fromJson(Map<String, dynamic> json) {
    return LessonRecord(
      lessonId: json['lessonId'] ?? 0,
      lessonName: json['lessonName'] ?? '',
      category: json['category'] ?? '',
      score: json['score'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      timeSpentMinutes: json['timeSpentMinutes'] ?? 0,
      isPerfect: json['isPerfect'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
      exercisesCompleted: json['exercisesCompleted'] ?? 0,
    );
  }
}

class DailyActivity {
  final DateTime date;
  final int lessonsCompleted;
  final int xpGained;
  final int minutesPracticed;
  final bool metDailyGoal;

  DailyActivity({
    DateTime? date,
    this.lessonsCompleted = 0,
    this.xpGained = 0,
    this.minutesPracticed = 0,
    this.metDailyGoal = false,
  }) : date = date ?? DateTime.now();

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      lessonsCompleted: json['lessonsCompleted'] ?? 0,
      xpGained: json['xpGained'] ?? 0,
      minutesPracticed: json['minutesPracticed'] ?? 0,
      metDailyGoal: json['metDailyGoal'] ?? false,
    );
  }
}

class Badge {
  final String title;
  final String icon;
  final DateTime earnedAt;
  final String reason;

  Badge({
    required this.title,
    required this.icon,
    DateTime? earnedAt,
    this.reason = '',
  }) : earnedAt = earnedAt ?? DateTime.now();

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      title: json['title'] ?? '',
      icon: json['icon'] ?? '',
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'])
          : DateTime.now(),
      reason: json['reason'] ?? '',
    );
  }
}

class CategoryCountResponse {
  final String category;
  final int count;

  CategoryCountResponse({
    required this.category,
    this.count = 0,
  });

  factory CategoryCountResponse.fromJson(Map<String, dynamic> json) {
    return CategoryCountResponse(
      category: json['category'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
