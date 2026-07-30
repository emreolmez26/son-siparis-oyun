import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/card_definition.dart';
import 'shell_canvas.dart';

class GameCardComponent extends PositionComponent with DragCallbacks {
  GameCardComponent({
    required Vector2 initialPosition,
    required this.definition,
    required this.restingPriority,
    required this.onDragStarted,
    required this.onDragPositionChanged,
    required this.onDragReleased,
    required this.onDragFinished,
  }) : super(
         position: initialPosition,
         size: Vector2(GameLayout.cardWidth, GameLayout.cardHeight),
         priority: restingPriority,
       );

  static const _draggingPriority = 100;

  CardDefinition definition;
  int restingPriority;
  bool isLocked = false;
  bool isProcessing = false;
  bool _hasAcceptedDrag = false;
  double _resultPopRemaining = 0;
  final void Function(String cardId) onDragStarted;
  final void Function(String cardId, Vector2 cardPosition)
  onDragPositionChanged;
  final Vector2 Function(String cardId, Vector2 cardPosition) onDragReleased;
  final void Function(String cardId) onDragFinished;

  static const _titleStyle = TextStyle(
    color: GameLayout.primaryTextColor,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
  static const _categoryStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: .7,
  );
  static const _stackMarkerStyle = TextStyle(
    color: Color(0xFF805B20),
    fontSize: 9,
    fontWeight: FontWeight.w900,
  );

