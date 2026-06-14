import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/history_item.dart';
import '../services/api_service.dart';

// ── Local stats computed from scan history ────────────────────────────────────

class _WeekStats {
  final List<HistoryItem> items;
  final DateTime weekStart;
  final DateTime today;

  _WeekStats(this.items, this.weekStart, this.today);

  static const double calLimit = 2000;
  static const double sugarLimit = 50;
  static const double sodiumLimit = 2000;

  int get totalScanned => items.length;

  Set<String> get _dayKeys => items
      .map((i) => '${i.scannedAt.year}-${i.scannedAt.month}-${i.scannedAt.day}')
      .toSet();

  int get activeDays => _dayKeys.length.clamp(1, 7);

  // Sum all nutrients then divide by active days → avg daily intake
  double get avgCalories =>
      items.fold(0.0, (s, i) => s + i.calories) / activeDays;
  double get avgSugar =>
      items.fold(0.0, (s, i) => s + i.sugarG) / activeDays;
  double get avgSodium =>
      items.fold(0.0, (s, i) => s + i.sodiumMg) / activeDays;

  double get calPct => (avgCalories / calLimit).clamp(0.0, 1.0);
  double get sugarPct => (avgSugar / sugarLimit).clamp(0.0, 1.0);
  double get sodiumPct => (avgSodium / sodiumLimit).clamp(0.0, 1.0);

