import 'dart:math'; // Random
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Used to set the status bar icon colors
import '../core/app_colors.dart';
import '../core/dedications.dart';
import '../core/arabic_text.dart';
import '../core/saved_items.dart';
import '../data/quran_data.dart';
import 'reader_screen.dart';
import 'favorites_screen.dart';

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
    final colors = context.colors;

    // Height of the system status bar. The hero image extends behind it.
    final double topInset = MediaQuery.paddingOf(context).top;
    final double heroHeight = _heroBaseHeight + topInset;

    // The hero is dark in both themes, so the status bar icons stay white here.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS
      ),
      child: Container(
        // Page background behind the content.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.backgroundTop, colors.background],
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
                      // Continue reading card: uses the saved reading position.
                      _ContinueReading(onOpenTab: onOpenTab),

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
    final colors = context.colors;

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
              'assets/images/noor_laha_home_hero.png',
              // cover fills the area without stretching the image.
              fit: BoxFit.cover,
              // Keep the illustration on the left, crop the empty right side.
              alignment: Alignment.centerLeft,
            ),
          ),

          // Extra tint over the image (transparent in light mode, dark in dark mode).
          ColoredBox(color: colors.heroTint),

          // Light dark gradient at the top so the status bar icons stay visible.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0x803A2352), Colors.transparent],
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
    final colors = context.colors;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(26),
      elevation: 4,
      shadowColor: colors.shadow,
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
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [colors.accentStrongStart, colors.accentStrongEnd],
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
                    Text(
                      'أكمل القراءة',
                      style: TextStyle(
                        color: colors.mutedText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      surahName,
                      style: TextStyle(
                        color: colors.title,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ayahText,
                      style: TextStyle(
                        color: colors.mutedText,
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
                decoration: BoxDecoration(
                  color: colors.softSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.accent,
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

// "Continue reading" card connected to the saved reading position.
class _ContinueReading extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const _ContinueReading({required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuranData>(
      future: QuranRepository.instance.load(),
      builder: (context, snapshot) {
        final QuranData? data = snapshot.data;

        // While the Quran data loads, the card just opens the Quran tab.
        if (data == null) {
          return _ContinueReadingCard(
            surahName: 'المصحف الشريف',
            ayahText: 'ابدأ القراءة',
            onTap: () => onOpenTab(1),
          );
        }

        return ValueListenableBuilder<LastRead?>(
          valueListenable: lastReadNotifier,
          builder: (context, last, _) {
            // Before the first reading we point to the start of the Quran.
            final AyahRef ref = last?.ref ?? const AyahRef(1, 1);
            final int page = last?.page ?? 1;
            final Surah surah = data.surahs[ref.surah - 1];

            return _ContinueReadingCard(
              surahName: 'سورة ${surah.name}',
              ayahText: last == null
                  ? 'ابدأ القراءة من البداية'
                  : 'الآية ${toArabicDigits(ref.ayah)} · صفحة ${toArabicDigits(page)}',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(data: data, initialPage: page),
                  ),
                );
              },
            );
          },
        );
      },
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
    final colors = context.colors;

    // Progress ratio between 0 and 1.
    final double progress = completedJuz / totalJuz;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(26),
      elevation: 2,
      shadowColor: colors.shadow,
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
                  color: colors.softSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: colors.accent,
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
                        Expanded(
                          child: Text(
                            'الورد اليومي',
                            style: TextStyle(
                              color: colors.title,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '$completedJuz من $totalJuz جزء',
                          style: TextStyle(
                            color: colors.mutedText,
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
                        backgroundColor: colors.softSurface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.accent,
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
    final colors = context.colors;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: colors.shadow,
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
                  color: colors.softSurface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: colors.accent, size: 25),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: colors.title,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.mutedText,
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


// Dedication card. The user swipes between the duas, and a random one is
// shown first every time the app opens.
class _DedicationCard extends StatefulWidget {
  const _DedicationCard();

  @override
  State<_DedicationCard> createState() => _DedicationCardState();
}

class _DedicationCardState extends State<_DedicationCard> {
  // Start from a random dua each time the app opens.
  late int _index = Random().nextInt(kDedications.length);

  // Controls the swipeable pages. It starts at the random dua above.
  late final PageController _controller = PageController(initialPage: _index);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Go to the next dua, and back to the first one after the last.
  void _next() {
    final int target = (_index + 1) % kDedications.length;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  // Copy the current dua to the clipboard.
  Future<void> _copy() async {
    // Capture the messenger before the await so we do not use context after it.
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: kDedications[_index]));
    messenger.showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الدعاء'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Light: cream fading to a soft lavender. Dark: the same idea, but we
    // lift the top corner with a purple tint, so it is visible on dark colors.
    final List<Color> gradientColors = isDark
        ? [
      Color.lerp(colors.softSurface, colors.accentStrongStart, 0.3)!,
      colors.card,
    ]
        : [colors.card, colors.softSurface.withValues(alpha: 0.6)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradientColors,
        ),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // ClipRRect cuts the watermark to the rounded corners of the card.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            // Faint plant branch watermark in the bottom-left corner.
            // Its size matches the shorter card, so it is not cut at the top.
            PositionedDirectional(
              end: -4,
              bottom: 38,
              child: CustomPaint(
                size: const Size(100, 135),
                painter: _BranchPainter(color: colors.accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(
                children: [
                  // Fixed height for the swipeable duas (up to 3 lines).
                  // Increase it if you add a long dua that needs 4 lines.
                  SizedBox(
                    height: 112,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: kDedications.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              kDedications[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.title,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.8,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Copy button (right), counter (center), next button (left).
                  Row(
                    children: [
                      _SoftIconButton(
                        icon: Icons.copy_rounded,
                        tooltip: 'نسخ الدعاء',
                        onTap: _copy,
                      ),
                      const Spacer(),
                      Text(
                        '${toArabicDigits(_index + 1)} / '
                            '${toArabicDigits(kDedications.length)}',
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _SoftIconButton(
                        icon: Icons.autorenew_rounded,
                        tooltip: 'دعاء آخر',
                        onTap: _next,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Small rounded icon button used inside the dedication card.
class _SoftIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SoftIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: colors.accent, size: 20),
          ),
        ),
      ),
    );
  }
}


// Draws a soft plant branch: a curved stem with leaves on both sides.
// It is drawn with code, so it follows the theme color (light and dark).
class _BranchPainter extends CustomPainter {
  final Color color;

  const _BranchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Stem is a quadratic curve from the bottom up to the top.
    final Offset start = Offset(size.width * 0.45, size.height);
    final Offset control = Offset(size.width * 0.1, size.height * 0.5);
    final Offset end = Offset(size.width * 0.7, size.height * 0.04);

    final Paint stemPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final Path stem = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    canvas.drawPath(stem, stemPaint);

    final Paint leafPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    // Point on the curve at t (0 = bottom, 1 = top).
    Offset pointAt(double t) {
      final double u = 1 - t;
      return Offset(
        u * u * start.dx + 2 * u * t * control.dx + t * t * end.dx,
        u * u * start.dy + 2 * u * t * control.dy + t * t * end.dy,
      );
    }

    // Direction of the stem at t, used to tilt each leaf along it.
    double angleAt(double t) {
      final double u = 1 - t;
      final double dx = 2 * u * (control.dx - start.dx) + 2 * t * (end.dx - control.dx);
      final double dy = 2 * u * (control.dy - start.dy) + 2 * t * (end.dy - control.dy);
      return atan2(dy, dx);
    }

    // Draw one leaf at t. side = 1 or -1 picks the left or right of the stem.
    void drawLeaf(double t, double side, double length) {
      final Offset p = pointAt(t);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angleAt(t) + side * 0.85);
      final double w = length * 0.32;
      final Path leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(length * 0.5, -w, length, 0)
        ..quadraticBezierTo(length * 0.5, w, 0, 0);
      canvas.drawPath(leaf, leafPaint);
      canvas.restore();
    }

    // Leaves alternate sides and get smaller toward the top.
    drawLeaf(0.28, 1, 44);
    drawLeaf(0.40, -1, 44);
    drawLeaf(0.55, 1, 38);
    drawLeaf(0.68, -1, 34);
    drawLeaf(0.82, 1, 29);
    drawLeaf(0.92, -1, 26);
    // Top leaf continues straight along the stem.
    drawLeaf(1.0, 0, 32);
  }

  @override
  bool shouldRepaint(_BranchPainter oldDelegate) => oldDelegate.color != color;
}