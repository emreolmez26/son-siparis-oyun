import 'dart:ui';

import '../models/card_definition.dart';
import '../state/equipment_processing_state.dart';
import '../state/kitchen_table_state.dart';

class EquipmentTarget {
  const EquipmentTarget({
    required this.equipmentCardId,
    required this.bounds,
    required this.isAvailable,
  });

  final String equipmentCardId;
  final Rect bounds;
  final bool isAvailable;
}

class EquipmentTargetResolver {
  const EquipmentTargetResolver({required this.cardSize});

  final Size cardSize;

  EquipmentTarget? resolvePattyTarget({
    required String draggedCardId,
    required Offset draggedCardPosition,
    required KitchenTableState tableState,
    required EquipmentProcessingState processingState,
  }) {
    if (tableState.definitionFor(draggedCardId).type != CardType.patty) {
      return null;
    }

    final draggedCenter = Offset(
      draggedCardPosition.dx + (cardSize.width / 2),
      draggedCardPosition.dy + (cardSize.height / 2),
    );
    EquipmentTarget? target;
    for (final equipmentCardId in tableState.tableCardIdsInRenderOrder) {
      if (!tableState.isOnKitchenTable(equipmentCardId) ||
          tableState.definitionFor(equipmentCardId).type != CardType.pan) {
        continue;
      }
      final equipmentPosition = tableState
          .placementFor(equipmentCardId)
          .currentValidPosition;
      final bounds = Rect.fromLTWH(
        equipmentPosition.dx,
        equipmentPosition.dy,
        cardSize.width,
        cardSize.height,
      );
      if (bounds.contains(draggedCenter)) {
        target = EquipmentTarget(
          equipmentCardId: equipmentCardId,
          bounds: bounds,
          isAvailable: processingState.isEquipmentAvailable(equipmentCardId),
        );
      }
    }
    return target;
  }
}
