class AppBadge {
  final String id;
  final String name;
  final String description;
  final bool earned;
  final DateTime? earnedAt;
  final String? icon;

  AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.earned,
    this.earnedAt,
    this.icon,
  });

  factory AppBadge.fromJson(Map<String, dynamic> json) => AppBadge(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    earned: json['earned'] ?? false,
    earnedAt: json['earnedAt'] != null
        ? DateTime.tryParse(json['earnedAt'].toString())
        : null,
    icon: json['icon']?.toString(),
  );
}

class GamificationStats {
  final int streak;
  final int points;
  final int totalScans;
  final List<AppBadge> badges;
  final int level;

  GamificationStats({
    required this.streak,
    required this.points,
    required this.totalScans,
    required this.badges,
    required this.level,
  });

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return GamificationStats(
      streak: (data['streak'] ?? 0).toInt(),
      points: (data['points'] ?? 0).toInt(),
      totalScans: (data['totalScans'] ?? 0).toInt(),
      badges: (data['badges'] as List? ?? [])
          .map((b) => AppBadge.fromJson(b as Map<String, dynamic>))
          .toList(),
      level: (data['level'] ?? 1).toInt(),
    );
  }

  List<AppBadge> get earnedBadges => badges.where((b) => b.earned).toList();
}
