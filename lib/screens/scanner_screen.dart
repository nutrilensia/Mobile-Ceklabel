import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/family_profile.dart';
import '../models/live_scan_result.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  /// Called by HomeScreen to notify tab visibility changes.
  final ValueNotifier<bool>? visibilityNotifier;

  const ScannerScreen({super.key, this.visibilityNotifier});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isInitializing = false; // Guard against concurrent _initCamera calls
  bool _isProcessing = false;
  bool _isCapturing = false; // true only during focus+shutter — hides overlay so user keeps camera still
  bool _hasPermission = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _isTabVisible = true; // Track tab visibility
  String? _errorMessage;

  // ── Live AR Mode ──
  bool _liveMode = false;
  bool _liveIdle = false; // auto-paused after _liveIdleThreshold ticks of no detection
  Timer? _liveTimer;
  bool _liveBusy = false; // in-flight guard — only one frame at a time
  String _liveStatus = '';
  final List<LiveScanResult> _detections = []; // deduped, most-recent first
  int _liveNoDetectTicks = 0;
  static const _liveIntervalMs = 4000;
  static const _liveIdleThreshold = 10; // 10 × 4s = 40s idle → auto-pause

  // Zoom state
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoom = 1.0;

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

    // Listen for tab visibility changes from HomeScreen
    widget.visibilityNotifier?.addListener(_onTabVisibilityChanged);
  }

  void _onTabVisibilityChanged() {
    final isVisible = widget.visibilityNotifier?.value ?? true;
    if (isVisible == _isTabVisible) return;
    _isTabVisible = isVisible;

    if (isVisible) {
      // Tab became visible — resume camera
      _initCamera();
    } else {
      // Tab became hidden — release camera resources
      _disposeCamera();
    }
  }

  Future<void> _loadFamilyProfiles() async {
    try {
      final profiles = await ApiService().getFamilyProfiles();
      if (mounted) setState(() => _familyProfiles = profiles);
    } catch (_) {}
  }

  @override
  void dispose() {
    widget.visibilityNotifier?.removeListener(_onTabVisibilityChanged);
    WidgetsBinding.instance.removeObserver(this);
    _liveTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;
    _pulseController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  /// Safely dispose camera and update state.
  Future<void> _disposeCamera() async {
    _pauseLiveMode();
    final controller = _cameraController;
    _cameraController = null;
    if (mounted) setState(() => _isCameraInitialized = false);
    await controller?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't do anything if the controller was already cleaned up
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      // Only re-init if the tab is visible
      if (_isTabVisible) {
        _initCamera();
      }
    }
  }

  Future<void> _initCamera() async {
    // Guard: prevent concurrent initializations
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final status = await Permission.camera.request();
      if (!mounted) return;

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

      _cameras = await availableCameras();
      if (!mounted) return;

      if (_cameras.isEmpty) {
        setState(() => _errorMessage = 'Tidak ada kamera yang tersedia');
        return;
      }

      final camera = _isFrontCamera && _cameras.length > 1
          ? _cameras[1]
          : _cameras[0];

      // Dispose old controller safely before creating new one
      final oldController = _cameraController;
      _cameraController = null;
      await oldController?.dispose();

      final controller = CameraController(
        camera,
        ResolutionPreset.high, // Upgraded from medium for better label scanning
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;

      await controller.initialize();
      if (!mounted) return;

      // Check that our controller is still the current one (not replaced by another init)
      if (_cameraController != controller) {
        await controller.dispose();
        return;
      }

      // Get zoom range
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _currentZoom = _minZoom;

      // Restore flash state (only for rear camera)
      if (!_isFrontCamera && _isFlashOn) {
        try {
          await controller.setFlashMode(FlashMode.torch);
        } catch (_) {
          _isFlashOn = false;
        }
      }

      // Set auto-focus mode
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {
        // Some devices may not support programmatic focus mode
      }

      if (mounted) setState(() => _isCameraInitialized = true);

      // Resume live AR sampling if it was active before camera was released
      if (_liveMode) _startLiveMode();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal membuka kamera: $e');
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (_isFrontCamera) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash tidak tersedia untuk kamera depan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final newFlash = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(newFlash);
      if (mounted) setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      if (mounted) {
        _showError('Flash tidak didukung pada perangkat ini');
      }
    }
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
      try {
        await _cameraController?.setFlashMode(FlashMode.off);
      } catch (_) {}
      _isFlashOn = false;
    }

    setState(() {
      _isCameraInitialized = false;
      _isFrontCamera = !_isFrontCamera;
      _currentZoom = 1.0;
    });

    await _initCamera();
  }

  void _setProcessing(bool isProcessing) {
    if (!mounted) return;
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
          } else {
            timer.cancel();
          }
        });
      } else {
        _loadingTimer?.cancel();
      }
    });
  }

  Future<void> _captureAndScan() async {
    final controller = _cameraController;
    if (_isProcessing || _isCapturing || controller == null || !controller.value.isInitialized) return;

    // Lock button immediately — but DON'T show loading overlay yet so user keeps camera still
    if (mounted) setState(() => _isCapturing = true);

    try {
      // Auto-focus at center — give it more time so label is sharp
      try {
        await controller.setFocusPoint(const Offset(0.5, 0.5));
        await Future.delayed(const Duration(milliseconds: 600));
      } catch (_) {}

      // Switch flash from torch to auto for capture to avoid overexposure
      if (_isFlashOn) {
        try {
          await controller.setFlashMode(FlashMode.auto);
        } catch (_) {}
      }

      if (!mounted) return;

      // Take the photo — ONLY NOW show the full loading overlay
      final image = await controller.takePicture();
      if (!mounted) return;

      // Photo is captured — safe to show loading UI and let user move
      if (mounted) setState(() => _isCapturing = false);
      _setProcessing(true);

      // Restore torch mode after capture if flash was on
      if (_isFlashOn) {
        try {
          await controller.setFlashMode(FlashMode.torch);
        } catch (_) {}
      }

      await _sendToApi(File(image.path));
    } catch (e) {
      if (mounted) setState(() => _isCapturing = false);
      _showError('Gagal mengambil foto: $e');
      _setProcessing(false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      if (!mounted) return;
      _setProcessing(true);
      await _sendToApi(File(image.path));
    } catch (e) {
      _showError('Gagal memilih foto: $e');
      _setProcessing(false);
    }
  }

  // ── Live AR Mode ────────────────────────────────────────────────────────

  void _toggleLiveMode() {
    if (_liveMode) {
      if (_liveIdle) {
        // Resume from idle without clearing detections
        setState(() {
          _liveIdle = false;
          _liveNoDetectTicks = 0;
          _liveStatus = 'Arahkan kamera ke label nutrisi...';
        });
        _startLiveMode();
        return;
      }
      _pauseLiveMode();
      setState(() {
        _liveMode = false;
        _liveIdle = false;
        _liveStatus = '';
        _detections.clear();
        _liveNoDetectTicks = 0;
      });
    } else {
      setState(() {
        _liveMode = true;
        _liveIdle = false;
        _liveNoDetectTicks = 0;
        _liveStatus = 'Arahkan kamera ke label nutrisi...';
      });
      _startLiveMode();
    }
  }

  void _startLiveMode() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(
      const Duration(milliseconds: _liveIntervalMs),
      (_) => _liveTick(),
    );
  }

  /// Stop sampling but keep [_liveMode] so it can resume after camera re-init.
  void _pauseLiveMode() {
    _liveTimer?.cancel();
    _liveTimer = null;
    _liveBusy = false;
  }

  Future<void> _liveTick() async {
    final controller = _cameraController;
    // Skip if busy, processing a full scan, or camera not ready
    if (_liveBusy || _isProcessing || controller == null || !controller.value.isInitialized) {
      return;
    }
    _liveBusy = true;
    try {
      final image = await controller.takePicture();
      if (!mounted || !_liveMode) return;

      final result = await ApiService().scanLive(File(image.path));
      if (!mounted || !_liveMode) return;

      if (result.detected) {
        _liveNoDetectTicks = 0;
        _addDetection(result);
        setState(() => _liveStatus = 'Terdeteksi! Sapukan ke produk lain...');
      } else {
        _liveNoDetectTicks++;
        if (_liveNoDetectTicks >= _liveIdleThreshold) {
          _pauseLiveMode();
          if (mounted) {
            setState(() {
              _liveIdle = true;
              _liveStatus = 'Idle 40 detik — ketuk LIVE untuk lanjut';
            });
          }
          return;
        }
        setState(() => _liveStatus = 'Arahkan kamera ke label nutrisi...');
      }
    } catch (_) {
      // Network/rate-limit/timeout — silently keep scanning
    } finally {
      _liveBusy = false;
    }
  }

  void _addDetection(LiveScanResult result) {
    final key = result.productName.toLowerCase().trim();
    // Dedup: if same product already detected recently, move it to front
    _detections.removeWhere((d) => d.productName.toLowerCase().trim() == key);
    _detections.insert(0, result);
    // Keep only the 5 most recent
    if (_detections.length > 5) _detections.removeRange(5, _detections.length);
    setState(() {});
  }

  Future<void> _showLiveDetail(LiveScanResult d) async {
    // Pause sampling while the detail dialog is open to avoid preview flicker
    _pauseLiveMode();
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'detail',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => _LiveDetailDialog(result: d),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.85 + 0.15 * curved.value, child: child),
        );
      },
    );
    // Resume sampling if still in live mode and not idle after the dialog closes
    if (mounted && _liveMode && !_liveIdle) _startLiveMode();
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

  // ── Zoom Handling ──────────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    if (newZoom == _currentZoom) return;

    _currentZoom = newZoom;
    try {
      await controller.setZoomLevel(_currentZoom);
      if (mounted) setState(() {}); // Update zoom indicator
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized && _cameraController != null)
            _buildCameraPreview()
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

          // Zoom indicator
          if (_isCameraInitialized && _currentZoom > _minZoom) _buildZoomIndicator(),

          if (_liveMode) _buildLiveOverlay(),
          if (_isCapturing) _buildShutterHint(),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// Camera preview with proper aspect ratio and pinch-to-zoom.
  Widget _buildCameraPreview() {
    final controller = _cameraController!;
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1,
            height: controller.value.previewSize?.width ?? 1,
            child: CameraPreview(controller),
          ),
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
            ] else if (_hasPermission && _errorMessage != null) ...[
              // Camera error with retry — permission granted but camera init failed
              const Icon(Icons.error_outline_rounded, size: 64, color: Colors.white24),
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

  Widget _buildZoomIndicator() {
    final zoomText = '${_currentZoom.toStringAsFixed(1)}x';
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _currentZoom > _minZoom ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Text(
              zoomText,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4ECDC4),
              ),
            ),
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
              // Live AR mode toggle
              GestureDetector(
                onTap: _toggleLiveMode,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _liveIdle
                        ? const Color(0xFFFFAD00).withValues(alpha: 0.85)
                        : _liveMode
                            ? const Color(0xFF4ECDC4).withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _liveIdle
                          ? const Color(0xFFFFAD00)
                          : _liveMode
                              ? const Color(0xFF4ECDC4)
                              : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _liveIdle
                            ? Icons.pause_circle_outline_rounded
                            : _liveMode
                                ? Icons.sensors_rounded
                                : Icons.sensors_off_rounded,
                        color: _liveMode ? Colors.black : Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _liveIdle ? 'IDLE' : 'LIVE',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _liveMode ? Colors.black : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
              ('🤏', 'Cubit layar untuk zoom in/out'),
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

  // ── Live AR overlay ───────────────────────────────────────────────────────

  Widget _buildLiveOverlay() {
    return Stack(
      children: [
        // Status pill — shows scanning state
        Positioned(
          top: MediaQuery.of(context).padding.top + 66,
          left: 0,
          right: 0,
          child: Center(child: _liveStatusPill()),
        ),

        // Detected products — accumulate down the left side, newest on top
        if (_detections.isNotEmpty)
          Positioned(
            left: 14,
            top: MediaQuery.of(context).size.height * 0.30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _detections.length; i++)
                  AnimatedOpacity(
                    opacity: i == 0 ? 1.0 : (1.0 - i * 0.18).clamp(0.3, 1.0),
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: () => _showLiveDetail(_detections[i]),
                      child: _liveDetectionCard(_detections[i], isNewest: i == 0),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _liveStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing live dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: _pulseController.value),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _liveStatus,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveDetectionCard(LiveScanResult d, {required bool isNewest}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      constraints: const BoxConstraints(maxWidth: 210),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNewest
              ? d.gradeColor.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.1),
          width: isNewest ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grade circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: d.gradeColor,
              shape: BoxShape.circle,
              boxShadow: isNewest
                  ? [BoxShadow(color: d.gradeColor.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1)]
                  : null,
            ),
            child: Center(
              child: Text(
                d.grade,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  d.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: d.gradeColor),
                ),
              ],
            ),
          ),
        ],
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
                child: CircularProgressIndicator(
                  color: Color(0xFF4ECDC4), strokeWidth: 2,
                ),
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

