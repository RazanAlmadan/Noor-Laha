import 'package:flutter/material.dart';

// Colors named by ROLE (not by hue), so every role can have a different
// value in the light and dark themes.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.backgroundTop,
    required this.card,
    required this.softSurface,
    required this.accent,
    required this.accentStrongStart,
    required this.accentStrongEnd,
    required this.title,
    required this.bodyText,
    required this.mutedText,
    required this.border,
    required this.shadow,
    required this.heroTint,
  });

  final Color background; // Page background (bottom of the page gradient)
  final Color backgroundTop; // Top of the page gradient
  final Color card; // Card surfaces
  final Color softSurface; // Icon boxes, progress track, selected tab
  final Color accent; // Icons and small highlights
  final Color accentStrongStart; // Gradient start of strong accent boxes
  final Color accentStrongEnd; // Gradient end of strong accent boxes
  final Color title; // Titles and strong text
  final Color bodyText; // Normal text
  final Color mutedText; // Secondary text
  final Color border; // Thin outlines
  final Color shadow; // Card shadows
  final Color heroTint; // Extra tint over the hero image

  static const AppPalette light = AppPalette(
    background: Color(0xFFF8F2F8),
    backgroundTop: Color(0xFFE9DBEF),
    card: Color(0xFFFFF9F5),
    softSurface: Color(0xFFE9DBEF),
    accent: Color(0xFF76518D),
    accentStrongStart: Color(0xFF76518D),
    accentStrongEnd: Color(0xFF4F356A),
    title: Color(0xFF4F356A),
    bodyText: Color(0xFF382846),
    mutedText: Color(0xFF87768E),
    border: Color(0xFFDCC8E6),
    shadow: Color(0x1F76518D),
    heroTint: Color(0x00000000),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF1A1124),
    backgroundTop: Color(0xFF2B1D3D),
    card: Color(0xFF2A1D3A),
    softSurface: Color(0xFF3D2B54),
    accent: Color(0xFFC8A4DC),
    accentStrongStart: Color(0xFF8B62AB),
    accentStrongEnd: Color(0xFF5A3C78),
    title: Color(0xFFF1E6F8),
    bodyText: Color(0xFFE6DAEF),
    mutedText: Color(0xFFB8A8C4),
    border: Color(0xFF4B3866),
    shadow: Color(0x66000000),
    heroTint: Color(0x40140A1E),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? backgroundTop,
    Color? card,
    Color? softSurface,
    Color? accent,
    Color? accentStrongStart,
    Color? accentStrongEnd,
    Color? title,
    Color? bodyText,
    Color? mutedText,
    Color? border,
    Color? shadow,
    Color? heroTint,
  }) {
    return AppPalette(
      background: background ?? this.background,
      backgroundTop: backgroundTop ?? this.backgroundTop,
      card: card ?? this.card,
      softSurface: softSurface ?? this.softSurface,
      accent: accent ?? this.accent,
      accentStrongStart: accentStrongStart ?? this.accentStrongStart,
      accentStrongEnd: accentStrongEnd ?? this.accentStrongEnd,
      title: title ?? this.title,
      bodyText: bodyText ?? this.bodyText,
      mutedText: mutedText ?? this.mutedText,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      heroTint: heroTint ?? this.heroTint,
    );
  }

  // Used by Flutter to animate smoothly between light and dark.
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      backgroundTop: Color.lerp(backgroundTop, other.backgroundTop, t)!,
      card: Color.lerp(card, other.card, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrongStart:
      Color.lerp(accentStrongStart, other.accentStrongStart, t)!,
      accentStrongEnd: Color.lerp(accentStrongEnd, other.accentStrongEnd, t)!,
      title: Color.lerp(title, other.title, t)!,
      bodyText: Color.lerp(bodyText, other.bodyText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      heroTint: Color.lerp(heroTint, other.heroTint, t)!,
    );
  }
}

// Shortcut: context.colors returns the palette of the current theme.
extension AppPaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}

// LEGACY fixed colors (light only).
// Only quran_screen.dart still uses them. Delete this class when the
// Quran screen is rebuilt in the next step.
class AppColors {
  static const Color primary = Color(0xFF76518D);
  static const Color deepPurple = Color(0xFF4F356A);
  static const Color lavender = Color(0xFFBC9ACA);
  static const Color softLavender = Color(0xFFE9DBEF);
  static const Color background = Color(0xFFF8F2F8);
  static const Color cream = Color(0xFFFFF9F5);
  static const Color text = Color(0xFF382846);
  static const Color mutedText = Color(0xFF87768E);
}