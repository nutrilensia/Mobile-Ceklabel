import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'compare_screen.dart';

/// "Belanja Pintar" dari foto: ambil 2-3 foto label produk langsung,
/// lalu bandingkan tanpa perlu produk ada di database.
class PhotoCompareScreen extends StatefulWidget {
  const PhotoCompareScreen({super.key});

  @override
  State<PhotoCompareScreen> createState() => _PhotoCompareScreenState();
}

class _PhotoCompareScreenState extends State<PhotoCompareScreen> {
  static const int _maxPhotos = 3;
  final List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _addPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.bottomSheet(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textQuaternary(context), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            _sourceTile(ctx, Icons.photo_camera_rounded, 'Ambil Foto', ImageSource.camera),
            const SizedBox(height: 10),
            _sourceTile(ctx, Icons.photo_library_rounded, 'Pilih dari Galeri', ImageSource.gallery),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null && mounted) {
        setState(() => _photos.add(File(picked.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e'),
              backgroundColor: const Color(0xFFFF6B6B)),
        );
      }
    }
  }

  Widget _sourceTile(BuildContext ctx, IconData icon, String label, ImageSource src) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, src),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4ECDC4), size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textPrimary(context), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _compare() {
    if (_photos.length < 2) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompareScreen(photos: List.of(_photos))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCompare = _photos.length >= 2;
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold(context),
        foregroundColor: AppColors.appBarForeground(context),
        title: Text('Bandingkan dari Foto',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF4ECDC4).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart_rounded,
                            color: Color(0xFF4ECDC4), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Foto 2-3 label produk yang ingin kamu bandingkan. '
                            'Cocok saat memilih produk di rak minimarket.',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF4ECDC4),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_photos.length, (i) => _photoCard(i)),
                  if (_photos.length < _maxPhotos) _addCard(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: canCompare ? _compare : null,
                  icon: const Icon(Icons.compare_arrows_rounded, size: 20),
                  label: Text(
                    canCompare
                        ? 'Bandingkan ${_photos.length} Produk'
                        : 'Tambah minimal 2 foto',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.disabledBg(context),
                    disabledForegroundColor: AppColors.disabledFg(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoCard(int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.file(_photos[i],
                width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Produk ${i + 1}',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
          ),
          IconButton(
            onPressed: () => setState(() => _photos.removeAt(i)),
            icon: Icon(Icons.close_rounded, color: AppColors.textTertiary(context), size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _addCard() {
    return GestureDetector(
      onTap: _addPhoto,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_rounded, color: Color(0xFF4ECDC4), size: 22),
            const SizedBox(width: 10),
            Text('Tambah foto produk',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF4ECDC4),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
