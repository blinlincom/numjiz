import 'package:flutter/material.dart';

class AppTheme {
  // 现代深蓝紫配色
  static const Color primaryColor = Color(0xFF4F46E5);    // Indigo 600
  static const Color primaryLight = Color(0xFFEEF2FF);    // Indigo 50
  static const Color secondaryColor = Color(0xFF7C3AED);  // Violet 600
  static const Color accentColor = Color(0xFFF59E0B);     // Amber 500
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFEF4444);      // Red 500
  static const Color successColor = Color(0xFF10B981);    // Emerald 500
  static const Color warningColor = Color(0xFFF59E0B);    // Amber 500
  static const Color textPrimary = Color(0xFF0F172A);     // Slate 900
  static const Color textSecondary = Color(0xFF64748B);   // Slate 500
  static const Color dividerColor = Color(0xFFE2E8F0);    // Slate 200
  static const Color cardShadow = Color(0x0F1E293B);      // Slate 800 6%

  // 费用类型颜色 — 更鲜明现代
  static const Map<String, Color> expenseColors = {
    '充电费': Color(0xFF06B6D4),   // Cyan 500
    '过路费': Color(0xFFF97316),   // Orange 500
    '停车费': Color(0xFF8B5CF6),   // Violet 500
    '货物买赔': Color(0xFFEF4444), // Red 500
  };

  static const Map<String, IconData> expenseIcons = {
    '充电费': Icons.electric_bolt_rounded,
    '过路费': Icons.toll_rounded,
    '停车费': Icons.local_parking_rounded,
    '货物买赔': Icons.inventory_2_rounded,
  };

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    final baseTextTheme = Typography.material2021(
      platform: TargetPlatform.android,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      textTheme: baseTextTheme.black.copyWith(
        headlineLarge: baseTextTheme.black.headlineLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, fontFamily: null),
        headlineMedium: baseTextTheme.black.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary, fontFamily: null),
        titleLarge: baseTextTheme.black.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary, fontFamily: null),
        titleMedium: baseTextTheme.black.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary, fontFamily: null),
        bodyLarge: baseTextTheme.black.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, fontFamily: null),
        bodyMedium: baseTextTheme.black.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, fontFamily: null),
        labelLarge: baseTextTheme.black.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: null),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: surfaceColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: dividerColor, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        extendedTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
