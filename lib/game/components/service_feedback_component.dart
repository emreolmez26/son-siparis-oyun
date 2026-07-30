import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class ServiceFeedbackComponent extends PositionComponent {
  ServiceFeedbackComponent() : super(priority: _feedbackPriority);

  static const _feedbackPriority = 102;
  double _remainingSeconds = 0;
  int _rewardCoins = GameLayout.successfulServiceRewardCoins;

  void trigger({int rewardCoins = GameLayout.successfulServiceRewardCoins}) {
    _rewardCoins = rewardCoins;
    _remainingSeconds = GameLayout.serviceFeedbackDurationSeconds;
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
        (_remainingSeconds / GameLayout.serviceFeedbackDurationSeconds * 255)
            .round()
            .clamp(0, 255)
            .toInt();
    final bounds = Rect.fromCenter(
      center: Offset(
        GameLayout.serviceCounterBounds.center.dx,
        GameLayout.serviceCounterBounds.top - 20,
      ),
      width: 168,
      height: 34,
    );
    ShellCanvas.panel(
      canvas,
      bounds,
      color: Color.fromARGB(alpha, 48, 80, 36),
      borderColor: Color.fromARGB(alpha, 158, 216, 123),
      radius: 16,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'MÜKEMMEL!  +10',
      position: Vector2(bounds.center.dx, bounds.top + 8),
      style: TextStyle(
        color: Color.fromARGB(alpha, 244, 255, 233),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.panel(
      canvas,
      bounds,
      color: Color.fromARGB(alpha, 48, 80, 36),
      borderColor: Color.fromARGB(alpha, 158, 216, 123),
      radius: 16,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'MÜKEMMEL!  +$_rewardCoins',
      position: Vector2(bounds.center.dx, bounds.top + 8),
      style: TextStyle(
        color: Color.fromARGB(alpha, 244, 255, 233),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }
}
