import 'gamification.dart';

class ScanResult {
  final String? id;
  final String productName;
  final String servingSize;
  final String category;
  final NutriScore nutriScore;
  final Nutrition nutrition;
  final ScoreBreakdown scoreBreakdown;
  final String explanation;
  final Analogies analogies;
  final double confidence;
  final String notes;
  final bool savedToHistory;

  // Fitur dasar
  final String? photoUrl;
  final String? productId;
  final IngredientInfo? ingredients;
  final List<ProfileInsight> familyInsights;
  final GamificationUpdate? gamification;

  // Fitur inovatif baru
  final List<MisleadingClaim> misleadingClaims;
  final DailyBudget? dailyBudget;
  final List<AlternativeProduct> alternatives;
  final String? detectionType; // "label_gizi" | "makanan_langsung" | null
  final String? sumberEstimasi; // keterangan sumber referensi AI, null jika tidak ada

  ScanResult({
    this.id,
    required this.productName,
    required this.servingSize,
    this.category = '',
    required this.nutriScore,
    required this.nutrition,
    required this.scoreBreakdown,
    required this.explanation,
    required this.analogies,
    required this.confidence,
    required this.notes,
    required this.savedToHistory,
    this.photoUrl,
    this.productId,
    this.ingredients,
    this.familyInsights = const [],
    this.gamification,
    this.misleadingClaims = const [],
    this.dailyBudget,
    this.alternatives = const [],
    this.detectionType,
    this.sumberEstimasi,
  });

  /// Petakan kontrak backend ke tipe tampilan mobile.
  /// Backend kirim `source: label|food|label-front` + `isEstimate`.
  /// Mobile tampilkan `label_gizi|makanan_langsung|kemasan_depan`.
  /// Terima juga `detectionType` eksplisit agar backward-compatible.
  static String? _mapDetectionType(Map<String, dynamic> json) {
    final explicit = json['detectionType']?.toString();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final source = json['source']?.toString();
    if (source == 'food') return 'makanan_langsung';
    if (source == 'label') return 'label_gizi';
    if (source == 'label-front') return 'kemasan_depan';
    if (json['isEstimate'] == true) return 'makanan_langsung';
    return null;
  }

