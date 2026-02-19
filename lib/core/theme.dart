import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: Color.fromARGB(255, 49, 118, 228),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: Color.fromARGB(255, 18, 43, 112),
      secondary: Color(0xFF38BDF8),
      onSecondary: Colors.white,
      tertiary: Color(0xFF14B8A6),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFCCFBF1),
      onTertiaryContainer: Color(0xFF134E4A),
      surface: Colors.white,
      onSurface: Color(0xFF1F2937),
      outline: Color(0xFFBFDBFE),
      outlineVariant: Color(0xFFD1E4FF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: colorScheme.primary, size: 28),
        actionsIconTheme: IconThemeData(color: colorScheme.primary, size: 28),
      ),
      cardColor: Colors.white,
      canvasColor: Colors.white,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.tertiaryContainer,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? colorScheme.primary : const Color(0xFF6B7280),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? colorScheme.primary : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primaryContainer,
        selectedColor: colorScheme.tertiaryContainer,
        labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
      ),
    );
  }
}
