import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'diary_screen.dart';
import 'explore_screen.dart';
import 'profile_edit_screen.dart';
import 'family_screen.dart';
import 'quiz_screen.dart';
import 'weekly_report_screen.dart';

class SayaScreen extends StatefulWidget {
  const SayaScreen({super.key});

  @override
  State<SayaScreen> createState() => _SayaScreenState();
}

class _SayaScreenState extends State<SayaScreen> {
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('Kamu akan keluar dari akun ini.',
            style: GoogleFonts.inter(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar',
                style: GoogleFonts.inter(
                    color: const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w600)),
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
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
                  )),
              const SizedBox(height: 14),

              _buildUserCard(name, email),
              const SizedBox(height: 24),

              _buildLabel('Fitur Utama'),
              _buildMenuItem(Icons.book_outlined, 'Diary Gizi',
                  'Catat & pantau asupan gizi harianmu', const Color(0xFF4ECDC4),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DiaryScreen()))),
              _buildMenuItem(Icons.explore_outlined, 'Jelajah Produk',
                  'Cari & bandingkan produk dari database komunitas', const Color(0xFFAD7BFF),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ExploreScreen()))),
              _buildMenuItem(Icons.bar_chart_rounded, 'Laporan Mingguan',
                  'Analisis rata-rata nutrisi 7 hari terakhir', const Color(0xFF6BCB77),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WeeklyReportScreen()))),

              const SizedBox(height: 24),
              _buildLabel('Kesehatan & Keluarga'),
              _buildMenuItem(Icons.family_restroom_rounded, 'Anggota Keluarga',
                  'Kelola profil & alergi untuk analisis per anggota', const Color(0xFFFFAD00),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FamilyScreen()))),

              const SizedBox(height: 24),
              _buildLabel('Edukasi'),
              _buildMenuItem(Icons.quiz_outlined, 'Kuis Nutrisi',
                  'Game tanya-jawab seputar gizi & kesehatan pangan', const Color(0xFFFF6B6B),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const QuizScreen()))),

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
          border: Border.all(
              color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.35),
                    width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: const Color(0xFF4ECDC4),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(email,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white54),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 10,
                          color: const Color(0xFF4ECDC4).withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Text('Tap untuk edit profil',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF4ECDC4).withValues(alpha: 0.7),
                          )),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded,
                  color: Color(0xFFFF6B6B), size: 20),
              tooltip: 'Logout',
              style: IconButton.styleFrom(
                backgroundColor:
                    const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: Colors.white30, letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.07)),
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
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.white38),
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
                    border: Border.all(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      size: 52, color: Color(0xFF4ECDC4)),
                ),
                const SizedBox(height: 28),
                Text('Profil',
                    style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                const SizedBox(height: 10),
                Text(
                  'Login untuk mengakses diary gizi, jelajah produk, profil kesehatan, dan fitur lainnya.',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: Colors.white54, height: 1.5),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Masuk / Daftar',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 15)),
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
