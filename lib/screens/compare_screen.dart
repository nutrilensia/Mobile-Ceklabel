import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/grade_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CompareScreen extends StatefulWidget {
  /// Bandingkan produk dari database/riwayat.
  final List<CompareItem>? items;

  /// Atau bandingkan langsung dari 2-3 foto label.
  final List<File>? photos;

  const CompareScreen({super.key, this.items, this.photos});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late Future<CompareResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _run();
  }

  Future<CompareResult> _run() {
    if (widget.photos != null) {
      return ApiService().compareByPhotos(widget.photos!);
    }
    return ApiService().compareProducts(widget.items ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        foregroundColor: AppColors.appBarForeground(context),
        title: Text(
          'Bandingkan Produk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<CompareResult>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF4ECDC4)),
                  const SizedBox(height: 16),
                  Text(
                    'Menganalisis produk...',
                    style: GoogleFonts.inter(color: AppColors.textSecondary(context), fontSize: 14),
                  ),
                ],
              ),
            );
          }
          if (snap.hasError) {
            return _buildError(snap.error.toString());
          }
          return _buildResult(snap.data!);
        },
      ),
    );
  }

  Widget _buildResult(CompareResult result) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (result.recommendedName != null)
          _buildRecommendationCard(result),
        const SizedBox(height: 16),
        ...result.products.asMap().entries.map(
          (e) => _buildProductCard(e.value, index: e.key),
        ),
        const SizedBox(height: 16),
        _buildNutritionTable(result.products),
      ],
    );
  }

  Widget _buildRecommendationCard(CompareResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF4ECDC4).withValues(alpha: 0.12),
          const Color(0xFF4ECDC4).withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart_checkout_rounded,
                  color: Color(0xFF4ECDC4), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pilih: ${result.recommendedName}',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4ECDC4)),
                ),
              ),
            ],
          ),
          if (result.personalized) ...[
            const SizedBox(height: 4),
            Text('Disesuaikan dengan profil kesehatanmu',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context))),
          ],
          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...result.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 14, color: Color(0xFF4ECDC4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textBody(context), height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(CompareProduct p, {required int index}) {
    final col = gradeColor(p.nutriScore);
    final label = ['A', 'B', 'C'][index < 3 ? index : 0];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.isRecommended
            ? const Color(0xFF4ECDC4).withValues(alpha: 0.06)
            : AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.isRecommended
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.3)
              : AppColors.cardBorder(context),
          width: p.isRecommended ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Produk A / B / C badge
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: col.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              p.nutriScore.isNotEmpty ? p.nutriScore : '?',
              style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: col,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produk $label',
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  p.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Skor: ${p.finalScore} (makin rendah makin sehat)',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context)),
                ),
              ],
            ),
          ),
          if (p.isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
              ),
              child: Text(
                'Terbaik',
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: const Color(0xFF4ECDC4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionTable(List<CompareProduct> products) {
    if (products.isEmpty) return const SizedBox();
    const nutrients = [
      ('calories', 'Kalori', 'kkal'),
      ('fatTotalG', 'Lemak', 'g'),
      ('sugarG', 'Gula', 'g'),
      ('sodiumMg', 'Sodium', 'mg'),
      ('proteinG', 'Protein', 'g'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Perbandingan Nutrisi',
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context),
              ),
            ),
          ),
          Divider(color: AppColors.divider(context), height: 1),
          // Column headers: label | Produk A | Produk B | Produk C
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                const SizedBox(width: 70),
                ...List.generate(products.length, (i) {
                  final letters = ['A', 'B', 'C'];
                  return Expanded(
                    child: Text(
                      'Produk ${letters[i]}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Divider(color: AppColors.divider(context), height: 1),
          ...nutrients.map(
            (n) => _buildNutrientRow(n.$1, n.$2, n.$3, products),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(
    String key, String label, String unit, List<CompareProduct> products) {
    final values = products.map((p) => (p.nutrition[key] ?? 0) as num).toList();
    final minVal = values.fold(values.first, (a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBg(context))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
          ),
          ...values.asMap().entries.map((e) {
            final val = e.value;
            final isBest = val == minVal && label != 'Protein';
            return Expanded(
              child: Text(
                '${val.round()} $unit',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isBest ? FontWeight.w600 : FontWeight.normal,
                  color: isBest ? const Color(0xFF4ECDC4) : AppColors.textBody(context),
                ),
              ),
            );
          }),
        ],
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
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {
                _future = _run();
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4), foregroundColor: Colors.black,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

}
