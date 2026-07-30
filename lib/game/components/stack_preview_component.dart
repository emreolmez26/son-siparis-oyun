import 'dart:ui';

import 'package:flame/components.dart';

class StackPreviewComponent extends PositionComponent {
  StackPreviewComponent() : super(priority: _previewPriority);

  static const _previewPriority = 90;
  Rect? _targetBounds;
  Rect? _newTopBounds;

  void show({required Rect targetBounds, required Rect newTopBounds}) {
    _targetBounds = targetBounds;
    _newTopBounds = newTopBounds;
  }

  void hide() {
    _targetBounds = null;
    _newTopBounds = null;
  }

  @override
  void render(Canvas canvas) {
    final targetBounds = _targetBounds;
    final newTopBounds = _newTopBounds;
    if (targetBounds == null || newTopBounds == null) {
      return;
    }

    final targetShape = RRect.fromRectAndRadius(
      targetBounds,
      const Radius.circular(14),
    );
    canvas.drawRRect(targetShape, Paint()..color = const Color(0x24F6B60B));
    canvas.drawRRect(
      targetShape,
      Paint()
        ..color = const Color(0xC9F6B60B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final topShape = RRect.fromRectAndRadius(
      newTopBounds,
      const Radius.circular(12),
    );
    canvas.drawRRect(topShape, Paint()..color = const Color(0x2EF6B60B));
    canvas.drawRRect(
      topShape,
      Paint()
        ..color = const Color(0xB3F6B60B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
