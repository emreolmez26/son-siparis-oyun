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
  double _rejectionRemaining = 0;

  void triggerSuccessGlow() {
    _successGlowRemaining = GameLayout.serviceFeedbackDurationSeconds;
  }

  void triggerRejection() {
    _rejectionRemaining = GameLayout.validDropFeedbackSeconds * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _successGlowRemaining = (_successGlowRemaining - dt)
        .clamp(0.0, GameLayout.serviceFeedbackDurationSeconds)
        .toDouble();
    _rejectionRemaining = (_rejectionRemaining - dt)
        .clamp(0.0, GameLayout.validDropFeedbackSeconds * 2)
        .toDouble();
  }

  @override
  void render(Canvas canvas) {
    final isGlowing = _successGlowRemaining > 0;
    final isRejecting = _rejectionRemaining > 0;
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: isRejecting
          ? const Color(0xFF5B2924)
          : isGlowing
          ? const Color(0xFF5B4824)
          : const Color(0xFF3A241A),
      borderColor: isRejecting
          ? const Color(0xFFE56B57)
          : isGlowing
          ? GameLayout.successColor
          : GameLayout.accentColor,
      radius: 12,
      borderWidth: isGlowing ? 3 : 2,
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
      text: 'Hazır siparişi buraya bırak',
      position: Vector2(size.x / 2, 29),
      style: _hintStyle,
      align: TextAlign.center,
    );
  }
}
