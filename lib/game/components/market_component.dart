import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../data/content_unlock_definitions.dart';
import '../game_layout.dart';
import '../models/content_ownership.dart';
import '../models/market_pack_definition.dart';
import '../state/market_state.dart';
import '../state/run_progression_state.dart';
import 'shell_canvas.dart';

class MarketComponent extends PositionComponent with TapCallbacks {
  MarketComponent({
    required this.isShowing,
    required this.catalog,
    required this.progression,
    required this.ownership,
    required this.marketState,
    required this.onPurchase,
    required this.onOpenLoadout,
    required this.onBack,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 350,
       );

  final bool Function() isShowing;
  final List<MarketPackDefinition> catalog;
  final RunProgressionState progression;
  final ContentOwnership ownership;
  final MarketState marketState;
  final void Function(String packId) onPurchase;
  final void Function() onOpenLoadout;
  final void Function() onBack;

  static const _backBounds = Rect.fromLTWH(34, 28, 92, 42);
  static const _loadoutBounds = Rect.fromLTWH(1040, 28, 204, 42);

  Rect _cardBounds(int index) => Rect.fromLTWH(58 + index * 408, 132, 350, 474);
  Rect _buyBounds(int index) => Rect.fromLTWH(111 + index * 408, 530, 244, 54);

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() && super.containsLocalPoint(point);

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    canvas.drawRect(size.toRect(), Paint()..color = GameLayout.backgroundColor);
    ShellCanvas.label(
      canvas,
      text: 'MARKET',
      position: Vector2(640, 38),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 30,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: '● ${progression.walletCoins} PARA',
      position: Vector2(640, 80),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    _button(canvas, _backBounds, '← GERİ');
    _button(canvas, _loadoutBounds, 'AKTİF MUTFAK');
    for (final indexed in catalog.indexed) {
      _drawPack(canvas, indexed.$1, indexed.$2);
    }
    final feedback = marketState.lastResult;
    if (feedback != null) {
      ShellCanvas.label(
        canvas,
        text: feedback.message,
        position: Vector2(640, 644),
        style: TextStyle(
          color: feedback == MarketPurchaseResult.success
              ? GameLayout.successColor
              : const Color(0xFFFF9B7A),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
      );
    }
  }

  void _drawPack(Canvas canvas, int index, MarketPackDefinition pack) {
    final bounds = _cardBounds(index);
    final owned = ownership.ownsPack(pack.id);
    ShellCanvas.panel(
      canvas,
      bounds,
      color: const Color(0xFF30231D),
      borderColor: owned
          ? GameLayout.successColor
          : GameLayout.panelStrokeColor,
      radius: 16,
      borderWidth: owned ? 3 : 1.5,
    );
    ShellCanvas.label(
      canvas,
      text: pack.displayName,
      position: Vector2(bounds.center.dx, bounds.top + 34),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    canvas.drawCircle(
      Offset(bounds.center.dx, bounds.top + 128),
      54,
      Paint()..color = const Color(0x33F6B60B),
    );
    ShellCanvas.label(
      canvas,
      text: index == 0
          ? '🌶'
          : index == 1
          ? '🔪'
          : '▥',
      position: Vector2(bounds.center.dx, bounds.top + 92),
      style: const TextStyle(fontSize: 46),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: pack.description,
      position: Vector2(bounds.center.dx, bounds.top + 206),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      align: TextAlign.center,
      maxWidth: bounds.width - 52,
    );
    final contents = [
      ...pack.ingredientIds,
      ...pack.equipmentIds,
      ...pack.recipeIds,
    ].map((id) => contentDisplayNames[id] ?? id).join(' · ');
    ShellCanvas.label(
      canvas,
      text: contents,
      position: Vector2(bounds.center.dx, bounds.top + 278),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 11,
        height: 1.6,
        fontWeight: FontWeight.w700,
      ),
      align: TextAlign.center,
      maxWidth: bounds.width - 40,
    );
    final buy = _buyBounds(index);
    ShellCanvas.panel(
      canvas,
      buy,
      color: owned ? const Color(0xFF3D4D2D) : GameLayout.accentColor,
      borderColor: owned ? GameLayout.successColor : const Color(0xFFFFD86F),
      radius: 12,
    );
    ShellCanvas.label(
      canvas,
      text: owned ? 'SATIN ALINDI' : 'SATIN AL · ${pack.priceCoins}',
      position: Vector2(buy.center.dx, buy.top + 18),
      style: TextStyle(
        color: owned ? GameLayout.successColor : const Color(0xFF39250C),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _button(Canvas canvas, Rect bounds, String label) {
    ShellCanvas.panel(
      canvas,
      bounds,
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 9,
    );
    ShellCanvas.label(
      canvas,
      text: label,
      position: Vector2(bounds.center.dx, bounds.top + 13),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
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
    if (_backBounds.contains(point)) return onBack();
    if (_loadoutBounds.contains(point)) return onOpenLoadout();
    for (final indexed in catalog.indexed) {
      if (_buyBounds(indexed.$1).contains(point)) {
        onPurchase(indexed.$2.id);
        return;
      }
    }
  }
}
