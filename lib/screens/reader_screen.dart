import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/app_colors.dart';
import '../core/arabic_text.dart';
import '../core/reader_settings.dart';
import '../data/quran_data.dart';

// Quran reader. The user chooses between swiping pages or scrolling.
class ReaderScreen extends StatefulWidget {
  final QuranData data;
  final int initialPage; // 1-based

  const ReaderScreen({
    super.key,
    required this.data,
    required this.initialPage,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // The page the user is on. It survives switching the view mode.
  late int _page = widget.initialPage;

  void _onPageChanged(int page) {
    if (page == _page) return;
    setState(() => _page = page);
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReaderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // The first ayah on the current page decides the title, juz and hizb.
    final AyahRef first = widget.data.ayahsOfPage(_page).first;
    final Surah surah = widget.data.surahs[first.surah - 1];
    final int juz = widget.data.juzOf(first.surah, first.ayah);
    final int? hizb = widget.data.hizbOf(first.surah, first.ayah);

    final String info = [
      'الجزء ${toArabicDigits(juz)}',
      if (hizb != null) 'الحزب ${toArabicDigits(hizb)}',
      'صفحة ${toArabicDigits(_page)}',
    ].join(' · ');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.title,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'سورة ${surah.name}',
              style: TextStyle(
                color: colors.title,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            Text(
              info,
              style: TextStyle(color: colors.mutedText, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'إعدادات القراءة',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openSettings,
          ),
        ],
      ),
      // The keys make Flutter rebuild the body from the current page
      // when the user switches the view mode.
      body: ValueListenableBuilder<ReaderViewMode>(
        valueListenable: readerViewModeNotifier,
        builder: (context, mode, _) {
          if (mode == ReaderViewMode.pages) {
            return _PagedBody(
              key: const ValueKey('pages'),
              data: widget.data,
              initialPage: _page,
              onPageChanged: _onPageChanged,
            );
          }
          return _ScrollBody(
            key: const ValueKey('scroll'),
            data: widget.data,
            initialPage: _page,
            onPageChanged: _onPageChanged,
          );
        },
      ),
    );
  }
}

// Mode 1: swipe between pages like a real book.
class _PagedBody extends StatefulWidget {
  final QuranData data;
  final int initialPage;
  final ValueChanged<int> onPageChanged;

  const _PagedBody({
    super.key,
    required this.data,
    required this.initialPage,
    required this.onPageChanged,
  });

  @override
  State<_PagedBody> createState() => _PagedBodyState();
}

class _PagedBodyState extends State<_PagedBody> {
  late final PageController _controller =
  PageController(initialPage: widget.initialPage - 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // In RTL, PageView turns pages from left to right, like a real book.
    return PageView.builder(
      controller: _controller,
      itemCount: widget.data.pageCount,
      onPageChanged: (i) => widget.onPageChanged(i + 1),
      itemBuilder: (context, i) {
        return _MushafPage(
          key: ValueKey(i + 1),
          data: widget.data,
          page: i + 1,
          scrollable: true,
        );
      },
    );
  }
}

// Mode 2: all pages stacked in one list that scrolls up and down.
class _ScrollBody extends StatefulWidget {
  final QuranData data;
  final int initialPage;
  final ValueChanged<int> onPageChanged;

  const _ScrollBody({
    super.key,
    required this.data,
    required this.initialPage,
    required this.onPageChanged,
  });

  @override
  State<_ScrollBody> createState() => _ScrollBodyState();
}

class _ScrollBodyState extends State<_ScrollBody> {
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  late int _lastReported = widget.initialPage;

  @override
  void initState() {
    super.initState();
    _positions.itemPositions.addListener(_onPositions);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_onPositions);
    super.dispose();
  }

