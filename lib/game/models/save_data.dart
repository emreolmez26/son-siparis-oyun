import '../data/content_unlock_definitions.dart';
import '../data/market_catalog.dart';
import '../systems/loadout_recipe_resolver.dart';
import 'content_ownership.dart';
import 'daily_challenge_result.dart';
import 'game_settings.dart';
import 'kitchen_loadout.dart';
import 'tutorial_status.dart';

abstract final class SaveSchema {
  static const int currentVersion = 2;
}

class SaveData {
  SaveData({
    this.schemaVersion = SaveSchema.currentVersion,
    this.day = 1,
    this.wallet = 120,
    Map<String, int>? upgradeLevels,
    Set<String>? discoveredRecipeIds,
    this.tutorialStatus = TutorialStatus.notStarted,
    GameSettings? settings,
    Set<String>? ownedMarketPackIds,
    Set<String>? unlockedIngredientIds,
    Set<String>? unlockedEquipmentIds,
    Set<String>? unlockedRecipeIds,
    Set<String>? selectedIngredientIds,
    Set<String>? selectedEquipmentIds,
    Map<String, DailyChallengeRecord>? dailyChallengeRecords,
  }) : upgradeLevels = Map.unmodifiable(upgradeLevels ?? const {}),
       discoveredRecipeIds = Set.unmodifiable(
         discoveredRecipeIds ?? ContentOwnership.starterRecipeIds,
       ),
       settings = settings == null
           ? GameSettings()
           : GameSettings(
               soundEffectsEnabled: settings.soundEffectsEnabled,
               musicEnabled: settings.musicEnabled,
               hapticsEnabled: settings.hapticsEnabled,
             ),
       ownedMarketPackIds = Set.unmodifiable(ownedMarketPackIds ?? const {}),
       unlockedIngredientIds = Set.unmodifiable(
         unlockedIngredientIds ?? ContentOwnership.starterIngredientIds,
       ),
       unlockedEquipmentIds = Set.unmodifiable(
         unlockedEquipmentIds ?? ContentOwnership.starterEquipmentIds,
       ),
       unlockedRecipeIds = Set.unmodifiable(
         unlockedRecipeIds ?? ContentOwnership.starterRecipeIds,
       ),
       selectedIngredientIds = Set.unmodifiable(
         selectedIngredientIds ?? KitchenLoadout.starter.ingredientIds,
       ),
       selectedEquipmentIds = Set.unmodifiable(
         selectedEquipmentIds ?? KitchenLoadout.starter.equipmentIds,
       ),
       dailyChallengeRecords = Map.unmodifiable(
         dailyChallengeRecords ?? const {},
       );

  final int schemaVersion;
  final int day;
  final int wallet;
  final Map<String, int> upgradeLevels;
  final Set<String> discoveredRecipeIds;
  final TutorialStatus tutorialStatus;
  final GameSettings settings;
  final Set<String> ownedMarketPackIds;
  final Set<String> unlockedIngredientIds;
  final Set<String> unlockedEquipmentIds;
  final Set<String> unlockedRecipeIds;
  final Set<String> selectedIngredientIds;
  final Set<String> selectedEquipmentIds;
  final Map<String, DailyChallengeRecord> dailyChallengeRecords;

  bool get hasProgress =>
      day > 1 ||
      wallet != 120 ||
      upgradeLevels.values.any((level) => level > 0) ||
      ownedMarketPackIds.isNotEmpty ||
      dailyChallengeRecords.isNotEmpty ||
      tutorialStatus != TutorialStatus.notStarted;

  Map<String, Object?> toJson() => {
    'schemaVersion': SaveSchema.currentVersion,
    'day': day,
    'wallet': wallet,
    'upgradeLevels': upgradeLevels,
    'discoveredRecipeIds': _sorted(discoveredRecipeIds),
    'tutorialStatus': tutorialStatus.name,
    'settings': {
      'soundEffectsEnabled': settings.soundEffectsEnabled,
      'musicEnabled': settings.musicEnabled,
      'hapticsEnabled': settings.hapticsEnabled,
    },
    'ownedMarketPackIds': _sorted(ownedMarketPackIds),
    'unlockedIngredientIds': _sorted(unlockedIngredientIds),
    'unlockedEquipmentIds': _sorted(unlockedEquipmentIds),
    'unlockedRecipeIds': _sorted(unlockedRecipeIds),
    'selectedIngredientIds': _sorted(selectedIngredientIds),
    'selectedEquipmentIds': _sorted(selectedEquipmentIds),
    'dailyChallengeRecords':
        dailyChallengeRecords.values.map((record) => record.toJson()).toList()
          ..sort(
            (a, b) =>
                (a['dateKey'] as String).compareTo(b['dateKey'] as String),
          ),
  };