/// Animated detail popup for a live-scanned product.
/// Grade circle bounces in (elastic), nutrition numbers count up, and the
/// stat cards cascade into view.
class _LiveDetailDialog extends StatelessWidget {
  final LiveScanResult result;
  const _LiveDetailDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final c = result.gradeColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: const Color(0xFF12121F),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: c.withValues(alpha: 0.45), width: 1.5),
              boxShadow: [
                BoxShadow(color: c.withValues(alpha: 0.28), blurRadius: 44, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Grade circle — elastic bounce-in ──
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  builder: (_, v, __) => Transform.scale(
                    scale: v.clamp(0.0, 1.4),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [c, c.withValues(alpha: 0.7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: c.withValues(alpha: 0.55), blurRadius: 24, spreadRadius: 2),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          result.grade,
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Product name & label ──
                Text(
                  result.productName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    result.label,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: c),
                  ),
                ),
                if (result.category.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Kategori: ${result.category}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                  ),
                ],
                const SizedBox(height: 20),

                // ── Nutrition stats — cascade in with count-up ──
                Row(
                  children: [
                    _stat(0, 'Kalori', result.calories, 'kkal', const Color(0xFFFF6B6B)),
                    const SizedBox(width: 8),
                    _stat(1, 'Gula', result.sugarG, 'g', const Color(0xFFFFAD00)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _stat(2, 'Natrium', result.sodiumMg, 'mg', const Color(0xFF4ECDC4)),
                    const SizedBox(width: 8),
                    _stat(3, 'Lemak Jenuh', result.fatSaturatedG, 'g', const Color(0xFF9B6BFF)),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Hint + close ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pencet tombol shutter untuk analisis lengkap, komposisi & simpan ke riwayat.',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white38, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One nutrition stat card with a staggered slide-up + count-up animation.
  Widget _stat(int index, String label, double value, String unit, Color color) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 500 + index * 160),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  // Count-up value
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => Text(
                      _fmt(v, unit),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(double v, String unit) {
    // Integers for kkal/mg, one decimal for grams
    final num shown = (unit == 'g') ? (v * 10).round() / 10 : v.round();
    return '$shown $unit';
  }
}
