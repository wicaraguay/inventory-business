import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

/// The "Precision Logic" theme translated to Flutter ThemeData, in light and
/// dark. Both share the same structure; only the structural colors differ.
abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        canvas: AppColors.lightCanvas,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        inputBorder: AppColors.lightInputBorder,
        divider: AppColors.lightDivider,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        canvas: AppColors.darkCanvas,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        inputBorder: AppColors.darkInputBorder,
        divider: AppColors.darkDivider,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color onSurface,
    required Color inputBorder,
    required Color divider,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: AppColors.danger,
    );

    final baseText = GoogleFonts.interTextTheme(
      brightness == Brightness.dark ? ThemeData.dark().textTheme : null,
    );
    final textTheme = baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: onSurface,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.24,
        color: onSurface,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 14),
      labelMedium: baseText.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
      ),
    );
  }
}
