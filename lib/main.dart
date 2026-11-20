import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'core/app_settings.dart';
import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'core/saved_items.dart';
import 'core/theme_controller.dart';
import 'core/reader_settings.dart';
import 'core/dedication_state.dart';
import 'core/tasbih_data.dart';
import 'core/tasbih_icon.dart';
import 'core/wird_data.dart';
import 'screens/wird_screen.dart';
import 'screens/tasbih_screen.dart';
import 'screens/dedication_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/quran_screen.dart';



Future<void> main() async {
  // Needed because we use plugins before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await loadReaderSettings();
  await loadSavedItems();
  await loadThemeMode();
  await loadTasbih();
  await loadWird();
  await loadAppSettings();

  // The dedication page shows once a day.
  final bool showDedication = await shouldShowDedication();
  runApp(NoorLahaApp(showDedication: showDedication));
}

// Root widget of the application.
class NoorLahaApp extends StatelessWidget {
  final bool showDedication;

  const NoorLahaApp({super.key, required this.showDedication});

  @override
  Widget build(BuildContext context) {
    // Rebuild the app whenever the theme mode changes.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'نور لها',
          debugShowCheckedModeBanner: false,

          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,

          builder: (context, child) {
            final bool isDark =
                Theme.of(context).brightness == Brightness.dark;

            // Status bar icons: light icons on dark theme, dark icons on light.
            // The home screen overrides this with its own style.
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark, // Android
                statusBarBrightness:
                isDark ? Brightness.dark : Brightness.light, // iOS
              ),
              // Force right-to-left layout for the whole app (Arabic).
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },

          home: AppRoot(showDedication: showDedication),
        );
      },
    );
  }
}

// Shows the dedication page first (once a day), then fades into the app.
class AppRoot extends StatefulWidget {
  final bool showDedication;

  const AppRoot({super.key, required this.showDedication});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late bool _showDedication = widget.showDedication;

  // Remember today, then fade into the app.
  void _finish() {
    markDedicationShown();
    setState(() => _showDedication = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _showDedication
          ? DedicationScreen(
        key: const ValueKey('dedication'),
        onContinue: _finish,
      )
          : const AppShell(key: ValueKey('shell')),
    );
  }
}

// Root widget that holds the bottom navigation bar and the tab screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    wirdNotifier.addListener(_checkWirdNotice);
    // Wait for the first frame, so the dialog can be shown.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkWirdNotice());
  }

  @override
  void dispose() {
    wirdNotifier.removeListener(_checkWirdNotice);
    super.dispose();
  }

  // Shows the "missed part of the wird" notice when there is one.
  void _checkWirdNotice() {
    if (mounted) unawaited(showWirdNoticeIfNeeded(context));
  }
  int selectedIndex = 0;

  // Switch to the tab with the given index.
  void openTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      // IndexedStack keeps all tabs alive and shows only the selected one.
      // The order here must match the order of the destinations below.
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomeScreen(onOpenTab: openTab), // 0: Home
          const QuranScreen(), // 1: Quran
          const TasbihScreen(), // 2: Tasbih // 2: Recitations
          const WirdScreen(), // 3: Daily wird // 3: Daily wird
          const MoreScreen(), // 4: More
        ],
      ),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          // Label style depends on whether the tab is selected.
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final bool selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? colors.title : colors.mutedText,
            );
          }),
          // Icon color also depends on the selected state.
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final bool selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 26,
              color: selected ? colors.title : colors.mutedText,
            );
          }),
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: selectedIndex,
          onDestinationSelected: openTab,
          backgroundColor: colors.card,
          indicatorColor: colors.softSurface,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'المصحف',
            ),
            NavigationDestination(
              icon: TasbihIcon(),
              label: 'المسبحة',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'الورد',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              selectedIcon: Icon(Icons.more_horiz_rounded),
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }
}