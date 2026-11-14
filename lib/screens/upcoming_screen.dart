import 'package:flutter/material.dart';
import '../core/app_colors.dart';

// Temporary screen for sections that are not built yet.
class UpcomingScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  // True when the screen is opened on top of another screen.
  // It shows an app bar with a back button.
  final bool showBackButton;

  const UpcomingScreen({
    super.key,
    required this.title,
    required this.icon,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show an app bar only when there is a previous screen to go back to.
      appBar: showBackButton
          ? AppBar(
        backgroundColor: AppColors.softLavender,
        foregroundColor: AppColors.deepPurple,
        elevation: 0,
        scrolledUnderElevation: 0,
      )
          : null,
      body: Container(
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'سنجهز هذه الصفحة قريبًا بإذن الله',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}