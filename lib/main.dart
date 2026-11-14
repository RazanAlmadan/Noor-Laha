import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'core/theme_controller.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/upcoming_screen.dart';

void main() {
  runApp(const NoorLahaApp());
}

// Root widget of the application.
class NoorLahaApp extends StatelessWidget {
  const NoorLahaApp({super.key});

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

          home: const AppShell(),
        );
      },
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
          const UpcomingScreen(
            title: 'التلاوات',
            icon: Icons.headphones_rounded,
          ), // 2: Recitations
          const UpcomingScreen(
            title: 'الورد اليومي',
            icon: Icons.calendar_month_rounded,
          ), // 3: Daily wird
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
              icon: Icon(Icons.headphones_outlined),
              selectedIcon: Icon(Icons.headphones_rounded),
              label: 'التلاوات',
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