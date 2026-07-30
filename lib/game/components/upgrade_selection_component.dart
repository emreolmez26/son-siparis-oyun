import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../data/prototype_upgrade_definitions.dart';
import '../game_layout.dart';
import '../models/upgrade_definition.dart';
import '../state/game_flow_controller.dart';
import 'shell_canvas.dart';

class UpgradeSelectionComponent extends PositionComponent with TapCallbacks {
  UpgradeSelectionComponent({
    required this.flow,
    required this.isShowing,
    required this.onConfirm,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 310,
       );

  final GameFlowController flow;
  final bool Function() isShowing;
  final void Function() onConfirm;

  Rect _cardBounds(int index) =>
      Rect.fromLTWH(88 + (index * 372), 176, 330, 330);
  Rect get _confirmBounds =>
      Rect.fromCenter(center: const Offset(640, 608), width: 300, height: 54);

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() && super.containsLocalPoint(point);

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    canvas.drawRect(size.toRect(), Paint()..color = GameLayout.backgroundColor);
    ShellCanvas.label(
      canvas,
      text: 'SON SİPARİŞ',
      position: Vector2(36, 30),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 23,
        fontWeight: FontWeight.w900,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: 'SEVİYE 1',
      position: Vector2(38, 59),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
    _drawTopValue(
      canvas,
      const Rect.fromLTWH(986, 25, 134, 42),
      '● ${flow.progression.walletCoins}',
    );
    _drawTopValue(
      canvas,
      const Rect.fromLTWH(1134, 25, 104, 42),
      'GÜN ${flow.progression.currentDay + 1}',
    );
    ShellCanvas.label(
      canvas,
      text: 'BİR YÜKSELTME SEÇ',
      position: Vector2(640, 92),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 30,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'Sonraki vardiyada mutfağını güçlendir.',
      position: Vector2(640, 130),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      align: TextAlign.center,
    );
    for (final entry in prototypeUpgradeDefinitions.indexed) {
      _drawCard(canvas, entry.$1, entry.$2);
    }
    final isEnabled = flow.canConfirmUpgrade;
    ShellCanvas.panel(
      canvas,
      _confirmBounds,
      color: isEnabled ? GameLayout.accentColor : const Color(0xFF655847),
      borderColor: isEnabled
          ? const Color(0xFFFFD86F)
          : GameLayout.panelStrokeColor,
      radius: 13,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'SEÇİMİ ONAYLA',
      position: Vector2(640, _confirmBounds.top + 17),
      style: TextStyle(
        color: isEnabled ? const Color(0xFF39250C) : GameLayout.mutedTextColor,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _drawTopValue(Canvas canvas, Rect bounds, String text) {
    ShellCanvas.panel(
      canvas,
      bounds,
      color: GameLayout.hudColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 9,
    );
    ShellCanvas.label(
      canvas,
      text: text,
      position: Vector2(bounds.center.dx, bounds.top + 12),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _drawCard(Canvas canvas, int index, UpgradeDefinition definition) {
    final bounds = _cardBounds(index);
    final level = flow.progression.upgrades.levelFor(definition.id);
    final isMaximum = flow.progression.upgrades.isAtMaximum(definition);
    final selected = flow.selectedUpgrade?.id == definition.id;
    final border = selected
        ? GameLayout.accentColor
        : GameLayout.panelStrokeColor;
    ShellCanvas.panel(
      canvas,
      bounds,
      color: const Color(0xFFFFF7DD),
      borderColor: border,
      radius: 18,
      borderWidth: selected ? 4 : 2,
    );
    final badge = Rect.fromLTWH(bounds.left + 18, bounds.top + 16, 82, 22);
    ShellCanvas.panel(
      canvas,
      badge,
      color: const Color(0xFF4A3425),
      borderColor: const Color(0xFF4A3425),
      radius: 8,
    );
    ShellCanvas.label(
      canvas,
      text: definition.category,
      position: Vector2(badge.center.dx, badge.top + 6),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    canvas.drawCircle(
      Offset(bounds.center.dx, bounds.top + 102),
      48,
      Paint()..color = const Color(0x44F6B60B),
    );
    final icon = switch (definition.iconIdentifier) {
      'pan' => '▰',
      'cheese' => '▲',
      _ => '♟',
    };
    ShellCanvas.label(
      canvas,
      text: icon,
      position: Vector2(bounds.center.dx, bounds.top + 73),
      style: const TextStyle(
        color: Color(0xFF5E4700),
        fontSize: 48,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: definition.name,
      position: Vector2(bounds.center.dx, bounds.top + 166),
      style: const TextStyle(
        color: Color(0xFF2F211A),
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
      maxWidth: bounds.width - 28,
    );
    ShellCanvas.label(
      canvas,
      text: definition.description,
      position: Vector2(bounds.center.dx, bounds.top + 205),
      style: const TextStyle(
        color: Color(0xFF53453C),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      align: TextAlign.center,
      maxWidth: bounds.width - 34,
    );
    final status = isMaximum ? 'MAKSİMUM' : 'SEVİYE $level → ${level + 1}';
    ShellCanvas.label(
      canvas,
      text: status,
      position: Vector2(bounds.center.dx, bounds.bottom - 68),
      style: TextStyle(
        color: isMaximum ? const Color(0xFFE47A60) : const Color(0xFF5D4638),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    final action = isMaximum
        ? 'MAKSİMUM'
        : selected
        ? 'SEÇİLDİ'
        : 'SEÇ';
    final actionBounds = Rect.fromCenter(
      center: Offset(bounds.center.dx, bounds.bottom - 32),
      width: 112,
      height: 34,
    );
    ShellCanvas.panel(
      canvas,
      actionBounds,
      color: selected ? GameLayout.accentColor : const Color(0xFF3B2B22),
      borderColor: selected ? const Color(0xFFFFD86F) : const Color(0xFF3B2B22),
      radius: 9,
    );
    ShellCanvas.label(
      canvas,
      text: action,
      position: Vector2(actionBounds.center.dx, actionBounds.top + 9),
      style: TextStyle(
        color: selected ? const Color(0xFF39250C) : GameLayout.primaryTextColor,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isShowing()) return;
    final point = Offset(event.localPosition.x, event.localPosition.y);
    if (_confirmBounds.contains(point)) {
      if (flow.canConfirmUpgrade) onConfirm();
      return;
    }
    for (final entry in prototypeUpgradeDefinitions.indexed) {
      if (_cardBounds(entry.$1).contains(point)) flow.selectUpgrade(entry.$2);
    }
  }
}
