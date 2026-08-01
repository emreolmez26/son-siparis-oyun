import 'dart:ui';

import '../models/card_definition.dart';
import '../models/pantry_supply_slot.dart';

class PantrySupplyState {
  PantrySupplyState({
    required Iterable<CardDefinition> definitions,
    required Map<String, Offset> positions,
    this.spawnCooldownSeconds = .18,
  }) : assert(spawnCooldownSeconds >= 0) {
    for (final definition in definitions) {
      final position = positions[definition.id];
      if (position == null) {
        throw ArgumentError.value(
          definition.id,
          'positions',
          'Missing pantry supply position',
        );
      }
      if (definition.category != CardCategory.ingredient) {
        throw ArgumentError.value(
          definition.id,
          'definitions',
          'Only base ingredients can be pantry supplies',
        );
      }
      _slots[definition.id] = PantrySupplySlot(
        id: definition.id,
        definition: definition,
        position: position,
      );
    }
    _activeSupplyIds = _slots.keys.toSet();
  }

  final double spawnCooldownSeconds;
  final Map<String, PantrySupplySlot> _slots = {};
  late Set<String> _activeSupplyIds;
  int _nextWorkingSequence = 1;

  Iterable<PantrySupplySlot> get slots =>
      _slots.values.where((slot) => _activeSupplyIds.contains(slot.id));
  Iterable<PantrySupplySlot> get allSlots => _slots.values;
  int get slotCount => _activeSupplyIds.length;
  bool isActive(String supplyId) => _activeSupplyIds.contains(supplyId);

  PantrySupplySlot slotFor(String supplyId) {
    final slot = _slots[supplyId];
    if (slot == null) {
      throw ArgumentError.value(supplyId, 'supplyId', 'Unknown pantry slot');
    }
    return slot;
  }

  bool isAvailable(String supplyId) => slotFor(supplyId).isAvailable;

  void configureActive(Iterable<String> supplyIds) {
    final requested = supplyIds.toSet();
    if (!requested.every(_slots.containsKey)) {
      throw ArgumentError.value(supplyIds, 'supplyIds', 'Unknown pantry slot');
    }
    _activeSupplyIds = requested;
    resetForShift();
  }

  CardDefinition? takeWorkingDefinition(String supplyId) {
    final slot = slotFor(supplyId);
    if (!isActive(supplyId) || !slot.isAvailable) return null;
    final sequence = _nextWorkingSequence.toString().padLeft(4, '0');
    _nextWorkingSequence++;
    _slots[supplyId] = slot.copyWith(
      cooldownRemainingSeconds: spawnCooldownSeconds,
    );
    return slot.definition.copyWithId(
      '${_runtimePrefix(slot.definition.type)}_$sequence',
    );
  }

  void advance(double dt) {
    if (dt <= 0) return;
    for (final entry in _slots.entries.toList()) {
      final remaining = entry.value.cooldownRemainingSeconds;
      if (remaining <= 0) continue;
      _slots[entry.key] = entry.value.copyWith(
        cooldownRemainingSeconds: (remaining - dt)
            .clamp(0.0, spawnCooldownSeconds)
            .toDouble(),
      );
    }
  }

  void resetForShift() {
    _nextWorkingSequence = 1;
    for (final entry in _slots.entries.toList()) {
      _slots[entry.key] = entry.value.copyWith(cooldownRemainingSeconds: 0);
    }
  }

  String _runtimePrefix(CardType type) => switch (type) {
    CardType.bread => 'bread',
    CardType.patty => 'raw_patty',
    CardType.cheese => 'cheese',
    CardType.tomato => 'raw_tomato',
    CardType.hotSauce => 'hot_sauce',
    CardType.potato => 'raw_potato',
    _ => throw StateError('$type is not a renewable base ingredient.'),
  };
}
