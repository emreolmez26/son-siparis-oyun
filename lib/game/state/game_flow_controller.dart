import '../models/app_screen.dart';
import '../models/upgrade_definition.dart';
import '../state/run_progression_state.dart';

class GameFlowController {
  GameFlowController({RunProgressionState? progression})
    : progression = progression ?? RunProgressionState();

  final RunProgressionState progression;
  AppScreen screen = AppScreen.mainMenu;
  UpgradeDefinition? selectedUpgrade;

  bool get isGameplayActive => screen == AppScreen.gameplay;
  bool get canConfirmUpgrade => selectedUpgrade != null;

  bool startShift() {
    if (screen != AppScreen.mainMenu) return false;
    screen = AppScreen.gameplay;
    return true;
  }

  bool showUpgradeSelection() {
    if (screen != AppScreen.shiftResults) return false;
    selectedUpgrade = null;
    screen = AppScreen.upgradeSelection;
    return true;
  }

  bool selectUpgrade(UpgradeDefinition definition) {
    if (screen != AppScreen.upgradeSelection ||
        progression.upgrades.isAtMaximum(definition)) {
      return false;
    }
    selectedUpgrade = definition;
    return true;
  }

  UpgradeDefinition? confirmUpgrade() {
    if (screen != AppScreen.upgradeSelection) return null;
    final selection = selectedUpgrade;
    if (selection == null || !progression.upgrades.increase(selection)) {
      return null;
    }
    selectedUpgrade = null;
    progression.advanceDay();
    screen = AppScreen.gameplay;
    return selection;
  }

  void showResults() {
    if (screen == AppScreen.gameplay) screen = AppScreen.shiftResults;
  }
}
