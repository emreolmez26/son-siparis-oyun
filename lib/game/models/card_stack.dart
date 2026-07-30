import 'dart:ui';

class CardStack {
  CardStack({
    required this.id,
    required List<String> cardIds,
    required this.basePosition,
  }) : cardIds = List.unmodifiable(cardIds) {
    if (cardIds.length < 2) {
      throw ArgumentError.value(
        cardIds,
        'cardIds',
        'A stack must contain at least two cards.',
      );
    }
    if (cardIds.toSet().length != cardIds.length) {
      throw ArgumentError.value(
        cardIds,
        'cardIds',
        'A stack cannot contain duplicate card IDs.',
      );
    }
  }

  final String id;
  final List<String> cardIds;
  final Offset basePosition;

  CardStack copyWith({List<String>? cardIds, Offset? basePosition}) {
    return CardStack(
      id: id,
      cardIds: cardIds ?? this.cardIds,
      basePosition: basePosition ?? this.basePosition,
    );
  }
}
