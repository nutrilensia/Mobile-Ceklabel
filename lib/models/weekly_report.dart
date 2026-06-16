import 'package:flutter/material.dart';

class ContributorItem {
  final String productName;
  final num total;
  final int times;

  ContributorItem({
    required this.productName,
    required this.total,
    required this.times,
  });

  factory ContributorItem.fromJson(Map<String, dynamic> json) => ContributorItem(
        productName: json['productName']?.toString() ?? '',
        total: json['totalSugarG'] ?? json['totalSodiumMg'] ?? json['total'] ?? 0,
        times: (json['times'] ?? 0).toInt(),
      );
}

class LifestyleScoreBreakdown {
  final int gradeScore;
  final int diaryScore;
  final int sugarScore;
  final int sodiumScore;

  LifestyleScoreBreakdown({
    required this.gradeScore,
    required this.diaryScore,
    required this.sugarScore,
    required this.sodiumScore,
  });

  factory LifestyleScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      LifestyleScoreBreakdown(
        gradeScore: (json['gradeScore'] ?? 0).toInt(),
        diaryScore: (json['diaryScore'] ?? 0).toInt(),
        sugarScore: (json['sugarScore'] ?? 0).toInt(),
        sodiumScore: (json['sodiumScore'] ?? 0).toInt(),
      );
}

class WeeklyReport {
  final String periodStart;
  final String periodEnd;
  final String profileName;
  final Map<String, num> dailyAverage;
  final Map<String, num> limits;
  final int caloriesPct;
  final int sugarPct;
  final int sodiumPct;
  final int fatSaturatedPct;
  final Map<String, int> gradeDistribution;
  final List<ContributorItem> topSugar;
  final List<ContributorItem> topSodium;
  final List<String> insights;
  final int totalEntries;
  final int daysLogged;
  final int lifestyleScore;
  final String lifestyleScoreLabel;
  final LifestyleScoreBreakdown? lifestyleScoreBreakdown;

  WeeklyReport({
    required this.periodStart,
    required this.periodEnd,
    required this.profileName,
    required this.dailyAverage,
    required this.limits,
    required this.caloriesPct,
    required this.sugarPct,
    required this.sodiumPct,
    required this.fatSaturatedPct,
    required this.gradeDistribution,
    required this.topSugar,
    required this.topSodium,
    required this.insights,
    required this.totalEntries,
    required this.daysLogged,
    this.lifestyleScore = 0,
    this.lifestyleScoreLabel = '',
    this.lifestyleScoreBreakdown,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    // Buka pembungkus: {data:{report:{...}}} atau {report:{...}} atau {...}
    final data = json['data'] ?? json;
    final report = (data is Map && data['report'] != null) ? data['report'] : data;
    final r = report as Map<String, dynamic>;

    final period = r['period'] as Map<String, dynamic>? ?? {};
    final avgVs = r['averageVsLimit'] as Map<String, dynamic>? ?? {};
    final dist = r['gradeDistribution'] as Map<String, dynamic>? ?? {};
    final profile = r['profile'] as Map<String, dynamic>? ?? {};

    Map<String, num> numMap(dynamic m) =>
        (m as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v ?? 0) as num));

    return WeeklyReport(
      periodStart: period['start']?.toString() ?? '',
      periodEnd: period['end']?.toString() ?? '',
      profileName: profile['name']?.toString() ?? 'Saya',
      dailyAverage: numMap(r['dailyAverage']),
      limits: numMap(r['limits']),
      caloriesPct: (avgVs['caloriesPct'] ?? 0).toInt(),
      sugarPct: (avgVs['sugarPct'] ?? 0).toInt(),
      sodiumPct: (avgVs['sodiumPct'] ?? 0).toInt(),
      fatSaturatedPct: (avgVs['fatSaturatedPct'] ?? 0).toInt(),
      gradeDistribution: dist.map((k, v) => MapEntry(k, (v ?? 0).toInt())),
      topSugar: (r['topSugarContributors'] as List? ?? [])
          .map((e) => ContributorItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      topSodium: (r['topSodiumContributors'] as List? ?? [])
          .map((e) => ContributorItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      insights: List<String>.from(r['insights'] ?? []),
      totalEntries: (r['totalEntries'] ?? 0).toInt(),
      daysLogged: (r['daysLogged'] ?? 0).toInt(),
      lifestyleScore: (r['lifestyleScore'] ?? 0).toInt(),
      lifestyleScoreLabel: r['lifestyleScoreLabel']?.toString() ?? '',
      lifestyleScoreBreakdown: r['lifestyleScoreBreakdown'] != null
          ? LifestyleScoreBreakdown.fromJson(
              r['lifestyleScoreBreakdown'] as Map<String, dynamic>)
          : null,
    );
  }

  int get totalGraded => gradeDistribution.values.fold(0, (a, b) => a + b);
  bool get isEmpty => totalEntries == 0;

  Color get lifestyleScoreColor {
    if (lifestyleScore >= 81) return const Color(0xFF1E8F4E);
    if (lifestyleScore >= 66) return const Color(0xFF6DB33F);
    if (lifestyleScore >= 51) return const Color(0xFFFFAD00);
    if (lifestyleScore >= 31) return const Color(0xFFEF7D00);
    return const Color(0xFFE63312);
  }
}
