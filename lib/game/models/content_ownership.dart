class ContentOwnership {
  ContentOwnership({
    Iterable<String> ownedPackIds = const [],
    Iterable<String> unlockedIngredientIds = starterIngredientIds,
    Iterable<String> unlockedEquipmentIds = starterEquipmentIds,
    Iterable<String> unlockedRecipeIds = starterRecipeIds,
  }) : ownedPackIds = {...ownedPackIds},
       unlockedIngredientIds = {...unlockedIngredientIds},
       unlockedEquipmentIds = {...unlockedEquipmentIds},
       unlockedRecipeIds = {...unlockedRecipeIds};

  static const starterIngredientIds = {'bread_01', 'patty_01', 'cheese_01'};
  static const starterEquipmentIds = {'pan_01'};
  static const starterRecipeIds = {'classic_burger'};

  final Set<String> ownedPackIds;
  final Set<String> unlockedIngredientIds;
  final Set<String> unlockedEquipmentIds;
  final Set<String> unlockedRecipeIds;

  bool ownsPack(String id) => ownedPackIds.contains(id);
  bool ownsIngredient(String id) => unlockedIngredientIds.contains(id);
  bool ownsEquipment(String id) => unlockedEquipmentIds.contains(id);
  bool ownsRecipe(String id) => unlockedRecipeIds.contains(id);

  ContentOwnership copy() => ContentOwnership(
    ownedPackIds: ownedPackIds,
    unlockedIngredientIds: unlockedIngredientIds,
    unlockedEquipmentIds: unlockedEquipmentIds,
    unlockedRecipeIds: unlockedRecipeIds,
  );

  void replaceWith(ContentOwnership other) {
    ownedPackIds
      ..clear()
      ..addAll(other.ownedPackIds);
    unlockedIngredientIds
      ..clear()
      ..addAll(other.unlockedIngredientIds);
    unlockedEquipmentIds
      ..clear()
      ..addAll(other.unlockedEquipmentIds);
    unlockedRecipeIds
      ..clear()
      ..addAll(other.unlockedRecipeIds);
  }

  void reset() => replaceWith(ContentOwnership());
}
