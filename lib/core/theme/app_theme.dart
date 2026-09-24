import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the single [ThemeData] used by the whole app.
///
/// Brand, radii, spacing and component shapes are centralised here so the UI
/// stays visually consistent and easy to update later.
abstract final class AppTheme {
  static ThemeData get light => _build(
    const ColorScheme.light(
      primary: AppColors.marianBlue,
      onPrimary: AppColors.surface,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      error: AppColors.error,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.surfaceMuted,
      onSurfaceVariant: AppColors.inkSoft,
      outlineVariant: Color(0xFFE1E6F0),
      outline: Color(0xFF8A93A6),
    ),
    filledButtonBackground: AppColors.marianBlue,
    filledButtonForeground: AppColors.surface,
    outlinedButtonForeground: AppColors.marianBlue,
    outlinedButtonSide: AppColors.marianBlueSoft,
    textButtonForeground: AppColors.marianBlue,
    navIndicator: AppColors.marianBlueSoft,
  );

  /// Full dark-mode palette. Prayer screens stay high contrast and readable.
  static ThemeData get dark => _build(
    const ColorScheme.dark(
      primary: Color(0xFF8FA8E0),
      onPrimary: Color(0xFF16224A),
      secondary: AppColors.gold,
      onSecondary: Color(0xFF241B06),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF3B0906),
      surface: Color(0xFF171E30),
      onSurface: Color(0xFFE7ECF8),
      surfaceContainerHighest: Color(0xFF232B40),
      onSurfaceVariant: Color(0xFF9AA6C2),
      outlineVariant: Color(0xFF2A3245),
      outline: Color(0xFF4A5570),
    ),
    filledButtonBackground: const Color(0xFF5B79CE),
    filledButtonForeground: Colors.white,
    outlinedButtonForeground: const Color(0xFF8FA8E0),
    outlinedButtonSide: const Color(0xFF3A4A78),
    textButtonForeground: const Color(0xFF8FA8E0),
    navIndicator: const Color(0xFF2C3A5E),
    cardBorder: const Color(0xFF2A3245),
  );

  static ThemeData _build(
    ColorScheme scheme, {
    required Color filledButtonBackground,
    required Color filledButtonForeground,
    required Color outlinedButtonForeground,
    required Color outlinedButtonSide,
    required Color textButtonForeground,
    required Color navIndicator,
    Color? cardBorder,
  }) {
    final brightness = scheme.brightness;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF0F1526)
          : AppColors.background,
      textTheme: AppTypography.textTheme(brightness),
      fontFamily: 'Poppins',
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF0F1526)
            : AppColors.background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          letterSpacing: 0.1,
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: cardBorder ?? const Color(0xFFE9EDF4)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: filledButtonBackground,
          foregroundColor: filledButtonForeground,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.textTheme(brightness).labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: outlinedButtonForeground,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: outlinedButtonSide),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.textTheme(brightness).labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textButtonForeground,
          textStyle: AppTypography.textTheme(brightness).labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: navIndicator,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.textTheme(brightness).labelSmall,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : null,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      dividerColor: cardBorder ?? const Color(0xFFE9EDF4),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}