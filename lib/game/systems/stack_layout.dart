import 'dart:math' as math;
import 'dart:ui';

class StackLayout {
  const StackLayout({
    required this.cardSize,
    required this.paddedTableBounds,
    required this.gridOrigin,
    required this.gridSpacing,
    required this.levelOffset,
  }) : assert(gridSpacing > 0);

  final Size cardSize;
  final Rect paddedTableBounds;
  final Offset gridOrigin;
  final double gridSpacing;
  final Offset levelOffset;

  Offset positionFor(Offset basePosition, int stackIndex) {
    return Offset(
      basePosition.dx + (levelOffset.dx * stackIndex),
      basePosition.dy + (levelOffset.dy * stackIndex),
    );
  }

  Rect cardBoundsAt(Offset basePosition, int stackIndex) {
    final position = positionFor(basePosition, stackIndex);
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      cardSize.width,
      cardSize.height,
    );
  }

  Rect boundsFor(Offset basePosition, int cardCount) {
    assert(cardCount > 0);
    final finalPosition = positionFor(basePosition, cardCount - 1);
    return Rect.fromLTRB(
      math.min(basePosition.dx, finalPosition.dx),
      math.min(basePosition.dy, finalPosition.dy),
      math.max(
        basePosition.dx + cardSize.width,
        finalPosition.dx + cardSize.width,
      ),
      math.max(
        basePosition.dy + cardSize.height,
        finalPosition.dy + cardSize.height,
      ),
    );
  }

  Offset clampBase(Offset requestedBase, int cardCount) {
    assert(cardCount > 0);
    final finalPosition = positionFor(Offset.zero, cardCount - 1);
    final minimum = Offset(
      paddedTableBounds.left - math.min(0, finalPosition.dx),
      paddedTableBounds.top - math.min(0, finalPosition.dy),
    );
    final maximum = Offset(
      paddedTableBounds.right - cardSize.width - math.max(0, finalPosition.dx),
      paddedTableBounds.bottom -
          cardSize.height -
          math.max(0, finalPosition.dy),
    );

    return Offset(
      _snapWithinRange(requestedBase.dx, minimum.dx, maximum.dx, gridOrigin.dx),
      _snapWithinRange(requestedBase.dy, minimum.dy, maximum.dy, gridOrigin.dy),
    );
  }

  bool isFullyInsidePaddedTable(Offset basePosition, int cardCount) {
    final bounds = boundsFor(basePosition, cardCount);
    return bounds.left >= paddedTableBounds.left &&
        bounds.top >= paddedTableBounds.top &&
        bounds.right <= paddedTableBounds.right &&
        bounds.bottom <= paddedTableBounds.bottom;
  }

  double _snapWithinRange(
    double requested,
    double minimum,
    double maximum,
    double axisOrigin,
  ) {
    final minimumIndex = ((minimum - axisOrigin) / gridSpacing).ceil();
    final maximumIndex = ((maximum - axisOrigin) / gridSpacing).floor();
    final requestedIndex = ((requested - axisOrigin) / gridSpacing).round();
    final clampedIndex = requestedIndex.clamp(minimumIndex, maximumIndex);
    return axisOrigin + (clampedIndex * gridSpacing);
  }
}
