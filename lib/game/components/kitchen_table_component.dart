import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class KitchenTableComponent extends PositionComponent {
  KitchenTableComponent()
    : super(
        position: Vector2(GameLayout.horizontalPadding, GameLayout.tableTop),
        size: Vector2(
          GameLayout.designWidth - (GameLayout.horizontalPadding * 2),
          GameLayout.tableHeight,
        ),
      );

  static const _titleStyle = TextStyle(
    color: GameLayout.mutedTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );
  @override
  void render(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: GameLayout.tableColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 16,
      borderWidth: 2,
    );

    final innerRect = Rect.fromLTWH(14, 14, size.x - 28, size.y - 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(11)),
      Paint()..color = GameLayout.tableInnerColor,
    );

    ShellCanvas.label(
      canvas,
      text: 'SERBEST MUTFAK MASASI',
      position: Vector2(28, 28),
      style: _titleStyle,
    );
  }
}
