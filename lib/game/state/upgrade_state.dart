import '../game_layout.dart';
import '../models/upgrade_definition.dart';
import '../models/upgrade_id.dart';
import '../models/card_definition.dart';

class UpgradeState {
  UpgradeState({Map<UpgradeId, int>? initialLevels})
    : _levels = {
        for (final id in UpgradeId.values) id: initialLevels?[id] ?? 0,
      };

  final Map<UpgradeId, int> _levels;

  Map<UpgradeId, int> get levels => Map.unmodifiable(_levels);

  int levelFor(UpgradeId id) => _levels[id] ?? 0;

  bool isAtMaximum(UpgradeDefinition definition) =>
      levelFor(definition.id) >= definition.maximumLevel;

  bool increase(UpgradeDefinition definition) {
    final current = levelFor(definition.id);
    if (current >= definition.maximumLevel) return false;
    _levels[definition.id] = current + 1;
    return true;
  }

  void reset() {
    for (final id in UpgradeId.values) {
      _levels[id] = 0;
    }
  }

  double effectivePanDuration() =>
      (GameLayout.processingDurationSeconds *
              _power(.75, levelFor(UpgradeId.fastPan)))
          .clamp(1.25, double.infinity)
          .toDouble();

  int effectiveBurgerReward() =>
      GameLayout.successfulServiceRewardCoins +
      (5 * levelFor(UpgradeId.doubleCheese));

  int effectiveRewardFor(CardDefinition definition) =>
      definition.baseRewardCoins +
      (definition.usesCheeseBonus ? 5 * levelFor(UpgradeId.doubleCheese) : 0);

  double nextOrderPatienceDuration({
    required bool hasPendingBonus,
    double baseDurationSeconds = GameLayout.customerPatienceDurationSeconds,
  }) =>
      baseDurationSeconds +
      (hasPendingBonus ? 4 * levelFor(UpgradeId.coolHeadedService) : 0);

  static double _power(double base, int exponent) {
    var value = 1.0;
    for (var index = 0; index < exponent; index++) {
      value *= base;
    }
    return value;
  }
}
