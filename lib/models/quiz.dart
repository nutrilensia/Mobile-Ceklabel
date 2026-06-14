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

  QuizAnswer({
    required this.isCorrect,
    required this.correctIndex,
    required this.correctAnswer,
    required this.explanation,
    required this.pointsEarned,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return QuizAnswer(
      isCorrect: data['isCorrect'] ?? false,
      correctIndex: (data['correctIndex'] ?? 0).toInt(),
      correctAnswer: data['correctAnswer']?.toString() ?? '',
      explanation: data['explanation']?.toString() ?? '',
      pointsEarned: (data['pointsEarned'] ?? 0).toInt(),
    );
  }
}
