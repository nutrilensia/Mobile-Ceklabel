import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/health_risk.dart';
import '../services/api_service.dart';

class HealthRiskScreen extends StatefulWidget {
  const HealthRiskScreen({super.key});

  @override
  State<HealthRiskScreen> createState() => _HealthRiskScreenState();
}

class _HealthRiskScreenState extends State<HealthRiskScreen> {
  HealthRiskReport? _report;
  bool _loading = true;
  String? _error;

  // Colors now from AppColors
  
  static const _teal = Color(0xFF4ECDC4);
  // Surface/bg colors now from AppColors

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final report = await ApiService().getHealthRisk();
      if (mounted) setState(() { _report = report; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.bottomSheet(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Prediksi Risiko Kesehatan',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary(context)),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textQuaternary(context)),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary(context))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.black),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final r = _report!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(r),
        const SizedBox(height: 16),
        if (r.daysWithData < 3)
          _buildEmptyState(r)
        else ...[
          if (r.risks.isEmpty) _buildAllGood(r),
          ...r.risks.map((risk) => _buildRiskCard(risk)),
          if (r.positives.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPositives(r.positives),
          ],
          const SizedBox(height: 8),
          _buildDisclaimer(),
        ],
      ],
    );
  }

  Widget _buildHeader(HealthRiskReport r) {
    final color = _overallColor(r.overallRiskLevel);
    final icon = _overallIcon(r.overallRiskLevel);
    final label = _overallLabel(r.overallRiskLevel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bottomSheet(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Risiko Keseluruhan',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary(context))),
                    Text(label,
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${r.daysWithData} hari data',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(r.summary, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody(context), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(HealthRiskReport r) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bottomSheet(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.textQuaternary(context)),
          const SizedBox(height: 12),
          Text(r.summary, textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary(context), height: 1.5)),
          const SizedBox(height: 16),
          Text('Catat konsumsi di menu Diary setelah scan produk.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary(context))),
        ],
      ),
    );
  }

  Widget _buildAllGood(HealthRiskReport r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E8F4E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E8F4E).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF1E8F4E), size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pola Makan Sehat!',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E8F4E))),
                Text('Semua nutrisi dalam batas aman. Pertahankan!',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(HealthRisk risk) {
    final color = _riskColor(risk.riskLevel);
    final trendIcon = _trendIcon(risk.trend);
    final trendColor = risk.trend == 'increasing' ? const Color(0xFFE63312) : risk.trend == 'decreasing' ? const Color(0xFF1E8F4E) : Colors.white38;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.bottomSheet(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(risk.label,
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(trendIcon, size: 13, color: trendColor),
                          const SizedBox(width: 4),
                          Text(_trendLabel(risk.trend),
                              style: GoogleFonts.inter(fontSize: 11, color: trendColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildPctBadge(risk.avgPct, color),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildProgressBar(risk.avgPct, color),
          ),
          const SizedBox(height: 12),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.warning_amber_rounded, risk.consequence, color.withValues(alpha: 0.8)),
                const SizedBox(height: 8),
                _infoRow(Icons.lightbulb_outline_rounded, risk.recommendation, _teal.withValues(alpha: 0.8)),
                const SizedBox(height: 8),
                _infoRow(Icons.article_outlined, risk.reference, Colors.white30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPctBadge(int pct, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$pct% AKG',
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildProgressBar(int pct, Color color) {
    final fraction = (pct / 200).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(height: 6, color: AppColors.cardBorder(context)),
          // 100% marker
          Positioned(
            left: MediaQuery.of(context).size.width * 0.5 - 48,
            child: Container(
              height: 6, width: 1.5,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildPositives(List<String> positives) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E8F4E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E8F4E).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined, color: Color(0xFF1E8F4E), size: 16),
              const SizedBox(width: 8),
              Text('Yang Sudah Baik',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E8F4E))),
            ],
          ),
          const SizedBox(height: 10),
          ...positives.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•', style: TextStyle(color: Color(0xFF1E8F4E), fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(p, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBg(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textQuaternary(context)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Analisis ini bersifat informatif berdasarkan data yang dicatat di diary. Konsultasikan dengan dokter atau ahli gizi untuk diagnosis dan saran medis.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textQuaternary(context), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'high': return const Color(0xFFE63312);
      case 'moderate': return const Color(0xFFEF7D00);
      default: return const Color(0xFFFFAD00);
    }
  }

  Color _overallColor(String level) {
    switch (level) {
      case 'high': return const Color(0xFFE63312);
      case 'moderate': return const Color(0xFFEF7D00);
      default: return const Color(0xFF1E8F4E);
    }
  }

  IconData _overallIcon(String level) {
    switch (level) {
      case 'high': return Icons.warning_rounded;
      case 'moderate': return Icons.info_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  String _overallLabel(String level) {
    switch (level) {
      case 'high': return 'Risiko Tinggi';
      case 'moderate': return 'Risiko Sedang';
      default: return 'Risiko Rendah';
    }
  }

  IconData _trendIcon(String trend) {
    switch (trend) {
      case 'increasing': return Icons.trending_up_rounded;
      case 'decreasing': return Icons.trending_down_rounded;
      default: return Icons.trending_flat_rounded;
    }
  }

  String _trendLabel(String trend) {
    switch (trend) {
      case 'increasing': return 'Cenderung naik';
      case 'decreasing': return 'Cenderung turun';
      default: return 'Stabil';
    }
  }
}
