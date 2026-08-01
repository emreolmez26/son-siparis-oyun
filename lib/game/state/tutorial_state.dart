import '../models/card_definition.dart';
import '../models/tutorial_status.dart';

class TutorialState {
  TutorialState({TutorialStatus initialStatus = TutorialStatus.notStarted})
    : status = initialStatus == TutorialStatus.active
          ? TutorialStatus.notStarted
          : initialStatus;

  TutorialStatus status;
  TutorialStep currentStep = TutorialStep.cookPatty;
  bool patienceProtectionActive = false;
  double _completionMessageRemainingSeconds = 0;

  bool get isActive => status == TutorialStatus.active;
  bool get isShowingCompletion => _completionMessageRemainingSeconds > 0;
  bool get shouldShowOverlay => isActive || isShowingCompletion;

  bool startFirstShift() {
    if (status != TutorialStatus.notStarted) return false;
    status = TutorialStatus.active;
    currentStep = TutorialStep.cookPatty;
    patienceProtectionActive = true;
    return true;
  }

  bool processingStarted({
    required String inputCardId,
    required String equipmentCardId,
  }) {
    if (!isActive || currentStep != TutorialStep.cookPatty) return false;
    if (inputCardId != 'patty_01' || equipmentCardId != 'pan_01') return false;
    currentStep = TutorialStep.buildClassicBurger;
    return true;
  }

  bool recipeResolved({required String recipeId}) {
    if (!isActive || currentStep != TutorialStep.buildClassicBurger) {
      return false;
    }
    if (recipeId != 'classic_burger') return false;
    currentStep = TutorialStep.serveClassicBurger;
    return true;
  }

  bool serviceCompleted({required CardType resultType}) {
    if (!isActive || currentStep != TutorialStep.serveClassicBurger) {
      return false;
    }
    if (resultType != CardType.classicBurger) return false;
    _complete();
    return true;
  }

  bool skip() {
    if (!isActive) return false;
    status = TutorialStatus.skipped;
    patienceProtectionActive = false;
    _completionMessageRemainingSeconds = 0;
    return true;
  }

  void finishFirstShiftSafely() {
    if (isActive) skip();
  }

  void resetForReplay() {
    status = TutorialStatus.notStarted;
    currentStep = TutorialStep.cookPatty;
    patienceProtectionActive = false;
    _completionMessageRemainingSeconds = 0;
  }

  bool allowsCard(CardDefinition definition) {
    if (!isActive) return true;
    return switch (currentStep) {
      TutorialStep.cookPatty => definition.id == 'patty_01',
      TutorialStep.buildClassicBurger =>
        definition.type == CardType.bread ||
            definition.type == CardType.cookedPatty ||
            definition.type == CardType.cheese,
      TutorialStep.serveClassicBurger =>
        definition.type == CardType.classicBurger,
    };
  }

  void advance(double deltaSeconds) {
    if (_completionMessageRemainingSeconds <= 0 || deltaSeconds <= 0) return;
    _completionMessageRemainingSeconds =
        (_completionMessageRemainingSeconds - deltaSeconds)
            .clamp(0.0, double.infinity)
            .toDouble();
  }

  void _complete() {
    status = TutorialStatus.completed;
    patienceProtectionActive = false;
    _completionMessageRemainingSeconds = 1.5;
  }
}
