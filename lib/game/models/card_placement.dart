import 'dart:ui';

import 'card_zone.dart';

class CardPlacement {
  const CardPlacement({
    required this.zone,
    required this.currentValidPosition,
    required this.lastValidPosition,
    this.stackId,
    this.stackIndex,
  });

  final CardZone zone;
  final Offset currentValidPosition;
  final Offset lastValidPosition;
  final String? stackId;
  final int? stackIndex;

  bool get isStacked => zone == CardZone.ingredientStack;

  @override
  bool operator ==(Object other) {
    return other is CardPlacement &&
        zone == other.zone &&
        currentValidPosition == other.currentValidPosition &&
        lastValidPosition == other.lastValidPosition &&
        stackId == other.stackId &&
        stackIndex == other.stackIndex;
  }

  @override
  int get hashCode => Object.hash(
    zone,
    currentValidPosition,
    lastValidPosition,
    stackId,
    stackIndex,
  );
}
