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
      color: const Color(0xFF352018),
      borderColor: const Color(0xFF8C5A31),
      radius: 18,
      borderWidth: 2.5,
    );

    final innerRect = Rect.fromLTWH(14, 14, size.x - 28, size.y - 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(11)),
      Paint()..color = const Color(0xFF4A2C1E),
    );
    for (
      var x = innerRect.left - innerRect.height;
      x < innerRect.right;
      x += 52
    ) {
      canvas.drawLine(
        Offset(x, innerRect.bottom),
        Offset(x + innerRect.height, innerRect.top),
        Paint()
          ..color = const Color(0x125F3825)
          ..strokeWidth = 2,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(11)),
      Paint()
        ..color = const Color(0x44E7A947)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    ShellCanvas.label(
      canvas,
      text: 'SERBEST MUTFAK MASASI',
      position: Vector2(28, 28),
      style: _titleStyle.copyWith(color: const Color(0xFFF0CC8A)),
    );
  }
}
