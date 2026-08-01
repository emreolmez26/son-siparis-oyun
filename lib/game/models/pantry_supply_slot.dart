import 'dart:ui';

import 'card_definition.dart';

class PantrySupplySlot {
  const PantrySupplySlot({
    required this.id,
    required this.definition,
    required this.position,
    this.cooldownRemainingSeconds = 0,
  });

  final String id;
  final CardDefinition definition;
  final Offset position;
  final double cooldownRemainingSeconds;

  bool get isAvailable => cooldownRemainingSeconds <= 0;

  PantrySupplySlot copyWith({double? cooldownRemainingSeconds}) =>
      PantrySupplySlot(
        id: id,
        definition: definition,
        position: position,
        cooldownRemainingSeconds:
            cooldownRemainingSeconds ?? this.cooldownRemainingSeconds,
      );
}
