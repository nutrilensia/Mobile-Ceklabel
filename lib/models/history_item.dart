class HistoryItem {
  final String id;
  final String productName;
  final String grade;
  final String gradeColor;
  final int calories;
  final double confidence;
  final DateTime scannedAt;

  HistoryItem({
    required this.id,
    required this.productName,
    required this.grade,
    required this.gradeColor,
    required this.calories,
    required this.confidence,
    required this.scannedAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final rawNutrition = json['rawNutrition'] as Map<String, dynamic>? ?? {};
    return HistoryItem(
      id: json['id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      grade: json['nutriScore']?.toString() ?? '',
      gradeColor: json['nutriScoreColor']?.toString() ?? '#888888',
      calories: (rawNutrition['calories'] ?? 0).toInt(),
      confidence: double.tryParse(json['aiConfidence']?.toString() ?? '0') ?? 0,
      scannedAt: DateTime.tryParse(json['scannedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
