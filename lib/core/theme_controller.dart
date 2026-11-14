import 'package:flutter/material.dart';

// Holds the current theme mode. The whole app listens to it.
// It is not saved yet, we will persist it in the settings step.
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.system);