  // Finds the first page that is still visible and reports it.
  void _onPositions() {
    final Iterable<ItemPosition> visible =
    _positions.itemPositions.value.where((p) => p.itemTrailingEdge > 0.15);
    if (visible.isEmpty) return;

    final int page =
        visible.reduce((a, b) => a.index <= b.index ? a : b).index + 1;
    if (page == _lastReported) return;
    _lastReported = page;

    // Wait for the frame to end so we never call setState during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPageChanged(page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemCount: widget.data.pageCount,
      initialScrollIndex: widget.initialPage - 1,
      itemPositionsListener: _positions,
      itemBuilder: (context, i) {
        return _MushafPage(
          key: ValueKey(i + 1),
          data: widget.data,
          page: i + 1,
          scrollable: false,
        );
      },
    );
  }
}

// Ayahs of one surah that appear on the same page.
class _PageBlock {
  final int surah;
  final List<int> ayahs = [];

  _PageBlock(this.surah);

  // True when the surah begins on this page (so we show its header).
  bool get startsSurah => ayahs.first == 1;
}

// One mushaf page: framed, flowing text with ayah number rosettes.
// scrollable = true: the page scrolls inside itself (swipe mode).
// scrollable = false: the page has its full height (list mode).
class _MushafPage extends StatefulWidget {
  final QuranData data;
  final int page;
  final bool scrollable;

  const _MushafPage({
    super.key,
    required this.data,
    required this.page,
    required this.scrollable,
  });

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  // One tap recognizer per ayah. They must be disposed with the page.
  final Map<AyahRef, TapGestureRecognizer> _recognizers = {};

  // The ayah that is highlighted while its sheet is open.
  AyahRef? _selected;

  late final List<_PageBlock> _blocks = _buildBlocks();

  @override
  void dispose() {
    for (final TapGestureRecognizer r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  // Groups the page ayahs by surah, because a surah header can sit in between.
  List<_PageBlock> _buildBlocks() {
    final List<_PageBlock> blocks = [];
    for (final AyahRef ref in widget.data.ayahsOfPage(widget.page)) {
      if (blocks.isEmpty || blocks.last.surah != ref.surah) {
        blocks.add(_PageBlock(ref.surah));
      }
      blocks.last.ayahs.add(ref.ayah);
    }
    return blocks;
  }

  TapGestureRecognizer _recognizerFor(AyahRef ref) {
    return _recognizers.putIfAbsent(
      ref,
          () => TapGestureRecognizer()..onTap = () => _onTapAyah(ref),
    );
  }

  Future<void> _onTapAyah(AyahRef ref) async {
    setState(() => _selected = ref);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AyahSheet(data: widget.data, ref: ref),
    );

    // The page may have been removed while the sheet was open.
    if (!mounted) return;
    setState(() => _selected = null);
  }

  Widget _buildAyahText(
      _PageBlock block,
      double fontSize,
      String family,
      AppPalette colors,
      ) {
    final Surah surah = widget.data.surahs[block.surah - 1];
    final List<InlineSpan> spans = [];

    for (final int n in block.ayahs) {
      final AyahRef ref = AyahRef(block.surah, n);

      spans.add(
        TextSpan(
          text: surah.ayahs[n - 1],
          recognizer: _recognizerFor(ref),
          style: _selected == ref
              ? TextStyle(backgroundColor: colors.accent.withValues(alpha: 0.18))
              : null,
        ),
      );
      spans.add(const TextSpan(text: ' '));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => _onTapAyah(ref),
            child: _AyahMarker(number: n, size: fontSize * 1.3),
          ),
        ),
      );
      spans.add(const TextSpan(text: ' '));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
      style: TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        height: 2.0,
        color: colors.bodyText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Rebuild when the font size or the font changes.
    return ListenableBuilder(
      listenable: Listenable.merge([readerFontSizeNotifier, readerFontNotifier]),
      builder: (context, _) {
        final double fontSize = readerFontSizeNotifier.value;
        final String family = fontFamilyOf(readerFontNotifier.value);

        final Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final _PageBlock block in _blocks) ...[
              if (block.startsSurah)
                _SurahBanner(
                  surah: widget.data.surahs[block.surah - 1],
                  basmala: widget.data.surahs[block.surah - 1].showsBasmalaHeader
                      ? widget.data.basmala
                      : null,
                  fontSize: fontSize,
                  fontFamily: family,
                ),
              _buildAyahText(block, fontSize, family, colors),
            ],
            const SizedBox(height: 12),
            Text(
              toArabicDigits(widget.page),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.mutedText, fontSize: 14),
            ),
          ],
        );

        const EdgeInsets padding = EdgeInsets.fromLTRB(14, 12, 14, 16);

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border, width: 1.5),
          ),
          // Inner thin frame: gives the double border of a mushaf page.
          child: Container(
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
            ),
            child: widget.scrollable
                ? SingleChildScrollView(padding: padding, child: content)
                : Padding(padding: padding, child: content),
          ),
        );
      },
    );
  }
}

