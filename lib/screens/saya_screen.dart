import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
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
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) {
      _lastUserId = user.id;
      _loadStats();
    }
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
        backgroundColor: AppColors.dialogBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar?',
            style: GoogleFonts.poppins(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600)),
        content: Text('Kamu akan keluar dari akun ini.',
            style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
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
        if (user == null) {
          // User logged out — clear cached stats
          if (_lastUserId != null) {
            _lastUserId = null;
            _stats = null;
          }
          return _buildLoginGate();
        }
        // New account logged in — reload stats
        if (user.id != _lastUserId) {
          _lastUserId = user.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _stats = null);
              _loadStats();
            }
          });
        }
        return _buildPage(user.name, user.email);
      },
    );
  }

  Widget _buildPage(String name, String email) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Profil',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
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

              const SizedBox(height: 24),
              _buildLabel('Pengaturan'),
              _buildThemeSelector(),

              const SizedBox(height: 16),
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
                          fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(email,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
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
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder(context)),
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
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary(context))),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: AppColors.cardBorder(context));

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
          decoration: BoxDecoration(
            color: AppColors.bottomSheet(context),
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
                      color: AppColors.textQuaternary(context), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Pencapaian',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
              Text('${s.earnedCount} dari ${s.badges.length} badge diraih',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary(context))),
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
            : AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: b.earned
                ? const Color(0xFFFFAD00).withValues(alpha: 0.25)
                : AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: b.earned
                  ? const Color(0xFFFFAD00).withValues(alpha: 0.15)
                  : AppColors.cardBg(context),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: b.earned
                ? Text(b.icon ?? '🏅', style: TextStyle(fontSize: 22))
                : Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textQuaternary(context)),
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
                        color: b.earned ? AppColors.textPrimary(context) : AppColors.textQuaternary(context))),
                Text(b.description,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: b.earned ? AppColors.textSecondary(context) : AppColors.textQuaternary(context))),
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
              color: AppColors.textQuaternary(context),
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
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder(context)),
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
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textQuaternary(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginGate() {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
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
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                const SizedBox(height: 10),
                Text(
                  'Login untuk mengakses diary gizi, laporan, profil keluarga, gamifikasi, dan fitur lainnya.',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary(context), height: 1.5),
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

  Widget _buildThemeSelector() {
    final themeProvider = context.watch<ThemeProvider>();
    final mode = themeProvider.mode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_rounded,
                    color: Color(0xFF9B59B6), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema Aplikasi',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context))),
                    Text('Pilih tampilan yang kamu suka',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputFill(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _themeOption(
                    Icons.phone_android_rounded, 'Sistem', ThemeMode.system,
                    mode == ThemeMode.system, themeProvider),
                _themeOption(
                    Icons.light_mode_rounded, 'Terang', ThemeMode.light,
                    mode == ThemeMode.light, themeProvider),
                _themeOption(
                    Icons.dark_mode_rounded, 'Gelap', ThemeMode.dark,
                    mode == ThemeMode.dark, themeProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(IconData icon, String label, ThemeMode targetMode,
      bool isActive, ThemeProvider provider) {
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setMode(targetMode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4ECDC4).withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: isActive
                      ? const Color(0xFF4ECDC4)
                      : AppColors.textTertiary(context)),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? const Color(0xFF4ECDC4)
                        : AppColors.textTertiary(context),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
