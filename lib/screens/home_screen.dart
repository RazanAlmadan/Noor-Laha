import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Used to set the status bar icon colors
import '../core/app_colors.dart';
import 'favorites_screen.dart';
import '../core/dedications.dart';
import 'dart:math'; // Needed for Random

// Hero image height, not counting the status bar. Increase it for a taller image.
const double _heroBaseHeight = 270;

// How far the cards overlap the bottom of the hero image.
const double _heroOverlap = 36;

// Home screen of the Noor Laha app.
class HomeScreen extends StatelessWidget {
  // Callback used to switch to a tab in the bottom bar (0 = home, 1 = Quran, ...).
  final ValueChanged<int> onOpenTab;

  const HomeScreen({
    super.key,
    required this.onOpenTab,
  });

  // Opens the favorites screen on top of the current tab.
  void _openFavorites(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Height of the system status bar. The hero image extends behind it.
    final double topInset = MediaQuery.paddingOf(context).top;
    final double heroHeight = _heroBaseHeight + topInset;

    // AnnotatedRegion keeps the status bar icons white over the purple image.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS
      ),
      child: Container(
        // Page background behind the content.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.cream,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Stack layers its children: image, then hero texts, then cards.
            Stack(
              children: [
                // 1) Hero image at the back.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: heroHeight,
                  child: const _HeroImage(),
                ),

                // 2) Hero text and icon buttons on top of the image.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _HeroContent(
                    topInset: topInset,
                    onBookmarkTap: () => _openFavorites(context),
                    onSettingsTap: () => onOpenTab(4), // "More" tab (settings)
                  ),
                ),

                // 3) Cards, pushed down by (hero height - overlap).
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    heroHeight - _heroOverlap,
                    18,
                    28,
                  ),
                  child: Column(
                    // stretch makes every card take the full width.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Continue reading card (static values for now,
                      // we will connect it to the real reading position later).
                      _ContinueReadingCard(
                        surahName: 'سورة البقرة',
                        ayahText: 'الآية 25',
                        onTap: () => onOpenTab(1),
                      ),

                      const SizedBox(height: 14),

                      // Daily wird card with a progress bar.
                      _DailyWirdCard(
                        completedJuz: 5,
                        totalJuz: 30,
                        onTap: () => onOpenTab(3),
                      ),

                      const SizedBox(height: 14),

                      // Two small cards side by side.
                      // IntrinsicHeight makes both cards the same height.
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _SmallFeatureCard(
                                title: 'التلاوات',
                                subtitle: 'استمع لتلاوات مختارة',
                                icon: Icons.headphones_rounded,
                                onTap: () => onOpenTab(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SmallFeatureCard(
                                title: 'المفضلة',
                                subtitle: 'آياتك وسورك المحفوظة',
                                icon: Icons.favorite_border_rounded,
                                onTap: () => _openFavorites(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Dedication card.
                      const _DedicationCard(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Hero image with rounded bottom corners.
class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // Round only the two bottom corners.
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(32),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Scale the image up 6% from the right edge. This crops the left edge
          // and hides the light corners baked into the original image.
          Transform.scale(
            scale: 1.06,
            alignment: Alignment.centerRight,
            child: Image.asset(
              // Same path that is registered in pubspec.yaml.
              'assets/images/noor_laha_home_hero.png',
              // cover fills the area without stretching the image.
              fit: BoxFit.cover,
              // Keep the illustration on the left, crop the empty right side.
              alignment: Alignment.centerLeft,
            ),
          ),

          // Light dark gradient at the top so the status bar icons stay visible.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  AppColors.deepPurple.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Texts and icon buttons displayed over the hero image.
class _HeroContent extends StatelessWidget {
  final double topInset;
  final VoidCallback onBookmarkTap;
  final VoidCallback onSettingsTap;

  const _HeroContent({
    required this.topInset,
    required this.onBookmarkTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // topInset moves everything below the status bar.
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero text on the right (42% of the width so it stays off the artwork).
          Expanded(
            flex: 42,
            child: const Padding(
              // Pushes the text down to the middle of the image. Tune the 40.
              padding: EdgeInsets.only(top: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نورٌ لها\nوأثرٌ يبقى',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'مع كل آية تُقرأ\nتشرق سكينة جديدة',
                    style: TextStyle(
                      color: Color(0xFFF1E4F5),
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Icon buttons on the left.
          Expanded(
            flex: 58,
            child: Row(
              // In RTL, "end" means the left side.
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _GlassIconButton(
                  icon: Icons.settings_outlined,
                  onTap: onSettingsTap,
                ),
                const SizedBox(width: 10),
                _GlassIconButton(
                  icon: Icons.bookmark_border_rounded,
                  onTap: onBookmarkTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Icon button with a semi-transparent background.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// Wide "continue reading" card.
class _ContinueReadingCard extends StatelessWidget {
  final String surahName;
  final String ayahText;
  final VoidCallback onTap;

  const _ContinueReadingCard({
    required this.surahName,
    required this.ayahText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(26),
      elevation: 4,
      shadowColor: AppColors.deepPurple.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon box with a purple gradient.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppColors.primary, AppColors.deepPurple],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              // Texts.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أكمل القراءة',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      surahName,
                      style: const TextStyle(
                        color: AppColors.deepPurple,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ayahText,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow circle.
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.softLavender,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Daily wird card with a progress bar.
class _DailyWirdCard extends StatelessWidget {
  final int completedJuz;
  final int totalJuz;
  final VoidCallback onTap;

  const _DailyWirdCard({
    required this.completedJuz,
    required this.totalJuz,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Progress ratio between 0 and 1.
    final double progress = completedJuz / totalJuz;

    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(26),
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  children: [
                    // Title on the right, count on the left.
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'الورد اليومي',
                            style: TextStyle(
                              color: AppColors.deepPurple,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '$completedJuz من $totalJuz جزء',
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Progress bar with rounded ends.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.softLavender,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
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

// Small card (used for recitations and favorites).
class _SmallFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary, size: 25),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dedication card. It shows a different dua every time the app opens,
// and the button lets the user switch to the next one.
class _DedicationCard extends StatefulWidget {
  const _DedicationCard();

  @override
  State<_DedicationCard> createState() => _DedicationCardState();
}

class _DedicationCardState extends State<_DedicationCard> {
  // Picked once when the card is created. It stays the same while the app
  // is open, until the user taps the button.
  late int _index = Random().nextInt(kDedications.length);

  // Move to the next dua (and go back to the first one after the last).
  void _next() {
    setState(() {
      _index = (_index + 1) % kDedications.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.softLavender, Color(0xFFF3E9F6)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.lavender.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.favorite_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(height: 10),
          const Text(
            'صدقة جارية',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),

          // minHeight keeps the card from jumping when the dua length changes.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 110),
            child: Center(
              // AnimatedSwitcher fades from the old dua to the new one.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  kDedications[_index],
                  // A different key tells Flutter this is a new widget,
                  // which is what triggers the fade animation.
                  key: ValueKey<int>(_index),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.deepPurple,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ),

          // Button to show the next dua (bottom-left in RTL).
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              onPressed: _next,
              tooltip: 'دعاء آخر',
              icon: const Icon(
                Icons.autorenew_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}