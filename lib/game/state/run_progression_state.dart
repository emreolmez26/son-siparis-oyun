import '../game_layout.dart';
import '../models/upgrade_id.dart';
import 'upgrade_state.dart';

class RunProgressionState {
  RunProgressionState({
    this.currentDay = 1,
    this.walletCoins = GameLayout.initialWalletCoins,
    UpgradeState? upgrades,
  }) : upgrades = upgrades ?? UpgradeState();

  int currentDay;
  int walletCoins;
  final UpgradeState upgrades;

  void addWalletCoins(int amount) {
    walletCoins += amount;
  }

  void advanceDay() {
    currentDay += 1;
  }

  int levelFor(UpgradeId id) => upgrades.levelFor(id);
}
