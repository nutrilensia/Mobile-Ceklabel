class FamilyProfile {
  final String id;
  final String name;
  final String relation;
  final String ageGroup;
  final Map<String, dynamic> conditions;
  final Map<String, dynamic>? effectiveDailyLimits;

  FamilyProfile({
    required this.id,
    required this.name,
    required this.relation,
    required this.ageGroup,
    required this.conditions,
    this.effectiveDailyLimits,
  });

  factory FamilyProfile.fromJson(Map<String, dynamic> json) => FamilyProfile(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    relation: json['relation']?.toString() ?? '',
    ageGroup: json['ageGroup']?.toString() ?? 'adult',
    conditions: Map<String, dynamic>.from(json['conditions'] ?? {}),
    effectiveDailyLimits: json['effectiveDailyLimits'] != null
        ? Map<String, dynamic>.from(json['effectiveDailyLimits'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation,
    'ageGroup': ageGroup,
    'conditions': conditions,
  };

  List<String> get allergyList =>
      List<String>.from(conditions['allergies'] ?? []);

  String get relationLabel => kRelationLabels[relation] ?? relation;
  String get ageGroupLabel => kAgeGroupLabels[ageGroup] ?? ageGroup;
}

const kRelationLabels = {
  'anak': 'Anak',
  'suami': 'Suami',
  'istri': 'Istri',
  'orang-tua': 'Orang Tua',
  'saudara': 'Saudara',
  'lainnya': 'Lainnya',
};

// Selaras dengan enum backend: child | teen | adult | elderly
const kAgeGroupLabels = {
  'child': 'Anak (4–12 th)',
  'teen': 'Remaja (13–17 th)',
  'adult': 'Dewasa (18–59 th)',
  'elderly': 'Lansia (60+ th)',
};
