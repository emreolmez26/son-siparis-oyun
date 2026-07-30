import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class RecipeButtonComponent extends PositionComponent {
  RecipeButtonComponent()
    : super(
        position: Vector2(GameLayout.horizontalPadding, 100),
        size: Vector2(116, 36),
      );

  static const _labelStyle = TextStyle(
    color: GameLayout.primaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  @override
  void render(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 8,
    );
    ShellCanvas.label(
      canvas,
      text: '▤  Tarifler',
      position: Vector2(size.x / 2, 10),
      style: _labelStyle,
      align: TextAlign.center,
    );
  }
}