// Surah header: a pointed arch with a crescent, the name and details.
// The Basmala and a decorative divider are shown under it when the surah
// has a Basmala.
class _SurahBanner extends StatelessWidget {
  final Surah surah;
  final String? basmala;
  final double fontSize;
  final String fontFamily;

  const _SurahBanner({
    required this.surah,
    required this.basmala,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String type = surah.isMeccan ? 'مكية' : 'مدنية';
    // Fixed above: the first label is replaced just below.

    return Column(
      children: [
        SizedBox(
          height: 124,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ArchBannerPainter(
                    line: colors.accent,
                    fill: colors.softSurface,
                  ),
                ),
              ),
              // Crescent, name and details sit inside the arch.
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 17),
                  child: Column(
                    children: [
                      Icon(
                        Icons.nightlight_round,
                        size: 16,
                        color: colors.accent,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'سورة ${surah.name}',
                        style: TextStyle(
                          color: colors.title,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 130,
                        height: 12,
                        child: CustomPaint(
                          painter: _OrnamentDividerPainter(
                            line: colors.accent,
                            fill: colors.softSurface,
                            scale: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$type · ${toArabicDigits(surah.ayahCount)} آية',
                        style: TextStyle(color: colors.mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (basmala != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              basmala!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                height: 2.0,
                color: colors.title,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: _OrnamentDivider(),
          ),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }
}

// Draws the arch outline (outer and inner line) with its fill.
class _ArchBannerPainter extends CustomPainter {
  final Color line;
  final Color fill;

  const _ArchBannerPainter({required this.line, required this.fill});

  // The whole header shape: a wide body with a pointed dome in the middle.
  // It is built for a box of w x h, starting at (0, 0).
  Path _shell(double w, double h) {
    const double m = 3; // side margin
    const double top = 9; // room above the tip of the dome
    final double cx = w / 2;
    final double hh = h - top;
    double y(double f) => top + hh * f;

    final double sy = y(0.52); // height of the shoulders
    final double dh = w * 0.3; // half width of the dome

    return Path()
      ..moveTo(m, h - 2)
      ..lineTo(m, sy + 12)
    // Rounded corner, then the left shoulder.
      ..quadraticBezierTo(m, sy, m + 14, sy)
      ..lineTo(cx - dh - 16, sy)
    // Left side of the dome: a small fillet, then up to the tip.
      ..cubicTo(cx - dh - 4, sy, cx - dh, sy - 6, cx - dh, sy - 20)
      ..cubicTo(cx - dh, y(0.2), cx - 0.5 * dh, y(0.14), cx - 0.14 * dh, y(0.07))
      ..cubicTo(
        cx - 0.07 * dh, y(0.04), cx - 0.03 * dh, y(0.03), cx, top,
      )
    // Right side of the dome (mirror of the left side).
      ..cubicTo(
        cx + 0.03 * dh, y(0.03), cx + 0.07 * dh, y(0.04), cx + 0.14 * dh, y(0.07),
      )
      ..cubicTo(cx + 0.5 * dh, y(0.14), cx + dh, y(0.2), cx + dh, sy - 20)
      ..cubicTo(cx + dh, sy - 6, cx + dh + 4, sy, cx + dh + 16, sy)
      ..lineTo(w - m - 14, sy)
      ..quadraticBezierTo(w - m, sy, w - m, sy + 12)
      ..lineTo(w - m, h - 2)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path outer = _shell(size.width, size.height);
    // The inner outline is a smaller copy moved 6px inside.
    final Path inner =
    _shell(size.width - 12, size.height - 12).shift(const Offset(6, 6));

    canvas.drawPath(outer, Paint()..color = fill);
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = line,
    );
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = line.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_ArchBannerPainter old) =>
      old.line != line || old.fill != fill;
}

// Decorative divider: two lines that fade out at the ends, with a small
// four-petal flower and two diamonds in the middle.
class _OrnamentDivider extends StatelessWidget {
  const _OrnamentDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 22,
      width: double.infinity,
      child: CustomPaint(
        painter: _OrnamentDividerPainter(
          line: colors.accent,
          fill: colors.card,
          scale: 1.0,
        ),
      ),
    );
  }
}

class _OrnamentDividerPainter extends CustomPainter {
  final Color line;
  final Color fill;
  final double scale; // 1.0 = normal size, smaller = more compact

  const _OrnamentDividerPainter({
    required this.line,
    required this.fill,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double cx = w / 2;
    final double cy = size.height / 2;
    final double gap = 22 * scale; // empty space reserved for the ornament
    final double lineLength = math.max(cx - gap, 1);

    // Left line fades in toward the center, right line fades out.
    final Paint linePaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    linePaint.shader = LinearGradient(
      colors: [line.withValues(alpha: 0), line],
    ).createShader(Rect.fromLTWH(0, 0, lineLength, size.height));
    canvas.drawLine(Offset(0, cy), Offset(cx - gap, cy), linePaint);

    linePaint.shader = LinearGradient(
      colors: [line, line.withValues(alpha: 0)],
    ).createShader(Rect.fromLTWH(cx + gap, 0, lineLength, size.height));
    canvas.drawLine(Offset(cx + gap, cy), Offset(w, cy), linePaint);

    // Two small diamonds next to the center.
    void diamond(Offset c, double r) {
      final Path p = Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - r, c.dy)
        ..close();
      canvas.drawPath(p, Paint()..color = line);
    }

    diamond(Offset(cx - 16 * scale, cy), 2.6 * scale);
    diamond(Offset(cx + 16 * scale, cy), 2.6 * scale);

    // Four-petal flower in the center.
    final Paint petal = Paint()..color = line;
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(i * math.pi / 2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -4.5 * scale),
          width: 5 * scale,
          height: 9 * scale,
        ),
        petal,
      );
      canvas.restore();
    }
    // Small dot in the middle of the flower.
    canvas.drawCircle(Offset(cx, cy), 1.8 * scale, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_OrnamentDividerPainter old) =>
      old.line != line || old.fill != fill || old.scale != scale;
}

// Ayah number inside a rounded 8-lobe star, like in a mushaf.
// Its size follows the font size.
class _AyahMarker extends StatelessWidget {
  final int number;
  final double size;

  const _AyahMarker({required this.number, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return CustomPaint(
      size: Size(size, size),
      painter: _StarMarkerPainter(line: colors.accent, fill: colors.softSurface),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            toArabicDigits(number),
            style: TextStyle(
              color: colors.title,
              fontSize: size * 0.36,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarMarkerPainter extends CustomPainter {
  final Color line;
  final Color fill;

  const _StarMarkerPainter({required this.line, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    const int lobes = 8;

    final double peak = size.width / 2 * 0.95; // distance to the lobe tips
    final double valley = peak * 0.80; // distance to the dips between lobes

    // Each lobe is a curve from one dip to the next. The control point is
    // pushed out so that the curve reaches (about) the peak distance.
    final double controlR = (peak - 0.5 * math.cos(math.pi / lobes) * valley) / 0.5;

    Offset at(double angle, double radius) {
      return c + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    }

    final Path path = Path();
    for (int i = 0; i < lobes; i++) {
      final double a0 = 2 * math.pi * (i - 0.5) / lobes;
      final double a1 = 2 * math.pi * (i + 0.5) / lobes;
      final double am = 2 * math.pi * i / lobes;

      final Offset start = at(a0, valley);
      final Offset end = at(a1, valley);
      final Offset control = at(am, controlR);

      if (i == 0) path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, size.width * 0.055)
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(_StarMarkerPainter old) =>
      old.line != line || old.fill != fill;
}

// Bottom sheet shown when an ayah is tapped. More actions come later
// (favorite, last read, tafsir, audio).
class _AyahSheet extends StatelessWidget {
  final QuranData data;
  final AyahRef ref;

  const _AyahSheet({required this.data, required this.ref});

  Future<void> _copy(BuildContext context) async {
    final Surah surah = data.surahs[ref.surah - 1];
    final String text = '${surah.ayahs[ref.ayah - 1]} '
        '﴿${toArabicDigits(ref.ayah)}﴾\n'
        '— سورة ${surah.name}';

    // Capture these before the await so we do not use context after it.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await Clipboard.setData(ClipboardData(text: text));
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الآية'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Surah surah = data.surahs[ref.surah - 1];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سورة ${surah.name} · الآية ${toArabicDigits(ref.ayah)}',
              style: TextStyle(
                color: colors.title,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              surah.ayahs[ref.ayah - 1],
              style: TextStyle(
                fontFamily: fontFamilyOf(readerFontNotifier.value),
                fontSize: 24,
                height: 2.0,
                color: colors.bodyText,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.copy_rounded, color: colors.accent),
              title: Text('نسخ الآية', style: TextStyle(color: colors.bodyText)),
              onTap: () => _copy(context),
            ),
          ],
        ),
      ),
    );
  }
}

// Reader settings: view mode, font, and font size with a live preview.
class _ReaderSettingsSheet extends StatelessWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final ButtonStyle segmentStyle = SegmentedButton.styleFrom(
      foregroundColor: colors.mutedText,
      selectedForegroundColor: colors.title,
      selectedBackgroundColor: colors.softSurface,
    );

    Widget label(String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: colors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            readerViewModeNotifier,
            readerFontNotifier,
            readerFontSizeNotifier,
          ]),
          builder: (context, _) {
            final ReaderViewMode mode = readerViewModeNotifier.value;
            final ReaderFont font = readerFontNotifier.value;
            final double size = readerFontSizeNotifier.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات القراءة',
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                label('طريقة العرض'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ReaderViewMode>(
                    style: segmentStyle,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ReaderViewMode.pages,
                        icon: Icon(Icons.menu_book_rounded),
                        label: Text('صفحات'),
                      ),
                      ButtonSegment(
                        value: ReaderViewMode.scroll,
                        icon: Icon(Icons.swap_vert_rounded),
                        label: Text('تمرير'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => setReaderViewMode(s.first),
                  ),
                ),

                label('الخط'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ReaderFont>(
                    style: segmentStyle,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ReaderFont.amiriQuran,
                        label: Text('أميري'),
                      ),
                      ButtonSegment(
                        value: ReaderFont.scheherazade,
                        label: Text('شهرزاد'),
                      ),
                    ],
                    selected: {font},
                    onSelectionChanged: (s) => setReaderFont(s.first),
                  ),
                ),

                label('حجم الخط'),
                Center(
                  child: Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamilyOf(font),
                      fontSize: size,
                      height: 2.0,
                      color: colors.bodyText,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'تصغير',
                      onPressed: size > kMinFontSize
                          ? () => setReaderFontSize(size - 2)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Expanded(
                      child: Slider(
                        value: size,
                        min: kMinFontSize,
                        max: kMaxFontSize,
                        divisions: 12,
                        activeColor: colors.accent,
                        onChanged: setReaderFontSize,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'تكبير',
                      onPressed: size < kMaxFontSize
                          ? () => setReaderFontSize(size + 2)
                          : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}