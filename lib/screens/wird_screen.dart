import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/arabic_text.dart';
import '../core/saved_items.dart';
import '../core/wird_data.dart';
import '../data/quran_data.dart';
import 'reader_screen.dart';

const List<String> _kMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

// "٨ ديسمبر" (the year is added only when it is not this year).
String _formatDate(DateTime d) {
  final String base = '${toArabicDigits(d.day)} ${_kMonths[d.month - 1]}';
  return d.year == DateTime.now().year
      ? base
      : '$base ${toArabicDigits(d.year)}';
}

// "يوم واحد"، "يومان"، "٥ أيام"، "٢٠ يوماً".
String _daysText(int days) {
  if (days == 1) return 'يوم واحد';
  if (days == 2) return 'يومان';
  if (days <= 10) return '${toArabicDigits(days)} أيام';
  return '${toArabicDigits(days)} يوماً';
}

// "الجزء ٤"، "الجزآن ٣ و٤"، "من الجزء ٣ إلى الجزء ٥" (null when the portion
// is not made of whole juz or hizb).
String? _unitLabel(Wird wird) {
  final span = wird.unitSpan;
  if (span == null) return null;

  final bool juz = span.unit == WirdUnit.juz;
  final String name = juz ? 'الجزء' : 'الحزب';
  final String first = toArabicDigits(span.first);
  final String last = toArabicDigits(span.last);

  if (span.first == span.last) return '$name $first';
  if (span.last == span.first + 1) {
    return '${juz ? 'الجزآن' : 'الحزبان'} $first و$last';
  }
  return 'من $name $first إلى $name $last';
}

// What the user reads every day in a khatma of [days] days.
String _perDayText(int days) {
  switch (wirdUnitForDays(days)) {
    case WirdUnit.hizb:
      return 'حزب واحد يومياً (حوالي ١٠ صفحات)';
    case WirdUnit.juz:
      final int juz = 30 ~/ days;
      final String name = juz == 1
          ? 'جزء واحد'
          : juz == 2
          ? 'جزءان'
          : juz <= 10
          ? '${toArabicDigits(juz)} أجزاء'
          : '${toArabicDigits(juz)} جزءاً';
      return '$name يومياً (حوالي ${toArabicDigits(juz * 20)} صفحة)';
    case WirdUnit.pages:
      final int pages = (kMushafPages + days - 1) ~/ days;
      return 'حوالي ${toArabicDigits(pages)} صفحة يومياً';
  }
}

// Turns "٣٠" or "30" into 30 (null if it is not a number).
int? _parseNumber(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final int unit in input.trim().runes) {
    // Arabic-Indic digits are U+0660..U+0669.
    if (unit >= 0x0660 && unit <= 0x0669) {
      buffer.writeCharCode(unit - 0x0660 + 0x30);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return int.tryParse(buffer.toString());
}

// "صفحة واحدة"، "صفحتان"، "٥ صفحات"، "٢٠ صفحة".
String _pagesText(int pages) {
  if (pages == 1) return 'صفحة واحدة';
  if (pages == 2) return 'صفحتان';
  if (pages <= 10) return '${toArabicDigits(pages)} صفحات';
  return '${toArabicDigits(pages)} صفحة';
}

bool _noticeShowing = false;

// Tells the user once that part of the last wird was missed, and what
// changed because of it. Does nothing when there is nothing to tell.
Future<void> showWirdNoticeIfNeeded(BuildContext context) async {
  final Wird? wird = wirdNotifier.value;
  if (wird == null || wird.missedPages <= 0 || _noticeShowing) return;

  final DateTime now = DateTime.now();
  final String missed = _pagesText(wird.missedPages);
  final String today = _pagesText(wird.dayCount);
  final String range = wird.dayCount == 1
      ? 'صفحة ${toArabicDigits(wird.firstPage)}'
      : 'من صفحة ${toArabicDigits(wird.firstPage)} '
      'إلى صفحة ${toArabicDigits(wird.lastPage)}';

  final String text;
  if (wird.type == WirdType.khatma) {
    final int left = wird.daysLeft(now) ?? 0;
    text = left > 0
        ? 'بقي من وردك السابق $missed. أعدنا حساب وردك، '
        'وباقي ${_daysText(left)} على نهاية الختمة، '
        'فورد اليوم $today ($range).'
        : 'بقي من وردك السابق $missed. انتهت المدة التي حددتها، ويمكنك '
        'إكمال الختمة بنفس الوتيرة، وورد اليوم $today ($range).';
  } else {
    final DateTime? end = wird.plannedEnd(now);
    text = 'بقي من وردك السابق $missed. سنكمل من حيث توقفت، '
        'وورد اليوم $range'
        '${end == null ? '' : '، وصار موعد انتهاء الختمة المتوقع ${_formatDate(end)}'}.';
  }

  _noticeShowing = true;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('فاتك جزء من وردك'),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('حسناً'),
        ),
      ],
    ),
  );
  // Closed by the button or by tapping outside: either way it is done.
  _noticeShowing = false;
  dismissWirdNotice();
}

