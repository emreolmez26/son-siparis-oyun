import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'shell_canvas.dart';

class RecipePreviewComponent extends PositionComponent {
  RecipePreviewComponent() : super(priority: _previewPriority);

  static const _previewPriority = 91;
  Rect? _targetBounds;
  Rect? _newTopBounds;
  String _label = '';

  void show({
    required Rect targetBounds,
    required Rect newTopBounds,
    required String recipeName,
  }) {
    _targetBounds = targetBounds;
    _newTopBounds = newTopBounds;
    _label = recipeName;
  }

  void hide() {
    _targetBounds = null;
    _newTopBounds = null;
    _label = '';
  }

  @override
  void render(Canvas canvas) {
    final targetBounds = _targetBounds;
    final newTopBounds = _newTopBounds;
    if (targetBounds == null || newTopBounds == null) {
      return;
    }

    final gold = const Color(0xFFFFC83D);
    final targetShape = RRect.fromRectAndRadius(
      targetBounds.inflate(5),
      const Radius.circular(17),
    );
    canvas.drawRRect(targetShape, Paint()..color = gold.withValues(alpha: .2));
    canvas.drawRRect(
      targetShape,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final topShape = RRect.fromRectAndRadius(
      newTopBounds,
      const Radius.circular(12),
    );
    canvas.drawRRect(topShape, Paint()..color = gold.withValues(alpha: .28));
    canvas.drawRRect(
      topShape,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final labelBounds = Rect.fromCenter(
      center: Offset(targetBounds.center.dx, targetBounds.top - 13),
      width: 132,
      height: 23,
    );
    ShellCanvas.panel(
      canvas,
      labelBounds,
      color: const Color(0xFF5B3A12),
      borderColor: gold,
      radius: 11,
      borderWidth: 1.5,
    );
    ShellCanvas.label(
      canvas,
      text: _label,
      position: Vector2(labelBounds.center.dx, labelBounds.top + 4),
      style: const TextStyle(
        color: Color(0xFFFFF3C8),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
      maxWidth: labelBounds.width - 10,
    );
  }
}
