enum DifficultyLevel {
  basic,
  intermediate,
  advanced,
}

enum ExerciseType {
  multipleChoice,
  signRecognition,
  practice,
  matching,
  trueFalse,
}

class Lesson {
  final int id;
  final String title;
  final String category;
  final String letter;
  final String description;
  final String imageUrl;
  final String imageBase64;  // Contenido de imagen en base64 desde MongoDB
  final String videoUrl;
  final String gifUrl;
  final int order;
  final int experiencePoints;
  final DifficultyLevel difficulty;
  final bool isCompleted;
  final bool isLocked;
  final List<Exercise> exercises;
  final List<String> learningTips;
  final int estimatedMinutes;

  Lesson({
    required this.id,
    required this.title,
    this.category = '',
    this.letter = '',
    this.description = '',
    this.imageUrl = '',
    this.imageBase64 = '',
    this.videoUrl = '',
    this.gifUrl = '',
    this.order = 0,
    this.experiencePoints = 10,
    this.difficulty = DifficultyLevel.basic,
    this.isCompleted = false,
    this.isLocked = false,
    List<Exercise>? exercises,
    List<String>? learningTips,
    this.estimatedMinutes = 5,
  })  : exercises = exercises ?? [],
        learningTips = learningTips ?? [];

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      letter: json['letter'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      imageBase64: json['imageBase64'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      gifUrl: json['gifUrl'] ?? '',
      order: json['order'] ?? 0,
      experiencePoints: json['experiencePoints'] ?? 10,
      difficulty: _parseDifficulty(json['difficulty']),
      isCompleted: json['isCompleted'] ?? false,
      isLocked: json['isLocked'] ?? false,
      exercises: json['exercises'] != null
          ? (json['exercises'] as List)
              .map((e) => Exercise.fromJson(e))
              .toList()
          : [],
      learningTips: json['learningTips'] != null
          ? List<String>.from(json['learningTips'])
          : [],
      estimatedMinutes: json['estimatedMinutes'] ?? 5,
    );
  }

  static DifficultyLevel _parseDifficulty(dynamic value) {
    if (value == null) return DifficultyLevel.basic;
    if (value is int) {
      return DifficultyLevel.values[value];
    }
    final str = value.toString().toLowerCase();
    if (str.contains('intermediate')) return DifficultyLevel.intermediate;
    if (str.contains('advanced')) return DifficultyLevel.advanced;
    return DifficultyLevel.basic;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'letter': letter,
      'description': description,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'videoUrl': videoUrl,
      'gifUrl': gifUrl,
      'order': order,
      'experiencePoints': experiencePoints,
      'difficulty': difficulty.index,
      'isCompleted': isCompleted,
      'isLocked': isLocked,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'learningTips': learningTips,
      'estimatedMinutes': estimatedMinutes,
    };
  }
}

class Exercise {
  final int id;
  final ExerciseType type;
  final String question;
  final String correctAnswer;
  final List<String> options;
  final String imageUrl;
  final String imageBase64;  // Contenido de imagen en base64
  final String hintText;
  final int points;

  Exercise({
    required this.id,
    required this.type,
    required this.question,
    required this.correctAnswer,
    List<String>? options,
    this.imageUrl = '',
    this.imageBase64 = '',
    this.hintText = '',
    this.points = 5,
  }) : options = options ?? [];

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? 0,
      type: _parseType(json['type']),
      question: json['question'] ?? '',
      correctAnswer: json['correctAnswer'] ?? '',
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : [],
      imageUrl: json['imageUrl'] ?? '',
      imageBase64: json['imageBase64'] ?? '',
      hintText: json['hintText'] ?? '',
      points: json['points'] ?? 5,
    );
  }

  static ExerciseType _parseType(dynamic value) {
    if (value == null) return ExerciseType.multipleChoice;
    if (value is int) {
      return ExerciseType.values[value];
    }
    final str = value.toString().toLowerCase();
    if (str.contains('recognition')) return ExerciseType.signRecognition;
    if (str.contains('practice')) return ExerciseType.practice;
    if (str.contains('matching')) return ExerciseType.matching;
    if (str.contains('truefalse')) return ExerciseType.trueFalse;
    return ExerciseType.multipleChoice;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'question': question,
      'correctAnswer': correctAnswer,
      'options': options,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'hintText': hintText,
      'points': points,
    };
  }
}

class LessonProgress {
  final int lessonId;
  final int exercisesCompleted;
  final int totalExercises;
  final double progressPercentage;
  final int score;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool isPerfect;

  LessonProgress({
    required this.lessonId,
    this.exercisesCompleted = 0,
    this.totalExercises = 0,
    this.progressPercentage = 0.0,
    this.score = 0,
    DateTime? startedAt,
    this.completedAt,
    this.isPerfect = false,
  }) : startedAt = startedAt ?? DateTime.now();

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lessonId'] ?? 0,
      exercisesCompleted: json['exercisesCompleted'] ?? 0,
      totalExercises: json['totalExercises'] ?? 0,
      progressPercentage: (json['progressPercentage'] ?? 0.0).toDouble(),
      score: json['score'] ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isPerfect: json['isPerfect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'exercisesCompleted': exercisesCompleted,
      'totalExercises': totalExercises,
      'progressPercentage': progressPercentage,
      'score': score,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isPerfect': isPerfect,
    };
  }
}
