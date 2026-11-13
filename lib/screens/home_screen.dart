import 'package:flutter/material.dart';
import '../core/app_colors.dart';

// Home screen of Noor Laha application
class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const HomeScreen({
    super.key,
    required this.onOpenTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Apply a soft purple background gradient
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
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            // Display the welcome message
            const _HomeHeader(),

            const SizedBox(height: 22),

            // Display the main illustrated banner
            const _IllustratedHero(),

            const SizedBox(height: 28),

            // Display the main section title
            const Text(
              'رحلتك مع القرآن الكريم',
              style: TextStyle(
                color: AppColors.deepPurple,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'اختر من أين تحب أن تبدأ اليوم',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            // Display the application features in a grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _FeatureCard(
                  title: 'المصحف',
                  subtitle: 'قراءة القرآن الكريم',
                  icon: Icons.menu_book_rounded,
                  onTap: () => onOpenTab(1),
                ),
                _FeatureCard(
                  title: 'التلاوات',
                  subtitle: 'استمع لتلاوات مختارة',
                  icon: Icons.headphones_rounded,
                  onTap: () => onOpenTab(2),
                ),
                _FeatureCard(
                  title: 'الورد اليومي',
                  subtitle: 'رحلتك اليومية مع القرآن',
                  icon: Icons.calendar_month_rounded,
                  onTap: () => onOpenTab(3),
                ),
                _FeatureCard(
                  title: 'المفضلة',
                  subtitle: 'آياتك المحفوظة',
                  icon: Icons.favorite_border_rounded,
                  onTap: () => onOpenTab(4),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Display the closing inspirational message
            const _ClosingMessage(),
          ],
        ),
      ),
    );
  }
}

// Display the welcome header
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'السلام عليكم ♡',
                style: TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'مرحبًا بك في نور لها',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Display the decorative crescent icon
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(
            Icons.nightlight_round,
            color: AppColors.primary,
            size: 25,
          ),
        ),
      ],
    );
  }
}


// Display the illustrated home banner
class _IllustratedHero extends StatelessWidget {
  const _IllustratedHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,

      // Apply rounded corners and a soft shadow
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepPurple.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),

        child: Stack(
          fit: StackFit.expand,
          children: [
            // Display the illustrated background
            Image.asset(
              'assets/images/noor_laha_home_hero.png',
              fit: BoxFit.fill,
            ),

            // Display the banner text on the right
            Row(
              children: [
                Expanded(
                  flex: 43,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 10,
                      end: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display the main title
                        const Text(
                          'نورٌ لها\nوأثرٌ يبقى',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Display the supporting message
                        const Text(
                          'مع كل آية تُقرأ\nتشرق سكينة جديدة',
                          style: TextStyle(
                            color: Color(0xFFF8EAF5),
                            fontSize: 11,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Keep the left side clear for the illustration
                const Expanded(
                  flex: 57,
                  child: SizedBox(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



// Reusable card for application features
class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(25),
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.12),
      child: InkWell(
        // Handle navigation when the user taps the card
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display the feature icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF0E4F3),
                      Color(0xFFE6D5ED),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  icon,
                  size: 29,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 12),

              // Display the feature title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              // Display the feature description
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
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

// Display a gentle message at the bottom of the page
class _ClosingMessage extends StatelessWidget {
  const _ClosingMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.softLavender,
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 27,
          ),
          SizedBox(height: 12),
          Text(
            'نورٌ يُتلى، وأثرٌ يبقى',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.deepPurple,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'رحلة هادئة مع القرآن الكريم، تبدأ بآية وتستمر بأثر جميل.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              height: 1.8,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}