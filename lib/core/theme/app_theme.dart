import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const navy = Color(0xFF082A36);
  static const navySoft = Color(0xFF123D49);
  static const fieldGreen = Color(0xFF0C8A5D);
  static const brightGreen = Color(0xFF19B979);
  static const lime = Color(0xFFC8F36A);
  static const canvas = Color(0xFFF2F6F4);
  static const ink = Color(0xFF12251E);
  static const line = Color(0xFFDCE7E2);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: fieldGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: fieldGreen,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDDF6EA),
      onPrimaryContainer: const Color(0xFF063E2B),
      secondary: navy,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDDE9EC),
      onSecondaryContainer: navy,
      tertiary: const Color(0xFF719E1E),
      tertiaryContainer: const Color(0xFFEAFBC6),
      surface: Colors.white,
      onSurface: ink,
      outline: const Color(0xFF75857E),
      outlineVariant: line,
    );

    final textTheme = ThemeData.light().textTheme.apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.35,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.4),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: navy.withValues(alpha: 0.08),
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FBF9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        prefixIconColor: navySoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: fieldGreen, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: fieldGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9E2DE),
          disabledForegroundColor: const Color(0xFF77827E),
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: fieldGreen),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: lime,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? navy
                : const Color(0xFF65736D),
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? navy
                : const Color(0xFF65736D),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: fieldGreen,
      ),
    );
  }
}
