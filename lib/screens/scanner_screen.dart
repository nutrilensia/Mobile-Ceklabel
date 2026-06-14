import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/family_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ImagePicker _imagePicker = ImagePicker();

  FamilyProfile? _selectedProfile;
  List<FamilyProfile> _familyProfiles = [];

  Timer? _loadingTimer;
  int _loadingTextIndex = 0;
  final List<String> _loadingMessages = [
    'Mengunggah gambar...',
    'Membaca label komposisi...',
    'Mengekstrak nutrisi...',
    'Menghitung Nutri-Score...',
    'Menganalisis hasil akhir...'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initCamera();
    if (AuthService().isLoggedIn) _loadFamilyProfiles();
  }

  Future<void> _loadFamilyProfiles() async {
    try {
      final profiles = await ApiService().getFamilyProfiles();
      if (mounted) setState(() => _familyProfiles = profiles);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _pulseController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Izin kamera diperlukan untuk scan label';
      });
      return;
    }

    setState(() {
      _hasPermission = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMessage = 'Tidak ada kamera yang tersedia');
        return;
      }

      final camera = _isFrontCamera && _cameras.length > 1 ? _cameras[1] : _cameras[0];

      await _cameraController?.dispose();

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Restore flash state
      if (!_isFrontCamera && _isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal membuka kamera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isFrontCamera) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash tidak tersedia untuk kamera depan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final newFlash = _isFlashOn ? FlashMode.off : FlashMode.torch;
    await _cameraController!.setFlashMode(newFlash);
    setState(() => _isFlashOn = !_isFlashOn);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hanya ada satu kamera yang tersedia')),
      );
      return;
    }
    // Turn off flash when switching to front
    if (!_isFrontCamera && _isFlashOn) {
      await _cameraController?.setFlashMode(FlashMode.off);
      _isFlashOn = false;
    }
    setState(() {
      _isCameraInitialized = false;
      _isFrontCamera = !_isFrontCamera;
    });
    await _initCamera();
  }

  void _setProcessing(bool isProcessing) {
    setState(() {
      _isProcessing = isProcessing;
      if (isProcessing) {
        _loadingTextIndex = 0;
        _loadingTimer?.cancel();
        _loadingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
          if (mounted) {
            setState(() {
              if (_loadingTextIndex < _loadingMessages.length - 1) _loadingTextIndex++;
            });
          }
        });
      } else {
        _loadingTimer?.cancel();
      }
    });
  }

  Future<void> _captureAndScan() async {
    if (_isProcessing || _cameraController == null || !_cameraController!.value.isInitialized) return;
    _setProcessing(true);
    try {
      final image = await _cameraController!.takePicture();
      await _sendToApi(File(image.path));
    } catch (e) {
      _showError('Gagal mengambil foto: $e');
      _setProcessing(false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;
      _setProcessing(true);
      await _sendToApi(File(image.path));
    } catch (e) {
      _showError('Gagal memilih foto: $e');
      _setProcessing(false);
    }
  }

  Future<void> _sendToApi(File imageFile) async {
    try {
      final result = await ApiService().scanLabel(imageFile);
      if (mounted) {
        _setProcessing(false);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ResultScreen(result: result, forProfile: _selectedProfile),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1), end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
      _setProcessing(false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: const Color(0xFFE63E11),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized && _cameraController != null)
            ClipRRect(child: CameraPreview(_cameraController!))
          else
            _buildCameraFallback(),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.2, 0.65, 1.0],
              ),
            ),
          ),

          if (_isCameraInitialized) _buildScanGuide(),

          _buildTopBar(),
          _buildBottomControls(),
          if (AuthService().isLoggedIn) _buildProfileSelector(),

          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraFallback() {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_hasPermission && _errorMessage != null) ...[
              const Icon(Icons.camera_alt_rounded, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: openAppSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Buka Pengaturan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ] else ...[
              const CircularProgressIndicator(color: Color(0xFF4ECDC4)),
              const SizedBox(height: 16),
              Text('Memuat kamera...', style: GoogleFonts.inter(fontSize: 15, color: Colors.white54)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanGuide() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.78,
        height: MediaQuery.of(context).size.width * 0.78 * 0.65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.6), width: 2,
          ),
        ),
        child: Stack(
          children: [
            ..._buildCorners(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.crop_free_rounded, size: 40,
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Arahkan ke label nutrisi',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const color = Color(0xFF4ECDC4);
    const size = 24.0;
    const thickness = 3.0;
    return [
      Positioned(top: -1, left: -1, child: _corner(top: true, left: true, color: color, size: size, thickness: thickness)),
      Positioned(top: -1, right: -1, child: _corner(top: true, left: false, color: color, size: size, thickness: thickness)),
      Positioned(bottom: -1, left: -1, child: _corner(top: false, left: true, color: color, size: size, thickness: thickness)),
      Positioned(bottom: -1, right: -1, child: _corner(top: false, left: false, color: color, size: size, thickness: thickness)),
    ];
  }

  Widget _corner({required bool top, required bool left, required Color color, required double size, required double thickness}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          left: left ? BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !left ? BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.eco_rounded, color: Color(0xFF4ECDC4), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'CekLabel',
                style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                ),
              ),
              const Spacer(),
              // Camera switch button
              GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              // Flash button
              GestureDetector(
                onTap: _toggleFlash,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isFlashOn
                        ? const Color(0xFFFFD93D).withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isFlashOn
                          ? const Color(0xFFFFD93D).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isFlashOn ? const Color(0xFFFFD93D) : Colors.white60,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30, left: 40, right: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.photo_library_rounded,
                label: 'Galeri',
                onTap: _pickFromGallery,
              ),

              GestureDetector(
                onTap: _captureAndScan,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _isCameraInitialized ? _pulseAnimation.value : 1.0,
                    child: child,
                  ),
                  child: Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ECDC4).withValues(alpha: 0.4),
                          blurRadius: 24, spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),

              // Zoom hint / placeholder for symmetry
              _buildControlButton(
                icon: Icons.info_outline_rounded,
                label: 'Tips',
                onTap: _showTips,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTips() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF12121F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tips Scan yang Baik',
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('📸', 'Pastikan label terbaca jelas, tidak blur'),
              ('💡', 'Gunakan flash jika pencahayaan kurang'),
              ('📐', 'Arahkan kamera sejajar dengan label'),
              ('🔍', 'Fokus pada tabel informasi nilai gizi'),
              ('🔄', 'Gunakan kamera belakang untuk hasil terbaik'),
            ].map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip.$2,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildProfileSelector() {
    final name = _selectedProfile?.name ?? 'Saya Sendiri';
    final isCustom = _selectedProfile != null;
    return Positioned(
      bottom: 130,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _showProfileSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isCustom
                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCustom ? Icons.people_alt_rounded : Icons.person_rounded,
                  size: 15,
                  color: isCustom ? const Color(0xFF4ECDC4) : Colors.white54,
                ),
                const SizedBox(width: 7),
                Text(
                  'Scan untuk:  $name',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isCustom ? const Color(0xFF4ECDC4) : Colors.white70,
                    fontWeight: isCustom ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF12121F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scan untuk siapa?',
              style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hasil analisis akan disesuaikan dengan profil yang dipilih',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              ctx: ctx,
              icon: Icons.person_rounded,
              name: 'Saya Sendiri',
              subtitle: 'Profil utama akun',
              selected: _selectedProfile == null,
              onTap: () {
                setState(() => _selectedProfile = null);
                Navigator.pop(ctx);
              },
            ),
            if (_familyProfiles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada anggota keluarga. Tambahkan di menu Profil.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                ),
              )
            else
              ..._familyProfiles.map((p) => _buildProfileOption(
                ctx: ctx,
                icon: _iconForRelation(p.relation),
                name: p.name,
                subtitle: '${p.relationLabel} • ${p.ageGroupLabel}',
                selected: _selectedProfile?.id == p.id,
                onTap: () {
                  setState(() => _selectedProfile = p);
                  Navigator.pop(ctx);
                },
                allergies: p.allergyList,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required BuildContext ctx,
    required IconData icon,
    required String name,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    List<String>? allergies,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF4ECDC4).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 18,
                  color: selected ? const Color(0xFF4ECDC4) : Colors.white38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: selected ? const Color(0xFF4ECDC4) : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                  ),
                  if (allergies != null && allergies.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Alergi: ${allergies.join(', ')}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFFFFAD00)),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4ECDC4), size: 18),
          ],
        ),
      ),
    );
  }

  IconData _iconForRelation(String relation) {
    switch (relation) {
      case 'anak': return Icons.child_care_rounded;
      case 'suami': return Icons.man_rounded;
      case 'istri': return Icons.woman_rounded;
      case 'orang-tua': return Icons.elderly_rounded;
      default: return Icons.people_alt_rounded;
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 56, height: 56,
                child: CircularProgressIndicator(color: Color(0xFF4ECDC4), strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _loadingMessages[_loadingTextIndex],
                  key: ValueKey<int>(_loadingTextIndex),
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mohon tunggu sebentar',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
