import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scan_result.dart';

class AnalogyCard extends StatelessWidget {
  final Analogies analogies;

  const AnalogyCard({super.key, required this.analogies});

  @override
  Widget build(BuildContext context) {
    final items = [
      _AnalogyItem(
        icon: Icons.cake_rounded,
        title: 'Gula',
        description: analogies.sugar,
        color: const Color(0xFFFFB347),
        bgGradient: [const Color(0xFFFFB347), const Color(0xFFFF6B6B)],
      ),
      _AnalogyItem(
        icon: Icons.grain_rounded,
        title: 'Sodium',
        description: analogies.sodium,
        color: const Color(0xFF87CEEB),
        bgGradient: [const Color(0xFF87CEEB), const Color(0xFF5B9BD5)],
      ),
      _AnalogyItem(
        icon: Icons.local_fire_department_rounded,
        title: 'Kalori',
        description: analogies.calories,
        color: const Color(0xFFFF6B6B),
        bgGradient: [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFFFB347),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Analogi Mudah Dipahami',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 200)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.bgGradient[0].withValues(alpha: 0.12),
                    item.bgGradient[1].withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item.color.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textBody(context),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AnalogyItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<Color> bgGradient;

  _AnalogyItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.bgGradient,
  });
}
