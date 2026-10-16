import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class NutriScoreBadge extends StatelessWidget {
  final String grade;
  final String label;
  final String colorHex;
  final int finalScore;
  final bool animate;
  final String? detectionType;
  final Widget? detectionWidget;

  const NutriScoreBadge({
    super.key,
    required this.grade,
    required this.label,
    required this.colorHex,
    required this.finalScore,
    this.animate = true,
    this.detectionType,
    this.detectionWidget,
  });

  Color get _color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  static const Map<String, Color> gradeColors = {
    'A': Color(0xFF2D8B35),
    'B': Color(0xFF85BB2F),
    'C': Color(0xFFFFCC00),
    'D': Color(0xFFEF8B2C),
    'E': Color(0xFFE63E11),
  };

  @override
  Widget build(BuildContext context) {
    final mainColor = _color;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0.0 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              mainColor.withValues(alpha: 0.15),
              mainColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: mainColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Grade badges row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['A', 'B', 'C', 'D', 'E'].map((g) {
                final isActive = g == grade;
                final gColor = gradeColors[g] ?? Colors.grey;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 56 : 40,
                  height: isActive ? 56 : 40,
                  decoration: BoxDecoration(
                    color: isActive ? gColor : gColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isActive ? 16 : 10),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: gColor.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      g,
                      style: GoogleFonts.poppins(
                        fontSize: isActive ? 24 : 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : gColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: mainColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Skor: $finalScore',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
            if (detectionWidget != null ||
                (detectionType != null && detectionType!.isNotEmpty)) ...[
              const SizedBox(height: 14),
              Divider(
                color: mainColor.withValues(alpha: 0.25),
                height: 1,
                thickness: 0.8,
              ),
              const SizedBox(height: 12),
              detectionWidget ?? _buildDetectionBadge(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionBadge() {
    final isMakanan = detectionType == 'makanan_langsung' || detectionType == 'food';
    final isKemasanDepan = detectionType == 'kemasan_depan' || detectionType == 'label-front';
    final icon = isMakanan
        ? Icons.fastfood_rounded
        : isKemasanDepan
            ? Icons.photo_rounded
            : Icons.label_rounded;
    final text = isMakanan
        ? 'Terdeteksi: Foto Makanan'
        : isKemasanDepan
            ? 'Terdeteksi: Kemasan Depan (Estimasi)'
            : 'Terdeteksi: Label Kemasan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF4ECDC4).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xFF4ECDC4),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4ECDC4),
            ),
          ),
        ],
      ),
    );
  }
}
