import 'dart:math' as math;

import 'package:flutter/material.dart';

// A small prayer-beads icon: a loop of beads, one larger bead and a tassel.
// It takes its color and size from the surrounding IconTheme, so it can be
// used anywhere a normal Icon is used (for example in the navigation bar).
class TasbihIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const TasbihIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final IconThemeData theme = IconTheme.of(context);
    final double s = size ?? theme.size ?? 24;
    final Color c = color ?? theme.color ?? Theme.of(context).iconTheme.color ?? Colors.black;

    return CustomPaint(
      size: Size.square(s),
      painter: _TasbihIconPainter(c),
    );
  }
}

class _TasbihIconPainter extends CustomPainter {
  final Color color;

  const _TasbihIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Offset center = Offset(s * 0.5, s * 0.40);
    final double radius = s * 0.30;

    final Paint fill = Paint()..color = color;
    final Paint thread = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035;

    // The thread the beads sit on.
    canvas.drawCircle(center, radius, thread);

    // Beads go around the loop, starting from the bottom.
    // The first one (at the bottom) is the larger bead.
    const int beads = 11;
    for (int i = 1; i < beads; i++) {
      final double angle = math.pi / 2 + i * 2 * math.pi / beads;
      final Offset position = center +
          Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(position, s * 0.07, fill);
    }

    final Offset bottom = center + Offset(0, radius);
    canvas.drawCircle(bottom, s * 0.10, fill);

    // The tassel hanging from the larger bead.
    final Paint tassel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(bottom.dx, bottom.dy + s * 0.09),
      Offset(bottom.dx, s * 0.95),
      tassel,
    );
  }

  @override
  bool shouldRepaint(_TasbihIconPainter old) => old.color != color;
}