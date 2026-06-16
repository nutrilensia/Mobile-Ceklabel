import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gamification.dart';

/// Helper untuk menampilkan feedback gamifikasi (poin + badge baru)
/// setelah aksi scan / log diary / quiz.
class GamificationFeedback {
  /// Tampilkan snackbar poin lalu dialog badge baru (jika ada).
  static void show(BuildContext context, GamificationUpdate? gami) {
    if (gami == null) return;

    if (gami.pointsEarned > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFAD00), size: 18),
              const SizedBox(width: 8),
              Text(
                '+${gami.pointsEarned} poin'
                '${gami.currentStreak > 1 ? '  🔥 ${gami.currentStreak} hari beruntun' : ''}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (gami.hasNewBadges) {
      // Tunda sedikit agar tidak bentrok dengan transisi layar.
      Future.delayed(const Duration(milliseconds: 600), () {
        if (context.mounted) showBadgeDialog(context, gami.newBadges);
      });
    }
  }

  static void showBadgeDialog(BuildContext context, List<BadgeInfo> badges) {
    if (badges.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF0D2B2B)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFAD00).withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badges.length > 1 ? '🎉 ${badges.length} Badge Baru!' : '🎉 Badge Baru!',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                ...badges.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFAD00).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(b.icon, style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.name,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                                Text(b.description,
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: Colors.white54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFAD00),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Keren!',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
