import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../art/gameplay_art.dart';
import '../game_layout.dart';
import '../models/card_definition.dart';
import '../state/pantry_supply_state.dart';
import 'shell_canvas.dart';

class PantrySupplyComponent extends PositionComponent with DragCallbacks {
  PantrySupplyComponent({
    required this.supplyId,
    required this.pantryState,
    required this.isShowing,
    required this.canInteract,
    required this.onSpawnStarted,
    required this.onSpawnPositionChanged,
    required this.onSpawnReleased,
    required this.onSpawnFinished,
    required this.onSpawnCancelled,
  }) : _restingPosition = Vector2(
         pantryState.slotFor(supplyId).position.dx,
         pantryState.slotFor(supplyId).position.dy,
       ),
       super(
         position: Vector2(
           pantryState.slotFor(supplyId).position.dx,
           pantryState.slotFor(supplyId).position.dy,
         ),
         size: Vector2(GameLayout.cardWidth, GameLayout.cardHeight),
         priority: 55,
       );

  final String supplyId;
  final PantrySupplyState pantryState;
  final bool Function() isShowing;
  final bool Function() canInteract;
  final String? Function(String supplyId) onSpawnStarted;
  final void Function(String workingCardId, Vector2 position)
  onSpawnPositionChanged;
  final void Function(String workingCardId, Vector2 position) onSpawnReleased;
  final void Function(String workingCardId) onSpawnFinished;
  final void Function(String workingCardId) onSpawnCancelled;
  final Vector2 _restingPosition;
  String? _workingCardId;

  bool get isSpawning => _workingCardId != null;

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() &&
      canInteract() &&
      pantryState.isAvailable(supplyId) &&
      super.containsLocalPoint(point);

  @override
  void onDragStart(DragStartEvent event) {
    if (!canInteract() || !pantryState.isAvailable(supplyId)) return;
    final workingCardId = onSpawnStarted(supplyId);
    if (workingCardId == null) return;
    super.onDragStart(event);
    _workingCardId = workingCardId;
    priority = 100;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final workingCardId = _workingCardId;
    if (workingCardId == null) return;
    position += event.localDelta;
    onSpawnPositionChanged(workingCardId, position.clone());
  }

  @override
  void onDragEnd(DragEndEvent event) {
    final workingCardId = _workingCardId;
    if (workingCardId == null) return;
    onSpawnReleased(workingCardId, position.clone());
    onSpawnFinished(workingCardId);
    _resetVisual();
    super.onDragEnd(event);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    final workingCardId = _workingCardId;
    if (workingCardId != null) onSpawnCancelled(workingCardId);
    _resetVisual();
    super.onDragCancel(event);
  }

  void cancelActiveSpawn() {
    _resetVisual();
  }

