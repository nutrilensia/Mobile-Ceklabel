class HistoryItem {
  final String id;
  final String productName;
  final String grade;
  final String gradeColor;
  final double calories;
  final double sugarG;
  final double sodiumMg;
  final double confidence;
  final DateTime scannedAt;

  HistoryItem({
    required this.id,
    required this.productName,
    required this.grade,
    required this.gradeColor,
    required this.calories,
    required this.sugarG,
    required this.sodiumMg,
    required this.confidence,
    required this.scannedAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final rawNutrition = json['rawNutrition'] as Map<String, dynamic>? ?? {};
    return HistoryItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      grade: json['nutriScore']?.toString() ?? '',
      gradeColor: json['nutriScoreColor']?.toString() ?? '#888888',
      calories: (rawNutrition['calories'] ?? 0).toDouble(),
      sugarG: (rawNutrition['sugarG'] ?? 0).toDouble(),
      sodiumMg: (rawNutrition['sodiumMg'] ?? 0).toDouble(),
      confidence: double.tryParse(json['aiConfidence']?.toString() ?? '0') ?? 0,
      scannedAt: (DateTime.tryParse(json['scannedAt']?.toString() ?? '') ?? DateTime.now()).toLocal(),
    );
  }
}
