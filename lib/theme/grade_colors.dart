import 'package:flutter/material.dart';

/// Centralized Nutri-Score grade colors.
/// Canonical values from result_screen — single source of truth.
const Map<String, Color> kGradeColors = {
  'A': Color(0xFF1E8F4E),
  'B': Color(0xFF6DB33F),
  'C': Color(0xFFFFAD00),
  'D': Color(0xFFEF7D00),
  'E': Color(0xFFE63312),
};

/// Return grade color, default to grey for unknown.
Color gradeColor(String grade) {
  return kGradeColors[grade.toUpperCase()] ?? const Color(0xFF888888);
}
