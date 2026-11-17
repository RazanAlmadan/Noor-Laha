import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/dedications.dart';
import '../core/reader_settings.dart';
import '../data/quran_data.dart';
import 'reader_screen.dart';

// Background pieces: the plate is cut in three so only the middle stretches.
const String _kTopImage = 'assets/images/dedication/dedication_top.jpg';
const String _kMidImage = 'assets/images/dedication/dedication_mid.jpg';
const String _kBottomImage = 'assets/images/dedication/dedication_bottom.jpg';
const String _kFlowersImage = 'assets/images/dedication/dedication_flowers.png';

// Size of the original plate and where it is cut (in plate pixels).
const double _kPlateWidth = 838;
const double _kTopSlice = 520;
const double _kBottomSlice = 446;

// This page has its own light look in both themes, so it uses fixed colors.
const Color _kTitle = Color(0xFF4F356A);
const Color _kBody = Color(0xFF32213F);
const Color _kAccent = Color(0xFF6A4683);
const Color _kMuted = Color(0xFF5E4A6B);

// Which mark closes each ayah: teardrop (like the reference picture) or
// numbered (the ornate number from the Quran reader).
enum _MarkerStyle { teardrop, numbered }

const _MarkerStyle _kMarker = _MarkerStyle.numbered;

// Opening page: the name of the deceased and Surat Al-Fatiha.
class DedicationScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const DedicationScreen({super.key, required this.onContinue});

  @override
  State<DedicationScreen> createState() => _DedicationScreenState();
}

class _DedicationScreenState extends State<DedicationScreen> {
  late final Future<QuranData> _data = QuranRepository.instance.load();
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load the pictures before the first frame, so nothing pops in.
    if (_precached) return;
    _precached = true;
    for (final String path in [
      _kTopImage,
      _kMidImage,
      _kBottomImage,
      _kFlowersImage,
    ]) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The background is light, so the status bar icons must be dark.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFD9C8EA),
        body: LayoutBuilder(
          builder: (context, box) {
            final double w = box.maxWidth;
            final double h = box.maxHeight;

            // Everything is measured from the screen width.
            final double s = w / _kPlateWidth;
            final double topH = _kTopSlice * s;
            final double bottomH = _kBottomSlice * s;
            final double midH = math.max(0.0, h - topH - bottomH);

            // The text grows a little on wide phones, within limits.
            final double fontSize = (20 * w / 390).clamp(17.0, 26.0);

            return Stack(
              children: [
                // Middle piece first, so it hides any hairline between pieces.
                Positioned(
                  top: topH - 1,
                  left: 0,
                  width: w,
                  height: midH + 2,
                  child: Image.asset(_kMidImage, fit: BoxFit.fill),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  width: w,
                  height: topH,
                  child: Image.asset(_kTopImage, fit: BoxFit.fill),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  width: w,
                  height: bottomH,
                  child: Image.asset(_kBottomImage, fit: BoxFit.fill),
                ),

                // Golden arch and crescent, drawn with code.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _ArchPainter(scale: s)),
                  ),
                ),

                // Lavender in the bottom-left corner.
                Positioned(
                  left: -4,
                  bottom: -4,
                  width: math.min(w * 0.385, 260),
                  child: IgnorePointer(
                    child: Image.asset(
                      _kFlowersImage,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),

                // The text scrolls on short phones; the button stays at the bottom.
                Positioned.fill(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          // The text starts under the crescent.
                          padding: EdgeInsets.fromLTRB(26, 318 * s, 26, 12),
                          child: _FadeIn(
                            disabled: reduceMotion,
                            child: _Content(data: _data, fontSize: fontSize),
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: _ContinueButton(onTap: widget.onContinue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Small fade-in with a light upward move. It is skipped if the phone asks for
// reduced motion.
class _FadeIn extends StatelessWidget {
  final bool disabled;
  final Widget child;

  const _FadeIn({required this.disabled, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: disabled ? 1 : 0, end: 1),
      duration: disabled ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// The opening words, the name, and Al-Fatiha.
class _Content extends StatelessWidget {
  final Future<QuranData> data;
  final double fontSize;

  const _Content({required this.data, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'رحم الله من قرأ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: _kAccent,
            fontSize: 19,
            height: 1.3,
          ),
        ),
        // Pulled up a little, because this font has a lot of space above it.
        Transform.translate(
          offset: const Offset(0, -6),
          child: const Text(
            'سورة الفاتحة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              color: _kTitle,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'وأهداها إلى روح المرحومة الشابة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: _kMuted,
            fontSize: 17,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          kDedicationName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: _kTitle,
            fontSize: 23,
            fontWeight: FontWeight.bold,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'وإلى أرواح المؤمنين والمؤمنات',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: _kMuted,
            fontSize: 17,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 18),
        FutureBuilder<QuranData>(
          future: data,
          builder: (context, snapshot) {
            final QuranData? quran = snapshot.data;
            // Keep the space while loading, so the text does not jump.
            if (quran == null) return const SizedBox(height: 220);
            return _Fatiha(data: quran, fontSize: fontSize);
          },
        ),
      ],
    );
  }
}

// Surat Al-Fatiha: the basmala alone on its line, then the ayahs flowing
// together with a star after each ayah.
class _Fatiha extends StatelessWidget {
  final QuranData data;
  final double fontSize;

  const _Fatiha({required this.data, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final Surah fatiha = data.surahs[0];
    final String family = fontFamilyOf(readerFontNotifier.value);

    // The basmala is shown by itself. In some data it is the first ayah,
    // in some it is kept in a separate field.
    final String basmala;
    final List<String> ayahs;
    if (fatiha.showsBasmalaHeader) {
      basmala = data.basmala;
      ayahs = fatiha.ayahs;
    } else {
      basmala = fatiha.ayahs.first;
      ayahs = fatiha.ayahs.sublist(1);
    }

    final TextStyle base = TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      height: 1.85,
      color: _kBody,
    );

    // Number of the first ayah after the basmala (for the numbered marks).
    final int firstNumber = fatiha.showsBasmalaHeader ? 1 : 2;

    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: quranAyahSpans(
              basmala,
              fontSize: fontSize,
              family: family,
              signColor: _kAccent,
            ),
          ),
          textAlign: TextAlign.center,
          style: base,
        ),
        // All the ayahs in one paragraph, with a mark after each one.
        Text.rich(
          TextSpan(
            children: [
              for (int i = 0; i < ayahs.length; i++) ...[
                ...quranAyahSpans(
                  ayahs[i],
                  fontSize: fontSize,
                  family: family,
                  signColor: _kAccent,
                ),
                // RLM keeps the mark as its own piece, next to its ayah.
                const TextSpan(text: ' \u200F'),
                if (_kMarker == _MarkerStyle.teardrop)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _AyahStar(size: fontSize * 0.85),
                  )
                else
                  TextSpan(
                    text: String.fromCharCode(0xE000 + firstNumber + i),
                    style: TextStyle(
                      fontFamily: 'AyahMarker',
                      fontSize: fontSize,
                      color: _kAccent,
                      height: 0.01,
                    ),
                  ),
                const TextSpan(text: '\u200F '),
              ],
            ],
          ),
          textAlign: TextAlign.center,
          style: base,
        ),
      ],
    );
  }
}

// The small star that marks the end of an ayah (drawn, not a font symbol).
class _AyahStar extends StatelessWidget {
  final double size;

  const _AyahStar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      child: SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: _StarPainter()),
      ),
    );
  }
}

