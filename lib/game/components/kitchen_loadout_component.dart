import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../data/prototype_card_definitions.dart';
import '../game_layout.dart';
import '../models/content_ownership.dart';
import '../state/loadout_state.dart';
import 'shell_canvas.dart';

class KitchenLoadoutComponent extends PositionComponent with TapCallbacks {
  KitchenLoadoutComponent({
    required this.isShowing,
    required this.ownership,
    required this.loadoutState,
    required this.onToggleIngredient,
    required this.onToggleEquipment,
    required this.onSave,
    required this.onBack,
    required this.feedbackProvider,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 360,
       );

  final bool Function() isShowing;
  final ContentOwnership ownership;
  final LoadoutState loadoutState;
  final void Function(String id) onToggleIngredient;
  final void Function(String id) onToggleEquipment;
  final void Function() onSave;
  final void Function() onBack;
  final String? Function() feedbackProvider;

  static const _backBounds = Rect.fromLTWH(40, 34, 100, 44);
  static const _saveBounds = Rect.fromLTWH(1010, 624, 220, 56);

  Rect _ingredientBounds(int index) =>
      Rect.fromLTWH(70 + index * 194, 182, 166, 142);
  Rect _equipmentBounds(int index) =>
      Rect.fromLTWH(296 + index * 230, 410, 196, 130);

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() && super.containsLocalPoint(point);

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    canvas.drawRect(size.toRect(), Paint()..color = GameLayout.backgroundColor);
    ShellCanvas.label(
      canvas,
      text: 'AKTİF MUTFAK',
      position: Vector2(640, 42),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 30,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'Kariyer vardiyalarında kullanacağın içerikleri seç.',
      position: Vector2(640, 86),
      style: const TextStyle(color: GameLayout.mutedTextColor, fontSize: 13),
      align: TextAlign.center,
    );
    _button(canvas, _backBounds, '← GERİ');
    final draft = loadoutState.draft ?? loadoutState.active;
    ShellCanvas.label(
      canvas,
      text: 'MALZEMELER  ${draft.ingredientIds.length}/6',
      position: Vector2(70, 140),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
    for (final indexed in prototypeCycleIngredientDefinitions.indexed) {
      final definition = indexed.$2;
      _item(
        canvas,
        _ingredientBounds(indexed.$1),
        definition.displayName,
        owned: ownership.ownsIngredient(definition.id),
        selected: draft.ingredientIds.contains(definition.id),
      );
    }
    ShellCanvas.label(
      canvas,
      text: 'EKİPMAN  ${draft.equipmentIds.length}/3',
      position: Vector2(70, 368),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
    for (final indexed in prototypeEquipmentDefinitions.indexed) {
      final definition = indexed.$2;
      _item(
        canvas,
        _equipmentBounds(indexed.$1),
        definition.displayName,
        owned: ownership.ownsEquipment(definition.id),
        selected: draft.equipmentIds.contains(definition.id),
      );
    }
    final feedback = feedbackProvider();
    if (feedback != null) {
      ShellCanvas.label(
        canvas,
        text: feedback,
        position: Vector2(620, 644),
        style: const TextStyle(
          color: Color(0xFFFF9B7A),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
        maxWidth: 600,
      );
    }
    _button(canvas, _saveBounds, 'KAYDET');
  }

  void _item(
    Canvas canvas,
    Rect bounds,
    String label, {
    required bool owned,
    required bool selected,
  }) {
    ShellCanvas.panel(
      canvas,
      bounds,
      color: !owned
          ? const Color(0xFF3B3532)
          : selected
          ? const Color(0xFF40562B)
          : GameLayout.panelColor,
      borderColor: selected
          ? GameLayout.successColor
          : GameLayout.panelStrokeColor,
      radius: 12,
      borderWidth: selected ? 3 : 1,
    );
    ShellCanvas.label(
      canvas,
      text: owned ? (selected ? '✓' : '○') : '🔒',
      position: Vector2(bounds.center.dx, bounds.top + 22),
      style: const TextStyle(fontSize: 28, color: GameLayout.primaryTextColor),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: label,
      position: Vector2(bounds.center.dx, bounds.top + 76),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: owned ? (selected ? 'AKTİF' : 'PASİF') : 'MARKETTEN AÇILIR',
      position: Vector2(bounds.center.dx, bounds.top + 106),
      style: TextStyle(
        color: owned ? GameLayout.mutedTextColor : const Color(0xFFFF9B7A),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _button(Canvas canvas, Rect bounds, String text) {
    ShellCanvas.panel(
      canvas,
      bounds,
      color: text == 'KAYDET' ? GameLayout.accentColor : GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 10,
    );
    ShellCanvas.label(
      canvas,
      text: text,
      position: Vector2(bounds.center.dx, bounds.top + 15),
      style: TextStyle(
        color: text == 'KAYDET'
            ? const Color(0xFF39250C)
            : GameLayout.primaryTextColor,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isShowing()) return;
    final point = Offset(event.localPosition.x, event.localPosition.y);
    if (_backBounds.contains(point)) return onBack();
    if (_saveBounds.contains(point)) return onSave();
    for (final indexed in prototypeCycleIngredientDefinitions.indexed) {
      if (_ingredientBounds(indexed.$1).contains(point)) {
        onToggleIngredient(indexed.$2.id);
        return;
      }
    }
    for (final indexed in prototypeEquipmentDefinitions.indexed) {
      if (_equipmentBounds(indexed.$1).contains(point)) {
        onToggleEquipment(indexed.$2.id);
        return;
      }
    }
  }
}
