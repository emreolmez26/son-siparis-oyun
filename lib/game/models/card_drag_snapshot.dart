import 'card_placement.dart';
import 'card_stack.dart';

class CardDragSnapshot {
  CardDragSnapshot({
    required this.cardId,
    required Map<String, CardPlacement> placements,
    required Map<String, CardStack> stacks,
    required this.nextStackSequence,
  }) : placements = Map.unmodifiable(Map.of(placements)),
       stacks = Map.unmodifiable(Map.of(stacks));

  final String cardId;
  final Map<String, CardPlacement> placements;
  final Map<String, CardStack> stacks;
  final int nextStackSequence;
}
