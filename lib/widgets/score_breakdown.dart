import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/scan_result.dart';

class ScoreBreakdownWidget extends StatelessWidget {
  final ScoreBreakdown breakdown;

  const ScoreBreakdownWidget({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorder(context),
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
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Rincian Skor',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Negative points section
          _buildSectionHeader('Poin Negatif', const Color(0xFFFF6B6B)),
          const SizedBox(height: 10),
          _buildScoreRow(context, 'Kalori', breakdown.calories, const Color(0xFFFF6B6B)),
          _buildScoreRow(context, 'Gula', breakdown.sugar, const Color(0xFFFFB347)),
          _buildScoreRow(context, 'Sodium', breakdown.sodium, const Color(0xFF87CEEB)),
          _buildScoreRow(context, 'Lemak Jenuh', breakdown.saturatedFat, const Color(0xFFDDA0DD)),
          _buildScoreRow(context, 'Lemak Trans', breakdown.transFat, const Color(0xFFCC7A7A)),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Negatif',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6B6B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${breakdown.totalNegativePoints}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.divider(context), height: 24),

          // Positive points section
          _buildSectionHeader('Poin Positif', const Color(0xFF4ECDC4)),
          const SizedBox(height: 10),
          _buildScoreRow(context, 'Serat', breakdown.fiber, const Color(0xFF98D8C8)),
          _buildScoreRow(context, 'Protein', breakdown.protein, const Color(0xFF7EC8E3)),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Positif',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4ECDC4),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${breakdown.totalPositivePoints}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4ECDC4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.divider(context), height: 24),

          // Final score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cardBorder(context),
                  AppColors.cardBg(context),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Skor Akhir',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  '${breakdown.totalNegativePoints} - ${breakdown.totalPositivePoints} = ${breakdown.finalScore}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4ECDC4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color.withValues(alpha: 0.8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildScoreRow(BuildContext context, String name, ScoreDetail detail, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${detail.value}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: detail.points > 0
                  ? color.withValues(alpha: 0.2)
                  : AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${detail.points}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: detail.points > 0 ? color : Colors.white30,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
