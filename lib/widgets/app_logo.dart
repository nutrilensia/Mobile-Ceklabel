import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? fallbackColor;

  const AppLogo({
    super.key,
    required this.size,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback jika file logo tidak ditemukan/gagal dimuat
        return Icon(
          Icons.eco_rounded,
          color: fallbackColor ?? const Color(0xFF4ECDC4),
          size: size,
        );
      },
    );
  }
}
