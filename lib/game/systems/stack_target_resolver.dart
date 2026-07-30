import 'dart:ui';

import '../models/card_definition.dart';
import '../state/kitchen_table_state.dart';

class StackTarget {
  const StackTarget({
    required this.cardId,
    required this.cardBounds,
    required this.renderOrder,
  });

  final String cardId;
  final Rect cardBounds;
  final int renderOrder;
}

class StackTargetResolver {
  const StackTargetResolver({required this.cardSize});

  final Size cardSize;

  StackTarget? resolve({
    required String draggedCardId,
    required Offset draggedCardPosition,
    required KitchenTableState tableState,
  }) {
    if (tableState.definitionFor(draggedCardId).category !=
        CardCategory.ingredient) {
      return null;
    }

    final draggedCenter = Offset(
      draggedCardPosition.dx + (cardSize.width / 2),
      draggedCardPosition.dy + (cardSize.height / 2),
    );
    StackTarget? topmostTarget;

    for (final entry in tableState.tableCardIdsInRenderOrder.indexed) {
      final cardId = entry.$2;
      if (cardId == draggedCardId ||
          !tableState.isOnKitchenTable(cardId) ||
          tableState.definitionFor(cardId).category !=
              CardCategory.ingredient) {
        continue;
      }

      final position = tableState.placementFor(cardId).currentValidPosition;
      final cardBounds = Rect.fromLTWH(
        position.dx,
        position.dy,
        cardSize.width,
        cardSize.height,
      );
      if (!cardBounds.contains(draggedCenter)) {
        continue;
      }

      topmostTarget = StackTarget(
        cardId: cardId,
        cardBounds: cardBounds,
        renderOrder: entry.$1,
      );
    }

    return topmostTarget;
  }
}
