import 'dart:ui';

class KitchenGrid {
  const KitchenGrid({
    required this.tableBounds,
    required this.cardSize,
    required this.spacing,
    required this.padding,
  }) : assert(spacing > 0),
       assert(padding >= 0);

  final Rect tableBounds;
  final Size cardSize;
  final double spacing;
  final double padding;

  Rect get paddedTableBounds => tableBounds.deflate(padding);

  Rect get validCardPositionBounds {
    final paddedBounds = paddedTableBounds;
    return Rect.fromLTRB(
      paddedBounds.left,
      paddedBounds.top,
      paddedBounds.right - cardSize.width,
      paddedBounds.bottom - cardSize.height,
    );
  }

  Offset get origin => validCardPositionBounds.topLeft;

  Offset? snapCandidate(Offset cardPosition) {
    if (!isCardPositionInsideTable(cardPosition)) {
      return null;
    }
    return snap(cardPosition);
  }

  Offset snap(Offset cardPosition) {
    final validBounds = validCardPositionBounds;
    return Offset(
      _snapAxis(cardPosition.dx, origin.dx, validBounds.right),
      _snapAxis(cardPosition.dy, origin.dy, validBounds.bottom),
    );
  }

  bool isCardPositionInsideTable(Offset cardPosition) {
    return _isInsideBounds(cardPosition, _cardPositionBoundsIn(tableBounds));
  }

  bool isCardPositionInsidePaddedArea(Offset cardPosition) {
    return _isInsideBounds(cardPosition, validCardPositionBounds);
  }

  Rect cardBoundsAt(Offset cardPosition) {
    return Rect.fromLTWH(
      cardPosition.dx,
      cardPosition.dy,
      cardSize.width,
      cardSize.height,
    );
  }

  bool isAligned(Offset cardPosition) {
    if (!isCardPositionInsidePaddedArea(cardPosition)) {
      return false;
    }
    return _isAlignedOnAxis(cardPosition.dx, origin.dx) &&
        _isAlignedOnAxis(cardPosition.dy, origin.dy);
  }

  double _snapAxis(double value, double axisOrigin, double maximum) {
    final maximumIndex = ((maximum - axisOrigin) / spacing).floor();
    final requestedIndex = ((value - axisOrigin) / spacing).round();
    final clampedIndex = requestedIndex.clamp(0, maximumIndex).toDouble();
    return axisOrigin + (clampedIndex * spacing);
  }

  bool _isAlignedOnAxis(double value, double axisOrigin) {
    final gridIndex = (value - axisOrigin) / spacing;
    return (gridIndex - gridIndex.round()).abs() < .001;
  }

  Rect _cardPositionBoundsIn(Rect bounds) {
    return Rect.fromLTRB(
      bounds.left,
      bounds.top,
      bounds.right - cardSize.width,
      bounds.bottom - cardSize.height,
    );
  }

  bool _isInsideBounds(Offset position, Rect bounds) {
    return position.dx >= bounds.left &&
        position.dx <= bounds.right &&
        position.dy >= bounds.top &&
        position.dy <= bounds.bottom;
  }
}
