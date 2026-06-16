import 'dart:io';
import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
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
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
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
        ...result.products.map((p) => _buildProductCard(p)),
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
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
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
                                fontSize: 12, color: Colors.white70, height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(CompareProduct p) {
    final gradeColor = _gradeColor(p.nutriScore);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.isRecommended
            ? const Color(0xFF4ECDC4).withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.isRecommended
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          width: p.isRecommended ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              p.nutriScore.isNotEmpty ? p.nutriScore : '?',
              style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: gradeColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
                Text(
                  'Skor: ${p.finalScore} (makin rendah makin sehat)',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Perbandingan Nutrisi',
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
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
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
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
                  color: isBest ? const Color(0xFF4ECDC4) : Colors.white70,
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
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
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
