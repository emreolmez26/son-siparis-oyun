import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/card_definition.dart';
import '../models/sabotage.dart';
import '../state/rival_state.dart';
import 'shell_canvas.dart';

class RivalSabotageComponent extends PositionComponent {
  RivalSabotageComponent({
    required this.rivalState,
    required this.positionForCard,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 105,
       );

  final RivalState rivalState;
  final Offset Function(String cardId) positionForCard;

  @override
  void render(Canvas canvas) {
    if (!rivalState.enabled && rivalState.feedbackText == null) return;
    if (rivalState.enabled) {
      _drawIndicator(canvas);
    }
    final active = rivalState.current;
    if (active != null) {
      _drawWarning(canvas, active);
      if (active.phase == SabotagePhase.active) {
        _drawActiveEffect(canvas, active);
      }
      _drawCounterTarget(canvas, active);
    }
    final feedback = rivalState.feedbackText;
    if (feedback != null) {
      ShellCanvas.label(
        canvas,
        text: feedback,
        position: Vector2(GameLayout.designWidth / 2, 202),
        style: const TextStyle(
          color: Color(0xFFFF6E54),
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
      );
    }
  }

  void _drawIndicator(Canvas canvas) {
    const bounds = Rect.fromLTWH(880, 18, 288, 54);
    ShellCanvas.panel(
      canvas,
      bounds,
      color: const Color(0xFF321C18),
      borderColor: const Color(0xFF9E4937),
      radius: 10,
    );
    ShellCanvas.label(
      canvas,
      text: RivalState.rivalName,
      position: Vector2(bounds.left + 14, bounds.top + 9),
      style: const TextStyle(
        color: Color(0xFFFF8A65),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
    ShellCanvas.label(
      canvas,
      text:
          'BASKI  •  Engellenen ${rivalState.defendedCount}  Etki ${rivalState.affectedCount}',
      position: Vector2(bounds.left + 14, bounds.top + 31),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _drawWarning(Canvas canvas, ActiveSabotage active) {
    const bounds = Rect.fromLTWH(438, 78, 404, 66);
    ShellCanvas.panel(
      canvas,
      bounds,
      color: const Color(0xE6351713),
      borderColor: const Color(0xFFFF6E54),
      radius: 11,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: active.event.type.warningText,
      position: Vector2(bounds.center.dx, bounds.top + 11),
      style: const TextStyle(
        color: Color(0xFFFFA07A),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text:
          '${_targetLabel(active.event)}  •  ${active.remainingSeconds.toStringAsFixed(1)} sn  •  ${active.event.type.countermeasure.displayName}',
      position: Vector2(bounds.center.dx, bounds.top + 37),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      align: TextAlign.center,
    );
  }

  void _drawActiveEffect(Canvas canvas, ActiveSabotage active) {
    switch (active.event.type) {
      case SabotageType.powerSurge:
        for (final id in const ['pan_01', 'knife_01', 'fryer_01']) {
          final position = positionForCard(id);
          _drawEquipmentStatus(canvas, position, 'ELEKTRİK YOK');
        }
      case SabotageType.equipmentJam:
        final id = active.event.targetEquipmentId;
        if (id != null) {
          _drawEquipmentStatus(canvas, positionForCard(id), 'SIKIŞTI');
        }
      case SabotageType.greasyTable:
        final region = active.event.greasyRegion;
        if (region != null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(region, const Radius.circular(16)),
            Paint()..color = const Color(0x669D8427),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(region, const Radius.circular(16)),
            Paint()
              ..color = const Color(0xFFE0BE43)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
          ShellCanvas.label(
            canvas,
            text: 'YAĞLI  ${_directionArrow(active.event.slideDirection)}',
            position: Vector2(region.center.dx, region.center.dy - 8),
            style: const TextStyle(
              color: Color(0xFFFFE38A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
            align: TextAlign.center,
          );
        }
      case SabotageType.fakeOrder:
        _drawFakeTicket(canvas, active.event.fakeOrderType);
    }
  }

  void _drawCounterTarget(Canvas canvas, ActiveSabotage active) {
    final target = switch (active.event.type) {
      SabotageType.powerSurge => RivalState.fuseBoxBounds,
      SabotageType.equipmentJam => _boundsFor(active.event.targetEquipmentId),
      SabotageType.greasyTable => active.event.greasyRegion,
      SabotageType.fakeOrder => RivalState.fakeTicketBounds,
    };
    if (target == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(target.inflate(4), const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFFFFB74D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (active.event.type == SabotageType.powerSurge) {
      ShellCanvas.label(
        canvas,
        text: 'SİGORTA KUTUSU',
        position: Vector2(target.center.dx, target.top + 17),
        style: const TextStyle(
          color: GameLayout.primaryTextColor,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
      );
    }
  }

  void _drawFakeTicket(Canvas canvas, CardType? type) {
    ShellCanvas.panel(
      canvas,
      RivalState.fakeTicketBounds,
      color: const Color(0xFF3D2624),
      borderColor: const Color(0xFFB65A49),
      radius: 10,
    );
    ShellCanvas.label(
      canvas,
      text: 'ŞÜPHELİ SİPARİŞ  ?!\n${_resultName(type)}',
      position: Vector2(
        RivalState.fakeTicketBounds.center.dx,
        RivalState.fakeTicketBounds.top + 18,
      ),
      style: const TextStyle(
        color: Color(0xFFFFB09C),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _drawEquipmentStatus(Canvas canvas, Offset position, String text) {
    final bounds = Rect.fromLTWH(
      position.dx,
      position.dy,
      GameLayout.cardWidth,
      GameLayout.cardHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(12)),
      Paint()..color = const Color(0x99000000),
    );
    ShellCanvas.label(
      canvas,
      text: text,
      position: Vector2(bounds.center.dx, bounds.center.dy - 7),
      style: const TextStyle(
        color: Color(0xFFFF6E54),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  Rect? _boundsFor(String? id) {
    if (id == null) return null;
    final position = positionForCard(id);
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      GameLayout.cardWidth,
      GameLayout.cardHeight,
    );
  }

  String _targetLabel(ScheduledSabotage event) => switch (event.type) {
    SabotageType.powerSurge => 'Tüm ekipman',
    SabotageType.equipmentJam => switch (event.targetEquipmentId) {
      'pan_01' => 'Tava',
      'knife_01' => 'Bıçak',
      'fryer_01' => 'Fritöz',
      _ => 'Ekipman',
    },
    SabotageType.greasyTable => 'Mutfak tezgâhı',
    SabotageType.fakeOrder => 'Müşteri alanı',
  };

  String _directionArrow(Offset direction) {
    if (direction.dx > 0) return '→';
    if (direction.dx < 0) return '←';
    if (direction.dy > 0) return '↓';
    return '↑';
  }

  String _resultName(CardType? type) => switch (type) {
    CardType.classicBurger => 'Klasik Burger',
    CardType.deluxeBurger => 'Gurme Burger',
    CardType.spicyBurger => 'Ateş Burger',
    CardType.crispyFries => 'Çıtır Patates',
    _ => 'Belirsiz Ürün',
  };
}
