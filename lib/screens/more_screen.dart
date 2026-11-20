import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_colors.dart';
import '../core/app_settings.dart';
import '../core/theme_controller.dart';
import 'about_screen.dart';
import 'favorites_screen.dart';

// "More" tab: favorites, theme, reading options, share, contact and about.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

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

  // Opens the share sheet with a short text (and the store link, once set).
  Future<void> _shareApp() async {
    final String text =
    kShareLink.isEmpty ? kShareText : '$kShareText\n$kShareLink';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  // Opens the mail app. If there is none, copies the address instead.
  Future<void> _contactUs(BuildContext context) async {
    final Uri uri = Uri.parse(
      'mailto:$kContactEmail'
          '?subject=${Uri.encodeComponent('تواصل بخصوص تطبيق نور لها')}',
    );

    bool opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }
    if (opened || !context.mounted) return;

    await Clipboard.setData(const ClipboardData(text: kContactEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لم نجد تطبيق بريد، نسخنا العنوان لك: $kContactEmail'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

            // Keep the screen on while reading the Quran.
            ValueListenableBuilder<bool>(
              valueListenable: keepScreenOnNotifier,
              builder: (context, on, _) {
                return _MoreTile(
                  icon: Icons.light_mode_outlined,
                  title: 'إبقاء الشاشة مضاءة',
                  subtitle: 'أثناء القراءة في المصحف',
                  onTap: () => setKeepScreenOn(!on),
                  trailing: Switch(
                    value: on,
                    onChanged: setKeepScreenOn,
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _MoreTile(
              icon: Icons.ios_share_rounded,
              title: 'مشاركة التطبيق',
              subtitle: 'شاركيه صدقة جارية',
              onTap: _shareApp,
            ),

            const SizedBox(height: 12),

            _MoreTile(
              icon: Icons.mail_outline_rounded,
              title: 'تواصل معنا',
              subtitle: 'اقتراح أو ملاحظة',
              onTap: () => _contactUs(context),
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

// One row in the "More" list. [trailing] replaces the arrow (for a switch).
class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
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

              trailing ??
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