import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class ServiceFeedbackComponent extends PositionComponent {
  ServiceFeedbackComponent() : super(priority: _feedbackPriority);

  static const _feedbackPriority = 102;
  double _remainingSeconds = 0;
  int _rewardCoins = GameLayout.successfulServiceRewardCoins;
  Offset? _origin;

  void trigger({
    int rewardCoins = GameLayout.successfulServiceRewardCoins,
    Offset? origin,
  }) {
    _rewardCoins = rewardCoins;
    _origin = origin;
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
    final origin = _origin;
    if (origin != null) {
      final progress =
          1 - (_remainingSeconds / GameLayout.serviceFeedbackDurationSeconds);
      final destination = GameLayout.serviceCounterBounds.center;
      final center = Offset.lerp(
        origin +
            const Offset(GameLayout.cardWidth / 2, GameLayout.cardHeight / 2),
        destination,
        Curves.easeOut.transform(progress.clamp(0, 1)),
      )!;
      final travelSize = 24 * (1 - (.35 * progress));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: travelSize,
            height: travelSize * .72,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = Color.fromARGB(alpha, 255, 205, 74),
      );
    }
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