  static String? _mapSumberEstimasi(Map<String, dynamic> json) {
    final explicit = json['sumber_estimasi']?.toString();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return json['estimateWarning']?.toString();
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id']?.toString() ?? json['scanId']?.toString(),
      productName: json['productName']?.toString() ?? '',
      servingSize: json['servingSize']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      nutriScore: NutriScore.fromJson(json['nutriScore'] ?? {}),
      nutrition: Nutrition.fromJson(json['nutrition'] ?? {}),
      scoreBreakdown: ScoreBreakdown.fromJson(json['scoreBreakdown'] ?? {}),
      explanation: json['explanation']?.toString() ?? '',
      analogies: Analogies.fromJson(json['analogies'] ?? {}),
      confidence: (json['confidence'] ?? 0).toDouble(),
      notes: json['notes']?.toString() ?? '',
      savedToHistory: json['savedToHistory'] ?? false,
      photoUrl: json['photoUrl']?.toString(),
      productId: json['productId']?.toString(),
      ingredients: json['ingredients'] != null
          ? IngredientInfo.fromJson(json['ingredients'] as Map<String, dynamic>)
          : null,
      familyInsights: (json['familyInsights'] as List? ?? [])
          .map((e) => ProfileInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      gamification: json['gamification'] != null
          ? GamificationUpdate.fromJson(json['gamification'] as Map<String, dynamic>)
          : null,
      misleadingClaims: (json['misleadingClaims'] as List? ?? [])
          .map((e) => MisleadingClaim.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyBudget: json['dailyBudget'] != null
          ? DailyBudget.fromJson(json['dailyBudget'] as Map<String, dynamic>)
          : null,
      alternatives: (json['alternatives'] as List? ?? [])
          .map((e) => AlternativeProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      detectionType: _mapDetectionType(json),
      sumberEstimasi: _mapSumberEstimasi(json),
    );
  }

  factory ScanResult.fromHistoryDetail(Map<String, dynamic> json) {
    final raw = json['rawNutrition'] as Map<String, dynamic>? ?? {};
    final score = json['scoreDetails'] as Map<String, dynamic>? ?? {};
    final analogies = json['aiAnalogies'] as Map<String, dynamic>? ?? {};
    final additives = (json['additives'] as List? ?? [])
        .map((e) => DetectedAdditive.fromJson(e as Map<String, dynamic>))
        .toList();
    final allergens = (json['allergens'] as List? ?? [])
        .map((e) => DetectedAllergen.fromJson(e as Map<String, dynamic>))
        .toList();
    final ingredientsRaw = json['ingredientsRaw']?.toString();
    return ScanResult(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      productName: json['productName']?.toString() ?? '',
      servingSize: raw['servingSize']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
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
      photoUrl: json['photoUrl']?.toString(),
      productId: json['productId']?.toString(),
      ingredients: (additives.isNotEmpty ||
              allergens.isNotEmpty ||
              (ingredientsRaw != null && ingredientsRaw.isNotEmpty))
          ? IngredientInfo(
              raw: ingredientsRaw,
              additives: additives,
              allergens: allergens,
              warnings: const [],
            )
          : null,
      detectionType: _mapDetectionType(json),
      sumberEstimasi: _mapSumberEstimasi(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'servingSize': servingSize,
    'category': category,
    'nutriScore': nutriScore.toJson(),
    'nutrition': nutrition.toJson(),
    'scoreBreakdown': scoreBreakdown.toJson(),
    'explanation': explanation,
    'analogies': analogies.toJson(),
    'confidence': confidence,
    'notes': notes,
    'savedToHistory': savedToHistory,
    'detectionType': detectionType,
    'sumber_estimasi': sumberEstimasi,
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

// ── Komposisi & alergen ──────────────────────────────────────────────────────

class DetectedAdditive {
  final String name;
  final String type; // sweetener | msg | preservative | coloring | trans_fat
  final String label;
  final String matchedTerm;

  DetectedAdditive({
    required this.name,
    required this.type,
    required this.label,
    required this.matchedTerm,
  });

  factory DetectedAdditive.fromJson(Map<String, dynamic> json) => DetectedAdditive(
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        matchedTerm: json['matchedTerm']?.toString() ?? '',
      );
}

class DetectedAllergen {
  final String allergen;
  final String label;
  final String matchedTerm;

  DetectedAllergen({
    required this.allergen,
    required this.label,
    required this.matchedTerm,
  });

  factory DetectedAllergen.fromJson(Map<String, dynamic> json) => DetectedAllergen(
        allergen: json['allergen']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        matchedTerm: json['matchedTerm']?.toString() ?? '',
      );
}

class IngredientInfo {
  final String? raw;
  final List<DetectedAdditive> additives;
  final List<DetectedAllergen> allergens;
  final List<String> warnings;

  IngredientInfo({
    this.raw,
    this.additives = const [],
    this.allergens = const [],
    this.warnings = const [],
  });

  bool get isEmpty =>
      (raw == null || raw!.isEmpty) &&
      additives.isEmpty &&
      allergens.isEmpty &&
      warnings.isEmpty;

  factory IngredientInfo.fromJson(Map<String, dynamic> json) => IngredientInfo(
        raw: json['raw']?.toString(),
        additives: (json['additives'] as List? ?? [])
            .map((e) => DetectedAdditive.fromJson(e as Map<String, dynamic>))
            .toList(),
        allergens: (json['allergens'] as List? ?? [])
            .map((e) => DetectedAllergen.fromJson(e as Map<String, dynamic>))
            .toList(),
        warnings: List<String>.from(json['warnings'] ?? []),
      );
}

// ── Interpretasi per anggota keluarga ────────────────────────────────────────

class InsightFlag {
  final String severity; // info | caution | danger
  final String message;

  InsightFlag({required this.severity, required this.message});

  factory InsightFlag.fromJson(Map<String, dynamic> json) => InsightFlag(
        severity: json['severity']?.toString() ?? 'info',
        message: json['message']?.toString() ?? '',
      );
}

class ProfileInsight {
  final String? profileId;
  final String profileName;
  final String ageGroup;
  final List<InsightFlag> flags;

  ProfileInsight({
    this.profileId,
    required this.profileName,
    required this.ageGroup,
    required this.flags,
  });

  factory ProfileInsight.fromJson(Map<String, dynamic> json) => ProfileInsight(
        profileId: json['profileId']?.toString(),
        profileName: json['profileName']?.toString() ?? '',
        ageGroup: json['ageGroup']?.toString() ?? 'adult',
        flags: (json['flags'] as List? ?? [])
            .map((e) => InsightFlag.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get hasDanger => flags.any((f) => f.severity == 'danger');
}

// ── Label Detective: klaim pemasaran yang menyesatkan ────────────────────────

class MisleadingClaim {
  final String claim;
  final String issue;
  final String severity; // info | caution | warning

  MisleadingClaim({
    required this.claim,
    required this.issue,
    required this.severity,
  });

  factory MisleadingClaim.fromJson(Map<String, dynamic> json) => MisleadingClaim(
        claim: json['claim']?.toString() ?? '',
        issue: json['issue']?.toString() ?? '',
        severity: json['severity']?.toString() ?? 'caution',
      );
}

// ── Budget Harian ─────────────────────────────────────────────────────────────

class DailyBudgetNutrient {
  final double usedToday;
  final double addedByThis;
  final double afterEating;
  final double limit;
  final int pctBefore;
  final int pctAfter;

  DailyBudgetNutrient({
    required this.usedToday,
    required this.addedByThis,
    required this.afterEating,
    required this.limit,
    required this.pctBefore,
    required this.pctAfter,
  });

  factory DailyBudgetNutrient.fromJson(Map<String, dynamic> json) => DailyBudgetNutrient(
        usedToday: (json['usedToday'] ?? 0).toDouble(),
        addedByThis: (json['addedByThis'] ?? 0).toDouble(),
        afterEating: (json['afterEating'] ?? 0).toDouble(),
        limit: (json['limit'] ?? 0).toDouble(),
        pctBefore: (json['pctBefore'] ?? 0).toInt(),
        pctAfter: (json['pctAfter'] ?? 0).toInt(),
      );
}

class DailyBudget {
  final DailyBudgetNutrient calories;
  final DailyBudgetNutrient sugar;
  final DailyBudgetNutrient sodium;
  final DailyBudgetNutrient fatTotal;
  final List<String> alerts;

  DailyBudget({
    required this.calories,
    required this.sugar,
    required this.sodium,
    required this.fatTotal,
    required this.alerts,
  });

  factory DailyBudget.fromJson(Map<String, dynamic> json) => DailyBudget(
        calories: DailyBudgetNutrient.fromJson(json['calories'] as Map<String, dynamic>? ?? {}),
        sugar: DailyBudgetNutrient.fromJson(json['sugar'] as Map<String, dynamic>? ?? {}),
        sodium: DailyBudgetNutrient.fromJson(json['sodium'] as Map<String, dynamic>? ?? {}),
        fatTotal: DailyBudgetNutrient.fromJson(json['fatTotal'] as Map<String, dynamic>? ?? {}),
        alerts: List<String>.from(json['alerts'] ?? []),
      );
}

// ── Alternatif Lebih Sehat ────────────────────────────────────────────────────

class AlternativeProduct {
  final String id;
  final String name;
  final String? brand;
  final String nutriScore;
  final int finalScore;
  final int scanCount;

  AlternativeProduct({
    required this.id,
    required this.name,
    this.brand,
    required this.nutriScore,
    required this.finalScore,
    required this.scanCount,
  });

  factory AlternativeProduct.fromJson(Map<String, dynamic> json) => AlternativeProduct(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        brand: json['brand']?.toString(),
        nutriScore: json['nutriScore']?.toString() ?? '',
        finalScore: (json['finalScore'] ?? 0).toInt(),
        scanCount: (json['scanCount'] ?? 0).toInt(),
      );
}
