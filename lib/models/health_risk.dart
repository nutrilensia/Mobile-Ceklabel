class HealthRisk {
  final String nutrient;
  final String label;
  final int avgPct;
  final String trend;
  final String riskLevel;
  final String consequence;
  final String recommendation;
  final String reference;

  HealthRisk({
    required this.nutrient,
    required this.label,
    required this.avgPct,
    required this.trend,
    required this.riskLevel,
    required this.consequence,
    required this.recommendation,
    required this.reference,
  });

  factory HealthRisk.fromJson(Map<String, dynamic> j) => HealthRisk(
        nutrient: j['nutrient']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
        avgPct: (j['avgPct'] ?? 0).toInt(),
        trend: j['trend']?.toString() ?? 'stable',
        riskLevel: j['riskLevel']?.toString() ?? 'low',
        consequence: j['consequence']?.toString() ?? '',
        recommendation: j['recommendation']?.toString() ?? '',
        reference: j['reference']?.toString() ?? '',
      );
}

class HealthRiskReport {
  final int periodDays;
  final int daysWithData;
  final List<HealthRisk> risks;
  final String overallRiskLevel;
  final String summary;
  final List<String> positives;

  HealthRiskReport({
    required this.periodDays,
    required this.daysWithData,
    required this.risks,
    required this.overallRiskLevel,
    required this.summary,
    required this.positives,
  });

  factory HealthRiskReport.fromJson(Map<String, dynamic> j) {
    final data = j['data'] ?? j;
    return HealthRiskReport(
      periodDays: (data['periodDays'] ?? 30).toInt(),
      daysWithData: (data['daysWithData'] ?? 0).toInt(),
      risks: (data['risks'] as List? ?? [])
          .map((e) => HealthRisk.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallRiskLevel: data['overallRiskLevel']?.toString() ?? 'low',
      summary: data['summary']?.toString() ?? '',
      positives: List<String>.from(data['positives'] ?? []),
    );
  }
}