// Eight teardrop petals with round tips, like the star in the reference.
class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Paint paint = Paint()
      ..color = _kAccent
      ..style = PaintingStyle.fill;

    // One petal pointing up: a round tip joined to the center by a narrow body.
    final Path petal = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(0, -r * 0.68), radius: r * 0.3),
      )
      ..moveTo(0, 0)
      ..lineTo(-r * 0.2, -r * 0.55)
      ..lineTo(r * 0.2, -r * 0.55)
      ..close();

    canvas.save();
    canvas.translate(r, r);
    for (int i = 0; i < 8; i++) {
      canvas.drawPath(petal, paint);
      canvas.rotate(math.pi / 4);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ContinueButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9170AB), Color(0xFF76518D)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF76518D).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: const Center(
              child: Text(
                'متابعة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Draws the golden arch outline and the crescent.
// All numbers are in plate pixels (838 wide) and are multiplied by [scale],
// so the shapes keep the same proportions on every screen width.
class _ArchPainter extends CustomPainter {
  final double scale;

  const _ArchPainter({required this.scale});

  // Horizontal center of the arch. The right side is the mirror of the left.
  static const double _centerX = 418;

  // Where the straight walls end: the line fades out between these two.
  static const double _fadeStart = 515;
  static const double _wallEnd = 849;

  // Left half of the arch outline, from the tip down to the wall.
  static const List<Offset> _left = [
    Offset(416.7, 22.0), Offset(415.5, 28.0), Offset(413.4, 34.0), Offset(410.3, 40.0),
    Offset(406.2, 46.0), Offset(401.5, 52.0), Offset(396.4, 58.0), Offset(390.6, 64.0),
    Offset(384.3, 70.0), Offset(377.4, 76.0), Offset(369.8, 82.0), Offset(361.4, 88.0),
    Offset(352.4, 94.0), Offset(342.5, 100.0), Offset(331.9, 106.0), Offset(320.6, 112.0),
    Offset(308.6, 118.0), Offset(296.1, 124.0), Offset(283.3, 130.0), Offset(270.4, 136.0),
    Offset(257.4, 142.0), Offset(244.7, 148.0), Offset(232.2, 154.0), Offset(220.5, 160.0),
    Offset(209.3, 166.0), Offset(198.8, 172.0), Offset(188.8, 178.0), Offset(179.5, 184.0),
    Offset(170.9, 190.0), Offset(162.8, 196.0), Offset(155.0, 202.0), Offset(147.6, 208.0),
    Offset(140.6, 214.0), Offset(134.1, 220.0), Offset(128.0, 226.0), Offset(122.0, 232.0),
    Offset(116.5, 238.0), Offset(111.5, 244.0), Offset(106.8, 250.0), Offset(102.2, 256.0),
    Offset(98.1, 262.0), Offset(94.2, 268.0), Offset(90.5, 274.0), Offset(87.2, 280.0),
    Offset(84.0, 286.0), Offset(81.4, 292.0), Offset(78.7, 298.0), Offset(76.4, 304.0),
    Offset(74.5, 310.0), Offset(73.0, 316.0), Offset(71.6, 322.0), Offset(70.5, 328.0),
    Offset(69.6, 334.0), Offset(69.1, 340.0), Offset(69.1, 346.0), Offset(69.4, 352.0),
    Offset(69.6, 358.0), Offset(65.1, 364.0), Offset(56.4, 370.0), Offset(49.5, 376.0),
    Offset(44.1, 382.0), Offset(40.2, 388.0), Offset(37.4, 394.0), Offset(35.1, 400.0),
    Offset(33.7, 406.0), Offset(33.0, 412.0), Offset(32.6, 418.0), Offset(32.5, 424.0),
    Offset(32.5, 430.0), Offset(32.5, 436.0), Offset(32.5, 442.0), Offset(32.5, 448.0),
    Offset(32.5, 454.0),
  ];

  // One side of the outline as a smooth path, ending with the straight wall.
  Path _outline({required bool mirrored}) {
    Offset at(Offset p) {
      final double x = mirrored ? 2 * _centerX - p.dx : p.dx;
      return Offset(x * scale, p.dy * scale);
    }

    final Path path = Path();
    // Both sides start at the tip of the arch.
    path.moveTo(_centerX * scale, 20 * scale);

    // Quadratic curves through the middle of each pair of points
    // make the outline smooth instead of a broken line.
    for (int i = 0; i < _left.length - 1; i++) {
      final Offset p = at(_left[i]);
      final Offset next = at(_left[i + 1]);
      path.quadraticBezierTo(
        p.dx,
        p.dy,
        (p.dx + next.dx) / 2,
        (p.dy + next.dy) / 2,
      );
    }

    final Offset last = at(_left.last);
    path.lineTo(last.dx, _wallEnd * scale);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // The line is opaque near the top and fades out down the walls.
    ui.Shader fade(Color color) {
      return ui.Gradient.linear(
        Offset(0, _fadeStart * scale),
        Offset(0, _wallEnd * scale),
        [color, color.withValues(alpha: 0)],
      );
    }

    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4)
      ..shader = fade(const Color(0x8CFFDCA8));

    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = fade(const Color(0xF2FFF0DC));

    for (final bool mirrored in [false, true]) {
      final Path outline = _outline(mirrored: mirrored);
      canvas.drawPath(outline, glow);
      canvas.drawPath(outline, line);
    }

    _paintCrescent(canvas);
  }

  // The crescent is a big circle with a smaller circle cut out of it.
  void _paintCrescent(Canvas canvas) {
    final Rect outer = Rect.fromCircle(
      center: Offset(410.75, 220.96) * scale,
      radius: 58.48 * scale,
    );
    final Rect cut = Rect.fromCircle(
      center: Offset(425.77, 208.32) * scale,
      radius: 54.95 * scale,
    );

    // Soft glow: a slightly bigger blurred copy under the crescent.
    final Path glowShape = Path.combine(
      PathOperation.difference,
      Path()..addOval(outer.inflate(19 * scale)),
      Path()..addOval(cut),
    );
    canvas.drawPath(
      glowShape,
      Paint()
        ..color = const Color(0x8CFFF3D6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 19 * scale),
    );

    final Path moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(outer),
      Path()..addOval(cut),
    );
    canvas.drawPath(moon, Paint()..color = const Color(0xFFFDF7EB));
  }

  @override
  bool shouldRepaint(_ArchPainter oldDelegate) => oldDelegate.scale != scale;
}