import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/diary_day.dart';
import '../models/family_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _selectedDate = DateTime.now();
  FamilyProfile? _profile;
  List<FamilyProfile> _profiles = [];
  Future<DiaryDay>? _future;

  @override
  void initState() {
    super.initState();
    if (AuthService().isLoggedIn) {
      _loadProfiles();
      _reload();
    }
  }

  String get _dateStr {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadProfiles() async {
    try {
      final p = await ApiService().getFamilyProfiles();
      if (mounted) setState(() => _profiles = p);
    } catch (_) {}
  }

  void _reload() {
    setState(() {
      _future = ApiService().getDiary(date: _dateStr, profileId: _profile?.id);
    });
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _changeDay(int delta) {
    final next = _selectedDate.add(Duration(days: delta));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
    _reload();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4ECDC4), surface: Color(0xFF1A1A2E)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        foregroundColor: AppColors.appBarForeground(context),
        title: Text('Diary Gizi',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17)),
        elevation: 0,
        actions: [
          if (AuthService().isLoggedIn)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reload,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: AuthService().isLoggedIn ? _buildBody() : _buildLoginPrompt(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (_profiles.isNotEmpty) _buildProfileSelector(),
        _buildDateSelector(),
        const SizedBox(height: 4),
        Expanded(
          child: FutureBuilder<DiaryDay>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4ECDC4)));
              }
              if (snap.hasError) return _buildError(snap.error.toString());
              final day = snap.data;
              if (day == null) return const SizedBox();
              return _buildDayView(day);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSelector() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        children: [
          _profileChip('Saya', _profile == null, () {
            setState(() => _profile = null);
            _reload();
          }),
          ..._profiles.map((p) => _profileChip(p.name, _profile?.id == p.id, () {
                setState(() => _profile = p);
                _reload();
              })),
        ],
      ),
    );
  }

  Widget _profileChip(String name, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
              : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                  : AppColors.cardBorder(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.person_rounded : Icons.person_outline_rounded,
                size: 14,
                color: selected ? const Color(0xFF4ECDC4) : Colors.white38),
            const SizedBox(width: 6),
            Text(name,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: selected ? const Color(0xFF4ECDC4) : Colors.white60,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final formatted =
        '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary(context)),
            onPressed: () => _changeDay(-1),
            splashRadius: 20,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Column(
                children: [
                  Text(_isToday ? 'Hari Ini' : 'Tanggal Dipilih',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context))),
                  const SizedBox(height: 2),
                  Text(formatted,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context))),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded,
                color: _isToday ? Colors.white12 : Colors.white54),
            onPressed: _isToday ? null : () => _changeDay(1),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDayView(DiaryDay day) {
    return RefreshIndicator(
      color: const Color(0xFF4ECDC4),
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _buildIntakeSummary(day),
          if (day.warnings.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...day.warnings.map(_buildWarningBanner),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.restaurant_rounded, size: 16, color: Color(0xFF4ECDC4)),
              const SizedBox(width: 8),
              Text('${day.entryCount} item dikonsumsi',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 12),
          if (day.entries.isEmpty)
            _buildEmptyEntries()
          else
            ...day.entries.map(_buildEntryCard),
        ],
      ),
    );
  }

  Widget _buildIntakeSummary(DiaryDay day) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2B2B), Color(0xFF12121F)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFF4ECDC4)),
              const SizedBox(width: 8),
              Text('Asupan ${day.profileName}',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 16),
          _intakeRow('Kalori', day.calories, 'kkal', const Color(0xFFFF6B6B)),
          const SizedBox(height: 14),
          _intakeRow('Gula', day.sugar, 'g', const Color(0xFFFFAD00)),
          const SizedBox(height: 14),
          _intakeRow('Natrium', day.sodium, 'mg', const Color(0xFF4ECDC4)),
          const SizedBox(height: 14),
          _intakeRow('Lemak jenuh', day.fatSaturated, 'g', const Color(0xFFAD7BFF)),
          const SizedBox(height: 8),
          Text('Batas berdasarkan AKG BPOM untuk profil ini',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textQuaternary(context))),
        ],
      ),
    );
  }

  Widget _intakeRow(String label, IntakeStatus? s, String unit, Color color) {
    final consumed = s?.consumed ?? 0;
    final limit = s?.limit ?? 0;
    final ratio = (s?.ratio ?? 0).clamp(0.0, 1.0);
    final pct = s?.percentage ?? 0;
    final over = s?.isOver ?? false;
    final c = over ? const Color(0xFFFF6B6B) : color;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody(context))),
            Row(
              children: [
                if (over)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 12, color: Color(0xFFFF6B6B)),
                  ),
                Text('${consumed.round()} / ${limit.round()} $unit',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: over ? const Color(0xFFFF6B6B) : Colors.white54,
                        fontWeight: over ? FontWeight.w600 : FontWeight.normal)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: AppColors.cardBorder(context),
                  valueColor: AlwaysStoppedAnimation(c),
                  minHeight: 7,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text('$pct%',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: c, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWarningBanner(String warning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFFF6B6B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(warning,
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFFF6B6B), height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntryItem item) {
    Color gradeColor;
    switch (item.nutriScore.toUpperCase()) {
      case 'A': gradeColor = const Color(0xFF1E8F4E); break;
      case 'B': gradeColor = const Color(0xFF6DB33F); break;
      case 'C': gradeColor = const Color(0xFFFFAD00); break;
      case 'D': gradeColor = const Color(0xFFEF7D00); break;
      case 'E': gradeColor = const Color(0xFFE63312); break;
      default: gradeColor = Colors.grey;
    }
    final time =
        '${item.consumedAt.hour.toString().padLeft(2, '0')}:${item.consumedAt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B)),
      ),
      confirmDismiss: (_) => _confirmDelete(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: gradeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(item.nutriScore.isNotEmpty ? item.nutriScore : '?',
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.bold, color: gradeColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${item.servings == item.servings.toInt() ? item.servings.toInt() : item.servings} porsi • '
                    '${item.totalCalories.round()} kkal • Gula ${item.totalSugar.round()}g',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(time, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textQuaternary(context))),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(DiaryEntryItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Hapus dari diary?',
            style: GoogleFonts.poppins(color: AppColors.textPrimary(context), fontSize: 16)),
        content: Text('${item.productName} akan dihapus dari catatan hari ini.',
            style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: AppColors.textSecondary(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService().deleteDiaryEntry(item.id);
        _reload();
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFFF6B6B)),
          );
        }
      }
    }
    return false;
  }

  Widget _buildEmptyEntries() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.no_meals_rounded, size: 40, color: AppColors.textQuaternary(context)),
          const SizedBox(height: 12),
          Text(_isToday ? 'Belum ada yang dicatat hari ini' : 'Tidak ada catatan',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
          const SizedBox(height: 6),
          Text(
            'Scan produk lalu tekan "Catat ke Diary Gizi"\nuntuk memantau asupan harian',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textQuaternary(context), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.textQuaternary(context)),
            const SizedBox(height: 16),
            Text('Masuk untuk melihat Diary',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              'Catat konsumsi harian dan pantau asupan\ngula, natrium, & kalori vs batas AKG',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary(context), height: 1.5),
            ),
          ],
        ),
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
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textQuaternary(context)),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary(context))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _reload,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4), foregroundColor: Colors.black),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
