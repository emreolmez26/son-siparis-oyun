import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../models/sabotage.dart';
import '../state/rival_state.dart';
import 'shell_canvas.dart';

class CountermeasureCardComponent extends PositionComponent with DragCallbacks {
  CountermeasureCardComponent({
    required this.rivalState,
    required this.canInteract,
    required this.onReleased,
  }) : super(
         position: Vector2(
           RivalState.responsePosition.dx,
           RivalState.responsePosition.dy,
         ),
         size: Vector2(128, 72),
         priority: 115,
       );

  final RivalState rivalState;
  final bool Function() canInteract;
  final bool Function(String runtimeId, Vector2 center) onReleased;
  bool _dragging = false;

  @override
  bool containsLocalPoint(Vector2 point) =>
      rivalState.countermeasureId != null &&
      canInteract() &&
      super.containsLocalPoint(point);

  @override
  void onDragStart(DragStartEvent event) {
    if (!canInteract() || rivalState.countermeasureId == null) return;
    super.onDragStart(event);
    _dragging = true;
    priority = 140;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragging) position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!_dragging) return;
    final id = rivalState.countermeasureId;
    if (id != null) onReleased(id, position + (size / 2));
    position.setValues(
      RivalState.responsePosition.dx,
      RivalState.responsePosition.dy,
    );
    priority = 115;
    _dragging = false;
    super.onDragEnd(event);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (rivalState.countermeasureId == null && !_dragging) {
      position.setValues(
        RivalState.responsePosition.dx,
        RivalState.responsePosition.dy,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final type = rivalState.countermeasureType;
    if (type == null) return;
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: const Color(0xFFEEE3C5),
      borderColor: const Color(0xFFD77A38),
      radius: 12,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: type.displayName,
      position: Vector2(size.x / 2, 18),
      style: const TextStyle(
        color: Color(0xFF39261D),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'SÜRÜKLE',
      position: Vector2(size.x / 2, 46),
      style: const TextStyle(
        color: Color(0xFF9B3E2F),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }
}
