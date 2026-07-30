import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class ServiceCounterComponent extends PositionComponent {
  ServiceCounterComponent()
    : super(
        position: Vector2(
          (GameLayout.designWidth - GameLayout.serviceWidth) / 2,
          GameLayout.serviceTop,
        ),
        size: Vector2(GameLayout.serviceWidth, GameLayout.serviceHeight),
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

  @override
  void render(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: GameLayout.serviceColor,
      borderColor: GameLayout.accentColor,
      radius: 10,
      borderWidth: 1.5,
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
      text: 'Statik yer tutucu',
      position: Vector2(size.x / 2, 29),
      style: _hintStyle,
      align: TextAlign.center,
    );
  }
}
