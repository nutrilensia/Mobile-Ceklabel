import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/history_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _selectedDate = DateTime.now();
  late Future<List<HistoryItem>> _future;

  static const double _calTarget = 2000;
  static const double _sugarTarget = 50;
  static const double _sodiumTarget = 2000;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _future = ApiService().getHistory(limit: 200);
    });
  }

  List<HistoryItem> _filterByDate(List<HistoryItem> all) {
    return all.where((item) =>
      item.scannedAt.year == _selectedDate.year &&
      item.scannedAt.month == _selectedDate.month &&
      item.scannedAt.day == _selectedDate.day
    ).toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
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
            primary: Color(0xFF4ECDC4),
            surface: Color(0xFF1A1A2E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        title: Text(
          'Diary Gizi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 4),
          Expanded(
            child: AuthService().isLoggedIn
                ? _buildContent()
                : _buildLoginPrompt(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final formatted =
        '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
            onPressed: () => _changeDay(-1),
            splashRadius: 20,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Column(
                children: [
                  Text(
                    _isToday ? 'Hari Ini' : 'Tanggal Dipilih',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatted,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _isToday ? Colors.white12 : Colors.white54,
            ),
            onPressed: _isToday ? null : () => _changeDay(1),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<HistoryItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4ECDC4)));
        }
        if (snap.hasError) {
          return _buildError(snap.error.toString());
        }
        final dayItems = _filterByDate(snap.data ?? []);
        return dayItems.isEmpty ? _buildEmpty() : _buildDayView(dayItems);
      },
    );
  }

  Widget _buildDayView(List<HistoryItem> items) {
    final totalCal = items.fold(0.0, (s, i) => s + i.calories);
    final totalSugar = items.fold(0.0, (s, i) => s + i.sugarG);
    final totalSodium = items.fold(0.0, (s, i) => s + i.sodiumMg);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildNutritionSummary(totalCal, totalSugar, totalSodium),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.fastfood_rounded, size: 16, color: Color(0xFF4ECDC4)),
            const SizedBox(width: 8),
            Text(
              '${items.length} produk dipindai',
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(_buildItemCard),
      ],
    );
  }

  Widget _buildNutritionSummary(double cal, double sugar, double sodium) {
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
              Text(
                'Ringkasan Nutrisi',
                style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNutrientRow('Kalori', cal, _calTarget, 'kkal', const Color(0xFFFF6B6B)),
          const SizedBox(height: 14),
          _buildNutrientRow('Gula', sugar, _sugarTarget, 'g', const Color(0xFFFFAD00)),
          const SizedBox(height: 14),
          _buildNutrientRow('Sodium', sodium, _sodiumTarget, 'mg', const Color(0xFF4ECDC4)),
          const SizedBox(height: 8),
          Text(
            'Berdasarkan kebutuhan harian dewasa (AKG)',
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(
      String label, double value, double target, String unit, Color color) {
    final ratio = (value / target).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    final isOver = ratio >= 1.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
            Row(
              children: [
                if (isOver)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 12, color: Color(0xFFFF6B6B)),
                  ),
                Text(
                  '${value.round()} / ${target.round()} $unit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isOver ? const Color(0xFFFF6B6B) : Colors.white54,
                    fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(
                    isOver ? const Color(0xFFFF6B6B) : color,
                  ),
                  minHeight: 7,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(
                '$pct%',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isOver ? const Color(0xFFFF6B6B) : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(HistoryItem item) {
    Color gradeColor;
    try {
      gradeColor =
          Color(int.parse(item.gradeColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      gradeColor = Colors.grey;
    }
    final timeStr =
        '${item.scannedAt.hour.toString().padLeft(2, '0')}:${item.scannedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              item.grade.isNotEmpty ? item.grade : '?',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: gradeColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _nutritionLabel(item),
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  String _nutritionLabel(HistoryItem item) {
    final parts = <String>[];
    if (item.calories > 0) parts.add('${item.calories.round()} kkal');
    if (item.sugarG > 0) parts.add('Gula ${item.sugarG.round()}g');
    if (item.sodiumMg > 0) parts.add('Na ${item.sodiumMg.round()}mg');
    return parts.isEmpty ? 'Data nutrisi tidak tersedia' : parts.join(' • ');
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.no_food_rounded,
                  size: 48, color: Color(0xFF4ECDC4)),
            ),
            const SizedBox(height: 20),
            Text(
              _isToday ? 'Belum ada scan hari ini' : 'Tidak ada scan di tanggal ini',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isToday
                  ? 'Scan produk makanan dan hasilnya\notomatis masuk ke diary harian ini'
                  : 'Semua produk yang kamu scan di\ntanggal ini akan tampil di sini',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white38, height: 1.5),
            ),
          ],
        ),
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
            const Icon(Icons.lock_outline_rounded,
                size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Masuk untuk melihat Diary',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diary gizi otomatis mencatat semua\nproduk yang kamu scan setiap hari',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white38, height: 1.5),
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
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.black,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
