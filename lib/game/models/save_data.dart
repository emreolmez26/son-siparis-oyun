import 'game_settings.dart';
import 'tutorial_status.dart';

abstract final class SaveSchema {
  static const int currentVersion = 1;
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
  }) : upgradeLevels = Map.unmodifiable(upgradeLevels ?? const {}),
       discoveredRecipeIds = Set.unmodifiable(
         discoveredRecipeIds ?? const {'classic_burger', 'crispy_fries'},
       ),
       settings = settings == null
           ? GameSettings()
           : GameSettings(
               soundEffectsEnabled: settings.soundEffectsEnabled,
               musicEnabled: settings.musicEnabled,
               hapticsEnabled: settings.hapticsEnabled,
             );

  final int schemaVersion;
  final int day;
  final int wallet;
  final Map<String, int> upgradeLevels;
  final Set<String> discoveredRecipeIds;
  final TutorialStatus tutorialStatus;
  final GameSettings settings;

  bool get hasProgress =>
      day > 1 ||
      wallet != 120 ||
      upgradeLevels.values.any((level) => level > 0) ||
      discoveredRecipeIds.length > 2 ||
      tutorialStatus != TutorialStatus.notStarted;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'day': day,
    'wallet': wallet,
    'upgradeLevels': upgradeLevels,
    'discoveredRecipeIds': discoveredRecipeIds.toList()..sort(),
    'tutorialStatus': tutorialStatus.name,
    'settings': {
      'soundEffectsEnabled': settings.soundEffectsEnabled,
      'musicEnabled': settings.musicEnabled,
      'hapticsEnabled': settings.hapticsEnabled,
    },
  };

  static SaveData fromJson(
    Map<String, Object?> json, {
    required Set<String> knownUpgradeIds,
    required Set<String> knownRecipeIds,
  }) {
    final rawVersion = json['schemaVersion'];
    if (rawVersion is int && rawVersion > SaveSchema.currentVersion) {
      return SaveData();
    }
    final rawUpgrades = json['upgradeLevels'];
    final upgradeLevels = <String, int>{};
    if (rawUpgrades is Map) {
      for (final entry in rawUpgrades.entries) {
        final id = entry.key;
        final level = entry.value;
        if (id is String && knownUpgradeIds.contains(id) && level is num) {
          upgradeLevels[id] = level.toInt().clamp(0, 3).toInt();
        }
      }
    }
    final recipes = <String>{'classic_burger', 'crispy_fries'};
    final rawRecipes = json['discoveredRecipeIds'];
    if (rawRecipes is List) {
      recipes.addAll(
        rawRecipes.whereType<String>().where(knownRecipeIds.contains),
      );
    }
    final rawSettings = json['settings'];
    bool setting(String key) => rawSettings is Map && rawSettings[key] is bool
        ? rawSettings[key] as bool
        : true;
    final statusName = json['tutorialStatus'];
    final status = TutorialStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => TutorialStatus.notStarted,
    );
    return SaveData(
      day: _validInt(json['day'], minimum: 1, fallback: 1),
      wallet: _validInt(json['wallet'], minimum: 0, fallback: 120),
      upgradeLevels: upgradeLevels,
      discoveredRecipeIds: recipes,
      tutorialStatus: status,
      settings: GameSettings(
        soundEffectsEnabled: setting('soundEffectsEnabled'),
        musicEnabled: setting('musicEnabled'),
        hapticsEnabled: setting('hapticsEnabled'),
      ),
    );
  }

  static int _validInt(
    Object? value, {
    required int minimum,
    required int fallback,
  }) => value is num ? value.toInt().clamp(minimum, 1 << 30).toInt() : fallback;
}
