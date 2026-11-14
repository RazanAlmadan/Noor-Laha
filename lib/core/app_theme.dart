import 'package:flutter/material.dart';
import 'app_colors.dart';

// Builds the light and dark ThemeData of the app.
class AppTheme {
  const AppTheme._();

  static final ThemeData light = _build(Brightness.light, AppPalette.light);
  static final ThemeData dark = _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    return ThemeData(
      useMaterial3: true,

      // Default font for the whole app (declared in pubspec.yaml).
      fontFamily: 'Tajawal',

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: palette.background,

      // Our own colors, read in widgets with context.colors.
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }
}