import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/history_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String uid;
  const HistoryScreen({super.key, required this.uid});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final future = ApiService().getHistory();
    setState(() { _future = future; });
  }

  Future<void> _openDetail(HistoryItem item) async {
    try {
      final result = await ApiService().getHistoryDetail(item.id);
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, b) => ResultScreen(result: result),
          transitionsBuilder: (_, animation, a, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1), end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: const Color(0xFFE63E11),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _deleteItem(HistoryItem item) async {
    try {
      await ApiService().deleteHistoryScan(item.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menghapus: $e', style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: const Color(0xFFE63E11),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBg(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar?', style: GoogleFonts.poppins(color: AppColors.dialogText(ctx), fontWeight: FontWeight.w600)),
        content: Text('Kamu akan keluar dari akun ini.', style: GoogleFonts.inter(color: AppColors.textSecondary(ctx))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary(ctx))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar', style: GoogleFonts.inter(color: const Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) await AuthService().logout();
  }

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A': return const Color(0xFF2ECC40);
      case 'B': return const Color(0xFF85C93A);
      case 'C': return const Color(0xFFFDCB6E);
      case 'D': return const Color(0xFFFF9F43);
      case 'E': return const Color(0xFFFF6B6B);
      default: return Colors.grey;
    }
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = today.difference(dtDay).inDays;

    if (dayDiff == 0) {
      final mins = now.difference(dt).inMinutes;
      if (mins < 1) return 'Baru saja';
      if (mins < 60) return '$mins mnt lalu';
      return '${now.difference(dt).inHours} jam lalu';
    }
    if (dayDiff == 1) return 'Kemarin';
    return '${dt.day} ${_months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.scaffold(context),
            expandedHeight: 100,
            pinned: true,
            automaticallyImplyLeading: false,
            titleTextStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white,
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Riwayat Scan', style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context),
                  )),
                  if (user != null)
                    Text(user.name.isNotEmpty ? user.name : user.email,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary(context))),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: _reload,
                icon: Icon(Icons.refresh_rounded, color: AppColors.textTertiary(context), size: 22),
              ),
              IconButton(
                onPressed: _confirmLogout,
                icon: Icon(Icons.logout_rounded, color: AppColors.textTertiary(context), size: 22),
              ),
            ],
          ),
          FutureBuilder<List<HistoryItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4))),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(child: _buildError(snapshot.error.toString()));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) return SliverFillRemaining(child: _buildEmptyState());
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildCard(items[index]),
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 56, color: AppColors.textQuaternary(context)),
          ),
          const SizedBox(height: 20),
          Text('Belum ada riwayat scan', style: GoogleFonts.poppins(
            fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context),
          )),
          const SizedBox(height: 8),
          Text('Hasil scan akan tersimpan otomatis di sini',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textQuaternary(context))),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textQuaternary(context)),
            const SizedBox(height: 16),
            Text('Gagal memuat riwayat', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context),
            )),
            const SizedBox(height: 8),
            Text(message, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textQuaternary(context)),
              textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4ECDC4)),
              label: Text('Coba lagi', style: GoogleFonts.inter(color: const Color(0xFF4ECDC4))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(HistoryItem item) {
    final gradeColor = _gradeColor(item.grade);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Color(0xFFFF6B6B), size: 24),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => _deleteItem(item),
      child: GestureDetector(
        onTap: () => _openDetail(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    item.grade.isEmpty ? '?' : item.grade.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.bold, color: gradeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName.isEmpty ? 'Produk tidak diketahui' : item.productName,
                      style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 13, color: AppColors.textTertiary(context)),
                        const SizedBox(width: 3),
                        Text('${item.calories.round()} kkal',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary(context))),
                        const SizedBox(width: 10),
                        Icon(Icons.access_time_rounded, size: 13, color: AppColors.textQuaternary(context)),
                        const SizedBox(width: 3),
                        Text(_formatDate(item.scannedAt),
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textQuaternary(context))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: AppColors.textQuaternary(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
