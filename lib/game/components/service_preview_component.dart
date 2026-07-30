import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'shell_canvas.dart';

class ServicePreviewComponent extends PositionComponent {
  ServicePreviewComponent() : super(priority: _previewPriority);

  static const _previewPriority = 93;
  Rect? _bounds;
  String _resultName = '';

  void show(Rect bounds, {required String resultName}) {
    _bounds = bounds;
    _resultName = resultName;
  }

  void hide() {
    _bounds = null;
  }

  @override
  void render(Canvas canvas) {
    final bounds = _bounds;
    if (bounds == null) {
      return;
    }
    final glow = RRect.fromRectAndRadius(
      bounds.inflate(5),
      const Radius.circular(14),
    );
    canvas.drawRRect(glow, Paint()..color = const Color(0x337EBB58));
    canvas.drawRRect(
      glow,
      Paint()
        ..color = const Color(0xFF7EBB58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final badge = Rect.fromCenter(
      center: Offset(bounds.center.dx, bounds.top - 60),
      width: 106,
      height: 30,
    );
    ShellCanvas.panel(
      canvas,
      badge,
      color: const Color(0xFF315025),
      borderColor: const Color(0xFF9ED87B),
      radius: 15,
      borderWidth: 1.5,
    );
    ShellCanvas.label(
      canvas,
      text: _resultName,
      position: Vector2(badge.center.dx, badge.top + 7),
      style: const TextStyle(
        color: Color(0xFFF2FFE9),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }
}
