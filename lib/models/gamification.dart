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
  final int currentStreak;
  final int longestStreak;
  final int points;
  final int totalScans;
  final List<AppBadge> badges;
  final Map<String, dynamic> counters;

  GamificationStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.points,
    required this.totalScans,
    required this.badges,
    required this.counters,
  });

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return GamificationStats(
      currentStreak: (data['currentStreak'] ?? data['streak'] ?? 0).toInt(),
      longestStreak: (data['longestStreak'] ?? 0).toInt(),
      points: (data['points'] ?? 0).toInt(),
      totalScans: (data['totalScans'] ?? 0).toInt(),
      badges: (data['badges'] as List? ?? [])
          .map((b) => AppBadge.fromJson(b as Map<String, dynamic>))
          .toList(),
      counters: Map<String, dynamic>.from(data['counters'] ?? {}),
    );
  }

  List<AppBadge> get earnedBadges => badges.where((b) => b.earned).toList();
  int get earnedCount => earnedBadges.length;
}

/// Badge yang baru saja diraih (dikembalikan oleh endpoint scan/diary/quiz).
class BadgeInfo {
  final String id;
  final String name;
  final String description;
  final String icon;

  BadgeInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory BadgeInfo.fromJson(Map<String, dynamic> json) => BadgeInfo(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '🏅',
      );
}

/// Delta gamifikasi setelah sebuah aksi (scan, diary, compare, quiz).
class GamificationUpdate {
  final int points;
  final int pointsEarned;
  final int currentStreak;
  final int longestStreak;
  final int totalScans;
  final List<BadgeInfo> newBadges;

  GamificationUpdate({
    required this.points,
    required this.pointsEarned,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalScans,
    required this.newBadges,
  });

  factory GamificationUpdate.fromJson(Map<String, dynamic> json) => GamificationUpdate(
        points: (json['points'] ?? 0).toInt(),
        pointsEarned: (json['pointsEarned'] ?? 0).toInt(),
        currentStreak: (json['currentStreak'] ?? 0).toInt(),
        longestStreak: (json['longestStreak'] ?? 0).toInt(),
        totalScans: (json['totalScans'] ?? 0).toInt(),
        newBadges: (json['newBadges'] as List? ?? [])
            .map((b) => BadgeInfo.fromJson(b as Map<String, dynamic>))
            .toList(),
      );

  bool get hasNewBadges => newBadges.isNotEmpty;
}
