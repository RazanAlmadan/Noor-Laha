import 'package:flutter/material.dart';

import 'core/app_colors.dart';
import 'screens/home_screen.dart';
import 'screens/quran_screen.dart';

void main() {
  runApp(const NoorLahaApp());
}

// Main application widget
class NoorLahaApp extends StatelessWidget {
  const NoorLahaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نور لها',
      debugShowCheckedModeBanner: false,

      // Apply the application theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),

      // Force right-to-left layout for Arabic content
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },

      home: const AppShell(),
    );
  }
}

// Root widget that manages bottom navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  // Navigate to the selected tab
  void openTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomeScreen(onOpenTab: openTab),
          const QuranScreen(),
          const UpcomingScreen(
            title: 'التلاوات',
            icon: Icons.headphones_rounded,
          ),
          const UpcomingScreen(
            title: 'الورد اليومي',
            icon: Icons.calendar_month_rounded,
          ),
          const UpcomingScreen(
            title: 'المفضلة',
            icon: Icons.favorite_rounded,
          ),
        ],
      ),

      // Display the bottom navigation bar
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 10),
          ),
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: selectedIndex,
          onDestinationSelected: openTab,
          backgroundColor: AppColors.cream,
          indicatorColor: AppColors.softLavender,
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
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'المفضلة',
            ),
          ],
        ),
      ),
    );
  }
}

// Temporary screen for sections we will build later
class UpcomingScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const UpcomingScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.softLavender,
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'سنجهز هذه الصفحة قريبًا بإذن الله',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}