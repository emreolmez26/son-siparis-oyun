import '../models/content_ownership.dart';
import '../models/kitchen_loadout.dart';
import '../systems/loadout_recipe_resolver.dart';

enum LoadoutSaveResult { saved, invalid, persistenceFailed, noDraft }

class LoadoutState {
  LoadoutState({
    required this.ownership,
    KitchenLoadout initialLoadout = KitchenLoadout.starter,
    LoadoutRecipeResolver resolver = const LoadoutRecipeResolver(),
  }) : _active = initialLoadout.copy(),
       _resolver = resolver;

  final ContentOwnership ownership;
  final LoadoutRecipeResolver _resolver;
  KitchenLoadout _active;
  KitchenLoadout? _draft;

  KitchenLoadout get active => _active.copy();
  KitchenLoadout? get draft => _draft?.copy();
  bool get hasDraft => _draft != null;

  void openEditor() => _draft = _active.copy();
  void closeWithoutSaving() => _draft = null;

  bool toggleIngredient(String id) {
    final draft = _draft;
    if (draft == null || !ownership.ownsIngredient(id)) return false;
    final next = {...draft.ingredientIds};
    if (!next.remove(id)) {
      if (next.length >= KitchenLoadout.maxIngredientCount) return false;
      next.add(id);
    }
    _draft = KitchenLoadout(
      ingredientIds: next,
      equipmentIds: {...draft.equipmentIds},
    );
    return true;
  }

  bool toggleEquipment(String id) {
    final draft = _draft;
    if (draft == null || !ownership.ownsEquipment(id)) return false;
    final next = {...draft.equipmentIds};
    if (!next.remove(id)) {
      if (next.length >= KitchenLoadout.maxEquipmentCount) return false;
      next.add(id);
    }
    _draft = KitchenLoadout(
      ingredientIds: {...draft.ingredientIds},
      equipmentIds: next,
    );
    return true;
  }

  bool get isDraftValid {
    final draft = _draft;
    return draft != null &&
        _resolver.isValid(
          loadout: draft,
          unlockedRecipeIds: ownership.unlockedRecipeIds,
        );
  }

  Future<LoadoutSaveResult> save(
    Future<bool> Function() persistCurrentSnapshot,
  ) async {
    final draft = _draft;
    if (draft == null) return LoadoutSaveResult.noDraft;
    if (!isDraftValid) return LoadoutSaveResult.invalid;
    final previous = _active;
    _active = draft.copy();
    var persisted = false;
    try {
      persisted = await persistCurrentSnapshot();
    } on Object {
      persisted = false;
    }
    if (!persisted) {
      _active = previous;
      return LoadoutSaveResult.persistenceFailed;
    }
    _draft = null;
    return LoadoutSaveResult.saved;
  }

  void addOwnedContentWhenCapacityAllows({
    required Iterable<String> ingredientIds,
    required Iterable<String> equipmentIds,
  }) {
    final ingredients = {..._active.ingredientIds};
    for (final id in ingredientIds) {
      if (ingredients.length < KitchenLoadout.maxIngredientCount) {
        ingredients.add(id);
      }
    }
    final equipment = {..._active.equipmentIds};
    for (final id in equipmentIds) {
      if (equipment.length < KitchenLoadout.maxEquipmentCount) {
        equipment.add(id);
      }
    }
    _active = KitchenLoadout(
      ingredientIds: ingredients,
      equipmentIds: equipment,
    );
  }

  void replaceActive(KitchenLoadout loadout) => _active = loadout.copy();

  void reset() {
    _active = KitchenLoadout.starter.copy();
    _draft = null;
  }
}
