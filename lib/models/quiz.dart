import 'gamification.dart';

class QuizQuestion {
  final String id;
  final String text;
  final List<String> options;
  final String category;

  QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.category,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    id: json['id']?.toString() ?? '',
    text: json['text']?.toString() ?? json['question']?.toString() ?? '',
    options: List<String>.from(json['options'] ?? []),
    category: json['category']?.toString() ?? '',
  );
}

class QuizAnswer {
  final bool isCorrect;
  final int correctIndex;
  final String correctAnswer;
  final String explanation;
  final int pointsEarned;
  final List<BadgeInfo> newBadges;

  QuizAnswer({
    required this.isCorrect,
    required this.correctIndex,
    required this.correctAnswer,
    required this.explanation,
    required this.pointsEarned,
    this.newBadges = const [],
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final gami = data['gamification'] as Map<String, dynamic>?;
    return QuizAnswer(
      isCorrect: data['isCorrect'] ?? false,
      correctIndex: (data['correctIndex'] ?? 0).toInt(),
      correctAnswer: data['correctAnswer']?.toString() ?? '',
      explanation: data['explanation']?.toString() ?? '',
      pointsEarned:
          (data['pointsEarned'] ?? gami?['pointsEarned'] ?? 0).toInt(),
      newBadges: (gami?['newBadges'] as List? ?? [])
          .map((b) => BadgeInfo.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}
