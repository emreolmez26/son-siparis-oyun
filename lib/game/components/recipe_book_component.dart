import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/recipe_book_entry.dart';
import '../state/recipe_discovery_state.dart';
import '../state/run_progression_state.dart';
import 'shell_canvas.dart';

class RecipeBookComponent extends PositionComponent with TapCallbacks {
  RecipeBookComponent({
    required this.entries,
    required this.discoveryState,
    required this.progression,
    required this.isShowing,
    required this.onClose,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 340,
       );

  final List<RecipeBookEntry> entries;
  final RecipeDiscoveryState discoveryState;
  final RunProgressionState progression;
  final bool Function() isShowing;
  final void Function() onClose;

  RecipeBookCategory _selectedCategory = RecipeBookCategory.burgers;
  String _selectedEntryId = 'classic_burger';

  static const _sidebarBounds = Rect.fromLTWH(28, 92, 214, 568);
  static const _gridBounds = Rect.fromLTWH(260, 92, 540, 568);
  static const _detailBounds = Rect.fromLTWH(818, 92, 434, 568);
  static const _closeBounds = Rect.fromLTWH(1166, 26, 70, 38);

  List<RecipeBookEntry> get _visibleEntries => entries
      .where((entry) => entry.category == _selectedCategory)
      .toList(growable: false);

  RecipeBookEntry? get _selectedEntry {
    for (final entry in entries) {
      if (entry.id == _selectedEntryId) return entry;
    }
    return null;
  }

  bool _isDiscovered(RecipeBookEntry entry) =>
      !entry.isPlaceholder && discoveryState.isDiscovered(entry.id);

  Rect _categoryBounds(int index) => Rect.fromLTWH(
    _sidebarBounds.left + 16,
    _sidebarBounds.top + 126 + index * 66,
    182,
    48,
  );

  Rect _entryBounds(int index) {
    final row = index ~/ 3;
    final column = index % 3;
    return Rect.fromLTWH(
      _gridBounds.left + 20 + (column * 164),
      _gridBounds.top + 126 + (row * 226),
      144,
      202,
    );
  }

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
      position: Vector2(30, 31),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 25,
        fontWeight: FontWeight.w900,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: 'MUTFAK REHBERİ',
      position: Vector2(31, 60),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
    _drawCloseButton(canvas);
    _drawSidebar(canvas);
    _drawGrid(canvas);
    _drawDetail(canvas);
  }

