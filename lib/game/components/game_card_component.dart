import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../art/gameplay_art.dart';
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
  bool isInteractionLocked = false;
  bool isProcessing = false;
  bool _hasAcceptedDrag = false;
  double _resultPopRemaining = 0;
  double _validDropRemaining = 0;
  double _invalidDropRemaining = 0;
  double _stackLandingRemaining = 0;
  Vector2 _returnVisualOffset = Vector2.zero();
  bool _pendingInvalidDrop = false;
  final bool Function(String cardId) onDragStarted;
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

  bool get displaysBusyState => isLocked || isProcessing;

  @override
  void onDragStart(DragStartEvent event) {
    if (isLocked || isInteractionLocked) {
      return;
    }
    super.onDragStart(event);
    if (!onDragStarted(definition.id)) return;
    _hasAcceptedDrag = true;
    priority = _draggingPriority;
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
    final releasedPosition = position.clone();
    final targetPosition = onDragReleased(definition.id, releasedPosition);
    if (_pendingInvalidDrop) {
      _returnVisualOffset = releasedPosition - targetPosition;
    }
    position.setFrom(targetPosition);
    onDragFinished(definition.id);
    priority = restingPriority;
    _hasAcceptedDrag = false;
    _pendingInvalidDrop = false;
    super.onDragEnd(event);
  }

  void applyRestingState({
    required Vector2 cardPosition,
    required int priority,
    required CardDefinition definition,
    required bool isLocked,
    required bool isInteractionLocked,
    required bool isProcessing,
  }) {
    restingPriority = priority;
    this.definition = definition;
    this.isLocked = isLocked;
    this.isInteractionLocked = isInteractionLocked;
    this.isProcessing = isProcessing;
    if (!isDragged) {
      position.setFrom(cardPosition);
      this.priority = priority;
    }
  }

  void cancelActiveDrag() {
    _hasAcceptedDrag = false;
    priority = restingPriority;
  }

  void triggerResultPop() {
    _resultPopRemaining = GameLayout.resultCardPopDurationSeconds;
  }

  void triggerValidDrop() {
    _validDropRemaining = GameLayout.validDropFeedbackSeconds;
  }

  void triggerInvalidDrop() {
    _pendingInvalidDrop = true;
    _invalidDropRemaining = GameLayout.invalidDropReturnSeconds;
  }

  void triggerStackLanding() {
    _stackLandingRemaining = GameLayout.stackLandingFeedbackSeconds;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _resultPopRemaining = (_resultPopRemaining - dt)
        .clamp(0.0, GameLayout.resultCardPopDurationSeconds)
        .toDouble();
    _validDropRemaining = (_validDropRemaining - dt)
        .clamp(0.0, GameLayout.validDropFeedbackSeconds)
        .toDouble();
    _invalidDropRemaining = (_invalidDropRemaining - dt)
        .clamp(0.0, GameLayout.invalidDropReturnSeconds)
        .toDouble();
    _stackLandingRemaining = (_stackLandingRemaining - dt)
        .clamp(0.0, GameLayout.stackLandingFeedbackSeconds)
        .toDouble();
    if (_invalidDropRemaining <= 0) _returnVisualOffset.setZero();
  }

  @override
  void render(Canvas canvas) {
    final hasResultPop = _resultPopRemaining > 0;
    final isAnimating =
        hasResultPop ||
        isDragged ||
        _validDropRemaining > 0 ||
        _invalidDropRemaining > 0 ||
        _stackLandingRemaining > 0;
    if (isAnimating) {
      final resultScale = hasResultPop
          ? 1 +
                (.08 *
                    (_resultPopRemaining /
                        GameLayout.resultCardPopDurationSeconds))
          : 1.0;
      final validProgress =
          _validDropRemaining / GameLayout.validDropFeedbackSeconds;
      final snapScale = _validDropRemaining > 0
          ? 1 - (.035 * (1 - (validProgress * 2 - 1).abs()))
          : 1.0;
      final stackProgress =
          _stackLandingRemaining / GameLayout.stackLandingFeedbackSeconds;
      final stackScale = _stackLandingRemaining > 0
          ? 1 + (.055 * (1 - (stackProgress * 2 - 1).abs()))
          : 1.0;
      final returnProgress =
          _invalidDropRemaining / GameLayout.invalidDropReturnSeconds;
      final offset = _returnVisualOffset * returnProgress;
      final shake = _invalidDropRemaining > 0
          ? (1 - returnProgress) *
                3 *
                ((returnProgress * 24).round().isEven ? 1 : -1)
          : 0.0;
      final scale =
          resultScale *
          snapScale *
          stackScale *
          (isDragged ? GameLayout.cardPickupScale : 1);
      canvas
        ..save()
        ..translate(offset.x + shake, offset.y)
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
        : _invalidDropRemaining > 0
        ? const Color(0xFFE56B57)
        : _stackLandingRemaining > 0
        ? const Color(0xFFFFCB45)
        : isDragged
        ? accentColor
        : restingBorder;

    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: cardColor,
      borderColor: borderColor,
      radius: 12,
      borderWidth:
          isDragged || isLocked || isResult || _invalidDropRemaining > 0
          ? 3
          : 1.5,
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
    final artwork = GameplayArt.instance.cardImage(
      definition.type,
      isActive: isProcessing,
    );
    if (artwork != null) {
      GameplayArt.drawContained(
        canvas,
        artwork,
        Rect.fromLTWH(10, 7, size.x - 20, 37),
        padding: 1,
      );
    } else {
      _drawPlaceholderIcon(canvas);
    }
    ShellCanvas.label(
      canvas,
      text: definition.displayName,
      position: Vector2(size.x / 2, 48),
      style: _titleStyle.copyWith(
        color: const Color(0xFF3A2615),
        fontSize: definition.displayName.length > 14 ? 10 : 15,
      ),
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
    if (isAnimating) {
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
      case CardType.tomato:
      case CardType.slicedTomato:
        _drawTomatoPlaceholder(
          canvas,
          sliced: definition.type == CardType.slicedTomato,
        );
        break;
      case CardType.hotSauce:
        _drawSaucePlaceholder(canvas);
        break;
      case CardType.potato:
      case CardType.crispyFries:
        _drawPotatoPlaceholder(
          canvas,
          crispy: definition.type == CardType.crispyFries,
        );
        break;
      case CardType.pan:
        _drawPanPlaceholder(canvas);
        break;
      case CardType.knife:
        _drawKnifePlaceholder(canvas);
        break;
      case CardType.fryer:
        _drawFryerPlaceholder(canvas);
        break;
      case CardType.classicBurger:
      case CardType.deluxeBurger:
      case CardType.spicyBurger:
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

  void _drawTomatoPlaceholder(Canvas canvas, {required bool sliced}) {
    final center = Offset(size.x / 2, 29);
    canvas.drawCircle(center, 17, Paint()..color = const Color(0xFFD95845));
    canvas.drawCircle(center, 11, Paint()..color = const Color(0xFFF18263));
    if (sliced) {
      canvas.drawLine(
        Offset(center.dx - 14, center.dy),
        Offset(center.dx + 14, center.dy),
        Paint()
          ..color = const Color(0xFFFFD2A6)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawSaucePlaceholder(Canvas canvas) {
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

  void _drawPotatoPlaceholder(Canvas canvas, {required bool crispy}) {
    final paint = Paint()
      ..color = crispy ? const Color(0xFFF1B52C) : const Color(0xFFD7B16E);
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

  void _drawKnifePlaceholder(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x / 2 - 24, 26, 42, 7),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFB9C5CB),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x / 2 + 15, 25, 16, 9),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF516673),
    );
  }

  void _drawFryerPlaceholder(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.x / 2, 31), width: 44, height: 27),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF668394));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.x / 2, 23), width: 30, height: 7),
      Paint()..color = const Color(0xFF233D4A),
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
