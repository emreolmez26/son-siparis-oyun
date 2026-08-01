import '../data/content_unlock_definitions.dart';
import '../models/card_definition.dart';
import '../models/kitchen_loadout.dart';

class LoadoutRecipeResolver {
  const LoadoutRecipeResolver();

  Set<String> supportedRecipeIds({
    required KitchenLoadout loadout,
    required Set<String> unlockedRecipeIds,
  }) => unlockedRecipeIds.where((recipeId) {
    final ingredients = recipeRequiredIngredientIds[recipeId];
    final equipment = recipeRequiredEquipmentIds[recipeId];
    return ingredients != null &&
        equipment != null &&
        loadout.ingredientIds.containsAll(ingredients) &&
        loadout.equipmentIds.containsAll(equipment);
  }).toSet();

  Set<CardType> supportedResultTypes({
    required KitchenLoadout loadout,
    required Set<String> unlockedRecipeIds,
  }) => supportedRecipeIds(
    loadout: loadout,
    unlockedRecipeIds: unlockedRecipeIds,
  ).map((id) => recipeResultTypes[id]!).toSet();

  bool isValid({
    required KitchenLoadout loadout,
    required Set<String> unlockedRecipeIds,
  }) => supportedRecipeIds(
    loadout: loadout,
    unlockedRecipeIds: unlockedRecipeIds,
  ).isNotEmpty;
}
