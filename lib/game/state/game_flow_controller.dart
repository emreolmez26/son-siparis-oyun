import '../models/app_screen.dart';
import '../models/upgrade_definition.dart';
import '../state/run_progression_state.dart';

class GameFlowController {
  GameFlowController({RunProgressionState? progression})
    : progression = progression ?? RunProgressionState();

  final RunProgressionState progression;
  AppScreen screen = AppScreen.mainMenu;
  UpgradeDefinition? selectedUpgrade;
  AppScreen? _recipeBookReturnScreen;
  AppScreen? _loadoutReturnScreen;

  bool get isGameplayActive => screen == AppScreen.gameplay;
  bool get canConfirmUpgrade => selectedUpgrade != null;

  bool startShift() {
    if (screen != AppScreen.mainMenu) return false;
    screen = AppScreen.gameplay;
    return true;
  }

  bool startDailyChallenge() {
    if (screen != AppScreen.mainMenu) return false;
    screen = AppScreen.gameplay;
    return true;
  }

  bool showMarket() {
    if (screen != AppScreen.mainMenu) return false;
    screen = AppScreen.market;
    return true;
  }

  bool closeMarket() {
    if (screen != AppScreen.market) return false;
    screen = AppScreen.mainMenu;
    return true;
  }

  bool showKitchenLoadout() {
    if (screen != AppScreen.mainMenu && screen != AppScreen.market) {
      return false;
    }
    _loadoutReturnScreen = screen;
    screen = AppScreen.kitchenLoadout;
    return true;
  }

  bool closeKitchenLoadout() {
    if (screen != AppScreen.kitchenLoadout || _loadoutReturnScreen == null) {
      return false;
    }
    screen = _loadoutReturnScreen!;
    _loadoutReturnScreen = null;
    return true;
  }

  bool showSettings() {
    if (screen != AppScreen.mainMenu) return false;
    screen = AppScreen.settings;
    return true;
  }

  bool closeSettings() {
    if (screen != AppScreen.settings) return false;
    screen = AppScreen.mainMenu;
    return true;
  }

  void resetToMainMenu() {
    selectedUpgrade = null;
    _recipeBookReturnScreen = null;
    _loadoutReturnScreen = null;
    screen = AppScreen.mainMenu;
  }

  void showDailyChallengeResults() {
    if (screen == AppScreen.gameplay) screen = AppScreen.dailyChallengeResults;
  }

  bool retryDailyChallenge() {
    if (screen != AppScreen.dailyChallengeResults) return false;
    screen = AppScreen.gameplay;
    return true;
  }

  bool dailyResultsToMainMenu() {
    if (screen != AppScreen.dailyChallengeResults) return false;
    screen = AppScreen.mainMenu;
    return true;
  }

  bool showRecipeBook() {
    if (screen != AppScreen.mainMenu && screen != AppScreen.gameplay) {
      return false;
    }
    _recipeBookReturnScreen = screen;
    screen = AppScreen.recipeBook;
    return true;
  }

  bool closeRecipeBook() {
    if (screen != AppScreen.recipeBook || _recipeBookReturnScreen == null) {
      return false;
    }
    screen = _recipeBookReturnScreen!;
    _recipeBookReturnScreen = null;
    return true;
  }

  bool showUpgradeSelection() {
    if (screen != AppScreen.shiftResults && screen != AppScreen.shiftMoment) {
      return false;
    }
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

  bool showShiftMoment() {
    if (screen != AppScreen.shiftResults) return false;
    screen = AppScreen.shiftMoment;
    return true;
  }
}
