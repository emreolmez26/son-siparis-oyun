import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class HudComponent extends PositionComponent {
  HudComponent()
    : super(
        position: Vector2(GameLayout.horizontalPadding, GameLayout.hudTop),
        size: Vector2(
          GameLayout.designWidth - (GameLayout.horizontalPadding * 2),
          GameLayout.hudHeight,
        ),
      );

  static const _labelStyle = TextStyle(
    color: GameLayout.mutedTextColor,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const _valueStyle = TextStyle(
    color: GameLayout.primaryTextColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  @override
  void render(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: GameLayout.hudColor,
      borderColor: GameLayout.panelStrokeColor,
    );

    _drawStat(canvas, 'GÜN 1', 'Akşam Servisi', 22, 164);
    _drawStat(canvas, 'SÜRE', '02:45', 202, 100);
    _drawStat(canvas, 'KASA', '120', 322, 88, prefix: '● ');
    _drawStat(canvas, 'KOMBO', 'x0', 430, 102);
    _drawStat(canvas, 'SİPARİŞ', '0/10', 550, 104);

    final pauseRect = Rect.fromLTWH(size.x - 58, 9, 42, size.y - 18);
    ShellCanvas.panel(
      canvas,
      pauseRect,
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 8,
    );
    ShellCanvas.label(
      canvas,
      text: 'Ⅱ',
      position: Vector2(pauseRect.center.dx, 13),
      style: _valueStyle.copyWith(color: GameLayout.accentColor, fontSize: 21),
      align: TextAlign.center,
    );
  }

  void _drawStat(
    Canvas canvas,
    String label,
    String value,
    double left,
    double width, {
    String prefix = '',
  }) {
    ShellCanvas.label(
      canvas,
      text: label,
      position: Vector2(left, 10),
      style: _labelStyle,
      maxWidth: width,
    );
    ShellCanvas.label(
      canvas,
      text: '$prefix$value',
      position: Vector2(left, 26),
      style: _valueStyle,
      maxWidth: width,
    );
  }
}
