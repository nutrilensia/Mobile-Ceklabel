import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'compare_screen.dart';
import 'photo_compare_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;
  List<Product> _searchResults = [];
  List<Product> _leaderboardBest = [];
  List<Product> _leaderboardWorst = [];
  List<ProductCategory> _categories = [];
  String? _selectedCategory;
  bool _loadingLeaderboard = false;
  bool _loadingSearch = false;
  bool _loadingCategories = false;
  Timer? _debounce;

  final List<Product> _compareList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Debounce input pencarian agar tidak memanggil API tiap ketukan.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _search('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  String? _leaderboardError;

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final cats = await ApiService().getProductCategories();
      if (mounted) {
        setState(() =>
            _categories = cats.where((c) => c.productCount > 0).toList());
      }
    } catch (_) {
      // Categories optional, ignore error
    }
    if (mounted) setState(() => _loadingCategories = false);
  }

  Future<void> _loadLeaderboard() async {
    setState(() { _loadingLeaderboard = true; _leaderboardError = null; });
    try {
      // Ambil "terbaik" & "terburuk" paralel agar latensi tidak dobel.
      final results = await Future.wait([
        ApiService().getLeaderboard(category: _selectedCategory, order: 'best'),
        ApiService().getLeaderboard(category: _selectedCategory, order: 'worst'),
      ]);
      if (mounted) {
        setState(() {
          _leaderboardBest = results[0];
          _leaderboardWorst = results[1];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _leaderboardError = e.toString());
    }
    if (mounted) setState(() => _loadingLeaderboard = false);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; });
      return;
    }
    setState(() { _isSearching = true; _loadingSearch = true; });
    try {
      final results = await ApiService().searchProducts(
        query: query, category: _selectedCategory);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {}
    if (mounted) setState(() => _loadingSearch = false);
  }

  void _toggleCompare(Product p) {
    setState(() {
      if (_compareList.any((c) => c.id == p.id)) {
        _compareList.removeWhere((c) => c.id == p.id);
      } else if (_compareList.length < 3) {
        _compareList.add(p);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maksimal 3 produk untuk dibandingkan'),
            backgroundColor: Color(0xFFFF6B6B),
          ),
        );
      }
    });
  }

  void _goCompare() {
    if (_compareList.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 2 produk')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareScreen(
          items: _compareList
              .map((p) => CompareItem(productId: p.id))
              .toList(),
        ),
      ),
    ).then((_) => setState(() => _compareList.clear()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearch(),
            _buildCategories(),
            if (!_isSearching) _buildTabs(),
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildLeaderboard(),
            ),
          ],
        ),
      ),
      floatingActionButton: _compareList.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _compareList.length >= 2 ? _goCompare : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pilih minimal 2 produk untuk dibandingkan'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: _compareList.length >= 2
                  ? const Color(0xFF4ECDC4)
                  : AppColors.disabledBg(context),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.compare_arrows_rounded),
              label: Text(
                _compareList.length >= 2
                    ? 'Bandingkan ${_compareList.length} Produk'
                    : 'Pilih 1 lagi...',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jelajah Produk',
            style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cari produk lalu tekan ⊕ untuk membandingkan hingga 3 produk sekaligus.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context), height: 1.4),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PhotoCompareScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                  const Color(0xFF4ECDC4).withValues(alpha: 0.05),
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_a_photo_rounded,
                      color: Color(0xFF4ECDC4), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bandingkan dari Foto',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4ECDC4))),
                        Text('Foto langsung 2-3 produk, tanpa harus ada di database',
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary(context))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF4ECDC4), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBorder(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.inter(color: AppColors.textPrimary(context), fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: GoogleFonts.inter(color: AppColors.textTertiary(context), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary(context)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: AppColors.textTertiary(context)),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: _onSearchChanged,
        onSubmitted: _search,
      ),
    );
  }

  Widget _buildCategories() {
    if (_loadingCategories || _categories.isEmpty) return const SizedBox(height: 4);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _categoryChip(null, 'Semua'),
          ..._categories.map((c) => _categoryChip(c.id, _capitalize(c.id))),
        ],
      ),
    );
  }

  Widget _categoryChip(String? value, String label) {
    final selected = _selectedCategory == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = value);
        if (_isSearching) {
          _search(_searchCtrl.text);
        } else {
          _loadLeaderboard();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
              : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                : AppColors.cardBorder(context),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: selected ? const Color(0xFF4ECDC4) : AppColors.textSecondary(context),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: const Color(0xFF4ECDC4),
          unselectedLabelColor: AppColors.textSecondary(context),
          labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Terbaik'),
            Tab(text: 'Terburuk'),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (_loadingLeaderboard) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)));
    }
    if (_leaderboardError != null && _leaderboardBest.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.textQuaternary(context)),
              const SizedBox(height: 16),
              Text('Fitur leaderboard belum tersedia',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textTertiary(context))),
              const SizedBox(height: 8),
              Text('Database produk masih dalam pengembangan',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textQuaternary(context)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _loadLeaderboard,
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4ECDC4)),
                label: Text('Coba lagi',
                    style: GoogleFonts.inter(color: const Color(0xFF4ECDC4))),
              ),
            ],
          ),
        ),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProductList(_leaderboardBest, 'Produk dengan nutrisi terbaik'),
        _buildProductList(_leaderboardWorst, 'Produk dengan nutrisi terburuk'),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_loadingSearch) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)));
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada hasil untuk "${_searchCtrl.text}"',
          style: GoogleFonts.inter(color: AppColors.textTertiary(context), fontSize: 14),
        ),
      );
    }
    return _buildProductList(_searchResults, '${_searchResults.length} hasil');
  }

  Widget _buildProductList(List<Product> products, String subtitle) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off_outlined, size: 48, color: AppColors.textQuaternary(context)),
            const SizedBox(height: 12),
            Text(
              'Belum ada data produk',
              style: GoogleFonts.poppins(color: AppColors.textTertiary(context), fontSize: 14),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary(context)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
            itemCount: products.length,
            itemBuilder: (_, i) => _buildProductCard(products[i], i + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product p, int rank) {
    final gradeColor = _gradeColor(p.nutriScore);
    final isSelected = _compareList.any((c) => c.id == p.id);
    final canAdd = _compareList.length < 3 || isSelected;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4ECDC4).withValues(alpha: 0.08)
            : AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
              : AppColors.cardBorder(context),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textTertiary(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF4ECDC4) : AppColors.textPrimary(context),
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _capitalize(p.category) +
                      (p.scanCount > 0 ? ' • ${p.scanCount}x scan' : ''),
                  style:
                      GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Nutri-Score badge
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              p.nutriScore.isNotEmpty ? p.nutriScore : '?',
              style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.bold, color: gradeColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Compare toggle button
          GestureDetector(
            onTap: canAdd ? () => _toggleCompare(p) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.2)
                    : canAdd
                        ? AppColors.cardBorder(context)
                        : AppColors.cardBg(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4ECDC4).withValues(alpha: 0.6)
                      : AppColors.inputBorder(context),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                isSelected
                    ? Icons.check_rounded
                    : Icons.add_rounded,
                size: 16,
                color: isSelected
                    ? const Color(0xFF4ECDC4)
                    : canAdd
                        ? AppColors.iconDefault(context)
                        : AppColors.iconInactive(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A': return const Color(0xFF1E8F4E);
      case 'B': return const Color(0xFF6DB33F);
      case 'C': return const Color(0xFFFFAD00);
      case 'D': return const Color(0xFFEF7D00);
      case 'E': return const Color(0xFFE63312);
      default: return const Color(0xFF888888);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split('-')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
