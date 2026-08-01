import '../models/content_ownership.dart';
import '../models/market_pack_definition.dart';
import 'loadout_state.dart';
import 'recipe_discovery_state.dart';
import 'run_progression_state.dart';

enum MarketPurchaseResult {
  success,
  unknownPack,
  alreadyOwned,
  insufficientFunds,
  invalidScreen,
  transactionRunning,
  persistenceFailed,
}

extension MarketPurchaseResultMessage on MarketPurchaseResult {
  String get message => switch (this) {
    MarketPurchaseResult.success => 'MUTFAĞA EKLENDİ!',
    MarketPurchaseResult.alreadyOwned => 'SATIN ALINDI',
    MarketPurchaseResult.insufficientFunds => 'YETERLİ PARAN YOK',
    MarketPurchaseResult.persistenceFailed => 'KAYIT BAŞARISIZ',
    _ => 'İŞLEM YAPILAMADI',
  };
}

class MarketState {
  MarketState({
    required Iterable<MarketPackDefinition> catalog,
    required this.progression,
    required this.ownership,
    required this.loadout,
    required this.discovery,
  }) : _catalog = {for (final pack in catalog) pack.id: pack};

  final Map<String, MarketPackDefinition> _catalog;
  final RunProgressionState progression;
  final ContentOwnership ownership;
  final LoadoutState loadout;
  final RecipeDiscoveryState discovery;
  bool transactionRunning = false;
  MarketPurchaseResult? lastResult;

  Iterable<MarketPackDefinition> get catalog => _catalog.values;

  Future<MarketPurchaseResult> purchase({
    required String packId,
    required bool isMarketScreen,
    required Future<bool> Function() persistCurrentSnapshot,
  }) async {
    if (transactionRunning) {
      return _set(MarketPurchaseResult.transactionRunning);
    }
    final pack = _catalog[packId];
    if (pack == null) return _set(MarketPurchaseResult.unknownPack);
    if (!isMarketScreen) return _set(MarketPurchaseResult.invalidScreen);
    if (ownership.ownsPack(packId)) {
      return _set(MarketPurchaseResult.alreadyOwned);
    }
    if (progression.walletCoins < pack.priceCoins) {
      return _set(MarketPurchaseResult.insufficientFunds);
    }

    transactionRunning = true;
    final previousWallet = progression.walletCoins;
    final previousOwnership = ownership.copy();
    final previousLoadout = loadout.active;
    final previousRecipes = discovery.discoveredRecipeIds;
    progression.walletCoins -= pack.priceCoins;
    ownership.ownedPackIds.add(pack.id);
    ownership.unlockedIngredientIds.addAll(pack.ingredientIds);
    ownership.unlockedEquipmentIds.addAll(pack.equipmentIds);
    ownership.unlockedRecipeIds.addAll(pack.recipeIds);
    for (final recipeId in pack.recipeIds) {
      discovery.discover(recipeId);
    }
    loadout.addOwnedContentWhenCapacityAllows(
      ingredientIds: pack.ingredientIds,
      equipmentIds: pack.equipmentIds,
    );

    var persisted = false;
    try {
      persisted = await persistCurrentSnapshot();
    } on Object {
      persisted = false;
    }
    if (!persisted) {
      progression.walletCoins = previousWallet;
      ownership.replaceWith(previousOwnership);
      loadout.replaceActive(previousLoadout);
      discovery.replaceWith(previousRecipes);
      transactionRunning = false;
      return _set(MarketPurchaseResult.persistenceFailed);
    }
    transactionRunning = false;
    return _set(MarketPurchaseResult.success);
  }

  MarketPurchaseResult _set(MarketPurchaseResult result) {
    lastResult = result;
    return result;
  }
}
