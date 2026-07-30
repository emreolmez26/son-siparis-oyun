import 'dart:ui';

class RecipeResolution {
  RecipeResolution({
    required this.recipeId,
    required this.sourceStackId,
    required List<String> sourceCardIds,
    required this.basePosition,
    required this.resultCardId,
  }) : sourceCardIds = List.unmodifiable(sourceCardIds);

  final String recipeId;
  final String sourceStackId;
  final List<String> sourceCardIds;
  final Offset basePosition;
  final String resultCardId;
}
