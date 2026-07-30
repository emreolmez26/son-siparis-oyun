import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class RecipeFeedbackComponent extends PositionComponent {
  RecipeFeedbackComponent() : super(priority: _feedbackPriority);

  static const _feedbackPriority = 101;
  double _remainingSeconds = 0;
  Offset? _anchor;
  String _text = '';

  void trigger({required Offset anchor, required String text}) {
    _anchor = anchor;
    _text = text;
    _remainingSeconds = GameLayout.recipeFeedbackDurationSeconds;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _remainingSeconds = (_remainingSeconds - dt)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  @override
  void render(Canvas canvas) {
    final anchor = _anchor;
    if (anchor == null || _remainingSeconds <= 0) {
      return;
    }

    final progress =
        _remainingSeconds / GameLayout.recipeFeedbackDurationSeconds;
    final alpha = (progress * 255).round().clamp(0, 255).toInt();
    final bounds = Rect.fromCenter(
      center: Offset(anchor.dx + (GameLayout.cardWidth / 2), anchor.dy - 22),
      width: 170,
      height: 31,
    );
    final glow = RRect.fromRectAndRadius(
      bounds.inflate(6),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      glow,
      Paint()..color = Color.fromARGB((alpha * .18).round(), 255, 200, 61),
    );
    ShellCanvas.panel(
      canvas,
      bounds,
      color: Color.fromARGB(alpha, 92, 56, 15),
      borderColor: Color.fromARGB(alpha, 255, 208, 69),
      radius: 15,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: _text,
      position: Vector2(bounds.center.dx, bounds.top + 7),
      style: TextStyle(
        color: Color.fromARGB(alpha, 255, 247, 213),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: .4,
      ),
      align: TextAlign.center,
      maxWidth: bounds.width - 14,
    );
  }
}
