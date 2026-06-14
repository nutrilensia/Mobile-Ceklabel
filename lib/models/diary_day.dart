class DiaryEntry {
  final String id;
  final String? scanId;
  final String? productId;
  final double servings;
  final String date;
  final String productName;
  final String nutriScore;
  final String nutriScoreColor;
  final num calories;
  final num sugarG;
  final num sodiumMg;
  final num fatG;

  DiaryEntry({
    required this.id,
    this.scanId,
    this.productId,
    required this.servings,
    required this.date,
    required this.productName,
    required this.nutriScore,
    required this.nutriScoreColor,
    required this.calories,
    required this.sugarG,
    required this.sodiumMg,
    required this.fatG,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final nutrition = json['nutrition'] as Map<String, dynamic>? ?? product;
    return DiaryEntry(
      id: json['id']?.toString() ?? '',
      scanId: json['scanId']?.toString(),
      productId: json['productId']?.toString(),
      servings: (json['servings'] ?? 1).toDouble(),
      date: json['date']?.toString() ?? '',
      productName: product['name']?.toString() ?? json['productName']?.toString() ?? 'Produk',
      nutriScore: product['nutriScore']?.toString() ?? json['nutriScore']?.toString() ?? '',
      nutriScoreColor: product['nutriScoreColor']?.toString() ?? '#888888',
      calories: nutrition['calories'] ?? 0,
      sugarG: nutrition['sugarG'] ?? nutrition['sugar'] ?? 0,
      sodiumMg: nutrition['sodiumMg'] ?? nutrition['sodium'] ?? 0,
      fatG: nutrition['fatG'] ?? nutrition['fat'] ?? 0,
    );
  }
}

class DiaryDay {
  final String date;
  final List<DiaryEntry> entries;
  final Map<String, num> totals;
  final Map<String, num> limits;
  final List<String> warnings;

  DiaryDay({
    required this.date,
    required this.entries,
    required this.totals,
    required this.limits,
    required this.warnings,
  });

  factory DiaryDay.fromJson(Map<String, dynamic> json) {
    final totals = Map<String, num>.from(json['totals'] ?? {});
    final limits = Map<String, num>.from(json['limits'] ?? {});
    return DiaryDay(
      date: json['date']?.toString() ?? '',
      entries: (json['entries'] as List? ?? [])
          .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: totals,
      limits: limits,
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  double get caloriesProgress {
    final limit = limits['calories']?.toDouble() ?? 2000;
    final total = totals['calories']?.toDouble() ?? 0;
    return limit > 0 ? (total / limit).clamp(0.0, 1.0) : 0;
  }

  double get sugarProgress {
    final limit = limits['sugar']?.toDouble() ?? 50;
    final total = totals['sugar']?.toDouble() ?? 0;
    return limit > 0 ? (total / limit).clamp(0.0, 1.0) : 0;
  }

  double get sodiumProgress {
    final limit = limits['sodium']?.toDouble() ?? 2000;
    final total = totals['sodium']?.toDouble() ?? 0;
    return limit > 0 ? (total / limit).clamp(0.0, 1.0) : 0;
  }
}
