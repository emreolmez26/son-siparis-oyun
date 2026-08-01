class RecipeDiscoveryState {
  RecipeDiscoveryState({Iterable<String>? initiallyDiscovered})
    : _discoveredRecipeIds = {'classic_burger', ...?initiallyDiscovered};

  final Set<String> _discoveredRecipeIds;

  bool isDiscovered(String recipeId) => _discoveredRecipeIds.contains(recipeId);

  bool discover(String recipeId) => _discoveredRecipeIds.add(recipeId);

  Set<String> get discoveredRecipeIds => Set.unmodifiable(_discoveredRecipeIds);

  void reset() {
    _discoveredRecipeIds
      ..clear()
      ..add('classic_burger');
  }

  void replaceWith(Iterable<String> recipeIds) {
    _discoveredRecipeIds
      ..clear()
      ..addAll(recipeIds)
      ..add('classic_burger');
  }
}
