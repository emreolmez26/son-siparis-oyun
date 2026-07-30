import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class OrderFailureFeedbackComponent extends PositionComponent {
  OrderFailureFeedbackComponent() : super(priority: _feedbackPriority);

  static const _feedbackPriority = 102;
  double _remainingSeconds = 0;

  void trigger() {
    _remainingSeconds = GameLayout.failureFeedbackDurationSeconds;
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
    if (_remainingSeconds <= 0) {
      return;
    }
    final alpha =
        (_remainingSeconds / GameLayout.failureFeedbackDurationSeconds * 255)
            .round()
            .clamp(0, 255)
            .toInt();
    final bounds = Rect.fromCenter(
      center: Offset(
        GameLayout.serviceCounterBounds.center.dx,
        GameLayout.serviceCounterBounds.top - 20,
      ),
      width: 192,
      height: 34,
    );
    ShellCanvas.panel(
      canvas,
      bounds,
      color: Color.fromARGB(alpha, 91, 35, 28),
      borderColor: Color.fromARGB(alpha, 237, 113, 77),
      radius: 16,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'SİPARİŞ KAÇTI!',
      position: Vector2(bounds.center.dx, bounds.top + 8),
      style: TextStyle(
        color: Color.fromARGB(alpha, 255, 235, 227),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }
}
