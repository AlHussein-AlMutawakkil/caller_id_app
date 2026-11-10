import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // اللون الأساسي للأيقونات والمؤشرات التفاعلية
  static Color get primary => isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF1E232C);

  // لون شريط التطبيق العلوي والسفلي
  static Color get appBarBackground => isDarkMode ? const Color(0xFF131822) : const Color(0xFF1E232C);

  // لون خلفية الأزرار الرئيسية
  static Color get buttonBackground => isDarkMode ? const Color(0xFF2563EB) : const Color(0xFF1E232C);

  // لون الحقول وعناصر الإدخال الثانوية
  static Color get secondary => isDarkMode ? const Color(0xFF1E2636) : const Color(0xFFEAEAEA);
  static Color get Secondary => secondary;

  // اللون الأزرق النيلي المخصص
  static Color get textDark => isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFEAEAEA);

  // ألوان الخلفيات والكروت
  static Color get scaffoldBackground => isDarkMode ? const Color(0xFF0F141C) : const Color(0xFFF7F8FA);
  static Color get cardBackground => isDarkMode ? const Color(0xFF181F2C) : Colors.white;
  static Color get cardBorder => isDarkMode ? const Color(0xFF263346) : const Color(0xFFF0F1F4);
  static Color get divider => isDarkMode ? const Color(0xFF222B3A) : const Color(0xFFF0F1F5);

  // ألوان النصوص
  static Color get textPrimary => isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1A1D26);
  static Color get textSecondary => isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF8A92A0);

  // ألوان الحالة
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFE53935);
  static Color get disabled => isDarkMode ? const Color(0xFF475569) : const Color(0xFFBDC3C7);
}
