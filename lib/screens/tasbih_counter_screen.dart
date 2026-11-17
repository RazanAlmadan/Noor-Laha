import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../core/app_colors.dart';
import '../core/arabic_text.dart';
import '../core/tasbih_data.dart';

// The counter page of one tasbih (built-in, open, or custom).
class TasbihCounterScreen extends StatelessWidget {
  final Tasbih tasbih;

  const TasbihCounterScreen({super.key, required this.tasbih});

  void _onTap() {
    final TasbihEvent event = tapTasbih(tasbih);
    if (!tasbihVibrationNotifier.value) return;

    // Vibrate only when a step or the whole tasbih is finished.
    switch (event) {
      case TasbihEvent.none:
        break;
      case TasbihEvent.stepDone:
        unawaited(Vibration.vibrate(duration: 120));
      case TasbihEvent.allDone:
        unawaited(Vibration.vibrate(pattern: [0, 200, 100, 300]));
    }
  }

  Future<void> _onReset(BuildContext context) async {
    // Nothing to lose, so no question.
    if (doneCountOf(tasbih) == 0 || isTasbihFinished(tasbih)) {
      resetTasbih(tasbih.id);
      return;
    }

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إعادة من البداية'),
        content: const Text('سيُمسح العدّ الحالي لهذه المسبحة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );
    if (ok == true) resetTasbih(tasbih.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;


    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.backgroundTop,
        foregroundColor: colors.title,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          tasbih.name,
          style: TextStyle(
            color: colors.title,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.backgroundTop, colors.background],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              tasbihProgressNotifier,
              tasbihVibrationNotifier,
            ]),
            builder: (context, _) {
              final TasbihProgress p = progressOf(tasbih);
              final bool finished = p.step >= tasbih.steps.length;
              final bool multi = tasbih.steps.length > 1;
              final TasbihStep? step = finished ? null : tasbih.steps[p.step];

              // With 2 or 3 steps the cards on top already show the current
              // one. The dhikr card is for a single step, or when the cards
              // scroll sideways and the current one may be out of sight.
              final bool showDhikrCard = !tasbih.isOpen &&
                  (tasbih.steps.length == 1 || tasbih.steps.length > 3);

              final Widget actions = Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'إعادة ضبط',
                    onTap: () => _onReset(context),
                  ),
                  _ActionButton(
                    icon: Icons.remove_rounded,
                    label: 'طرح واحدة',
                    onTap: () => undoTasbih(tasbih),
                  ),
                  _ActionButton(
                    icon: Icons.vibration_rounded,
                    label: tasbihVibrationNotifier.value
                        ? 'اهتزاز'
                        : 'بدون اهتزاز',
                    active: tasbihVibrationNotifier.value,
                    onTap: () => setTasbihVibration(
                      !tasbihVibrationNotifier.value,
                    ),
                  ),
                ],
              );

              // The page fills the screen: info on top, and the counting
              // button at the bottom where the thumb reaches it easily.
              return LayoutBuilder(
                builder: (context, constraints) {
                  // As big as the screen allows, but not huge.
                  final double buttonSize = math.min(
                    math.min(MediaQuery.sizeOf(context).width * 0.64, 240.0),
                    constraints.maxHeight * 0.36,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 16,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              if (tasbih.subtitle != null) ...[
                                Text(
                                  tasbih.subtitle!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.mutedText,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (finished) ...[
                                const Spacer(),
                                _FinishedView(
                                  onRestart: () => resetTasbih(tasbih.id),
                                ),
                                const Spacer(),
                                actions,
                                const SizedBox(height: 14),
                              ] else ...[
                                if (multi) ...[
                                  _StepTabs(tasbih: tasbih, current: p.step),
                                  const SizedBox(height: 14),
                                  _StepTrack(
                                    total: tasbih.steps.length,
                                    current: p.step,
                                  ),
                                ],
                                if (showDhikrCard) ...[
                                  const SizedBox(height: 14),
                                  _CurrentDhikrCard(
                                    text: step!.text,
                                    stepIndex: p.step,
                                  ),
                                ],
                                const Spacer(),
                                _BigCount(
                                  count: p.count,
                                  limit: tasbih.isOpen ? null : step!.count,
                                ),
                                const Spacer(),
                                actions,
                                const SizedBox(height: 10),
                                _CounterButton(
                                  size: buttonSize,
                                  fraction: tasbih.isOpen
                                      ? 0
                                      : p.count / step!.count,
                                  semanticCount: toArabicDigits(p.count),
                                  onTap: _onTap,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------- Steps ----------

// One card per step. With more than 3 steps the row scrolls sideways.
class _StepTabs extends StatelessWidget {
  final Tasbih tasbih;
  final int current;

  const _StepTabs({required this.tasbih, required this.current});

  @override
  Widget build(BuildContext context) {
    final List<TasbihStep> steps = tasbih.steps;

    Widget tab(int i) =>
        _StepTab(step: steps[i], done: i < current, current: i == current);

    if (steps.length <= 3) {
      return Row(
        children: [
          for (int i = 0; i < steps.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 8),
                child: tab(i),
              ),
            ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 8),
              child: SizedBox(width: 112, child: tab(i)),
            ),
        ],
      ),
    );
  }
}

class _StepTab extends StatelessWidget {
  final TasbihStep step;
  final bool done;
  final bool current;

  const _StepTab({
    required this.step,
    required this.done,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: current
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.accentStrongStart, colors.accentStrongEnd],
        )
            : null,
        color: current
            ? null
            : (done ? colors.softSurface : colors.card),
        borderRadius: BorderRadius.circular(18),
        border: current ? null : Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            step.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: current ? Colors.white : colors.title,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${toArabicDigits(step.count)} مرة',
            style: TextStyle(
              color: current ? Colors.white70 : colors.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Numbered circles joined by a line: done, current, and waiting steps.
class _StepTrack extends StatelessWidget {
  final int total;
  final int current;

  const _StepTrack({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    // With many steps there is no room for it, and the cards above are enough.
    if (total > 8) return const SizedBox.shrink();

    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          for (int i = 0; i < total; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= current ? colors.accent : colors.softSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            _StepDot(number: i + 1, done: i < current, current: i == current),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final bool done;
  final bool current;

  const _StepDot({
    required this.number,
    required this.done,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool filled = done || current;
    final double size = current ? 32 : 26;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.accent : colors.softSurface,
        border: current ? Border.all(color: colors.card, width: 3) : null,
        boxShadow: current
            ? [BoxShadow(color: colors.shadow, blurRadius: 8)]
            : null,
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : Text(
        toArabicDigits(number),
        style: TextStyle(
          color: current ? Colors.white : colors.mutedText,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ---------- Cards above the button ----------

// Shows the dhikr of the current step.
class _CurrentDhikrCard extends StatelessWidget {
  final String text;
  final int stepIndex;

  const _CurrentDhikrCard({required this.text, required this.stepIndex});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: colors.softSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'الذكر الحالي',
              style: TextStyle(color: colors.mutedText, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          // The text fades when a new step starts.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              text,
              key: ValueKey<int>(stepIndex),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.title,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The big number in the middle of the page.
// [limit] is null for the open tasbih, which has no limit.
class _BigCount extends StatelessWidget {
  final int count;
  final int? limit;

  const _BigCount({required this.count, required this.limit});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A long number shrinks instead of breaking the layout.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            toArabicDigits(count),
            style: TextStyle(
              color: colors.title,
              fontSize: 76,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 230,
          child: Row(
            children: [
              Expanded(child: Container(height: 1, color: colors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  limit == null
                      ? 'عدد التسبيحات'
                      : 'من ${toArabicDigits(limit!)}',
                  style: TextStyle(color: colors.mutedText, fontSize: 15),
                ),
              ),
              Expanded(child: Container(height: 1, color: colors.border)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- The big button ----------

class _CounterButton extends StatefulWidget {
  final double size; // Diameter of the button with its ring
  final double fraction; // 0..1, progress of the current step
  final String semanticCount;
  final VoidCallback onTap;

  const _CounterButton({
    required this.size,
    required this.fraction,
    required this.semanticCount,
    required this.onTap,
  });

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton> {
  bool _pressed = false;

  // Room around the ring for the leaves.
  static const double _ornament = 26;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const double stroke = 9;
    final double total = widget.size + _ornament * 2;

    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Two leaf branches around the button (decoration only).
          CustomPaint(
            size: Size.square(total),
            painter: _WreathPainter(color: colors.accent.withAlpha(95)),
          ),
          Semantics(
            button: true,
            label: 'تسبيح، العدد الحالي ${widget.semanticCount}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: widget.onTap,
              // The button gets a little smaller while it is pressed.
              child: AnimatedScale(
                scale: _pressed ? 0.96 : 1,
                duration: const Duration(milliseconds: 90),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft halo behind the ring.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.softSurface,
                        ),
                        child: SizedBox.expand(),
                      ),
                      // The ring grows smoothly to the new value.
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: widget.fraction),
                        duration: const Duration(milliseconds: 180),
                        builder: (context, value, _) {
                          return CustomPaint(
                            size: Size.square(widget.size),
                            painter: _RingPainter(
                              fraction: value,
                              stroke: stroke,
                              track: colors.card,
                              progress: colors.accent,
                            ),
                          );
                        },
                      ),
                      // The button itself fills the ring.
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(stroke + 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors.accentStrongStart,
                                  colors.accentStrongEnd,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow,
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    color: Colors.white,
                                    size: widget.size * 0.2,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'تسبيح',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: widget.size * 0.13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final double stroke;
  final Color track;
  final Color progress;

  const _RingPainter({
    required this.fraction,
    required this.stroke,
    required this.track,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(stroke / 2 + 2);

    final Paint trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (fraction <= 0) return;
    final Paint progressPaint = Paint()
      ..color = progress
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // Starts at the top and goes around.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
          old.track != track ||
          old.progress != progress;
}

// Two leaf branches that open around the button, like a small wreath.
// Everything is drawn from the size it is given, so it fits any screen.
class _WreathPainter extends CustomPainter {
  final Color color;

  const _WreathPainter({required this.color});

  double _rad(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    // The right branch, then the same branch mirrored for the left side.
    _branch(canvas, size);
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    _branch(canvas, size);
    canvas.restore();
  }

  void _branch(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - size.width * 0.045;

    final Paint stem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final Paint leafPaint = Paint()..color = color;

    // The branch starts near the bottom and curves up the side.
    const double startDeg = 78;
    const double endDeg = -52;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _rad(startDeg),
      _rad(endDeg - startDeg),
      false,
      stem,
    );

    const int nodes = 9;
    for (int i = 0; i < nodes; i++) {
      final double t = i / (nodes - 1);
      final double theta = _rad(startDeg + (endDeg - startDeg) * t);
      final Offset position =
          center + Offset(math.cos(theta), math.sin(theta)) * radius;

      // Direction the branch grows in at this point.
      final double growth = theta - math.pi / 2;
      // Leaves get a little smaller toward the tip.
      final double length = size.width * 0.06 * (1 - 0.3 * t);

      _leaf(canvas, leafPaint, position, growth + 0.7, length);
      _leaf(canvas, leafPaint, position, growth - 0.7, length);
      if (i == nodes - 1) {
        _leaf(canvas, leafPaint, position, growth, length * 1.1);
      }
    }
  }

  void _leaf(
      Canvas canvas,
      Paint paint,
      Offset at,
      double angle,
      double length,
      ) {
    final double width = length * 0.32;
    final Path path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -width * 2, length, 0)
      ..quadraticBezierTo(length * 0.5, width * 2, 0, 0);

    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WreathPainter old) => old.color != color;
}

// ---------- Bottom actions ----------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active ? colors.accent : colors.card,
          elevation: 1,
          shadowColor: colors.shadow,
          shape: CircleBorder(side: BorderSide(color: colors.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 54,
              height: 54,
              child: Icon(
                icon,
                color: active ? Colors.white : colors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: colors.bodyText, fontSize: 13)),
      ],
    );
  }
}

// ---------- Finished ----------

class _FinishedView extends StatelessWidget {
  final VoidCallback onRestart;

  const _FinishedView({required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.softSurface,
          ),
          child: Icon(Icons.check_rounded, color: colors.accent, size: 64),
        ),
        const SizedBox(height: 20),
        Text(
          'تمّت المسبحة',
          style: TextStyle(
            color: colors.title,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'تقبّل الله منك',
          style: TextStyle(color: colors.mutedText, fontSize: 16),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('ابدأ من جديد'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          ),
        ),
      ],
    );
  }
}