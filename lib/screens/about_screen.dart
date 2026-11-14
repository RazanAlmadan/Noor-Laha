import 'package:flutter/material.dart';
import '../core/app_colors.dart';

// About screen.
// NOTE: the wording below is a placeholder.
// Replace it with the text the client approves.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'عن التطبيق',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.softLavender,
        foregroundColor: AppColors.deepPurple,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.softLavender,
              AppColors.background,
              AppColors.cream,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              // App name.
              const Text(
                'نور لها',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Short description.
              const Text(
                'تطبيق لقراءة القرآن الكريم،\n'
                    'صدقة جارية يُهدى ثوابها للمرحومة بإذن الله.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  height: 1.9,
                ),
              ),

              const SizedBox(height: 28),

              // Dedication card.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'اللهم اجعل نور القرآن\nنورًا لها في قبرها',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.deepPurple,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}