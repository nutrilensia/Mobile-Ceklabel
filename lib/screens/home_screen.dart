import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'scanner_screen.dart';
import 'history_screen.dart';
import 'saya_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _historyKey = 0;
  int _sayaKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: StreamBuilder<UserModel?>(
        stream: AuthService().authStateChanges,
        initialData: AuthService().currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          return IndexedStack(
            index: _selectedIndex,
            children: [
              const ScannerScreen(),
              user != null
                  ? HistoryScreen(key: ValueKey(_historyKey), uid: user.id)
                  : _buildLoginGate(
                      icon: Icons.history_rounded,
                      title: 'Riwayat Scan',
                      subtitle: 'Login untuk melihat semua riwayat scan-mu.',
                    ),
              SayaScreen(key: ValueKey(_sayaKey)),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildLoginGate({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
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
                          color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, size: 52, color: const Color(0xFF4ECDC4)),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.white54, height: 1.5),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Masuk / Daftar',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: GNav(
            gap: 8,
            backgroundColor: Colors.transparent,
            color: Colors.white38,
            activeColor: const Color(0xFF4ECDC4),
            tabBackgroundColor: const Color(0xFF4ECDC4).withValues(alpha: 0.12),
            iconSize: 22,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            duration: const Duration(milliseconds: 300),
            onTabChange: (index) {
              setState(() {
                if (index == 1 && _selectedIndex != 1) _historyKey++;
                if (index == 2 && _selectedIndex != 2) _sayaKey++;
                _selectedIndex = index;
              });
            },
            tabs: const [
              GButton(icon: Icons.qr_code_scanner_rounded, text: 'Scan'),
              GButton(icon: Icons.history_rounded, text: 'Riwayat'),
              GButton(icon: Icons.person_outline_rounded, text: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}
