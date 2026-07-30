import 'dart:ui';

import 'package:flame/components.dart';

class ProcessingPreviewComponent extends PositionComponent {
  ProcessingPreviewComponent() : super(priority: _previewPriority);

  static const _previewPriority = 92;
  Rect? _panBounds;
  Rect? _inputBounds;
  bool _isAvailable = false;

  void show({
    required Rect panBounds,
    required Rect inputBounds,
    required bool isAvailable,
  }) {
    _panBounds = panBounds;
    _inputBounds = inputBounds;
    _isAvailable = isAvailable;
  }

  void hide() {
    _panBounds = null;
    _inputBounds = null;
  }

  @override
  void render(Canvas canvas) {
    final panBounds = _panBounds;
    final inputBounds = _inputBounds;
    if (panBounds == null || inputBounds == null) {
      return;
    }

    final color = _isAvailable
        ? const Color(0xFF78C65A)
        : const Color(0xFFE08A3A);
    final panShape = RRect.fromRectAndRadius(
      panBounds.inflate(3),
      const Radius.circular(14),
    );
    canvas.drawRRect(panShape, Paint()..color = color.withValues(alpha: .16));
    canvas.drawRRect(
      panShape,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final inputShape = RRect.fromRectAndRadius(
      inputBounds,
      const Radius.circular(12),
    );
    canvas.drawRRect(
      inputShape,
      Paint()
        ..color = color.withValues(alpha: .18)
        ..style = PaintingStyle.fill,
    );
  }
}
