import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class PauseOverlayComponent extends PositionComponent with TapCallbacks {
  PauseOverlayComponent({required this.isShowing, required this.onResume})
    : super(
        size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
        priority: 220,
      );

  final bool Function() isShowing;
  final void Function() onResume;

  Rect get _panelBounds => Rect.fromCenter(
    center: const Offset(
      GameLayout.designWidth / 2,
      GameLayout.designHeight / 2,
    ),
    width: 360,
    height: 184,
  );

  Rect get _resumeBounds => Rect.fromCenter(
    center: Offset(_panelBounds.center.dx, _panelBounds.bottom - 42),
    width: 216,
    height: 42,
  );

  @override
  bool containsLocalPoint(Vector2 point) {
    return isShowing() && super.containsLocalPoint(point);
  }

  @override
  void render(Canvas canvas) {
    if (!isShowing()) {
      return;
    }
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xB8000000));
    ShellCanvas.panel(
      canvas,
      _panelBounds,
      color: GameLayout.hudColor,
      borderColor: GameLayout.accentColor,
      radius: 18,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'DURAKLATILDI',
      position: Vector2(_panelBounds.center.dx, _panelBounds.top + 35),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'Vardiya ve müşteri sabır süresi bekliyor',
      position: Vector2(_panelBounds.center.dx, _panelBounds.top + 74),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.panel(
      canvas,
      _resumeBounds,
      color: GameLayout.accentColor,
      borderColor: const Color(0xFFFFD86F),
      radius: 12,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'DEVAM ET',
      position: Vector2(_resumeBounds.center.dx, _resumeBounds.top + 12),
      style: const TextStyle(
        color: Color(0xFF39250C),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isShowing()) {
      return;
    }
    final localPosition = event.localPosition;
    if (_resumeBounds.contains(Offset(localPosition.x, localPosition.y))) {
      onResume();
    }
  }
}
