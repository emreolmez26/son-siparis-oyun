import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class ServiceCounterComponent extends PositionComponent {
  ServiceCounterComponent()
    : super(
        position: Vector2(
          GameLayout.serviceCounterBounds.left,
          GameLayout.serviceCounterBounds.top,
        ),
        size: Vector2(
          GameLayout.serviceCounterBounds.width,
          GameLayout.serviceCounterBounds.height,
        ),
      );

  static const _labelStyle = TextStyle(
    color: GameLayout.primaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
  );
  static const _hintStyle = TextStyle(
    color: GameLayout.mutedTextColor,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
  double _successGlowRemaining = 0;

  void triggerSuccessGlow() {
    _successGlowRemaining = GameLayout.serviceFeedbackDurationSeconds;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _successGlowRemaining = (_successGlowRemaining - dt)
        .clamp(0.0, GameLayout.serviceFeedbackDurationSeconds)
        .toDouble();
  }

  @override
  void render(Canvas canvas) {
    final isGlowing = _successGlowRemaining > 0;
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: isGlowing ? const Color(0xFF5B4824) : GameLayout.serviceColor,
      borderColor: isGlowing ? GameLayout.successColor : GameLayout.accentColor,
      radius: 10,
      borderWidth: isGlowing ? 3 : 1.5,
    );
    ShellCanvas.label(
      canvas,
      text: 'SERVİS BANKOSU',
      position: Vector2(size.x / 2, 10),
      style: _labelStyle,
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'Hazır sonuç teslim noktası',
      position: Vector2(size.x / 2, 29),
      style: _hintStyle,
      align: TextAlign.center,
    );
  }
}
