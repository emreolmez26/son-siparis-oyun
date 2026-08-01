import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class PlayerHandComponent extends PositionComponent {
  PlayerHandComponent()
    : super(
        position: Vector2(GameLayout.horizontalPadding, GameLayout.handTop),
        size: Vector2(
          GameLayout.designWidth - (GameLayout.horizontalPadding * 2),
          GameLayout.handHeight,
        ),
      );

  static const _titleStyle = TextStyle(
    color: GameLayout.primaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
  );
  static const _hintStyle = TextStyle(
    color: GameLayout.mutedTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  @override
  void render(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: const Color(0xFF2A1A14),
      borderColor: const Color(0xFF70482D),
      radius: 14,
      borderWidth: 1.5,
    );
    ShellCanvas.label(
      canvas,
      text: 'OYUNCU ELİ',
      position: Vector2(20, 14),
      style: _titleStyle.copyWith(color: const Color(0xFFF5D18D)),
    );
    ShellCanvas.label(
      canvas,
      text: 'Kartları mutfak masasına sürükleyin.',
      position: Vector2(20, 44),
      style: _hintStyle.copyWith(color: const Color(0xFFD9BFA2)),
    );
  }
}