  static SaveData fromJson(
    Map<String, Object?> json, {
    required Set<String> knownUpgradeIds,
    required Set<String> knownRecipeIds,
    Set<String> knownPackIds = allMarketPackIds,
    Set<String> knownIngredientIds = allIngredientIds,
    Set<String> knownEquipmentIds = allEquipmentIds,
  }) {
    final rawVersion = json['schemaVersion'];
    if (rawVersion is int && rawVersion > SaveSchema.currentVersion) {
      return SaveData();
    }
    final isV1 = rawVersion == null || rawVersion == 1;
    final upgrades = _readUpgradeLevels(json['upgradeLevels'], knownUpgradeIds);
    final settings = _readSettings(json['settings']);
    final status = TutorialStatus.values.firstWhere(
      (value) => value.name == json['tutorialStatus'],
      orElse: () => TutorialStatus.notStarted,
    );

    if (isV1) {
      final discoveries = _readSet(json['discoveredRecipeIds'], knownRecipeIds)
        ..addAll(allRecipeIds.where(knownRecipeIds.contains));
      return SaveData(
        day: _validInt(json['day'], minimum: 1, fallback: 1),
        wallet: _validInt(json['wallet'], minimum: 0, fallback: 120),
        upgradeLevels: upgrades,
        discoveredRecipeIds: discoveries,
        tutorialStatus: status,
        settings: settings,
        ownedMarketPackIds: knownPackIds.intersection(allMarketPackIds),
        unlockedIngredientIds: knownIngredientIds.intersection(
          allIngredientIds,
        ),
        unlockedEquipmentIds: knownEquipmentIds.intersection(allEquipmentIds),
        unlockedRecipeIds: knownRecipeIds.intersection(allRecipeIds),
        selectedIngredientIds: knownIngredientIds.intersection(
          allIngredientIds,
        ),
        selectedEquipmentIds: knownEquipmentIds.intersection(allEquipmentIds),
      );
    }

    final packs = _readSet(json['ownedMarketPackIds'], knownPackIds);
    final ingredients = _readSet(
      json['unlockedIngredientIds'],
      knownIngredientIds,
    )..addAll(ContentOwnership.starterIngredientIds);
    final equipment = _readSet(json['unlockedEquipmentIds'], knownEquipmentIds)
      ..addAll(ContentOwnership.starterEquipmentIds);
    final recipes = _readSet(json['unlockedRecipeIds'], knownRecipeIds)
      ..addAll(ContentOwnership.starterRecipeIds);
    for (final pack in marketCatalog.where((pack) => packs.contains(pack.id))) {
      ingredients.addAll(pack.ingredientIds.where(knownIngredientIds.contains));
      equipment.addAll(pack.equipmentIds.where(knownEquipmentIds.contains));
      recipes.addAll(pack.recipeIds.where(knownRecipeIds.contains));
    }
    var selectedIngredients = _readSet(
      json['selectedIngredientIds'],
      knownIngredientIds,
    ).intersection(ingredients);
    var selectedEquipment = _readSet(
      json['selectedEquipmentIds'],
      knownEquipmentIds,
    ).intersection(equipment);
    final loadout = KitchenLoadout(
      ingredientIds: selectedIngredients,
      equipmentIds: selectedEquipment,
    );
    if (!const LoadoutRecipeResolver().isValid(
      loadout: loadout,
      unlockedRecipeIds: recipes,
    )) {
      selectedIngredients = {...KitchenLoadout.starter.ingredientIds};
      selectedEquipment = {...KitchenLoadout.starter.equipmentIds};
    }
    final discoveries = _readSet(json['discoveredRecipeIds'], knownRecipeIds)
      ..addAll(recipes);
    final records = <String, DailyChallengeRecord>{};
    final rawRecords = json['dailyChallengeRecords'];
    if (rawRecords is List) {
      for (final raw in rawRecords) {
        final record = DailyChallengeRecord.fromJson(raw);
        if (record != null) records[record.storageKey] = record;
      }
    }
    final sortedRecords = records.values.toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return SaveData(
      day: _validInt(json['day'], minimum: 1, fallback: 1),
      wallet: _validInt(json['wallet'], minimum: 0, fallback: 120),
      upgradeLevels: upgrades,
      discoveredRecipeIds: discoveries,
      tutorialStatus: status,
      settings: settings,
      ownedMarketPackIds: packs,
      unlockedIngredientIds: ingredients,
      unlockedEquipmentIds: equipment,
      unlockedRecipeIds: recipes,
      selectedIngredientIds: selectedIngredients,
      selectedEquipmentIds: selectedEquipment,
      dailyChallengeRecords: {
        for (final record in sortedRecords.take(30)) record.storageKey: record,
      },
    );
  }

  static List<String> _sorted(Iterable<String> values) =>
      values.toList()..sort();

  static Set<String> _readSet(Object? raw, Set<String> knownIds) => raw is List
      ? raw.whereType<String>().where(knownIds.contains).toSet()
      : <String>{};

  static Map<String, int> _readUpgradeLevels(
    Object? raw,
    Set<String> knownIds,
  ) {
    final levels = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.key is String &&
            knownIds.contains(entry.key) &&
            entry.value is num) {
          levels[entry.key as String] = (entry.value as num).toInt().clamp(
            0,
            3,
          );
        }
      }
    }
    return levels;
  }

  static GameSettings _readSettings(Object? raw) {
    bool setting(String key) =>
        raw is Map && raw[key] is bool ? raw[key] as bool : true;
    return GameSettings(
      soundEffectsEnabled: setting('soundEffectsEnabled'),
      musicEnabled: setting('musicEnabled'),
      hapticsEnabled: setting('hapticsEnabled'),
    );
  }

  static int _validInt(
    Object? value, {
    required int minimum,
    required int fallback,
  }) => value is num ? value.toInt().clamp(minimum, 1 << 30) : fallback;
}
