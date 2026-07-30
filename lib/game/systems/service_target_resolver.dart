import 'dart:ui';

import '../game_layout.dart';
import '../state/kitchen_table_state.dart';
import '../state/order_system.dart';

class ServiceTarget {
  const ServiceTarget({required this.bounds, required this.resultName});

  final Rect bounds;
  final String resultName;
}

class ServiceTargetResolver {
  const ServiceTargetResolver({required this.cardSize});

  final Size cardSize;

  ServiceTarget? resolve({
    required String draggedCardId,
    required Offset draggedCardPosition,
    required KitchenTableState tableState,
    required OrderSystem orderSystem,
  }) {
    if (!orderSystem.canServeDefinition(
      tableState.definitionFor(draggedCardId),
    )) {
      return null;
    }
    final draggedCenter = Offset(
      draggedCardPosition.dx + (cardSize.width / 2),
      draggedCardPosition.dy + (cardSize.height / 2),
    );
    if (!GameLayout.serviceCounterBounds.contains(draggedCenter)) {
      return null;
    }
    return ServiceTarget(
      bounds: GameLayout.serviceCounterBounds,
      resultName: tableState.definitionFor(draggedCardId).displayName,
    );
  }
}
