import 'dart:ui';

import '../models/processing_definition.dart';
import '../state/equipment_processing_state.dart';
import '../state/kitchen_table_state.dart';

class EquipmentTarget {
  const EquipmentTarget({
    required this.equipmentCardId,
    required this.bounds,
    required this.isAvailable,
    required this.processingDefinition,
  });

  final String equipmentCardId;
  final Rect bounds;
  final bool isAvailable;
  final ProcessingDefinition processingDefinition;
}

class EquipmentTargetResolver {
  const EquipmentTargetResolver({required this.cardSize});

  final Size cardSize;

  EquipmentTarget? resolveTarget({
    required String draggedCardId,
    required Offset draggedCardPosition,
    required KitchenTableState tableState,
    required EquipmentProcessingState processingState,
  }) {
    final draggedCenter = Offset(
      draggedCardPosition.dx + (cardSize.width / 2),
      draggedCardPosition.dy + (cardSize.height / 2),
    );
    EquipmentTarget? target;
    for (final equipmentCardId in tableState.tableCardIdsInRenderOrder) {
      if (!tableState.isOnKitchenTable(equipmentCardId)) {
        continue;
      }
      final processingDefinition = processingState.definitionFor(
        tableState: tableState,
        equipmentCardId: equipmentCardId,
        inputCardId: draggedCardId,
      );
      if (processingDefinition == null) {
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
          processingDefinition: processingDefinition,
        );
      }
    }
    return target;
  }

  /// Compatibility entry point for the original patty-on-pan prototype.
  EquipmentTarget? resolvePattyTarget({
    required String draggedCardId,
    required Offset draggedCardPosition,
    required KitchenTableState tableState,
    required EquipmentProcessingState processingState,
  }) => resolveTarget(
    draggedCardId: draggedCardId,
    draggedCardPosition: draggedCardPosition,
    tableState: tableState,
    processingState: processingState,
  );
}