  void _drawCloseButton(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      _closeBounds,
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 9,
    );
    ShellCanvas.label(
      canvas,
      text: 'KAPAT',
      position: Vector2(_closeBounds.center.dx, _closeBounds.top + 11),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _drawSidebar(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      _sidebarBounds,
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 14,
    );
    ShellCanvas.label(
      canvas,
      text: 'TARİF DEFTERİ',
      position: Vector2(_sidebarBounds.left + 18, _sidebarBounds.top + 22),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: '${discoveryState.discoveredRecipeIds.length}/4 tarif keşfedildi',
      position: Vector2(_sidebarBounds.left + 18, _sidebarBounds.top + 50),
      style: const TextStyle(
        color: GameLayout.successColor,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
    const labels = ['BURGERLER', 'YAN ÜRÜNLER', 'GİZLİ TARİFLER'];
    for (final entry in RecipeBookCategory.values.indexed) {
      final selected = _selectedCategory == entry.$2;
      final bounds = _categoryBounds(entry.$1);
      ShellCanvas.panel(
        canvas,
        bounds,
        color: selected ? const Color(0xFF4D8700) : const Color(0xFF281D17),
        borderColor: selected
            ? GameLayout.accentColor
            : GameLayout.panelStrokeColor,
        radius: 9,
        borderWidth: selected ? 2 : 1,
      );
      ShellCanvas.label(
        canvas,
        text: labels[entry.$1],
        position: Vector2(bounds.left + 14, bounds.top + 16),
        style: TextStyle(
          color: selected
              ? GameLayout.primaryTextColor
              : GameLayout.mutedTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      );
    }
  }

  void _drawGrid(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      _gridBounds,
      color: const Color(0xFF2A1E18),
      borderColor: GameLayout.panelStrokeColor,
      radius: 14,
    );
    final categoryTitle = switch (_selectedCategory) {
      RecipeBookCategory.burgers => 'BURGERLER',
      RecipeBookCategory.sides => 'YAN ÜRÜNLER',
      RecipeBookCategory.secrets => 'GİZLİ TARİFLER',
    };
    ShellCanvas.label(
      canvas,
      text: categoryTitle,
      position: Vector2(_gridBounds.left + 22, _gridBounds.top + 22),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 23,
        fontWeight: FontWeight.w900,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: 'Tarifi seçerek ayrıntıları görüntüle.',
      position: Vector2(_gridBounds.left + 23, _gridBounds.top + 54),
      style: const TextStyle(color: GameLayout.mutedTextColor, fontSize: 11),
    );
    for (final entry in _visibleEntries.indexed) {
      _drawRecipeCard(canvas, entry.$1, entry.$2);
    }
  }

  void _drawRecipeCard(Canvas canvas, int index, RecipeBookEntry entry) {
    final bounds = _entryBounds(index);
    final discovered = _isDiscovered(entry);
    final selected = entry.id == _selectedEntryId;
    ShellCanvas.panel(
      canvas,
      bounds,
      color: discovered ? const Color(0xFFFFF7DD) : const Color(0xFF625D5B),
      borderColor: selected
          ? GameLayout.accentColor
          : GameLayout.panelStrokeColor,
      radius: 12,
      borderWidth: selected ? 3 : 1.5,
    );
    canvas.drawCircle(
      Offset(bounds.center.dx, bounds.top + 54),
      33,
      Paint()
        ..color = discovered
            ? const Color(0x33F6B60B)
            : const Color(0x44312520),
    );
    ShellCanvas.label(
      canvas,
      text: discovered ? _iconFor(entry) : '?',
      position: Vector2(bounds.center.dx, bounds.top + 31),
      style: TextStyle(
        color: discovered
            ? const Color(0xFF573D0E)
            : GameLayout.primaryTextColor,
        fontSize: discovered ? 35 : 41,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: discovered ? entry.displayName : 'Keşfedilmedi',
      position: Vector2(bounds.center.dx, bounds.top + 102),
      style: TextStyle(
        color: discovered
            ? const Color(0xFF392B23)
            : GameLayout.primaryTextColor,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
      maxWidth: bounds.width - 14,
    );
    ShellCanvas.label(
      canvas,
      text: discovered ? 'KEŞFEDİLDİ' : 'KİLİTLİ',
      position: Vector2(bounds.center.dx, bounds.top + 128),
      style: TextStyle(
        color: discovered ? const Color(0xFF4F8700) : const Color(0xFFE9D5CA),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    if (discovered) {
      ShellCanvas.label(
        canvas,
        text: '${entry.ingredientCount} malzeme',
        position: Vector2(bounds.center.dx, bounds.top + 151),
        style: const TextStyle(
          color: Color(0xFF5D4638),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        align: TextAlign.center,
      );
      ShellCanvas.label(
        canvas,
        text: entry.preparation.join(' · '),
        position: Vector2(bounds.center.dx, bounds.top + 172),
        style: const TextStyle(
          color: Color(0xFF5D4638),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
        align: TextAlign.center,
        maxWidth: bounds.width - 12,
      );
    }
  }

  void _drawDetail(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      _detailBounds,
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 14,
    );
    final entry = _selectedEntry;
    if (entry == null || !_isDiscovered(entry)) {
      ShellCanvas.label(
        canvas,
        text: 'KEŞFEDİLMEDİ',
        position: Vector2(_detailBounds.center.dx, _detailBounds.top + 128),
        style: const TextStyle(
          color: GameLayout.primaryTextColor,
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
      );
      ShellCanvas.label(
        canvas,
        text: 'Bu tarifin malzemeleri henüz gizli.',
        position: Vector2(_detailBounds.center.dx, _detailBounds.top + 168),
        style: const TextStyle(color: GameLayout.mutedTextColor, fontSize: 12),
        align: TextAlign.center,
      );
      return;
    }
    ShellCanvas.label(
      canvas,
      text: entry.displayName.toUpperCase(),
      position: Vector2(_detailBounds.center.dx, _detailBounds.top + 32),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 25,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'HAZIRLIK SIRASI',
      position: Vector2(_detailBounds.left + 28, _detailBounds.top + 92),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
    for (final input in entry.orderedInputs.indexed) {
      final bounds = Rect.fromLTWH(
        _detailBounds.left + 26,
        _detailBounds.top + 118 + input.$1 * 40,
        _detailBounds.width - 52,
        31,
      );
      ShellCanvas.panel(
        canvas,
        bounds,
        color: const Color(0xFFFFF7DD),
        borderColor: input.$1 == 0
            ? GameLayout.accentColor
            : const Color(0xFFE5D8C4),
        radius: 7,
      );
      ShellCanvas.label(
        canvas,
        text: '${input.$1 + 1}. ${input.$2}',
        position: Vector2(bounds.left + 13, bounds.top + 8),
        style: const TextStyle(
          color: Color(0xFF3D2E26),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    final preparationTop =
        _detailBounds.top + 118 + entry.orderedInputs.length * 40 + 20;
    ShellCanvas.label(
      canvas,
      text: 'EKİPMAN',
      position: Vector2(_detailBounds.left + 28, preparationTop),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
    for (final item in entry.preparation.indexed) {
      ShellCanvas.label(
        canvas,
        text: '• ${item.$2}',
        position: Vector2(
          _detailBounds.left + 32,
          preparationTop + 25 + item.$1 * 20,
        ),
        style: const TextStyle(
          color: GameLayout.mutedTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final definition = entry.resultDefinition!;
    final baseReward = definition.baseRewardCoins;
    final effectiveReward = progression.upgrades.effectiveRewardFor(definition);
    final bonus = effectiveReward - baseReward;
    final rewardBounds = Rect.fromLTWH(
      _detailBounds.left + 26,
      _detailBounds.bottom - 124,
      _detailBounds.width - 52,
      94,
    );
    ShellCanvas.panel(
      canvas,
      rewardBounds,
      color: const Color(0xFF211713),
      borderColor: GameLayout.panelStrokeColor,
      radius: 9,
    );
    ShellCanvas.label(
      canvas,
      text: 'ÖDÜL',
      position: Vector2(rewardBounds.left + 15, rewardBounds.top + 13),
      style: const TextStyle(
        color: GameLayout.successColor,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: '$baseReward Para',
      position: Vector2(rewardBounds.left + 15, rewardBounds.top + 34),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
    if (bonus > 0) {
      ShellCanvas.label(
        canvas,
        text: '+$bonus Çifte Peynir Bonusu',
        position: Vector2(rewardBounds.left + 15, rewardBounds.top + 56),
        style: const TextStyle(
          color: Color(0xFFE9A8E8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );
      ShellCanvas.label(
        canvas,
        text: 'Toplam: $effectiveReward Para',
        position: Vector2(rewardBounds.right - 15, rewardBounds.top + 72),
        style: const TextStyle(
          color: GameLayout.accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.right,
      );
    }
  }

  String _iconFor(RecipeBookEntry entry) => switch (entry.id) {
    'crispy_fries' => '≋',
    _ => '▰',
  };

  @override
  void onTapUp(TapUpEvent event) {
    if (!isShowing()) return;
    final point = Offset(event.localPosition.x, event.localPosition.y);
    if (_closeBounds.contains(point)) {
      onClose();
      return;
    }
    for (final category in RecipeBookCategory.values.indexed) {
      if (_categoryBounds(category.$1).contains(point)) {
        _selectedCategory = category.$2;
        return;
      }
    }
    for (final entry in _visibleEntries.indexed) {
      if (_entryBounds(entry.$1).contains(point)) {
        _selectedEntryId = entry.$2.id;
        return;
      }
    }
  }
}