// ---------- Wird tab ----------

class WirdScreen extends StatefulWidget {
  const WirdScreen({super.key});

  @override
  State<WirdScreen> createState() => _WirdScreenState();
}

class _WirdScreenState extends State<WirdScreen> with WidgetsBindingObserver {
  QuranData? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      QuranRepository.instance.load().then((data) {
        if (mounted) setState(() => _data = data);
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // When the app comes back (maybe on a new day), update today's portion.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshWirdDay();
  }

  void _openReader(int page) {
    final QuranData? data = _data;
    if (data == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(data: data, initialPage: page),
      ),
    );
  }

  void _openSetup() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _WirdSetupSheet(replacing: wirdNotifier.value != null),
    );
  }

  Future<void> _confirmStop() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إيقاف الورد'),
        content: const Text('سيُحذف الورد الحالي وتقدمك فيه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إيقاف'),
          ),
        ],
      ),
    );
    if (ok == true) stopWird();
  }

  // "سورة النساء" or "من سورة البقرة إلى سورة آل عمران".
  String? _surahText(Wird wird) {
    final QuranData? data = _data;
    if (data == null) return null;

    final AyahRef first = data.ayahsOfPage(wird.firstPage).first;
    final AyahRef last = data.ayahsOfPage(wird.lastPage).last;
    final String firstName = data.surahs[first.surah - 1].name;
    final String lastName = data.surahs[last.surah - 1].name;

    return firstName == lastName
        ? 'سورة $firstName'
        : 'من سورة $firstName إلى سورة $lastName';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.backgroundTop, colors.background],
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<Wird?>(
            valueListenable: wirdNotifier,
            builder: (context, wird, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الورد اليومي',
                          style: TextStyle(
                            color: colors.title,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (wird != null)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: colors.mutedText,
                          ),
                          onSelected: (value) {
                            if (value == 'new') _openSetup();
                            if (value == 'stop') _confirmStop();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'new', child: Text('ورد جديد')),
                            PopupMenuItem(
                              value: 'stop',
                              child: Text('إيقاف الورد'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (wird == null)
                    _EmptyWird(onCreate: _openSetup)
                  else ...[
                    _TodayCard(
                      wird: wird,
                      surahText: _surahText(wird),
                      onContinue: () {
                        final int? page = wird.firstUndonePage;
                        if (page != null) _openReader(page);
                      },
                      onComplete: completeWirdToday,
                      onUndo: undoCompleteWirdToday,
                      onNew: _openSetup,
                    ),
                    const SizedBox(height: 14),
                    _KhatmaCard(wird: wird),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------- No wird yet ----------

class _EmptyWird extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyWird({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.softSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: colors.accent,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ابدأ وردك اليومي',
            style: TextStyle(
              color: colors.title,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر ختمة بمدة تناسبك، أو عدداً ثابتاً من الصفحات كل يوم.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('إنشاء ورد', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ---------- Today's portion ----------

class _TodayCard extends StatelessWidget {
  final Wird wird;
  final String? surahText;
  final VoidCallback onContinue;
  final VoidCallback onComplete;
  final VoidCallback onUndo;
  final VoidCallback onNew;

  const _TodayCard({
    required this.wird,
    required this.surahText,
    required this.onContinue,
    required this.onComplete,
    required this.onUndo,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool finished = wird.isKhatmaComplete;
    final bool complete = wird.todayComplete;

    // The text next to the ring.
    final List<Widget> lines;
    if (finished || complete) {
      lines = [
        Text(
          finished ? 'أتممت الختمة' : 'أتممت ورد اليوم',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'تقبّل الله منك',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ];
    } else {
      final String first = toArabicDigits(wird.firstPage);
      final String last = toArabicDigits(wird.lastPage);
      final String? unitLabel = _unitLabel(wird);
      final String pagesText = wird.dayCount == 1
          ? 'صفحة $first'
          : 'من صفحة $first إلى صفحة $last';

      lines = [
        if (unitLabel != null) ...[
          Text(
            unitLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pagesText,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ] else ...[
          Text(
            wird.dayCount == 1 ? 'صفحة $first' : 'من صفحة $first',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (wird.dayCount > 1)
            Text(
              'إلى صفحة $last',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
        if (surahText != null) ...[
          const SizedBox(height: 4),
          Text(
            surahText!,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [colors.accentStrongStart, colors.accentStrongEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            finished ? 'الختمة' : 'ورد اليوم',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _WirdRing(
                fraction: finished ? 1 : wird.todayFraction,
                done: wird.doneCount,
                total: wird.dayCount,
                showCheck: finished || complete,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines,
                ),
              ),
            ],
          ),
          if (finished) ...[
            const SizedBox(height: 14),
            _CardButton(
              label: 'ختمة جديدة',
              filled: true,
              onTap: onNew,
            ),
          ] else if (!complete) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CardButton(
                    label: 'تابع القراءة',
                    filled: true,
                    onTap: onContinue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CardButton(
                    label: 'أكملت',
                    icon: Icons.check_rounded,
                    filled: false,
                    onTap: onComplete,
                  ),
                ),
              ],
            ),
          ] else if (wird.canUndo) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: onUndo,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('تراجع'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// A button on the purple card: white filled, or white outline.
class _CardButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final EdgeInsets padding = const EdgeInsets.symmetric(vertical: 12);

    final Widget text = Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );

    if (filled) {
      return FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: colors.accentStrongEnd,
          padding: padding,
          shape: shape,
        ),
        child: text,
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: text,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        padding: padding,
        shape: shape,
      ),
    );
  }
}

// The ring with "٧ من ٢٠" inside.
class _WirdRing extends StatelessWidget {
  final double fraction;
  final int done;
  final int total;
  final bool showCheck;

  const _WirdRing({
    required this.fraction,
    required this.done,
    required this.total,
    required this.showCheck,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: fraction),
            duration: const Duration(milliseconds: 250),
            builder: (context, value, _) {
              return CustomPaint(
                size: const Size.square(88),
                painter: _WirdRingPainter(fraction: value),
              );
            },
          ),
          if (showCheck)
            const Icon(Icons.check_rounded, color: Colors.white, size: 40)
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  toArabicDigits(done),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  'من ${toArabicDigits(total)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WirdRingPainter extends CustomPainter {
  final double fraction;

  const _WirdRingPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 8;
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);

    final Paint track = Paint()
      ..color = Colors.white.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (fraction <= 0) return;
    final Paint progress = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_WirdRingPainter old) => old.fraction != fraction;
}

// ---------- Khatma progress ----------

class _KhatmaCard extends StatelessWidget {
  final Wird wird;

  const _KhatmaCard({required this.wird});

  String _statusText() {
    final DateTime now = DateTime.now();
    final DateTime? end = wird.plannedEnd(now);
    if (end == null) return '';

    if (wird.type == WirdType.khatma) {
      final int left = wird.daysLeft(now) ?? 0;
      return left == 0
          ? 'انتهت المدة المحددة'
          : 'باقي ${_daysText(left)} · تنتهي في ${_formatDate(end)}';
    }
    return 'تنتهي الختمة تقريباً في ${_formatDate(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final int percent = (wird.khatmaFraction * 100).floor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الختمة',
                  style: TextStyle(
                    color: colors.title,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${toArabicDigits(percent)}٪',
                style: TextStyle(color: colors.mutedText, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: wird.khatmaFraction,
              minHeight: 8,
              backgroundColor: colors.softSurface,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'قرأت ${toArabicDigits(wird.pagesReadTotal)} '
                'صفحة من ${toArabicDigits(kMushafPages)}',
            style: TextStyle(color: colors.bodyText, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            _statusText(),
            style: TextStyle(color: colors.mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---------- Setup sheet ----------

class _WirdSetupSheet extends StatefulWidget {
  // True when a wird already exists and this one will replace it.
  final bool replacing;

  const _WirdSetupSheet({required this.replacing});

  @override
  State<_WirdSetupSheet> createState() => _WirdSetupSheetState();
}

class _WirdSetupSheetState extends State<_WirdSetupSheet> {
  static const List<int> _presets = [7, 15, 30, 60];

  WirdType _type = WirdType.khatma;
  int _days = 30;
  bool _customDays = false;
  int _pages = 5;
  bool _fromLast = false;
  String? _error;

  final TextEditingController _customController = TextEditingController();

  // The page where the user stopped, if it is worth offering.
  int? get _lastPage {
    final int? page = lastReadNotifier.value?.page;
    return (page != null && page > 1) ? page : null;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String get _info {
    final DateTime today = DateTime.now();

    if (_type == WirdType.khatma) {
      final DateTime end = today.add(Duration(days: _days - 1));
      return '${_perDayText(_days)}، وتنتهي في ${_formatDate(end)}';
    }

    final int days = (kMushafPages + _pages - 1) ~/ _pages;
    final DateTime end = today.add(Duration(days: days - 1));
    return 'مدة الختمة حوالي ${_daysText(days)}، وتنتهي في ${_formatDate(end)}';
  }

  void _save() {
    int days = _days;
    if (_type == WirdType.khatma && _customDays) {
      final int? value = _parseNumber(_customController.text);
      if (value == null || value < 1 || value > 365) {
        setState(() => _error = 'اكتب عدد أيام بين ١ و٣٦٥');
        return;
      }
      days = value;
    }

    startWird(
      type: _type,
      startPage: _fromLast ? (_lastPage ?? 1) : 1,
      durationDays: _type == WirdType.khatma ? days : 0,
      pagesPerDay: _type == WirdType.fixedPages ? _pages : 0,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final int? lastPage = _lastPage;

    return SingleChildScrollView(
      // Moves up with the keyboard.
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.replacing ? 'ورد جديد' : 'ابدأ وردك',
              style: TextStyle(
                color: colors.title,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.replacing) ...[
              const SizedBox(height: 4),
              Text(
                'سيحل هذا الورد محل وردك الحالي.',
                style: TextStyle(color: colors.mutedText, fontSize: 13),
              ),
            ],
            const SizedBox(height: 14),

            // Type switch.
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colors.softSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _SegmentButton(
                    label: 'ختمة بمدة',
                    selected: _type == WirdType.khatma,
                    onTap: () => setState(() => _type = WirdType.khatma),
                  ),
                  _SegmentButton(
                    label: 'صفحات ثابتة',
                    selected: _type == WirdType.fixedPages,
                    onTap: () => setState(() => _type = WirdType.fixedPages),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_type == WirdType.khatma) ...[
              Text(
                'مدة الختمة',
                style: TextStyle(color: colors.mutedText, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final int d in _presets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: _OptionChip(
                          label: '${toArabicDigits(d)} يوم',
                          selected: !_customDays && _days == d,
                          onTap: () => setState(() {
                            _customDays = false;
                            _days = d;
                            _error = null;
                          }),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _OptionChip(
                      label: 'مخصص',
                      selected: _customDays,
                      onTap: () => setState(() => _customDays = true),
                    ),
                  ),
                ],
              ),
              if (_customDays) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9\u0660-\u0669]'),
                    ),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.bodyText),
                  onChanged: (text) {
                    final int? value = _parseNumber(text);
                    setState(() {
                      _error = null;
                      if (value != null && value >= 1 && value <= 365) {
                        _days = value;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'عدد الأيام',
                    hintStyle: TextStyle(color: colors.mutedText),
                    counterText: '',
                    filled: true,
                    fillColor: colors.softSurface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ] else ...[
              Text(
                'عدد الصفحات كل يوم',
                style: TextStyle(color: colors.mutedText, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'أقل',
                    onPressed: _pages > 1
                        ? () => setState(() => _pages--)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${toArabicDigits(_pages)} صفحة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.title,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'أكثر',
                    onPressed: _pages < 100
                        ? () => setState(() => _pages++)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.softSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _info,
                style: TextStyle(color: colors.title, fontSize: 13),
              ),
            ),

            const SizedBox(height: 14),
            Text(
              'من أين تبدأ',
              style: TextStyle(color: colors.mutedText, fontSize: 13),
            ),
            const SizedBox(height: 4),
            _StartOption(
              label: 'من بداية المصحف',
              selected: !_fromLast || lastPage == null,
              onTap: () => setState(() => _fromLast = false),
            ),
            if (lastPage != null)
              _StartOption(
                label: 'من حيث توقفت (صفحة ${toArabicDigits(lastPage)})',
                selected: _fromLast,
                onTap: () => setState(() => _fromLast = true),
              ),

            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('ابدأ الورد', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : colors.title,
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.accent : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.bodyText,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StartOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StartOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? colors.accent : colors.mutedText,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: colors.bodyText, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}