  void _resetVisual() {
    _workingCardId = null;
    position.setFrom(_restingPosition);
    priority = 55;
  }

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    final definition = pantryState.slotFor(supplyId).definition;
    if (isSpawning) {
      canvas.save();
      canvas.translate(
        _restingPosition.x - position.x,
        _restingPosition.y - position.y,
      );
      _drawCard(canvas, definition, ghost: true);
      canvas.restore();
    }
    _drawCard(canvas, definition);
  }

  void _drawCard(
    Canvas canvas,
    CardDefinition definition, {
    bool ghost = false,
  }) {
    final bounds = size.toRect();
    ShellCanvas.panel(
      canvas,
      bounds,
      color: ghost ? const Color(0xAAFFF3C4) : const Color(0xFFFFE7A7),
      borderColor: GameLayout.accentColor,
      radius: 10,
      borderWidth: ghost ? 1 : 2,
    );
    ShellCanvas.label(
      canvas,
      text: definition.displayName.substring(0, 1),
      position: Vector2(13, 12),
      style: TextStyle(
        color: const Color(0xFF805B20).withValues(alpha: ghost ? .55 : 1),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    final artwork = GameplayArt.instance.cardImage(definition.type);
    if (artwork != null) {
      GameplayArt.drawContained(
        canvas,
        artwork,
        Rect.fromLTWH(10, 7, size.x - 20, 37),
        padding: 1,
      );
    } else {
      _drawIngredientIcon(canvas, definition.type);
    }
    ShellCanvas.label(
      canvas,
      text: definition.displayName,
      position: Vector2(bounds.center.dx, 48),
      style: TextStyle(
        color: const Color(0xFF3E2B20).withValues(alpha: ghost ? .65 : 1),
        fontSize: definition.displayName.length > 12 ? 10 : 14,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
      maxWidth: bounds.width - 12,
    );
    ShellCanvas.label(
      canvas,
      text: 'KİLER',
      position: Vector2(bounds.center.dx, 66),
      style: TextStyle(
        color: const Color(0xFF805B20).withValues(alpha: ghost ? .55 : 1),
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      ),
      align: TextAlign.center,
    );
  }

  void _drawIngredientIcon(Canvas canvas, CardType type) {
    switch (type) {
      case CardType.bread:
        _drawBreadIcon(canvas);
      case CardType.patty:
        _drawPattyIcon(canvas);
      case CardType.cheese:
        _drawCheeseIcon(canvas);
      case CardType.tomato:
        _drawTomatoIcon(canvas);
      case CardType.hotSauce:
        _drawSauceIcon(canvas);
      case CardType.potato:
        _drawPotatoIcon(canvas);
      case CardType.cookedPatty:
      case CardType.slicedTomato:
      case CardType.crispyFries:
      case CardType.pan:
      case CardType.knife:
      case CardType.fryer:
      case CardType.classicBurger:
      case CardType.deluxeBurger:
      case CardType.spicyBurger:
        throw StateError('$type cannot be used as a pantry supply.');
    }
  }

  void _drawBreadIcon(Canvas canvas) {
    final bun = Rect.fromCenter(
      center: Offset(size.x / 2, 29),
      width: 50,
      height: 25,
    );
    canvas.drawOval(bun, Paint()..color = const Color(0xFFD9973D));
    canvas.drawOval(
      Rect.fromLTWH(bun.left + 4, bun.top + 3, bun.width - 8, 10),
      Paint()..color = const Color(0xFFF4C66E),
    );
    for (final offset in const [Offset(-12, 0), Offset(0, -2), Offset(12, 0)]) {
      canvas.drawCircle(
        bun.center + offset,
        1.5,
        Paint()..color = const Color(0xFF9A6326),
      );
    }
  }

  void _drawPattyIcon(Canvas canvas) {
    final patty = Rect.fromCenter(
      center: Offset(size.x / 2, 30),
      width: 52,
      height: 24,
    );
    canvas.drawOval(patty, Paint()..color = const Color(0xFF9A4C34));
    canvas.drawOval(
      Rect.fromLTWH(patty.left + 5, patty.top + 5, patty.width - 10, 8),
      Paint()..color = const Color(0xFFCB7651),
    );
  }

  void _drawCheeseIcon(Canvas canvas) {
    final cheese = Path()
      ..moveTo(size.x / 2 - 28, 40)
      ..lineTo(size.x / 2 + 28, 40)
      ..lineTo(size.x / 2 + 18, 17)
      ..lineTo(size.x / 2 - 18, 17)
      ..close();
    canvas.drawPath(cheese, Paint()..color = const Color(0xFFF4C948));
    for (final offset in const [
      Offset(-11, 28),
      Offset(8, 31),
      Offset(2, 22),
    ]) {
      canvas.drawCircle(
        Offset(size.x / 2 + offset.dx, offset.dy),
        2.5,
        Paint()..color = const Color(0xFFD99C25),
      );
    }
  }

  void _drawTomatoIcon(Canvas canvas) {
    final center = Offset(size.x / 2, 29);
    canvas.drawCircle(center, 17, Paint()..color = const Color(0xFFD95845));
    canvas.drawCircle(center, 11, Paint()..color = const Color(0xFFF18263));
  }

  void _drawSauceIcon(Canvas canvas) {
    final bottle = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.x / 2, 30), width: 22, height: 35),
      const Radius.circular(6),
    );
    canvas.drawRRect(bottle, Paint()..color = const Color(0xFFCF4B37));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.x / 2, 10), width: 10, height: 5),
      Paint()..color = const Color(0xFF573022),
    );
  }

  void _drawPotatoIcon(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFD7B16E);
    for (final offset in const [Offset(-14, 2), Offset(-4, -3), Offset(7, 2)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.x / 2 + offset.dx, 29 + offset.dy),
            width: 8,
            height: 28,
          ),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }
}
