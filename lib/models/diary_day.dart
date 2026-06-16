import 'scan_result.dart';
import 'gamification.dart';

/// Status satu nutrien terhadap batas harian AKG.
class IntakeStatus {
  final num consumed;
  final num limit;
  final int percentage;
  final String level; // ok | caution | warning | exceeded
  final String? message;

  IntakeStatus({
    required this.consumed,
    required this.limit,
    required this.percentage,
    required this.level,
    this.message,
  });

  factory IntakeStatus.fromJson(Map<String, dynamic> json) => IntakeStatus(
        consumed: json['consumed'] ?? 0,
        limit: json['limit'] ?? 0,
        percentage: (json['percentage'] ?? 0).toInt(),
        level: json['level']?.toString() ?? 'ok',
        message: json['message']?.toString(),
      );

  double get ratio => limit > 0 ? (consumed / limit).toDouble() : 0;
  bool get isOver => level == 'exceeded';
}

class DiaryEntryItem {
  final String id;
  final String? scanId;
  final String? productId;
  final String productName;
  final String nutriScore;
  final double servings;
  final Nutrition nutrition;
  final DateTime consumedAt;
  final String consumedDate;

  DiaryEntryItem({
    required this.id,
    this.scanId,
    this.productId,
    required this.productName,
    required this.nutriScore,
    required this.servings,
    required this.nutrition,
    required this.consumedAt,
    required this.consumedDate,
  });

  factory DiaryEntryItem.fromJson(Map<String, dynamic> json) {
    return DiaryEntryItem(
      id: json['id']?.toString() ?? '',
      scanId: json['scanId']?.toString(),
      productId: json['productId']?.toString(),
      productName: json['productName']?.toString() ?? 'Produk',
      nutriScore: json['nutriScore']?.toString() ?? '',
      servings: double.tryParse(json['servings']?.toString() ?? '1') ?? 1,
      nutrition:
          Nutrition.fromJson(json['nutritionPerServing'] as Map<String, dynamic>? ?? {}),
      consumedAt:
          (DateTime.tryParse(json['consumedAt']?.toString() ?? '') ?? DateTime.now())
              .toLocal(),
      consumedDate: json['consumedDate']?.toString() ?? '',
    );
  }

  num get totalCalories => nutrition.calories * servings;
  num get totalSugar => nutrition.sugarG * servings;
  num get totalSodium => nutrition.sodiumMg * servings;
}

class DiaryDay {
  final String date;
  final String profileName;
  final int entryCount;
  final Map<String, IntakeStatus> intake;
  final List<String> warnings;
  final Map<String, num> limits;
  final List<DiaryEntryItem> entries;

  DiaryDay({
    required this.date,
    required this.profileName,
    required this.entryCount,
    required this.intake,
    required this.warnings,
    required this.limits,
    required this.entries,
  });

  factory DiaryDay.fromJson(Map<String, dynamic> json) {
    final intakeRaw = json['intake'] as Map<String, dynamic>? ?? {};
    final intake = <String, IntakeStatus>{};
    for (final key in ['calories', 'sugar', 'sodium', 'fatTotal', 'fatSaturated']) {
      if (intakeRaw[key] is Map) {
        intake[key] = IntakeStatus.fromJson(intakeRaw[key] as Map<String, dynamic>);
      }
    }
    return DiaryDay(
      date: json['date']?.toString() ?? '',
      profileName: json['profileName']?.toString() ?? 'Saya',
      entryCount: (json['entryCount'] ?? 0).toInt(),
      intake: intake,
      warnings: List<String>.from(intakeRaw['warnings'] ?? json['warnings'] ?? []),
      limits: (json['limits'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v ?? 0) as num)),
      entries: (json['entries'] as List? ?? [])
          .map((e) => DiaryEntryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  IntakeStatus? get calories => intake['calories'];
  IntakeStatus? get sugar => intake['sugar'];
  IntakeStatus? get sodium => intake['sodium'];
  IntakeStatus? get fatTotal => intake['fatTotal'];
  IntakeStatus? get fatSaturated => intake['fatSaturated'];
}

/// Hasil logging satu entri ke diary.
class DiaryLogResult {
  final String message;
  final DiaryDay summary;
  final GamificationUpdate? gamification;

  DiaryLogResult({
    required this.message,
    required this.summary,
    this.gamification,
  });

  factory DiaryLogResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return DiaryLogResult(
      message: json['message']?.toString() ?? 'Tercatat ke Diary',
      summary: DiaryDay.fromJson(data['summary'] as Map<String, dynamic>? ?? {}),
      gamification: data['gamification'] != null
          ? GamificationUpdate.fromJson(data['gamification'] as Map<String, dynamic>)
          : null,
    );
  }
}
