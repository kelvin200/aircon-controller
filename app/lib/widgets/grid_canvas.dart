import 'package:flutter/material.dart';
import '../theme.dart';

/// Paints the near-black navy canvas overlaid with a faint square grid pattern.
///
/// Place behind the app's (transparent) scaffolds so the grid shows through
/// every screen.
class GridCanvas extends StatelessWidget {
  const GridCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return CustomPaint(
      painter: _GridPainter(canvasColor: c.canvas, lineColor: c.hairline),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color canvasColor;
  final Color lineColor;

  _GridPainter({required this.canvasColor, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = canvasColor,
    );
    final line = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.canvasColor != canvasColor || oldDelegate.lineColor != lineColor;
}
