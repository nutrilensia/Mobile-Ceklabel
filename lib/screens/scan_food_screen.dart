import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'result_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/handle_bar.dart';

class ScanFoodScreen extends StatefulWidget {
  const ScanFoodScreen({super.key});

  @override
  State<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends State<ScanFoodScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isInitializing = false;
  bool _hasPermission = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _isLoading = false;
  bool _isCapturing = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final status = await Permission.camera.request();
      if (!mounted) return;

      if (!status.isGranted) {
        setState(() {
          _hasPermission = false;
          _errorMessage = 'Izin kamera diperlukan untuk scan makanan';
        });
        return;
      }
      setState(() {
        _hasPermission = true;
        _errorMessage = null;
      });

      _cameras = await availableCameras();
      if (!mounted) return;

      if (_cameras.isEmpty) {
        setState(() => _errorMessage = 'Tidak ada kamera yang tersedia');
        return;
      }

      final camera = _isFrontCamera && _cameras.length > 1
          ? _cameras[1]
          : _cameras[0];

      final oldController = _cameraController;
      _cameraController = null;
      await oldController?.dispose();

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      await controller.initialize();
      if (!mounted) return;

      if (_cameraController != controller) {
        await controller.dispose();
        return;
      }

      // Restore flash state (only for rear camera)
      if (!_isFrontCamera && _isFlashOn) {
        try {
          await controller.setFlashMode(FlashMode.torch);
        } catch (_) {
          _isFlashOn = false;
        }
      }

      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal membuka kamera: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (_isFrontCamera) {
      _showSnack('Flash tidak tersedia untuk kamera depan');
      return;
    }

    try {
      final newFlash = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(newFlash);
      if (mounted) setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      _showSnack('Flash tidak didukung pada perangkat ini');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      _showSnack('Hanya ada satu kamera yang tersedia');
      return;
    }

    if (!_isFrontCamera && _isFlashOn) {
      try {
        await _cameraController?.setFlashMode(FlashMode.off);
      } catch (_) {}
      _isFlashOn = false;
    }

    setState(() {
      _isCameraInitialized = false;
      _isFrontCamera = !_isFrontCamera;
    });

    await _initCamera();
  }

  Future<void> _captureAndScan() async {
    final controller = _cameraController;
    if (_isCapturing || _isLoading || controller == null || !controller.value.isInitialized) return;

    setState(() => _isCapturing = true);
    try {
      try {
        await controller.setFocusPoint(const Offset(0.5, 0.5));
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {}

      final image = await controller.takePicture();
      if (!mounted) return;
      setState(() => _isCapturing = false);
      await _processImage(File(image.path));
    } catch (e) {
      if (mounted) setState(() => _isCapturing = false);
      setState(() => _errorMessage = 'Gagal mengambil foto: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isLoading) return;
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      await _processImage(File(image.path));
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memilih foto: $e');
    }
  }

  Future<void> _processImage(File file) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService().scanFoodPhoto(file);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResultScreen(result: result)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showSnack(String message) {
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized && _cameraController != null)
            _buildCameraPreview()
          else
            _buildCameraFallback(),

          if (_isCameraInitialized) _buildScanGuide(),

          _buildTopBar(),

          if (_isCameraInitialized && !_isLoading) _buildBottomControls(),

          if (_isCapturing) _buildShutterHint(),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController!;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
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
              const Icon(Icons.camera_alt_rounded, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white70),
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
            ] else if (_hasPermission && _errorMessage != null) ...[
              Icon(Icons.error_outline_rounded, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isInitializing ? null : _initCamera,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  _isInitializing ? 'Memuat...' : 'Coba Lagi',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(color: Color(0xFF4ECDC4)),
              const SizedBox(height: 16),
              Text('Memuat kamera...', style: GoogleFonts.inter(fontSize: 15, color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanGuide() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.55), width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fastfood_rounded, size: 40,
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                'Arahkan ke makanan Anda',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Scan Makanan Langsung',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
              ),
              // Icon buttons group (switch cam, flash, tips)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _switchCamera,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    Container(width: 1, height: 18, color: Colors.white24),
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _isFlashOn ? const Color(0xFFFFD93D) : Colors.white60,
                          size: 18,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 18, color: Colors.white24),
                    GestureDetector(
                      onTap: _showTips,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.info_outline_rounded, color: Colors.white60, size: 18),
                      ),
                    ),
                  ],
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
          child: Column(
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onTap: _pickFromGallery,
                  ),
                  GestureDetector(
                    onTap: _captureAndScan,
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
                        child: const Icon(Icons.fastfood_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  // Placeholder for symmetry
                  const SizedBox(width: 56),
                ],
              ),
            ],
          ),
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
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  void _showTips() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.bottomSheet(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HandleBar(),
            const SizedBox(height: 20),
            Text(
              'Tips Scan yang Baik',
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('📸', 'Foto seluruh makanan dari atas agar semua komponen terlihat'),
              ('💡', 'Gunakan flash jika pencahayaan kurang terang'),
              ('🍽️', 'Pastikan piring/wadah terlihat untuk membantu estimasi porsi'),
              ('🔍', 'Ambil jarak dekat agar detail bahan makanan jelas'),
              ('🥗', 'Jika makanan tercampur, coba pisahkan sedikit agar tiap komponen terlihat'),
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
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody(context), height: 1.4),
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

  Widget _buildShutterHint() {
    return Positioned(
      bottom: 160,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(color: Color(0xFF4ECDC4), strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Tahan kamera — sedang memfokus...',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF4ECDC4)),
            const SizedBox(height: 24),
            Text(
              'Menganalisis Makanan...',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'AI sedang mengestimasi komponen dan nilai gizi.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}