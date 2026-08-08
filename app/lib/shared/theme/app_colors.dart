import 'package:flutter/material.dart';

/// "Precision Logic" brand + semantic colors (from the Stitch design system).
///
/// Brand and status colors are the same in light and dark. The five STRUCTURAL
/// colors (canvas, surface, onSurface, inputBorder, divider) change with the
/// theme: they're exposed as theme-aware getters that read [dark], which the app
/// sets from the resolved MaterialApp theme on every build. The concrete
/// `light*` / `dark*` constants feed the ThemeData builders (which must not
/// depend on the runtime flag).
abstract final class AppColors {
  // --- Brand + status: identical in both themes -------------------------
  static const primary = Color(0xFF4F46E5); // Vibrant Indigo
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFD1FAE5);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const danger = Color(0xFFBA1A1A);
  static const dangerBg = Color(0xFFFFDAD6);

  // --- Structural: concrete values per theme ----------------------------
  static const lightCanvas = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1E293B); // Deep Slate
  static const lightInputBorder = Color(0xFFD1D5DB);
  static const lightDivider = Color(0xFFF1F5F9);

  static const darkCanvas = Color(0xFF0F172A); // Slate 900
  static const darkSurface = Color(0xFF1E293B); // Slate 800
  static const darkOnSurface = Color(0xFFE2E8F0); // Slate 200
  static const darkInputBorder = Color(0xFF334155); // Slate 700
  static const darkDivider = Color(0xFF334155);

  /// Set once per build from the resolved theme brightness. Drives the getters.
  static bool dark = false;

  static Color get canvas => dark ? darkCanvas : lightCanvas;
  static Color get surface => dark ? darkSurface : lightSurface;
  static Color get onSurface => dark ? darkOnSurface : lightOnSurface;
  static Color get inputBorder => dark ? darkInputBorder : lightInputBorder;
  static Color get divider => dark ? darkDivider : lightDivider;
}
