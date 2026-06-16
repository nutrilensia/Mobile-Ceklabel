import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'scanner_screen.dart';
import 'diary_screen.dart';
import 'explore_screen.dart';
import 'saya_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Key untuk me-refresh tab tertentu saat dibuka kembali.
  int _diaryKey = 0;
  int _exploreKey = 0;
  int _sayaKey = 0;

  /// Memberi tahu ScannerScreen apakah tab scan sedang terlihat,
  /// agar kamera bisa di-pause/resume untuk hemat resource.
  final ValueNotifier<bool> _scannerVisibility = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _scannerVisibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ScannerScreen(visibilityNotifier: _scannerVisibility),
          DiaryScreen(key: ValueKey('diary_$_diaryKey')),
          ExploreScreen(key: ValueKey('explore_$_exploreKey')),
          SayaScreen(key: ValueKey('saya_$_sayaKey')),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: GNav(
            gap: 6,
            backgroundColor: Colors.transparent,
            color: Colors.white38,
            activeColor: const Color(0xFF4ECDC4),
            tabBackgroundColor: const Color(0xFF4ECDC4).withValues(alpha: 0.12),
            iconSize: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(milliseconds: 300),
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                if (index == 1 && _selectedIndex != 1) _diaryKey++;
                if (index == 2 && _selectedIndex != 2) _exploreKey++;
                if (index == 3 && _selectedIndex != 3) _sayaKey++;
                _selectedIndex = index;
              });
              _scannerVisibility.value = (index == 0);
            },
            tabs: const [
              GButton(icon: Icons.qr_code_scanner_rounded, text: 'Scan'),
              GButton(icon: Icons.book_rounded, text: 'Diary'),
              GButton(icon: Icons.explore_rounded, text: 'Jelajah'),
              GButton(icon: Icons.person_rounded, text: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}