  @override
  void onDragStart(DragStartEvent event) {
    if (isLocked) {
      return;
    }
    super.onDragStart(event);
    _hasAcceptedDrag = true;
    priority = _draggingPriority;
    onDragStarted(definition.id);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_hasAcceptedDrag) {
      return;
    }
    position += event.localDelta;
    onDragPositionChanged(definition.id, position.clone());
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!_hasAcceptedDrag) {
      return;
    }
    position.setFrom(onDragReleased(definition.id, position.clone()));
    onDragFinished(definition.id);
    priority = restingPriority;
    _hasAcceptedDrag = false;
    super.onDragEnd(event);
  }

  void applyRestingState({
    required Vector2 cardPosition,
    required int priority,
    required CardDefinition definition,
    required bool isLocked,
    required bool isProcessing,
  }) {
    position.setFrom(cardPosition);
    restingPriority = priority;
    this.definition = definition;
    this.isLocked = isLocked;
    this.isProcessing = isProcessing;
    if (!isDragged) {
      this.priority = priority;
    }
  }

  void triggerResultPop() {
    _resultPopRemaining = GameLayout.resultCardPopDurationSeconds;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _resultPopRemaining = (_resultPopRemaining - dt)
        .clamp(0.0, GameLayout.resultCardPopDurationSeconds)
        .toDouble();
  }

  @override
  void render(Canvas canvas) {
    final hasResultPop = _resultPopRemaining > 0;
    if (hasResultPop) {
      final progress =
          _resultPopRemaining / GameLayout.resultCardPopDurationSeconds;
      final scale = 1 + (.08 * progress);
      canvas
        ..save()
        ..translate(size.x / 2, size.y / 2)
        ..scale(scale)
        ..translate(-size.x / 2, -size.y / 2);
    }

    final shadowRect = Rect.fromLTWH(3, 4, size.x - 3, size.y - 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(12)),
      Paint()..color = const Color(0x55000000),
    );

    final isEquipment = definition.category == CardCategory.equipment;
    final isResult = definition.category == CardCategory.result;
    final cardColor = isEquipment
        ? const Color(0xFFE1EBF1)
        : isResult
        ? const Color(0xFFFFD978)
        : const Color(0xFFFFE6A8);
    final restingBorder = isEquipment
        ? const Color(0xFF4D7E9E)
        : isResult
        ? const Color(0xFFE19A18)
        : const Color(0xFFB77B25);
    final accentColor = isEquipment
        ? const Color(0xFF75B9D8)
        : isResult
        ? const Color(0xFFFFB800)
        : GameLayout.accentColor;
    final borderColor = isProcessing
        ? const Color(0xFFE46A35)
        : isLocked
        ? GameLayout.accentColor
        : isDragged
        ? accentColor
        : restingBorder;

    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: cardColor,
      borderColor: borderColor,
      radius: 12,
      borderWidth: isDragged || isLocked || isResult ? 3 : 1.5,
    );
    if (isResult && hasResultPop) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          size.toRect().inflate(4),
          const Radius.circular(15),
        ),
        Paint()
          ..color = const Color(0x66FFE078)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    ShellCanvas.label(
      canvas,
      text: definition.displayName.substring(0, 1),
      position: Vector2(13, 12),
      style: _stackMarkerStyle.copyWith(
        color: isEquipment
            ? const Color(0xFF395A70)
            : isResult
            ? const Color(0xFF80510B)
            : const Color(0xFF805B20),
      ),
      align: TextAlign.center,
    );
    _drawPlaceholderIcon(canvas);
    ShellCanvas.label(
      canvas,
      text: definition.displayName,
      position: Vector2(size.x / 2, 48),
      style: _titleStyle.copyWith(color: const Color(0xFF3A2615)),
      align: TextAlign.center,
      maxWidth: size.x - 12,
    );
    if (isLocked) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(size.toRect(), const Radius.circular(12)),
        Paint()
          ..color = isProcessing
              ? const Color(0x33E46A35)
              : const Color(0x24F6B60B),
      );
      ShellCanvas.label(
        canvas,
        text: isProcessing ? 'PİŞİYOR' : 'MEŞGUL',
        position: Vector2(size.x / 2, size.y - 11),
        style: const TextStyle(
          color: Color(0xFF5A2918),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
      );
    }
    ShellCanvas.label(
      canvas,
      text: definition.categoryLabel,
      position: Vector2(size.x / 2, 66),
      style: _categoryStyle.copyWith(
        color: isEquipment
            ? const Color(0xFF395A70)
            : isResult
            ? const Color(0xFF80510B)
            : const Color(0xFF805B20),
      ),
      align: TextAlign.center,
    );
    if (hasResultPop) {
      canvas.restore();
    }
  }

  void _drawPlaceholderIcon(Canvas canvas) {
    switch (definition.type) {
      case CardType.bread:
        _drawBreadPlaceholder(canvas);
        break;
      case CardType.patty:
        _drawPattyPlaceholder(canvas);
        break;
      case CardType.cookedPatty:
        _drawCookedPattyPlaceholder(canvas);
        break;
      case CardType.cheese:
        _drawCheesePlaceholder(canvas);
        break;
      case CardType.pan:
        _drawPanPlaceholder(canvas);
        break;
      case CardType.classicBurger:
        _drawBurgerPlaceholder(canvas);
        break;
    }
  }

  void _drawBreadPlaceholder(Canvas canvas) {
    final bunRect = Rect.fromCenter(
      center: Offset(size.x / 2, 29),
      width: 50,
      height: 25,
    );
    canvas.drawOval(bunRect, Paint()..color = const Color(0xFFD9973D));
    canvas.drawOval(
      Rect.fromLTWH(bunRect.left + 4, bunRect.top + 3, bunRect.width - 8, 10),
      Paint()..color = const Color(0xFFF4C66E),
    );

    for (final offset in const [Offset(-12, 0), Offset(0, -2), Offset(12, 0)]) {
      canvas.drawCircle(
        Offset(bunRect.center.dx + offset.dx, bunRect.center.dy + offset.dy),
        1.5,
        Paint()..color = const Color(0xFF9A6326),
      );
    }
  }

  void _drawPattyPlaceholder(Canvas canvas) {
    final pattyRect = Rect.fromCenter(
      center: Offset(size.x / 2, 30),
      width: 52,
      height: 24,
    );
    canvas.drawOval(pattyRect, Paint()..color = const Color(0xFF9A4C34));
    canvas.drawOval(
      Rect.fromLTWH(
        pattyRect.left + 5,
        pattyRect.top + 5,
        pattyRect.width - 10,
        8,
      ),
      Paint()..color = const Color(0xFFCB7651),
    );
  }

  void _drawCookedPattyPlaceholder(Canvas canvas) {
    final pattyRect = Rect.fromCenter(
      center: Offset(size.x / 2, 30),
      width: 52,
      height: 24,
    );
    canvas.drawOval(pattyRect, Paint()..color = const Color(0xFF623527));
    canvas.drawOval(
      Rect.fromLTWH(
        pattyRect.left + 5,
        pattyRect.top + 5,
        pattyRect.width - 10,
        8,
      ),
      Paint()..color = const Color(0xFFD17A3E),
    );
    for (final yOffset in const [9.0, 14.0]) {
      canvas.drawLine(
        Offset(pattyRect.left + 11, pattyRect.top + yOffset),
        Offset(pattyRect.right - 11, pattyRect.top + yOffset),
        Paint()
          ..color = const Color(0xFF3F241D)
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawCheesePlaceholder(Canvas canvas) {
    final cheesePath = Path()
      ..moveTo(size.x / 2 - 28, 40)
      ..lineTo(size.x / 2 + 28, 40)
      ..lineTo(size.x / 2 + 18, 17)
      ..lineTo(size.x / 2 - 18, 17)
      ..close();
    canvas.drawPath(cheesePath, Paint()..color = const Color(0xFFF4C948));
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

  void _drawPanPlaceholder(Canvas canvas) {
    final center = Offset(size.x / 2 - 8, 28);
    canvas.drawCircle(center, 17, Paint()..color = const Color(0xFF54778D));
    canvas.drawCircle(center, 12, Paint()..color = const Color(0xFFB5CFDD));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x / 2 + 7, 24, 25, 8),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF54778D),
    );
  }

  void _drawBurgerPlaceholder(Canvas canvas) {
    final centerX = size.x / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, 22), width: 50, height: 15),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFFD68B30),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, 29), width: 54, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF6E9D3C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, 34), width: 50, height: 9),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF693324),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, 40), width: 52, height: 10),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFE1A13C),
    );
  }
}
