import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NutriScoreBadge extends StatelessWidget {
  final String grade;
  final String label;
  final String colorHex;
  final int finalScore;
  final bool animate;

  const NutriScoreBadge({
    super.key,
    required this.grade,
    required this.label,
    required this.colorHex,
    required this.finalScore,
    this.animate = true,
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
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
