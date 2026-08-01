class MarketPackDefinition {
  const MarketPackDefinition({
    required this.id,
    required this.displayName,
    required this.priceCoins,
    required this.description,
    required this.ingredientIds,
    required this.equipmentIds,
    required this.recipeIds,
  });

  final String id;
  final String displayName;
  final int priceCoins;
  final String description;
  final Set<String> ingredientIds;
  final Set<String> equipmentIds;
  final Set<String> recipeIds;
}
