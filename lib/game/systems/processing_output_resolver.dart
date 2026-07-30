import 'dart:ui';

import '../game_layout.dart';
import '../kitchen_grid.dart';

class ProcessingOutputResolver {
  const ProcessingOutputResolver({required this.kitchenGrid});

  final KitchenGrid kitchenGrid;

  Offset resolve(Offset panPosition) {
    final rightPosition = Offset(
      panPosition.dx + GameLayout.processingOutputHorizontalOffset,
      panPosition.dy,
    );
    if (kitchenGrid.isCardPositionInsidePaddedArea(rightPosition)) {
      return kitchenGrid.snap(rightPosition);
    }

    final leftPosition = Offset(
      panPosition.dx - GameLayout.processingOutputHorizontalOffset,
      panPosition.dy,
    );
    if (kitchenGrid.isCardPositionInsidePaddedArea(leftPosition)) {
      return kitchenGrid.snap(leftPosition);
    }

    return kitchenGrid.snap(leftPosition);
  }
}
