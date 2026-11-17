import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'theme_mode';

// Holds the current theme mode. The whole app listens to it.
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.system);

// Call once before runApp to restore the saved theme.
Future<void> loadThemeMode() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  themeModeNotifier.value =
      ThemeMode.values.asNameMap()[prefs.getString(_themeModeKey)] ??
          ThemeMode.system;
}

// Updates the screen first, then saves the choice on the device.
Future<void> setThemeMode(ThemeMode mode) async {
  themeModeNotifier.value = mode;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeModeKey, mode.name);
}