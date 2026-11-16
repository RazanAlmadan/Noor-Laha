import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// How the pages are shown: swipe like a book, or scroll up and down.
enum ReaderViewMode { pages, scroll }

// The Quran font the user can choose.
enum ReaderFont { amiriQuran, scheherazade }

// Maps each choice to the font family name registered in pubspec.yaml.
String fontFamilyOf(ReaderFont font) {
  switch (font) {
    case ReaderFont.amiriQuran:
      return 'AmiriQuran';
    case ReaderFont.scheherazade:
      return 'ScheherazadeNew';
  }
}

// Font size limits and default.
const double kMinFontSize = 20;
const double kMaxFontSize = 44;
const double kDefaultFontSize = 28;

const String _fontSizeKey = 'reader_font_size';
const String _fontKey = 'reader_font';
const String _viewModeKey = 'reader_view_mode';

// Widgets listen to these, so they rebuild when a setting changes.
final ValueNotifier<double> readerFontSizeNotifier =
ValueNotifier<double>(kDefaultFontSize);
final ValueNotifier<ReaderFont> readerFontNotifier =
ValueNotifier<ReaderFont>(ReaderFont.amiriQuran);
final ValueNotifier<ReaderViewMode> readerViewModeNotifier =
ValueNotifier<ReaderViewMode>(ReaderViewMode.pages);

// Call once before runApp to restore the saved settings.
Future<void> loadReaderSettings() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final double size = prefs.getDouble(_fontSizeKey) ?? kDefaultFontSize;
  readerFontSizeNotifier.value =
      size.clamp(kMinFontSize, kMaxFontSize).toDouble();

  readerFontNotifier.value =
      ReaderFont.values.asNameMap()[prefs.getString(_fontKey)] ??
          ReaderFont.amiriQuran;

  readerViewModeNotifier.value =
      ReaderViewMode.values.asNameMap()[prefs.getString(_viewModeKey)] ??
          ReaderViewMode.pages;
}

// Each setter updates the screen first, then saves on the device.
Future<void> setReaderFontSize(double size) async {
  final double clamped = size.clamp(kMinFontSize, kMaxFontSize).toDouble();
  readerFontSizeNotifier.value = clamped;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_fontSizeKey, clamped);
}

Future<void> setReaderFont(ReaderFont font) async {
  readerFontNotifier.value = font;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(_fontKey, font.name);
}

Future<void> setReaderViewMode(ReaderViewMode mode) async {
  readerViewModeNotifier.value = mode;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(_viewModeKey, mode.name);
}