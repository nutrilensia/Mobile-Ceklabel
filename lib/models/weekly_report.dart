class WeeklyReport {
  final String periodStart;
  final String periodEnd;
  final Map<String, num> averages;
  final Map<String, num> limits;
  final Map<String, int> gradeDistribution;
  final List<String> insights;
  final List<Map<String, dynamic>> topContributors;
  final int totalEntries;

  WeeklyReport({
    required this.periodStart,
    required this.periodEnd,
    required this.averages,
    required this.limits,
    required this.gradeDistribution,
    required this.insights,
    required this.topContributors,
    required this.totalEntries,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final period = data['period'] as Map<String, dynamic>? ?? {};
    final dist = data['gradeDistribution'] as Map<String, dynamic>? ?? {};
    return WeeklyReport(
      periodStart: period['start']?.toString() ?? '',
      periodEnd: period['end']?.toString() ?? '',
      averages: Map<String, num>.from(data['averages'] ?? {}),
      limits: Map<String, num>.from(data['limits'] ?? {}),
      gradeDistribution: dist.map((k, v) => MapEntry(k, (v ?? 0).toInt())),
      insights: List<String>.from(data['insights'] ?? []),
      topContributors: List<Map<String, dynamic>>.from(
          (data['topContributors'] ?? []).map((e) => Map<String, dynamic>.from(e))),
      totalEntries: (data['totalEntries'] ?? 0).toInt(),
    );
  }

  int get totalScanned =>
      gradeDistribution.values.fold(0, (a, b) => a + b);
}
