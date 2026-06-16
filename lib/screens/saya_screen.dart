import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gamification.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'history_screen.dart';
import 'profile_edit_screen.dart';
import 'family_screen.dart';
import 'quiz_screen.dart';
import 'weekly_report_screen.dart';
import 'chat_screen.dart';
import 'health_risk_screen.dart';

class SayaScreen extends StatefulWidget {
  const SayaScreen({super.key});

  @override
  State<SayaScreen> createState() => _SayaScreenState();
}

class _SayaScreenState extends State<SayaScreen> {
  GamificationStats? _stats;

  @override
  void initState() {
    super.initState();
    if (AuthService().isLoggedIn) _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final s = await ApiService().getGamificationStats();
      if (mounted) setState(() => _stats = s);
    } catch (_) {}
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar?',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('Kamu akan keluar dari akun ini.',
            style: GoogleFonts.inter(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar',
                style: GoogleFonts.inter(
                    color: const Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) await AuthService().logout();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      initialData: AuthService().currentUser,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return _buildLoginGate();
        return _buildPage(user.name, user.email);
      },
    );
  }

  Widget _buildPage(String name, String email) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Profil',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 14),

              _buildUserCard(name, email),
              const SizedBox(height: 14),
              if (_stats != null) _buildStatsCard(_stats!),
              const SizedBox(height: 24),

              _buildLabel('Aktivitas'),
              _buildMenuItem(Icons.history_rounded, 'Riwayat Scan',
                  'Semua produk yang pernah kamu pindai', const Color(0xFF4ECDC4), () {
                final uid = AuthService().currentUser?.id;
                if (uid != null) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => HistoryScreen(uid: uid)));
                }
              }),
              _buildMenuItem(Icons.bar_chart_rounded, 'Laporan Mingguan',
                  'Rata-rata asupan 7 hari & export PDF', const Color(0xFF6BCB77),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WeeklyReportScreen()))),
              _buildMenuItem(Icons.chat_bubble_outline_rounded, 'Asisten Gizi',
                  'Tanya AI soal nutrisi, pola makan & produk yang kamu scan', const Color(0xFF4ECDC4),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()))),

              const SizedBox(height: 24),
              _buildLabel('Kesehatan & Keluarga'),
              _buildMenuItem(Icons.monitor_heart_rounded, 'Prediksi Risiko Kesehatan',
                  'Analisis pola 30 hari — risiko sodium, gula, lemak jenuh', const Color(0xFFFF6B6B),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HealthRiskScreen()))),
              _buildMenuItem(Icons.family_restroom_rounded, 'Anggota Keluarga',
                  'Kelola profil & alergi untuk analisis per anggota', const Color(0xFFFFAD00),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FamilyScreen()))),

              const SizedBox(height: 24),
              _buildLabel('Edukasi'),
              _buildMenuItem(Icons.quiz_outlined, 'Kuis Nutrisi',
                  'Game tanya-jawab seputar gizi & literasi label', const Color(0xFFFF6B6B),
                  () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const QuizScreen()));
                _loadStats();
              }),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String name, String email) {
    return GestureDetector(
      onTap: () async {
        final user = AuthService().currentUser;
        if (user == null) return;
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => ProfileEditScreen(user: user)),
        );
        if (changed == true && mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4ECDC4).withValues(alpha: 0.12),
              const Color(0xFF4ECDC4).withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.35), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4ECDC4)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(email,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 10, color: const Color(0xFF4ECDC4).withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Text('Tap untuk edit profil',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF4ECDC4).withValues(alpha: 0.7))),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 20),
              tooltip: 'Logout',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(GamificationStats s) {
    return GestureDetector(
      onTap: () => _showBadges(s),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            _stat('🔥', '${s.currentStreak}', 'Hari beruntun'),
            _divider(),
            _stat('⭐', '${s.points}', 'Poin'),
            _divider(),
            _stat('🏅', '${s.earnedCount}/${s.badges.length}', 'Badge'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08));

  void _showBadges(GamificationStats s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12121F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pencapaian',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${s.earnedCount} dari ${s.badges.length} badge diraih',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: s.badges.length,
                  itemBuilder: (_, i) => _badgeRow(s.badges[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeRow(AppBadge b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: b.earned
            ? const Color(0xFFFFAD00).withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: b.earned
                ? const Color(0xFFFFAD00).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: b.earned
                  ? const Color(0xFFFFAD00).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: b.earned
                ? Text(b.icon ?? '🏅', style: const TextStyle(fontSize: 22))
                : const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white24),
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
                        color: b.earned ? Colors.white : Colors.white38)),
                Text(b.description,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: b.earned ? Colors.white54 : Colors.white24)),
              ],
            ),
          ),
          if (b.earned)
            const Icon(Icons.check_circle_rounded, color: Color(0xFFFFAD00), size: 18),
        ],
      ),
    );
  }

  Widget _buildLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white30,
              letterSpacing: 1.2)),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginGate() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      size: 52, color: Color(0xFF4ECDC4)),
                ),
                const SizedBox(height: 28),
                Text('Profil',
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                Text(
                  'Login untuk mengakses diary gizi, laporan, profil keluarga, gamifikasi, dan fitur lainnya.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white54, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Masuk / Daftar',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
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
