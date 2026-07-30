import '../models/card_definition.dart';
import '../models/recipe_definition.dart';

class RecipeResolver {
  RecipeResolver({required Iterable<RecipeDefinition> recipes})
    : _recipes = List.unmodifiable(recipes);

  final List<RecipeDefinition> _recipes;

  RecipeDefinition? resolve(Iterable<CardType> orderedCardTypes) {
    final types = List<CardType>.of(orderedCardTypes);
    for (final recipe in _recipes) {
      if (_hasExactOrderedTypes(recipe.requiredCardTypes, types)) {
        return recipe;
      }
    }
    return null;
  }

  bool _hasExactOrderedTypes(
    List<CardType> expectedTypes,
    List<CardType> actualTypes,
  ) {
    if (expectedTypes.length != actualTypes.length) {
      return false;
    }
    for (var index = 0; index < expectedTypes.length; index++) {
      if (expectedTypes[index] != actualTypes[index]) {
        return false;
      }
    }
    return true;
  }
}
