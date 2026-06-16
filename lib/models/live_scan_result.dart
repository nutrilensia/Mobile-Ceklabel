import 'package:flutter/material.dart';

class LiveScanResult {
  final bool detected;
  final String productName;
  final String category;
  final String grade;
  final int finalScore;
  final String color; // hex string from backend, e.g. "#1B7A1B"
  final String label;
  final double calories;
  final double sugarG;
  final double sodiumMg;
  final double fatSaturatedG;

  LiveScanResult({
    required this.detected,
    this.productName = '',
    this.category = '',
    this.grade = '',
    this.finalScore = 0,
    this.color = '#888888',
    this.label = '',
    this.calories = 0,
    this.sugarG = 0,
    this.sodiumMg = 0,
    this.fatSaturatedG = 0,
  });

  factory LiveScanResult.fromJson(Map<String, dynamic> j) {
    final data = j['data'] ?? j;
    if (data['detected'] != true) return LiveScanResult(detected: false);
    final n = data['nutrition'] as Map<String, dynamic>? ?? {};
    return LiveScanResult(
      detected: true,
      productName: data['productName']?.toString() ?? 'Produk',
      category: data['category']?.toString() ?? '',
      grade: data['grade']?.toString() ?? '',
      finalScore: (data['finalScore'] ?? 0).toInt(),
      color: data['color']?.toString() ?? '#888888',
      label: data['label']?.toString() ?? '',
      calories: (n['calories'] ?? 0).toDouble(),
      sugarG: (n['sugarG'] ?? 0).toDouble(),
      sodiumMg: (n['sodiumMg'] ?? 0).toDouble(),
      fatSaturatedG: (n['fatSaturatedG'] ?? 0).toDouble(),
    );
  }

  Color get gradeColor {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF888888);
    }
  }
}
