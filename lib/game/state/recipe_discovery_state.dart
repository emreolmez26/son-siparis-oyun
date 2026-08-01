class RecipeDiscoveryState {
  RecipeDiscoveryState({Iterable<String>? initiallyDiscovered})
    : _discoveredRecipeIds = {
        'classic_burger',
        'crispy_fries',
        ...?initiallyDiscovered,
      };

  final Set<String> _discoveredRecipeIds;

  bool isDiscovered(String recipeId) => _discoveredRecipeIds.contains(recipeId);

  bool discover(String recipeId) => _discoveredRecipeIds.add(recipeId);

  Set<String> get discoveredRecipeIds => Set.unmodifiable(_discoveredRecipeIds);

  void reset() {
    _discoveredRecipeIds
      ..clear()
      ..addAll(const {'classic_burger', 'crispy_fries'});
  }
}
