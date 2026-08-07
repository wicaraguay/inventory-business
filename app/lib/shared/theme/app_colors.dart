import 'package:flutter/material.dart';

/// "Precision Logic" brand + semantic colors (from the Stitch design system).
/// ColorScheme covers primary/surface/error; these are the extras.
abstract final class AppColors {
  static const primary = Color(0xFF4F46E5); // Vibrant Indigo
  static const onSurface = Color(0xFF1E293B); // Deep Slate
  static const canvas = Color(0xFFF8FAFC); // global background
  static const surface = Color(0xFFFFFFFF); // cards
  static const inputBorder = Color(0xFFD1D5DB);
  static const divider = Color(0xFFF1F5F9);

  // Status (In Stock / Low Stock / Out of Stock).
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFD1FAE5);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const danger = Color(0xFFBA1A1A);
  static const dangerBg = Color(0xFFFFDAD6);
}
