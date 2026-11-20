import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App version shown on the About screen. Keep it in sync with pubspec.yaml.
const String kAppVersion = '1.0.0';

// Temporary contact email until the final one is agreed.
const String kContactEmail = 'razanalmadn@gmail.com';

// Store link of the app. Leave it empty until the app is published;
// the share text is sent without a link while it is empty.
const String kShareLink = '';

const String kShareText =
    'نور لها: تطبيق لقراءة القرآن الكريم، صدقة جارية يُهدى ثوابها للمرحومة بإذن الله.';

const String _keepScreenOnKey = 'keep_screen_on';

// True when the screen should stay on while the user reads the Quran.
final ValueNotifier<bool> keepScreenOnNotifier = ValueNotifier<bool>(false);

// Call once before runApp to restore the saved settings.
Future<void> loadAppSettings() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  keepScreenOnNotifier.value = prefs.getBool(_keepScreenOnKey) ?? false;
}

// Updates the screen first, then saves on the device.
Future<void> setKeepScreenOn(bool value) async {
  keepScreenOnNotifier.value = value;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keepScreenOnKey, value);
}