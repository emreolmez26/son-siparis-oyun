import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';

class SnapPreviewComponent extends PositionComponent {
  SnapPreviewComponent()
    : super(
        size: Vector2(GameLayout.cardWidth, GameLayout.cardHeight),
        priority: _previewPriority,
      );

  static const _previewPriority = 10;
  bool _isShown = false;

  void showAt(Vector2 candidatePosition) {
    position.setFrom(candidatePosition);
    _isShown = true;
  }

  void hide() {
    _isShown = false;
  }

  @override
  void render(Canvas canvas) {
    if (!_isShown) {
      return;
    }

    final previewRect = size.toRect();
    final previewShape = RRect.fromRectAndRadius(
      previewRect,
      const Radius.circular(12),
    );
    canvas.drawRRect(previewShape, Paint()..color = const Color(0x24F6B60B));
    canvas.drawRRect(
      previewShape,
      Paint()
        ..color = const Color(0xB3F6B60B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
