import 'package:flutter/material.dart';

/// Central colour palette for the Rosary Break brand.
///
/// Marian blue + white + subtle gold. Keep this file free of layout logic.
abstract final class AppColors {
  // Primary — Marian blue (Mary, prayer, peace, trust)
  static const Color marianBlue = Color(0xFF1C3D8A);
  static const Color marianBlueDark = Color(0xFF122A63);
  static const Color marianBlueSoft = Color(0xFFE9EEF9);

  // Secondary — Warm Ivory (calm, clean, warm background)
  static const Color warmIvory = Color(0xFFFAF7F0);
  static const Color warmIvorySoft = Color(0xFFFDFBF7);

  // Accent — Soft gold (highlights and important moments)
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldSoft = Color(0xFFF7F0DD);
  static const Color goldDark = Color(0xFFA98633);

  // Supporting palette
  static const Color deepNavy = Color(0xFF0D1B2A);
  static const Color mutedRose = Color(0xFFC88D8E);
  static const Color softSkyBlue = Color(0xFF7CA5D8);
  static const Color warmBeige = Color(0xFFF4EFEB);

  // Neutrals
  static const Color ink = Color(0xFF1B2233);
  static const Color inkSoft = Color(0xFF5A6478);
  static const Color inkMuted = Color(0xFF8A93A6);

  static const Color background = Color(0xFFFAF7F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2ECE4);

  // Feedback
  static const Color success = Color(0xFF2E7D5B);
  static const Color successSoft = Color(0xFFE3F1EA);
  static const Color error = Color(0xFFB3261E);
  static const Color errorSoft = Color(0xFFF9E5E4);

  // Decade dots
  static const Color dotActive = marianBlue;
  static const Color dotCompleted = gold;
  static const Color dotUpcoming = Color(0xFFD4DAE6);

  /// Soft blue-to-white gradient used on hero surfaces.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF24489B), marianBlue],
  );

  /// Subtle gold shimmer used for small highlights.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFE3C889), gold],
  );
}