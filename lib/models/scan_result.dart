class ScanResult {
  final String productName;
  final String servingSize;
  final NutriScore nutriScore;
  final Nutrition nutrition;
  final ScoreBreakdown scoreBreakdown;
  final String explanation;
  final Analogies analogies;
  final double confidence;
  final String notes;
  final bool savedToHistory;

  ScanResult({
    required this.productName,
    required this.servingSize,
    required this.nutriScore,
    required this.nutrition,
    required this.scoreBreakdown,
    required this.explanation,
    required this.analogies,
    required this.confidence,
    required this.notes,
    required this.savedToHistory,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      productName: json['productName']?.toString() ?? '',
      servingSize: json['servingSize']?.toString() ?? '',
      nutriScore: NutriScore.fromJson(json['nutriScore'] ?? {}),
      nutrition: Nutrition.fromJson(json['nutrition'] ?? {}),
      scoreBreakdown: ScoreBreakdown.fromJson(json['scoreBreakdown'] ?? {}),
      explanation: json['explanation']?.toString() ?? '',
      analogies: Analogies.fromJson(json['analogies'] ?? {}),
      confidence: (json['confidence'] ?? 0).toDouble(),
      notes: json['notes']?.toString() ?? '',
      savedToHistory: json['savedToHistory'] ?? false,
    );
  }

  factory ScanResult.fromHistoryDetail(Map<String, dynamic> json) {
    final raw = json['rawNutrition'] as Map<String, dynamic>? ?? {};
    final score = json['scoreDetails'] as Map<String, dynamic>? ?? {};
    final analogies = json['aiAnalogies'] as Map<String, dynamic>? ?? {};
    return ScanResult(
      productName: json['productName']?.toString() ?? '',
      servingSize: raw['servingSize']?.toString() ?? '',
      nutriScore: NutriScore(
        grade: json['nutriScore']?.toString() ?? '',
        label: json['nutriScoreLabel']?.toString() ?? '',
        color: json['nutriScoreColor']?.toString() ?? '#888888',
        finalScore: (score['finalScore'] ?? 0).toInt(),
      ),
      nutrition: Nutrition(
        calories: raw['calories'] ?? 0,
        sugarG: raw['sugarG'] ?? 0,
        sodiumMg: raw['sodiumMg'] ?? 0,
        fatTotalG: raw['fatTotalG'] ?? 0,
        fatSaturatedG: raw['fatSaturatedG'] ?? 0,
        fatTransG: raw['fatTransG'] ?? 0,
        fiberG: raw['fiberG'] ?? 0,
        proteinG: raw['proteinG'] ?? 0,
      ),
      scoreBreakdown: ScoreBreakdown(
        calories: ScoreDetail.fromJson(score['calories'] ?? {}),
        sugar: ScoreDetail.fromJson(score['sugar'] ?? {}),
        sodium: ScoreDetail.fromJson(score['sodium'] ?? {}),
        saturatedFat: ScoreDetail.fromJson(score['saturatedFat'] ?? {}),
        transFat: ScoreDetail.fromJson(score['transFat'] ?? {}),
        fiber: ScoreDetail.fromJson(score['fiber'] ?? {}),
        protein: ScoreDetail.fromJson(score['protein'] ?? {}),
        totalNegativePoints: (score['totalNegativePoints'] ?? 0).toInt(),
        totalPositivePoints: (score['totalPositivePoints'] ?? 0).toInt(),
        finalScore: (score['finalScore'] ?? 0).toInt(),
      ),
      explanation: json['aiExplanation']?.toString() ?? '',
      analogies: Analogies(
        sugar: analogies['sugar']?.toString() ?? '',
        sodium: analogies['sodium']?.toString() ?? '',
        calories: analogies['calories']?.toString() ?? '',
      ),
      confidence: double.tryParse(json['aiConfidence']?.toString() ?? '0') ?? 0,
      notes: '',
      savedToHistory: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'servingSize': servingSize,
    'nutriScore': nutriScore.toJson(),
    'nutrition': nutrition.toJson(),
    'scoreBreakdown': scoreBreakdown.toJson(),
    'explanation': explanation,
    'analogies': analogies.toJson(),
    'confidence': confidence,
    'notes': notes,
    'savedToHistory': savedToHistory,
  };
}

class NutriScore {
  final String grade;
  final String label;
  final String color;
  final int finalScore;

  NutriScore({
    required this.grade,
    required this.label,
    required this.color,
    required this.finalScore,
  });

  factory NutriScore.fromJson(Map<String, dynamic> json) {
    return NutriScore(
      grade: json['grade']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      color: json['color']?.toString() ?? '#888888',
      finalScore: (json['finalScore'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'grade': grade,
    'label': label,
    'color': color,
    'finalScore': finalScore,
  };
}

class Nutrition {
  final num calories;
  final num sugarG;
  final num sodiumMg;
  final num fatTotalG;
  final num fatSaturatedG;
  final num fatTransG;
  final num fiberG;
  final num proteinG;

  Nutrition({
    required this.calories,
    required this.sugarG,
    required this.sodiumMg,
    required this.fatTotalG,
    required this.fatSaturatedG,
    required this.fatTransG,
    required this.fiberG,
    required this.proteinG,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json['calories'] ?? 0,
      sugarG: json['sugarG'] ?? 0,
      sodiumMg: json['sodiumMg'] ?? 0,
      fatTotalG: json['fatTotalG'] ?? 0,
      fatSaturatedG: json['fatSaturatedG'] ?? 0,
      fatTransG: json['fatTransG'] ?? 0,
      fiberG: json['fiberG'] ?? 0,
      proteinG: json['proteinG'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'sugarG': sugarG,
    'sodiumMg': sodiumMg,
    'fatTotalG': fatTotalG,
    'fatSaturatedG': fatSaturatedG,
    'fatTransG': fatTransG,
    'fiberG': fiberG,
    'proteinG': proteinG,
  };
}

class ScoreDetail {
  final num value;
  final int points;

  ScoreDetail({required this.value, required this.points});

  factory ScoreDetail.fromJson(Map<String, dynamic> json) {
    return ScoreDetail(
      value: json['value'] ?? 0,
      points: (json['points'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {'value': value, 'points': points};
}

class ScoreBreakdown {
  final ScoreDetail calories;
  final ScoreDetail sugar;
  final ScoreDetail sodium;
  final ScoreDetail saturatedFat;
  final ScoreDetail transFat;
  final ScoreDetail fiber;
  final ScoreDetail protein;
  final int totalNegativePoints;
  final int totalPositivePoints;
  final int finalScore;

  ScoreBreakdown({
    required this.calories,
    required this.sugar,
    required this.sodium,
    required this.saturatedFat,
    required this.transFat,
    required this.fiber,
    required this.protein,
    required this.totalNegativePoints,
    required this.totalPositivePoints,
    required this.finalScore,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      calories: ScoreDetail.fromJson(json['calories'] ?? {}),
      sugar: ScoreDetail.fromJson(json['sugar'] ?? {}),
      sodium: ScoreDetail.fromJson(json['sodium'] ?? {}),
      saturatedFat: ScoreDetail.fromJson(json['saturatedFat'] ?? {}),
      transFat: ScoreDetail.fromJson(json['transFat'] ?? {}),
      fiber: ScoreDetail.fromJson(json['fiber'] ?? {}),
      protein: ScoreDetail.fromJson(json['protein'] ?? {}),
      totalNegativePoints: (json['totalNegativePoints'] ?? 0).toInt(),
      totalPositivePoints: (json['totalPositivePoints'] ?? 0).toInt(),
      finalScore: (json['finalScore'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories.toJson(),
    'sugar': sugar.toJson(),
    'sodium': sodium.toJson(),
    'saturatedFat': saturatedFat.toJson(),
    'transFat': transFat.toJson(),
    'fiber': fiber.toJson(),
    'protein': protein.toJson(),
    'totalNegativePoints': totalNegativePoints,
    'totalPositivePoints': totalPositivePoints,
    'finalScore': finalScore,
  };
}

class Analogies {
  final String sugar;
  final String sodium;
  final String calories;

  Analogies({
    required this.sugar,
    required this.sodium,
    required this.calories,
  });

  factory Analogies.fromJson(Map<String, dynamic> json) {
    return Analogies(
      sugar: json['sugar']?.toString() ?? '',
      sodium: json['sodium']?.toString() ?? '',
      calories: json['calories']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'sugar': sugar,
    'sodium': sodium,
    'calories': calories,
  };
}
