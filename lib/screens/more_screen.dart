import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/theme_controller.dart';
import 'about_screen.dart';
import 'favorites_screen.dart';

// "More" tab: favorites, theme, settings and about.
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

  // Cycle the theme: system -> light -> dark -> system.
  void _cycleTheme() {
    themeModeNotifier.value = switch (themeModeNotifier.value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'تلقائي (حسب الجهاز)',
      ThemeMode.light => 'فاتح',
      ThemeMode.dark => 'داكن',
    };
  }

  IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.backgroundTop, colors.background],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            Text(
              'المزيد',
              style: TextStyle(
                color: colors.title,
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

            // ValueListenableBuilder rebuilds only this tile when the mode changes.
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) {
                return _MoreTile(
                  icon: _themeIcon(mode),
                  title: 'المظهر',
                  subtitle: _themeLabel(mode),
                  onTap: _cycleTheme,
                );
              },
            ),

            const SizedBox(height: 12),

            _MoreTile(
              icon: Icons.settings_outlined,
              title: 'الإعدادات',
              subtitle: 'حجم الخط وغيرها',
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
    final colors = context.colors;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(22),
      elevation: 1.5,
      shadowColor: colors.shadow,
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
                  color: colors.softSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colors.accent, size: 26),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.title,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.accent,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}