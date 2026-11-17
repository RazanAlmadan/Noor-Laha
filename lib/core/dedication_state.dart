import 'package:shared_preferences/shared_preferences.dart';

const String _lastShownKey = 'dedication_last_shown';

// Today's date as text, using the phone's local date.
String _todayKey() {
  final DateTime now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

// True if the dedication page was not shown yet today.
Future<bool> shouldShowDedication() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(_lastShownKey) != _todayKey();
}

// Called when the user taps continue, so the page stays hidden until tomorrow.
Future<void> markDedicationShown() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastShownKey, _todayKey());
}