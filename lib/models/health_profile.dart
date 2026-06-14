class HealthProfile {
  final bool hasDiabetes;
  final bool hasHypertension;
  final bool hasHighCholesterol;
  final bool isVegetarian;
  final List<String> allergies;
  final int dailyCalorieTarget;

  const HealthProfile({
    this.hasDiabetes = false,
    this.hasHypertension = false,
    this.hasHighCholesterol = false,
    this.isVegetarian = false,
    this.allergies = const [],
    this.dailyCalorieTarget = 2000,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) => HealthProfile(
    hasDiabetes: json['hasDiabetes'] ?? false,
    hasHypertension: json['hasHypertension'] ?? false,
    hasHighCholesterol: json['hasHighCholesterol'] ?? false,
    isVegetarian: json['isVegetarian'] ?? false,
    allergies: List<String>.from(json['allergies'] ?? []),
    dailyCalorieTarget: (json['dailyCalorieTarget'] ?? 2000).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'hasDiabetes': hasDiabetes,
    'hasHypertension': hasHypertension,
    'hasHighCholesterol': hasHighCholesterol,
    'isVegetarian': isVegetarian,
    'allergies': allergies,
    'dailyCalorieTarget': dailyCalorieTarget,
  };

  HealthProfile copyWith({
    bool? hasDiabetes,
    bool? hasHypertension,
    bool? hasHighCholesterol,
    bool? isVegetarian,
    List<String>? allergies,
    int? dailyCalorieTarget,
  }) => HealthProfile(
    hasDiabetes: hasDiabetes ?? this.hasDiabetes,
    hasHypertension: hasHypertension ?? this.hasHypertension,
    hasHighCholesterol: hasHighCholesterol ?? this.hasHighCholesterol,
    isVegetarian: isVegetarian ?? this.isVegetarian,
    allergies: allergies ?? this.allergies,
    dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
  );
}

const kAllergyOptions = [
  'susu', 'kacang', 'kacang-pohon', 'telur',
  'gluten', 'kedelai', 'ikan', 'krustasea', 'kerang', 'wijen',
];
