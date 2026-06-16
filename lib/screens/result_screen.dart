import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scan_result.dart';
import '../models/family_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/nutri_score_badge.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/score_breakdown.dart';
import '../widgets/analogy_card.dart';
import '../widgets/gamification_feedback.dart';

class ResultScreen extends StatefulWidget {
  final ScanResult result;
  final FamilyProfile? forProfile;

  const ResultScreen({super.key, required this.result, this.forProfile});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _loggedToDiary = false;

  @override
  void initState() {
    super.initState();
    // Tampilkan feedback gamifikasi (poin + badge) setelah layar muncul.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GamificationFeedback.show(context, widget.result.gamification);
    });
  }

  Color get _nutriColor {
    try {
      return Color(int.parse(widget.result.nutriScore.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final canLog = AuthService().isLoggedIn && r.id != null;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.scaffold(context),
            expandedHeight: 100,
            floating: false,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary(context), size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text('Hasil Analisis',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 14, color: const Color(0xFF4ECDC4).withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text('${(r.confidence * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4ECDC4))),
                  ],
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProductHeader(),
                const SizedBox(height: 16),

                // Label Detective: klaim menyesatkan
                if (r.misleadingClaims.isNotEmpty) ...[
                  _buildLabelDetective(r.misleadingClaims),
                  const SizedBox(height: 16),
                ],

                // Insight per anggota keluarga (dari backend)
                if (r.familyInsights.isNotEmpty) ...[
                  _buildFamilyInsights(r.familyInsights),
                  const SizedBox(height: 16),
                ],

                NutriScoreBadge(
                  grade: r.nutriScore.grade,
                  label: r.nutriScore.label,
                  colorHex: r.nutriScore.color,
                  finalScore: r.nutriScore.finalScore,
                ),
                const SizedBox(height: 24),

                _buildExplanation(),
                const SizedBox(height: 24),

                // Budget Harian (hanya untuk user login)
                if (r.dailyBudget != null) ...[
                  _buildDailyBudget(r.dailyBudget!),
                  const SizedBox(height: 24),
                ],

                // Komposisi & alergen
                if (r.ingredients != null && !r.ingredients!.isEmpty) ...[
                  _buildIngredients(r.ingredients!),
                  const SizedBox(height: 24),
                ],

                AnalogyCard(analogies: r.analogies),
                const SizedBox(height: 24),

                NutritionCard(nutrition: r.nutrition),
                const SizedBox(height: 24),

                ScoreBreakdownWidget(breakdown: r.scoreBreakdown),
                const SizedBox(height: 24),

                // Alternatif lebih sehat (hanya grade D/E)
                if (r.alternatives.isNotEmpty) ...[
                  _buildAlternatives(r.alternatives),
                  const SizedBox(height: 24),
                ],

                if (r.notes.isNotEmpty) ...[
                  _buildNotes(),
                  const SizedBox(height: 24),
                ],

                if (canLog) ...[
                  _buildLogToDiaryButton(),
                  const SizedBox(height: 12),
                ],

                _buildScanAgainButton(context),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    final r = widget.result;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _nutriColor.withValues(alpha: 0.12),
            _nutriColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _nutriColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _nutriColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_rounded, color: _nutriColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.productName,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                            height: 1.3)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(r.servingSize, AppColors.cardBorder(context), Colors.white60),
                        if (r.category.isNotEmpty)
                          _chip(_capitalize(r.category),
                              const Color(0xFFAD7BFF).withValues(alpha: 0.12),
                              const Color(0xFFAD7BFF)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildFamilyInsights(List<ProfileInsight> insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.family_restroom_rounded,
                    size: 16, color: Color(0xFF4ECDC4)),
              ),
              const SizedBox(width: 10),
              Text('Untuk Keluarga',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map(_buildProfileInsightRow),
        ],
      ),
    );
  }

  Widget _buildProfileInsightRow(ProfileInsight insight) {
    final highlighted = widget.forProfile != null &&
        (insight.profileId == widget.forProfile!.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFF4ECDC4).withValues(alpha: 0.07)
            : AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.3)
              : AppColors.cardBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(insight.hasDanger
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: insight.hasDanger
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF4ECDC4)),
              const SizedBox(width: 8),
              Text(insight.profileName,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            ],
          ),
          if (insight.flags.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 22),
              child: Text('Relatif aman dalam porsi wajar',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary(context))),
            )
          else
            ...insight.flags.map((f) {
              final c = _severityColor(f.severity);
              return Padding(
                padding: const EdgeInsets.only(top: 6, left: 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text(f.message,
                          style: GoogleFonts.inter(fontSize: 12, color: c, height: 1.4)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'danger':
        return const Color(0xFFFF6B6B);
      case 'caution':
        return const Color(0xFFFFAD00);
      default:
        return const Color(0xFF4ECDC4);
    }
  }

  Widget _buildIngredients(IngredientInfo ing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFAD00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.science_outlined,
                    color: Color(0xFFFFAD00), size: 20),
              ),
              const SizedBox(width: 12),
              Text('Komposisi & Aditif',
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 14),

          if (ing.allergens.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dangerous_outlined,
                          size: 15, color: Color(0xFFFF6B6B)),
                      const SizedBox(width: 6),
                      Text('Mengandung Alergen',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF6B6B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ing.allergens
                        .map((a) => _tag(a.label, const Color(0xFFFF6B6B)))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (ing.additives.isNotEmpty) ...[
            Text('Aditif terdeteksi',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ing.additives
                  .map((a) => _tag(a.label, _additiveColor(a.type)))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (ing.warnings.isNotEmpty) ...[
            ...ing.warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 13, color: AppColors.textTertiary(context)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(w,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textSecondary(context), height: 1.4)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 4),
          ],

          if (ing.raw != null && ing.raw!.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 20),
            Text('Daftar komposisi',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context))),
            const SizedBox(height: 4),
            Text(ing.raw!,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary(context), height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Color _additiveColor(String type) {
    switch (type) {
      case 'sweetener':
        return const Color(0xFFAD7BFF);
      case 'msg':
        return const Color(0xFFFFAD00);
      case 'preservative':
        return const Color(0xFF4ECDC4);
      case 'coloring':
        return const Color(0xFFFF8FB1);
      case 'trans_fat':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.white54;
    }
  }

  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF9B59B6), size: 20),
              ),
              const SizedBox(width: 12),
              Text('Penjelasan',
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 14),
          Text(widget.result.explanation,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textBody(context), height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF95A5A6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.note_alt_rounded,
                    color: Color(0xFF95A5A6), size: 20),
              ),
              const SizedBox(width: 12),
              Text('Catatan',
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 14),
          Text(widget.result.notes,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context), height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildLogToDiaryButton() {
    return GestureDetector(
      onTap: _loggedToDiary ? null : _showLogSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _loggedToDiary
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.08)
              : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF4ECDC4).withValues(alpha: _loggedToDiary ? 0.3 : 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_loggedToDiary ? Icons.check_circle_rounded : Icons.add_chart_rounded,
                color: const Color(0xFF4ECDC4), size: 20),
            const SizedBox(width: 10),
            Text(_loggedToDiary ? 'Sudah dicatat ke Diary' : 'Catat ke Diary Gizi',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4ECDC4))),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogSheet() async {
    double servings = 1;
    FamilyProfile? profile;
    List<FamilyProfile> profiles = [];
    try {
      profiles = await ApiService().getFamilyProfiles();
    } catch (_) {}
    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: AppColors.bottomSheet(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textQuaternary(context), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Catat ke Diary',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
              const SizedBox(height: 4),
              Text(widget.result.productName,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))),
              const SizedBox(height: 20),

              Text('Jumlah porsi',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [0.5, 1.0, 1.5, 2.0, 3.0].map((s) {
                  final sel = servings == s;
                  return GestureDetector(
                    onTap: () => setSheet(() => servings = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
                            : AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel
                                ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                                : AppColors.cardBorder(context)),
                      ),
                      child: Text(s == s.toInt() ? '${s.toInt()}' : '$s',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: sel ? const Color(0xFF4ECDC4) : Colors.white60,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Text('Untuk siapa',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _profilePill(ctx, 'Saya', profile == null,
                      () => setSheet(() => profile = null)),
                  ...profiles.map((p) => _profilePill(
                      ctx, p.name, profile?.id == p.id,
                      () => setSheet(() => profile = p))),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Catat Sekarang',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _doLog(servings, profile);
    }
  }

  Widget _profilePill(BuildContext ctx, String name, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
              : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                  : AppColors.cardBorder(context)),
        ),
        child: Text(name,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: selected ? const Color(0xFF4ECDC4) : Colors.white60,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Future<void> _doLog(double servings, FamilyProfile? profile) async {
    try {
      final res = await ApiService().logDiary(
        scanId: widget.result.id,
        servings: servings,
        profileId: profile?.id,
      );
      if (!mounted) return;
      setState(() => _loggedToDiary = true);

      final warnings = res.summary.warnings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            warnings.isNotEmpty ? warnings.first : res.message,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary(context)),
          ),
          backgroundColor: warnings.isNotEmpty
              ? const Color(0xFFE63E11)
              : const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      GamificationFeedback.show(context, res.gamification);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: const Color(0xFFE63E11),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildScanAgainButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.textPrimary(context), size: 22),
            const SizedBox(width: 10),
            Text('Scan Lagi',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split('-')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // ── Label Detective ─────────────────────────────────────────────────────────

  Widget _buildLabelDetective(List<MisleadingClaim> claims) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.policy_rounded,
                    size: 16, color: Color(0xFFFF6B35)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Label Detective',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF6B35))),
                    Text('Klaim pada kemasan yang perlu diperhatikan',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...claims.map((c) => _buildClaimRow(c)),
        ],
      ),
    );
  }

  Widget _buildClaimRow(MisleadingClaim c) {
    final color = c.severity == 'warning'
        ? const Color(0xFFFF6B6B)
        : c.severity == 'caution'
            ? const Color(0xFFFFAD00)
            : const Color(0xFF4ECDC4);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                c.severity == 'warning'
                    ? Icons.error_outline_rounded
                    : c.severity == 'caution'
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text('"${c.claim}"',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(c.issue,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textSecondary(context), height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ── Budget Harian ────────────────────────────────────────────────────────────

  Widget _buildDailyBudget(DailyBudget budget) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_rounded,
                    size: 16, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dampak ke Budget Harian',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context))),
                    Text('Jika kamu makan 1 saji hari ini',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textTertiary(context))),
                  ],
                ),
              ),
            ],
          ),
          if (budget.alerts.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...budget.alerts.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 13, color: Color(0xFFFFAD00)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(a,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFFFFAD00),
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _budgetRow('Gula', budget.sugar, 'g'),
          _budgetRow('Natrium', budget.sodium, 'mg'),
          _budgetRow('Kalori', budget.calories, 'kkal'),
          _budgetRow('Lemak', budget.fatTotal, 'g'),
        ],
      ),
    );
  }

  Widget _budgetRow(String label, DailyBudgetNutrient n, String unit) {
    final pct = n.pctAfter.clamp(0, 100);
    Color barColor;
    if (n.pctAfter >= 100) barColor = const Color(0xFFFF6B6B);
    else if (n.pctAfter >= 80) barColor = const Color(0xFFFFAD00);
    else barColor = const Color(0xFF4ECDC4);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(label,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context))),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: AppColors.cardBorder(context),
                      ),
                      FractionallySizedBox(
                        widthFactor: n.pctBefore / 100,
                        child: Container(
                          height: 6,
                          color: AppColors.textQuaternary(context),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct / 100,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${n.pctAfter}%',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: barColor)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 56, top: 2),
            child: Text(
              '+${n.addedByThis}$unit → total ${n.afterEating}$unit / ${n.limit.toInt()}$unit',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textQuaternary(context)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Alternatif Lebih Sehat ────────────────────────────────────────────────────

  Widget _buildAlternatives(List<AlternativeProduct> alts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E8F4E).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E8F4E).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swap_vert_circle_rounded,
                    size: 16, color: Color(0xFF4ECDC4)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alternatif Lebih Sehat',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context))),
                    Text('Produk serupa dengan NutriScore lebih baik',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textTertiary(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alts.map(_buildAltRow),
        ],
      ),
    );
  }

  Widget _buildAltRow(AlternativeProduct alt) {
    final gradeColor = _gradeColor(alt.nutriScore);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(alt.nutriScore,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: gradeColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alt.name,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (alt.brand != null && alt.brand!.isNotEmpty)
                  Text(alt.brand!,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textTertiary(context))),
              ],
            ),
          ),
          Text('skor ${alt.finalScore}',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textQuaternary(context))),
        ],
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
      default:  return const Color(0xFF888888);
    }
  }
}
