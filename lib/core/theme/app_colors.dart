import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // اللون الداكن الأساسي للـ AppBar والعناصر البارزة
  static Color get primary => isDarkMode ? const Color(0xFF1E2633) : const Color(0xFF1E232C);
  static Color get Secondary => isDarkMode ? const Color(0xFF222938) : const Color(0xFFeaeaea);

  // اللون الأزرق النيلي الغامق المخصص لعرض الأسماء المطابقة
  static Color get textDark => isDarkMode ? const Color(0xFF2B3447) : const Color(0xFFeaeaea);

  // ألوان الخلفيات والكروت
  static Color get scaffoldBackground => isDarkMode ? const Color(0xFF0F1218) : const Color(0xFFF7F8FA);
  static Color get cardBackground => isDarkMode ? const Color(0xFF181D26) : Colors.white;
  static Color get cardBorder => isDarkMode ? const Color(0xFF252D3B) : const Color(0xFFF0F1F4);
  static Color get divider => isDarkMode ? const Color(0xFF232A37) : const Color(0xFFF0F1F5);

  // ألوان النصوص
  static Color get textPrimary => isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1A1D26);
  static Color get textSecondary => isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF8A92A0);

  // ألوان الحالة
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFE53935);
  static Color get disabled => isDarkMode ? const Color(0xFF475569) : const Color(0xFFBDC3C7);
}
