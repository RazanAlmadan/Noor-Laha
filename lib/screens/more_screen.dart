import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'about_screen.dart';
import 'favorites_screen.dart';

// "More" tab: favorites, settings and about.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  // Temporary message for screens that are not built yet.
  void _showSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سنجهز هذه الصفحة قريبًا بإذن الله'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
            AppColors.cream,
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            const Text(
              'المزيد',
              style: TextStyle(
                color: AppColors.deepPurple,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            // Navigator.push opens a screen on top of the current one.
            // The back button returns to this screen.
            _MoreTile(
              icon: Icons.favorite_border_rounded,
              title: 'المفضلة',
              subtitle: 'آياتك وسورك المحفوظة',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FavoritesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _MoreTile(
              icon: Icons.settings_outlined,
              title: 'الإعدادات',
              subtitle: 'المظهر وحجم الخط',
              onTap: () => _showSoon(context),
            ),

            const SizedBox(height: 12),

            _MoreTile(
              icon: Icons.info_outline_rounded,
              title: 'عن التطبيق',
              subtitle: 'صدقة جارية',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// One row in the "More" list.
class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(22),
      elevation: 1.5,
      shadowColor: AppColors.primary.withValues(alpha: 0.10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.deepPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}