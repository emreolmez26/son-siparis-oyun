import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

abstract final class ShellCanvas {
  static void panel(
    Canvas canvas,
    Rect rect, {
    required Color color,
    required Color borderColor,
    double radius = 12,
    double borderWidth = 1,
  }) {
    final roundedRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(roundedRect, Paint()..color = color);
    canvas.drawRRect(
      roundedRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  static void label(
    Canvas canvas, {
    required String text,
    required Vector2 position,
    required TextStyle style,
    TextAlign align = TextAlign.left,
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);

    var dx = position.x;
    if (align == TextAlign.center) {
      dx -= painter.width / 2;
    } else if (align == TextAlign.right) {
      dx -= painter.width;
    }

    painter.paint(canvas, Offset(dx, position.y));
  }
}
