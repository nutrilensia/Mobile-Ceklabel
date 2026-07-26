import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/grade_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/weekly_report.dart';
import '../services/api_service.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  Future<WeeklyReport>? _future;
  bool _exporting = false;
  DateTime _weekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _startStr =>
      '${_weekStart.year}-${_weekStart.month.toString().padLeft(2, '0')}-${_weekStart.day.toString().padLeft(2, '0')}';

  bool get _isThisWeek =>
      _weekStart.isAtSameMomentAs(_mondayOf(DateTime.now()));

  void _load() {
    setState(() => _future = ApiService().getWeeklyReport(startDate: _startStr));
  }

  void _changeWeek(int deltaWeeks) {
    final next = _weekStart.add(Duration(days: 7 * deltaWeeks));
    if (next.isAfter(_mondayOf(DateTime.now()))) return;
    setState(() => _weekStart = next);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        foregroundColor: AppColors.appBarForeground(context),
        title: Text('Laporan Mingguan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17)),
        elevation: 0,
        actions: [
          FutureBuilder<WeeklyReport>(
            future: _future,
            builder: (_, snap) {
              if (snap.data == null || snap.data!.isEmpty) return const SizedBox();
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
                      onPressed: () => _exportPdf(snap.data!),
                    );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekSelector(),
          Expanded(
            child: FutureBuilder<WeeklyReport>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4ECDC4)));
                }
                if (snap.hasError) return _buildError(snap.error.toString());
                final report = snap.data;
                if (report == null || report.isEmpty) return _buildEmpty();
                return _buildReport(report);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary(context)),
            onPressed: () => _changeWeek(-1),
            splashRadius: 20,
          ),
          Expanded(
            child: Text(_isThisWeek ? 'Minggu Ini' : 'Mulai $_startStr',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded,
                color: _isThisWeek ? AppColors.textQuaternary(context) : AppColors.textSecondary(context)),
            onPressed: _isThisWeek ? null : () => _changeWeek(1),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildReport(WeeklyReport r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (r.lifestyleScore > 0) ...[
          _buildLifestyleScore(r),
          const SizedBox(height: 20),
        ],
        _buildPeriodHeader(r),
        const SizedBox(height: 20),
        _buildAveragesSection(r),
        const SizedBox(height: 20),
        if (r.totalGraded > 0) ...[
          _buildGradeDistribution(r),
          const SizedBox(height: 20),
        ],
        if (r.topSugar.isNotEmpty) ...[
          _buildContributors('Penyumbang Gula Terbesar', r.topSugar, 'g',
              const Color(0xFFFFAD00)),
          const SizedBox(height: 20),
        ],
        if (r.topSodium.isNotEmpty) ...[
          _buildContributors('Penyumbang Natrium Terbesar', r.topSodium, 'mg',
              const Color(0xFF4ECDC4)),
          const SizedBox(height: 20),
        ],
        if (r.insights.isNotEmpty) _buildInsights(r),
        const SizedBox(height: 16),
        _buildPdfHint(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPeriodHeader(WeeklyReport r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF4ECDC4).withValues(alpha: 0.15),
          const Color(0xFF4ECDC4).withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, color: Color(0xFF4ECDC4), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.profileName} • ${r.periodStart} – ${r.periodEnd}',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                Text('${r.totalEntries} catatan konsumsi',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${r.daysLogged}/7',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4ECDC4))),
              Text('hari tercatat',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAveragesSection(WeeklyReport r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rata-rata Harian vs Batas AKG',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBody(context))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _avgCard('Kalori', r.dailyAverage['calories'] ?? 0,
                    r.limits['calories'] ?? 0, 'kkal', r.caloriesPct,
                    const Color(0xFFFF6B6B))),
            const SizedBox(width: 10),
            Expanded(
                child: _avgCard('Gula', r.dailyAverage['sugarG'] ?? 0,
                    r.limits['sugarG'] ?? 0, 'g', r.sugarPct,
                    const Color(0xFFFFD93D))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _avgCard('Natrium', r.dailyAverage['sodiumMg'] ?? 0,
                    r.limits['sodiumMg'] ?? 0, 'mg', r.sodiumPct,
                    const Color(0xFF6BCB77))),
            const SizedBox(width: 10),
            Expanded(
                child: _avgCard('Lemak jenuh', r.dailyAverage['fatSaturatedG'] ?? 0,
                    r.limits['fatSaturatedG'] ?? 0, 'g', r.fatSaturatedPct,
                    const Color(0xFFAD7BFF))),
          ],
        ),
      ],
    );
  }

  Widget _avgCard(String label, num val, num limit, String unit, int pct, Color color) {
    final over = pct >= 100;
    final displayColor = over ? const Color(0xFFFF6B6B) : color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: over
                ? displayColor.withValues(alpha: 0.3)
                : AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
          const SizedBox(height: 4),
          Text(val.round().toString(),
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold, color: displayColor)),
          Text('/ ${limit.round()} $unit',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary(context))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.cardBorder(context),
              valueColor: AlwaysStoppedAnimation<Color>(displayColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text('$pct% batas harian',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: over ? const Color(0xFFFF6B6B) : AppColors.textTertiary(context),
                  fontWeight: over ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution(WeeklyReport r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Distribusi Nutri-Score Produk',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBody(context))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder(context)),
          ),
          child: Column(
            children: ['A', 'B', 'C', 'D', 'E'].map((g) {
              final count = r.gradeDistribution[g] ?? 0;
              final pct = r.totalGraded > 0 ? count / r.totalGraded : 0.0;
              return _gradeBar(g, count, pct);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _gradeBar(String grade, int count, double pct) {
    final color = gradeColor(grade);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7)),
            alignment: Alignment.center,
            child: Text(grade,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.cardBorder(context),
                valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.7)),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text('${(pct * 100).round()}%',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: count > 0 ? color : AppColors.textQuaternary(context),
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 18,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildContributors(
      String title, List<ContributorItem> items, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBody(context))),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Row(
              children: [
                Text('${i + 1}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textQuaternary(context))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.productName,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody(context)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text('${item.total.round()} $unit',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                if (item.times > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text('×${item.times}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textQuaternary(context))),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInsights(WeeklyReport r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Catatan Minggu Ini',
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBody(context))),
        const SizedBox(height: 12),
        ...r.insights.map((insight) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder(context)),
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
                            fontSize: 13, color: AppColors.textBody(context), height: 1.4)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildPdfHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4ECDC4).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF4ECDC4), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap ikon PDF di kanan atas untuk export laporan ini — bisa dibawa ke dokter/ahli gizi.',
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

  // ── PDF Export (dari data report nyata) ──────────────────────────────────

  Future<void> _exportPdf(WeeklyReport r) async {
    setState(() => _exporting = true);
    try {
      final pdf = pw.Document();
      final teal = PdfColor.fromHex('#4ECDC4');
      final grey = PdfColors.grey400;
      final gradeColors = <String, PdfColor>{
        'A': PdfColor.fromHex('#1E8F4E'),
        'B': PdfColor.fromHex('#6DB33F'),
        'C': PdfColor.fromHex('#FFAD00'),
        'D': PdfColor.fromHex('#EF7D00'),
        'E': PdfColor.fromHex('#E63312'),
      };

      pw.Widget bar(double frac, PdfColor fill, {double h = 6}) =>
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
                      color: fill, borderRadius: pw.BorderRadius.circular(h / 2))),
            ]);
          });

      final avgRows = [
        ('Kalori', r.dailyAverage['calories'] ?? 0, r.limits['calories'] ?? 0, 'kkal', r.caloriesPct),
        ('Gula', r.dailyAverage['sugarG'] ?? 0, r.limits['sugarG'] ?? 0, 'g', r.sugarPct),
        ('Natrium', r.dailyAverage['sodiumMg'] ?? 0, r.limits['sodiumMg'] ?? 0, 'mg', r.sodiumPct),
        ('Lemak jenuh', r.dailyAverage['fatSaturatedG'] ?? 0, r.limits['fatSaturatedG'] ?? 0, 'g', r.fatSaturatedPct),
      ];

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.interRegular(),
          bold: await PdfGoogleFonts.interBold(),
        ),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('NutriLensia',
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold, color: teal)),
                  pw.Text('Laporan Gizi Mingguan',
                      style: pw.TextStyle(fontSize: 12, color: grey)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('Profil: ${r.profileName}',
                      style: pw.TextStyle(fontSize: 10, color: grey)),
                  pw.Text('${r.periodStart} – ${r.periodEnd}',
                      style: pw.TextStyle(fontSize: 10, color: grey)),
                  pw.Text('${r.daysLogged}/7 hari • ${r.totalEntries} catatan',
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
          pw.Text('RATA-RATA HARIAN VS BATAS AKG',
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
              border: pw.Border.all(color: PdfColors.grey800, width: 0.5),
            ),
            child: pw.Column(children: [
              for (final n in avgRows) ...[
                pw.SizedBox(height: 4),
                pw.Row(children: [
                  pw.SizedBox(
                      width: 80,
                      child: pw.Text(n.$1,
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.white))),
                  pw.Expanded(
                      child: bar((n.$5 / 100), n.$5 >= 100 ? PdfColor.fromHex('#FF6B6B') : teal)),
                  pw.SizedBox(width: 10),
                  pw.Text('${n.$2.round()}/${n.$3.round()} ${n.$4}',
                      style: pw.TextStyle(fontSize: 10, color: grey)),
                  pw.SizedBox(width: 8),
                  pw.Text('${n.$5}%',
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: n.$5 >= 100 ? PdfColor.fromHex('#FF6B6B') : PdfColors.white)),
                ]),
              ],
            ]),
          ),
          pw.SizedBox(height: 20),

          if (r.totalGraded > 0) ...[
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
                border: pw.Border.all(color: PdfColors.grey800, width: 0.5),
              ),
              child: pw.Column(children: [
                for (final g in ['A', 'B', 'C', 'D', 'E']) ...[
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Container(
                      width: 24, height: 24,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: (gradeColors[g] ?? PdfColors.grey).shade(0.8),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(g,
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: gradeColors[g] ?? PdfColors.grey)),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                        child: bar(
                            r.totalGraded > 0
                                ? (r.gradeDistribution[g] ?? 0) / r.totalGraded
                                : 0,
                            (gradeColors[g] ?? PdfColors.grey).shade(0.7))),
                    pw.SizedBox(width: 10),
                    pw.Text('(${r.gradeDistribution[g] ?? 0})',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey400)),
                  ]),
                ],
              ]),
            ),
            pw.SizedBox(height: 20),
          ],

          if (r.topSugar.isNotEmpty) ...[
            _pdfContributorSection('PENYUMBANG GULA TERBESAR', r.topSugar, 'g', grey),
            pw.SizedBox(height: 20),
          ],
          if (r.topSodium.isNotEmpty) ...[
            _pdfContributorSection('PENYUMBANG NATRIUM TERBESAR', r.topSodium, 'mg', grey),
            pw.SizedBox(height: 20),
          ],

          if (r.insights.isNotEmpty) ...[
            pw.Text('CATATAN',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: grey,
                    letterSpacing: 1.2)),
            pw.SizedBox(height: 10),
            for (final insight in r.insights)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#12121F'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey800, width: 0.5),
                ),
                child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(
                              color: PdfColor.fromHex('#FFD93D'),
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(
                          child: pw.Text(insight,
                              style: pw.TextStyle(fontSize: 11, color: PdfColors.white))),
                    ]),
              ),
            pw.SizedBox(height: 20),
          ],

          pw.Divider(color: PdfColors.grey700),
          pw.SizedBox(height: 6),
          pw.Text(
              'Laporan dari catatan mandiri di aplikasi NutriLensia — bukan pengganti konsultasi medis. '
              'Batas harian mengacu pada AKG BPOM/Kemenkes.',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ));

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'ceklabel-laporan-${r.periodStart}.pdf',
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

  pw.Widget _pdfContributorSection(
      String title, List<ContributorItem> items, String unit, PdfColor grey) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title,
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
          border: pw.Border.all(color: PdfColors.grey800, width: 0.5),
        ),
        child: pw.Column(children: [
          for (int i = 0; i < items.length; i++) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: pw.Row(children: [
                pw.Text('${i + 1}. ',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey500)),
                pw.Expanded(
                    child: pw.Text(items[i].productName,
                        style: pw.TextStyle(fontSize: 11, color: PdfColors.white))),
                pw.Text('${items[i].total.round()} $unit (×${items[i].times})',
                    style: pw.TextStyle(fontSize: 11, color: grey)),
              ]),
            ),
            if (i < items.length - 1)
              pw.Divider(color: PdfColors.grey800, thickness: 0.5),
          ],
        ]),
      ),
    ]);
  }

  // ── Skor Gaya Hidup ─────────────────────────────────────────────────────────

  Widget _buildLifestyleScore(WeeklyReport r) {
    final color = r.lifestyleScoreColor;
    final bd = r.lifestyleScoreBreakdown;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular gauge
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: r.lifestyleScore / 100,
                        strokeWidth: 7,
                        backgroundColor: AppColors.cardBorder(context),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${r.lifestyleScore}',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                        Text('/100',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: AppColors.textTertiary(context))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skor Gaya Hidup',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(r.lifestyleScoreLabel,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ),
                    const SizedBox(height: 8),
                    Text('Berdasarkan pola konsumsi & konsistensi diary minggu ini',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textTertiary(context), height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (bd != null) ...[
            const SizedBox(height: 16),
            Divider(color: AppColors.divider(context), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _scoreComponent('Produk\nSehat', bd.gradeScore, 40, color),
                _scoreComponent('Konsistensi\nDiary', bd.diaryScore, 25, color),
                _scoreComponent('Batas\nGula', bd.sugarScore, 20, color),
                _scoreComponent('Batas\nNatrium', bd.sodiumScore, 15, color),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreComponent(String label, int score, int max, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('$score/$max',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 9, color: AppColors.textTertiary(context), height: 1.3)),
        ],
      ),
    );
  }

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
              child: const Icon(Icons.bar_chart_rounded, size: 48, color: Color(0xFF4ECDC4)),
            ),
            const SizedBox(height: 20),
            Text('Belum ada catatan minggu ini',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              'Catat konsumsi lewat "Catat ke Diary Gizi"\nsetelah scan, lalu laporan mingguan terbentuk otomatis',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary(context), height: 1.5),
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
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textQuaternary(context)),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary(context))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4), foregroundColor: Colors.black),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

}