  Map<String, int> get gradeDistribution {
    final map = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0};
    for (final i in items) {
      final g = i.grade.toUpperCase();
      if (map.containsKey(g)) map[g] = map[g]! + 1;
    }
    return map;
  }

  double get healthScore {
    if (items.isEmpty) return 0;
    final good =
        items.where((i) => i.grade == 'A' || i.grade == 'B').length;
    return good / items.length;
  }

  int get healthScorePct => (healthScore * 100).round();

  List<HistoryItem> get topByCalorie {
    final sorted = [...items]
      ..sort((a, b) => b.calories.compareTo(a.calories));
    return sorted.take(5).toList();
  }

  List<String> get insights {
    final list = <String>[];
    if (items.isEmpty) return list;

    if (healthScorePct >= 70) {
      list.add(
          '$healthScorePct% produk yang kamu scan bernilai Nutri-Score A/B — pilihan yang sehat!');
    } else if (healthScorePct >= 40) {
      list.add(
          '$healthScorePct% produk bernilai A/B. Masih ada ruang untuk pilihan lebih sehat.');
    } else {
      list.add(
          'Hanya $healthScorePct% produk bernilai A/B. Coba pilih produk lebih sehat minggu depan.');
    }

    final calP = (calPct * 100).round();
    if (calP > 0) {
      list.add(
          'Rata-rata asupan kalori dari produk yang di-scan: $calP% dari batas harian (2000 kkal).');
    }
    if (avgSodium > 1500) {
      list.add(
          'Asupan sodium cukup tinggi (${avgSodium.round()} mg/hari). Kurangi produk yang terlalu asin.');
    } else if (avgSodium > 0) {
      list.add(
          'Asupan sodium terkontrol (${avgSodium.round()} mg/hari dari batas 2000 mg). Bagus!');
    }
    if (avgSugar > 40) {
      list.add(
          'Asupan gula rata-rata ${avgSugar.round()} g/hari. Perhatikan konsumsi gula tambahan.');
    }
    list.add(
        'Kamu scan $totalScanned produk dalam $activeDays hari aktif minggu ini. '
        '${activeDays >= 5 ? "Konsisten!" : "Coba lebih sering scan setiap hari."}');

    return list;
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des'
  ];

  String get periodStart =>
      '${weekStart.day} ${_months[weekStart.month - 1]}';
  String get periodEnd => '${today.day} ${_months[today.month - 1]}';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  late Future<List<HistoryItem>> _future;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = ApiService().getHistory(limit: 500);
    });
  }

  _WeekStats _buildStats(List<HistoryItem> all) {
    final now = DateTime.now();
    final monday =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final weekItems = all
        .where((i) =>
            !i.scannedAt.isBefore(monday) && !i.scannedAt.isAfter(endOfDay))
        .toList();
    return _WeekStats(weekItems, monday, now);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        title: Text('Laporan Mingguan',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 17)),
        elevation: 0,
        actions: [
          FutureBuilder<List<HistoryItem>>(
            future: _future,
            builder: (_, snap) {
              if (snap.data == null) return const SizedBox();
              final stats = _buildStats(snap.data!);
              if (stats.totalScanned == 0) return const SizedBox();
              return _exporting
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Color(0xFF4ECDC4), strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.picture_as_pdf_rounded,
                          color: Color(0xFF4ECDC4)),
                      tooltip: 'Export PDF',
                      onPressed: () => _exportPdf(stats),
                    );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<HistoryItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4ECDC4)));
          }
          if (snap.hasError) return _buildError(snap.error.toString());
          final stats = _buildStats(snap.data ?? []);
          return stats.totalScanned == 0
              ? _buildEmpty()
              : _buildReport(stats);
        },
      ),
    );
  }

  // ── Report layout ─────────────────────────────────────────────────────────

  Widget _buildReport(_WeekStats s) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPeriodHeader(s),
        const SizedBox(height: 20),
        _buildHealthScoreCard(s),
        const SizedBox(height: 20),
        _buildNutritionSection(s),
        const SizedBox(height: 20),
        _buildGradeDistribution(s),
        const SizedBox(height: 20),
        _buildInsights(s),
        if (s.topByCalorie.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildTopProducts(s),
        ],
        const SizedBox(height: 24),
        _buildPdfHint(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPeriodHeader(_WeekStats s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4ECDC4).withValues(alpha: 0.15),
            const Color(0xFF4ECDC4).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded,
              color: Color(0xFF4ECDC4), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Minggu Ini',
                    style:
                        GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                Text('${s.periodStart} – ${s.periodEnd}',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.totalScanned} scan',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4ECDC4)),
              ),
              Text(
                '${s.activeDays} hari aktif',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(_WeekStats s) {
    final pct = s.healthScorePct;
    final color = pct >= 70
        ? const Color(0xFF4ECDC4)
        : pct >= 40
            ? const Color(0xFFFFAD00)
            : const Color(0xFFFF6B6B);
    final label = pct >= 70
        ? 'Sangat Baik'
        : pct >= 40
            ? 'Cukup Baik'
            : 'Perlu Ditingkatkan';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 7,
                  backgroundColor: Colors.transparent,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
                CircularProgressIndicator(
                  value: s.healthScore,
                  strokeWidth: 7,
                  backgroundColor: Colors.transparent,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$pct%',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Skor Kesehatan',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 4),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(height: 6),
                Text(
                  '${s.gradeDistribution['A']! + s.gradeDistribution['B']!} dari ${s.totalScanned} produk bernilai A/B',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(_WeekStats s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Rata-rata Asupan Harian',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70)),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Dihitung dari total nutrisi dibagi hari aktif scan',
              child: Icon(Icons.info_outline_rounded,
                  size: 14, color: Colors.white30),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildNutrientCard(
                    'Kalori', s.avgCalories, _WeekStats.calLimit, 'kkal',
                    s.calPct, const Color(0xFFFF6B6B))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildNutrientCard(
                    'Gula', s.avgSugar, _WeekStats.sugarLimit, 'g',
                    s.sugarPct, const Color(0xFFFFD93D))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildNutrientCard(
                    'Sodium', s.avgSodium, _WeekStats.sodiumLimit, 'mg',
                    s.sodiumPct, const Color(0xFF6BCB77))),
          ],
        ),
      ],
    );
  }

  Widget _buildNutrientCard(String label, double val, double limit,
      String unit, double ratio, Color color) {
    final isOver = ratio >= 1.0;
    final displayColor = isOver ? const Color(0xFFFF6B6B) : color;
    final pct = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver
              ? displayColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(
            val.round().toString(),
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: displayColor),
          ),
          Text('/ ${limit.round()} $unit',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(displayColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$pct% batas harian',
            style: GoogleFonts.inter(
                fontSize: 10,
                color: isOver ? const Color(0xFFFF6B6B) : Colors.white30,
                fontWeight:
                    isOver ? FontWeight.w600 : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution(_WeekStats s) {
    final dist = s.gradeDistribution;
    final total = s.totalScanned;
    if (total == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Distribusi Nutri-Score',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            children: ['A', 'B', 'C', 'D', 'E'].map((grade) {
              final count = dist[grade] ?? 0;
              final pct = total > 0 ? count / total : 0.0;
              return _buildGradeBar(grade, count, pct, total);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeBar(String grade, int count, double pct, int total) {
    final color = _gradeColor(grade);
    final pctLabel = total > 0 ? '${(pct * 100).round()}%' : '0%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(grade,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor:
                    AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.7)),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(pctLabel,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: count > 0 ? color : Colors.white24,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 18,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(_WeekStats s) {
    final insights = s.insights;
    if (insights.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insight Minggu Ini',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70)),
        const SizedBox(height: 12),
        ...insights.map(
          (insight) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFFFD93D), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(insight,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProducts(_WeekStats s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Produk Tertinggi Kalori',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70)),
        const SizedBox(height: 12),
        ...s.topByCalorie.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final color = _gradeColor(item.grade);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Text('${i + 1}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white24)),
                const SizedBox(width: 10),
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(item.grade.isNotEmpty ? item.grade : '?',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.productName,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text('${item.calories.round()} kkal',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPdfHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4ECDC4).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded,
              color: Color(0xFF4ECDC4), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap ikon PDF di pojok kanan atas untuk export laporan ini sebagai file PDF.',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.8),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── PDF Export ────────────────────────────────────────────────────────────

  Future<void> _exportPdf(_WeekStats s) async {
    setState(() => _exporting = true);
    try {
      final pdf = pw.Document();
      final teal = PdfColor.fromHex('#4ECDC4');
      final red = PdfColor.fromHex('#FF6B6B');
      final yellow = PdfColor.fromHex('#FFD93D');
      final green = PdfColor.fromHex('#6BCB77');
      final grey = PdfColors.grey400;

      final gradeColors = <String, PdfColor>{
        'A': PdfColor.fromHex('#1E8F4E'),
        'B': PdfColor.fromHex('#6DB33F'),
        'C': PdfColor.fromHex('#FFAD00'),
        'D': PdfColor.fromHex('#EF7D00'),
        'E': PdfColor.fromHex('#E63312'),
      };

      pw.Widget pdfBar(double frac, PdfColor fill, {double h = 5}) =>
          pw.LayoutBuilder(builder: (ctx, con) {
            final w = con?.maxWidth ?? 400.0;
            return pw.Stack(children: [
              pw.Container(
                  width: w,
                  height: h,
                  decoration: pw.BoxDecoration(
                      color: PdfColors.grey800,
                      borderRadius: pw.BorderRadius.circular(h / 2))),
              pw.Container(
                  width: w * frac.clamp(0.0, 1.0),
                  height: h,
                  decoration: pw.BoxDecoration(
                      color: fill,
                      borderRadius: pw.BorderRadius.circular(h / 2))),
            ]);
          });

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.interRegular(),
          bold: await PdfGoogleFonts.interBold(),
          italic: await PdfGoogleFonts.interRegular(),
        ),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CekLabel',
                          style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: teal)),
                      pw.Text('Laporan Mingguan Gizi',
                          style: pw.TextStyle(fontSize: 12, color: grey)),
                    ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Periode: ${s.periodStart} – ${s.periodEnd}',
                          style: pw.TextStyle(fontSize: 10, color: grey)),
                      pw.Text(
                          '${s.totalScanned} scan · ${s.activeDays} hari aktif',
                          style: pw.TextStyle(fontSize: 10, color: grey)),
                    ]),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: teal, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          // Health score
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0D2B2B'),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: teal, width: 0.8),
            ),
            child: pw.Row(children: [
              pw.Text('Skor Kesehatan: ',
                  style: pw.TextStyle(fontSize: 12, color: grey)),
              pw.Text('${s.healthScorePct}%',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: s.healthScorePct >= 70
                          ? teal
                          : s.healthScorePct >= 40
                              ? yellow
                              : red)),
              pw.Text(
                  '  (${s.gradeDistribution['A']! + s.gradeDistribution['B']!} '
                  'dari ${s.totalScanned} produk bernilai A/B)',
                  style: pw.TextStyle(fontSize: 11, color: grey)),
            ]),
          ),
          pw.SizedBox(height: 20),

          // Nutrition averages
          pw.Text('RATA-RATA ASUPAN HARIAN',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: grey,
                  letterSpacing: 1.2)),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            for (final n in [
              ('Kalori', s.avgCalories, _WeekStats.calLimit, 'kkal', red,
                  s.calPct),
              ('Gula', s.avgSugar, _WeekStats.sugarLimit, 'g', yellow,
                  s.sugarPct),
              ('Sodium', s.avgSodium, _WeekStats.sodiumLimit, 'mg', green,
                  s.sodiumPct),
            ])
              pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(right: 8),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#12121F'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                        color: PdfColors.grey800, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(n.$1,
                          style:
                              pw.TextStyle(fontSize: 10, color: grey)),
                      pw.SizedBox(height: 4),
                      pw.Text('${n.$2.round()} ${n.$4}',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: n.$5)),
                      pw.Text(
                          '${(n.$6 * 100).round()}% dari ${n.$3.round()} ${n.$4}',
                          style:
                              pw.TextStyle(fontSize: 9, color: grey)),
                      pw.SizedBox(height: 6),
                      pdfBar(n.$6, n.$5),
                    ],
                  ),
                ),
              ),
          ]),
          pw.SizedBox(height: 20),

          // Grade distribution
          pw.Text('DISTRIBUSI NUTRI-SCORE',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: grey,
                  letterSpacing: 1.2)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#12121F'),
              borderRadius: pw.BorderRadius.circular(8),
              border:
                  pw.Border.all(color: PdfColors.grey800, width: 0.5),
            ),
            child: pw.Column(children: [
              for (final grade in ['A', 'B', 'C', 'D', 'E']) ...[
                pw.SizedBox(height: 4),
                pw.Row(children: [
                  pw.Container(
                    width: 24, height: 24,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: (gradeColors[grade] ?? PdfColors.grey)
                          .shade(0.8),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(grade,
                        style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: gradeColors[grade] ?? PdfColors.grey)),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                      child: pdfBar(
                          s.totalScanned > 0
                              ? ((s.gradeDistribution[grade] ?? 0) /
                                      s.totalScanned)
                                  .clamp(0.0, 1.0)
                              : 0,
                          (gradeColors[grade] ?? PdfColors.grey).shade(0.7),
                          h: 6)),
                  pw.SizedBox(width: 10),
                  pw.Text(
                      '${(s.totalScanned > 0 ? (s.gradeDistribution[grade] ?? 0) / s.totalScanned * 100 : 0).round()}%',
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.SizedBox(width: 6),
                  pw.Text('(${s.gradeDistribution[grade] ?? 0})',
                      style:
                          pw.TextStyle(fontSize: 10, color: PdfColors.grey400)),
                ]),
              ],
            ]),
          ),
          pw.SizedBox(height: 20),

          // Insights
          if (s.insights.isNotEmpty) ...[
            pw.Text('INSIGHT MINGGU INI',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: grey,
                    letterSpacing: 1.2)),
            pw.SizedBox(height: 10),
            for (final insight in s.insights)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#12121F'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                      color: PdfColors.grey800, width: 0.5),
                ),
                child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(
                              color: yellow,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(
                          child: pw.Text(insight,
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.white))),
                    ]),
              ),
            pw.SizedBox(height: 20),
          ],

          // Top products
          if (s.topByCalorie.isNotEmpty) ...[
            pw.Text('PRODUK TERTINGGI KALORI',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: grey,
                    letterSpacing: 1.2)),
            pw.SizedBox(height: 10),
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#12121F'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                    color: PdfColors.grey800, width: 0.5),
              ),
              child: pw.Column(children: [
                for (int i = 0; i < s.topByCalorie.length; i++) ...[
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    child: pw.Row(children: [
                      pw.Text('${i + 1}. ',
                          style: pw.TextStyle(
                              fontSize: 11, color: PdfColors.grey500)),
                      pw.Expanded(
                          child: pw.Text(s.topByCalorie[i].productName,
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.white))),
                      pw.Text(
                          '${s.topByCalorie[i].calories.round()} kkal  •  ${s.topByCalorie[i].grade}',
                          style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: grey)),
                    ]),
                  ),
                  if (i < s.topByCalorie.length - 1)
                    pw.Divider(
                        color: PdfColors.grey800, thickness: 0.5),
                ],
              ]),
            ),
          ],

          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey700),
          pw.SizedBox(height: 6),
          pw.Text('Digenerate oleh CekLabel',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ));

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'laporan-gizi-${s.periodStart}-${s.periodEnd}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal export PDF: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
        ));
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  size: 48, color: Color(0xFF4ECDC4)),
            ),
            const SizedBox(height: 20),
            Text('Belum ada data minggu ini',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Scan produk makanan dan laporan\nmingguan otomatis terbentuk dari data scan kamu',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white38, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.black),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A': return const Color(0xFF1E8F4E);
      case 'B': return const Color(0xFF6DB33F);
      case 'C': return const Color(0xFFFFAD00);
      case 'D': return const Color(0xFFEF7D00);
      case 'E': return const Color(0xFFE63312);
      default: return const Color(0xFF888888);
    }
  }
}
