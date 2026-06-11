import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scan_result.dart';

class NutritionCard extends StatelessWidget {
  final Nutrition nutrition;

  const NutritionCard({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NutritionItem('Kalori', '${nutrition.calories}', 'kcal', nutrition.calories / 2000, const Color(0xFFFF6B6B)),
      _NutritionItem('Gula', '${nutrition.sugarG}', 'g', nutrition.sugarG / 50, const Color(0xFFFFB347)),
      _NutritionItem('Sodium', '${nutrition.sodiumMg}', 'mg', nutrition.sodiumMg / 2300, const Color(0xFF87CEEB)),
      _NutritionItem('Lemak Total', '${nutrition.fatTotalG}', 'g', nutrition.fatTotalG / 65, const Color(0xFFDDA0DD)),
      _NutritionItem('Lemak Jenuh', '${nutrition.fatSaturatedG}', 'g', nutrition.fatSaturatedG / 20, const Color(0xFFE8A0C9)),
      _NutritionItem('Lemak Trans', '${nutrition.fatTransG}', 'g', nutrition.fatTransG / 2, const Color(0xFFCC7A7A)),
      _NutritionItem('Serat', '${nutrition.fiberG}', 'g', nutrition.fiberG / 25, const Color(0xFF98D8C8)),
      _NutritionItem('Protein', '${nutrition.proteinG}', 'g', nutrition.proteinG / 50, const Color(0xFF7EC8E3)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Color(0xFF4ECDC4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informasi Nutrisi',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.map((item) => _buildNutritionRow(item)),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(_NutritionItem item) {
    final clampedRatio = item.ratio.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: item.value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: ' ${item.unit}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: clampedRatio),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: animatedValue,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item.color,
                            item.color.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NutritionItem {
  final String name;
  final String value;
  final String unit;
  final double ratio;
  final Color color;

  _NutritionItem(this.name, this.value, this.unit, num rawRatio, this.color)
      : ratio = rawRatio.toDouble();
}
