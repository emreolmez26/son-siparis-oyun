import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/customer_area_component.dart';
import 'components/combo_feedback_component.dart';
import 'components/game_card_component.dart';
import 'components/hud_component.dart';
import 'components/kitchen_table_component.dart';
import 'components/last_second_feedback_component.dart';
import 'components/main_menu_component.dart';
import 'components/order_failure_feedback_component.dart';
import 'components/pause_overlay_component.dart';
import 'components/player_hand_component.dart';
import 'components/processing_indicator_component.dart';
import 'components/processing_preview_component.dart';
import 'components/recipe_button_component.dart';
import 'components/recipe_book_component.dart';
import 'components/recipe_feedback_component.dart';
import 'components/recipe_preview_component.dart';
import 'components/service_counter_component.dart';
import 'components/service_feedback_component.dart';
import 'components/service_preview_component.dart';
import 'components/settings_component.dart';
import 'components/shift_results_component.dart';
import 'components/snap_preview_component.dart';
import 'components/stack_preview_component.dart';
import 'components/shift_moment_component.dart';
import 'components/tutorial_overlay_component.dart';
import 'components/upgrade_selection_component.dart';
import 'data/prototype_card_definitions.dart';
import 'data/prototype_customer_definitions.dart';
import 'data/prototype_processing_definitions.dart';
import 'data/prototype_recipe_definitions.dart';
import 'data/recipe_book_entries.dart';
import 'game_layout.dart';
import 'kitchen_grid.dart';
import 'models/app_screen.dart';
import 'models/card_definition.dart';
import 'models/card_drag_snapshot.dart';
import 'models/game_settings.dart';
import 'models/customer_slot_state.dart';
import 'models/processing_job.dart';
import 'models/recipe_definition.dart';
import 'models/recipe_resolution.dart';
import 'models/save_data.dart';
import 'models/shift_phase.dart';
import 'models/shift_moment.dart';
import 'models/tutorial_status.dart';
import 'models/upgrade_id.dart';
import 'state/equipment_processing_state.dart';
import 'state/feedback_state.dart';
import 'state/game_flow_controller.dart';
import 'state/kitchen_table_state.dart';
import 'state/order_system.dart';
import 'state/run_progression_state.dart';
import 'state/shift_state.dart';
import 'state/recipe_discovery_state.dart';
import 'state/shift_moment_tracker.dart';
import 'state/tutorial_state.dart';
import 'state/upgrade_state.dart';
import 'services/audio_service.dart';
import 'services/haptic_service.dart';
import 'services/save_service.dart';
import 'systems/equipment_target_resolver.dart';
import 'systems/processing_output_resolver.dart';
import 'systems/recipe_resolver.dart';
import 'systems/service_target_resolver.dart';
import 'systems/stack_layout.dart';
import 'systems/stack_target_resolver.dart';

class SonSiparisGame extends FlameGame {
  SonSiparisGame({
    SaveData? initialSaveData,
    SaveService? saveService,
    AudioService? audioService,
    HapticService? hapticService,
  }) : _initialSaveData = initialSaveData ?? SaveData(),
       _saveService = saveService,
       super(
         camera: CameraComponent.withFixedResolution(
           width: GameLayout.designWidth,
           height: GameLayout.designHeight,
         ),
       ) {
    settings = _initialSaveData.settings;
    audio = audioService ?? PlatformAudioService(settings);
    haptics = hapticService ?? PlatformHapticService(settings);
  }

  final SaveData _initialSaveData;
  final SaveService? _saveService;
  late final GameSettings settings;
  late final AudioService audio;
  late final HapticService haptics;

  late final KitchenGrid _kitchenGrid = KitchenGrid(
    tableBounds: GameLayout.kitchenTableBounds,
    cardSize: GameLayout.cardSize,
    spacing: GameLayout.kitchenGridSpacing,
    padding: GameLayout.kitchenGridPadding,
  );
  late final StackLayout _stackLayout = StackLayout(
    cardSize: GameLayout.cardSize,
    paddedTableBounds: _kitchenGrid.paddedTableBounds,
    gridOrigin: _kitchenGrid.origin,
    gridSpacing: _kitchenGrid.spacing,
    levelOffset: GameLayout.stackLevelOffset,
  );
  late final StackTargetResolver _stackTargetResolver = StackTargetResolver(
    cardSize: GameLayout.cardSize,
  );
  late final EquipmentTargetResolver _equipmentTargetResolver =
      EquipmentTargetResolver(cardSize: GameLayout.cardSize);
  late final ProcessingOutputResolver _processingOutputResolver =
      ProcessingOutputResolver(kitchenGrid: _kitchenGrid);
  late final RecipeResolver _recipeResolver = RecipeResolver(
    recipes: prototypeRecipeDefinitions,
  );
  late final ServiceTargetResolver _serviceTargetResolver =
      ServiceTargetResolver(cardSize: GameLayout.cardSize);
  late final ShiftState _shiftState = ShiftState();
  late final GameFlowController _flow = GameFlowController(
    progression: RunProgressionState(
      currentDay: _initialSaveData.day,
      walletCoins: _initialSaveData.wallet,
      upgrades: UpgradeState(
        initialLevels: {
          for (final id in UpgradeId.values)
            id: _initialSaveData.upgradeLevels[id.name] ?? 0,
        },
      ),
    ),
  );
  late final TutorialState _tutorialState = TutorialState(
    initialStatus: _initialSaveData.tutorialStatus,
  );
  late final RecipeDiscoveryState _recipeDiscoveryState = RecipeDiscoveryState(
    initiallyDiscovered: _initialSaveData.discoveredRecipeIds,
  );
  late final ShiftMomentTracker _shiftMomentTracker = ShiftMomentTracker();
  late final OrderSystem _orderSystem = OrderSystem(
    customerDefinitions: prototypeCustomerDefinitions,
  );
  late final EquipmentProcessingState _processingState =
      EquipmentProcessingState(
        processingDurationSeconds: GameLayout.processingDurationSeconds,
      );
  late final KitchenTableState _tableState = KitchenTableState(
    definitions: prototypeCardDefinitions,
    initialHandPositions: GameLayout.initialHandCardPositions,
    initialEquipmentTablePositions: GameLayout.initialEquipmentTablePositions,
    stackLayout: _stackLayout,
  );
  late final SnapPreviewComponent _snapPreview = SnapPreviewComponent();
  late final StackPreviewComponent _stackPreview = StackPreviewComponent();
  late final RecipePreviewComponent _recipePreview = RecipePreviewComponent();
  late final ProcessingPreviewComponent _processingPreview =
      ProcessingPreviewComponent();
  late final RecipeFeedbackComponent _recipeFeedback =
      RecipeFeedbackComponent();
  late final ServicePreviewComponent _servicePreview =
      ServicePreviewComponent();
  late final ServiceFeedbackComponent _serviceFeedback =
      ServiceFeedbackComponent();
  late final OrderFailureFeedbackComponent _failureFeedback =
      OrderFailureFeedbackComponent();
  late final ServiceCounterComponent _serviceCounter =
      ServiceCounterComponent();
  late final HudComponent _hud = HudComponent(
    shiftState: _shiftState,
    dayProvider: () => _flow.progression.currentDay,
    onPausePressed: _togglePause,
  );
  late final ComboFeedbackComponent _comboFeedback = ComboFeedbackComponent();
  late final ComboMilestoneTracker _comboMilestones = ComboMilestoneTracker();
  late final LastSecondFeedbackState _lastSecondFeedbackState =
      LastSecondFeedbackState();

  final Map<String, GameCardComponent> _cardComponents = {};
  String? _activeCardId;
  CardDragSnapshot? _activeDragSnapshot;
  bool _hasPendingPatienceBonus = false;

  ShiftState get shiftState => _shiftState;
  GameFlowController get flow => _flow;
  OrderSystem get orderSystem => _orderSystem;
  EquipmentProcessingState get processingState => _processingState;
  KitchenTableState get tableState => _tableState;
  TutorialState get tutorialState => _tutorialState;
  RecipeDiscoveryState get recipeDiscoveryState => _recipeDiscoveryState;
  ShiftMomentTracker get shiftMomentTracker => _shiftMomentTracker;
  ShiftMoment? get selectedShiftMoment => _shiftMomentTracker.selectMoment();
  bool get isGameplayInputAllowed =>
      _flow.isGameplayActive && _shiftState.isGameplayInputAllowed;
  bool get canContinue => _currentSaveData().hasProgress;

  @override
  Color backgroundColor() => GameLayout.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();

    world.addAll([
      _hud,
      CustomerAreaComponent(orderSystem: _orderSystem),
      RecipeButtonComponent(
        isShowing: () => _flow.screen == AppScreen.gameplay,
        onOpenRecipeBook: _openRecipeBook,
      ),
      KitchenTableComponent(),
      _serviceCounter,
      PlayerHandComponent(),
      _snapPreview,
      _stackPreview,
      _recipePreview,
      _processingPreview,
      _recipeFeedback,
      _servicePreview,
      _serviceFeedback,
      _failureFeedback,
      _comboFeedback,
      LastSecondFeedbackComponent(state: _lastSecondFeedbackState),
      ProcessingIndicatorComponent(
        jobsProvider: () => _processingState.activeJobs,
        positionForCard: (cardId) =>
            _tableState.placementFor(cardId).currentValidPosition,
      ),
      PauseOverlayComponent(
        isShowing: () => _shiftState.phase == ShiftPhase.paused,
        onResume: _resumeShift,
      ),
      ShiftResultsComponent(
        shiftState: _shiftState,
        isShowing: () => _flow.screen == AppScreen.shiftResults,
        onSelectUpgrades: _continueAfterResults,
      ),
      MainMenuComponent(
        isShowing: () => _flow.screen == AppScreen.mainMenu,
        progression: _flow.progression,
        onStartShift: _startShiftFromMenu,
        onContinue: _startShiftFromMenu,
        canContinue: () => canContinue,
        onOpenRecipeBook: _openRecipeBook,
        onOpenSettings: _openSettings,
      ),
      SettingsComponent(
        isShowing: () => _flow.screen == AppScreen.settings,
        settings: settings,
        onSettingsChanged: _settingsChanged,
        onReplayTutorial: _replayTutorial,
        onResetConfirmed: _resetSave,
        onBack: _closeSettings,
      ),
      RecipeBookComponent(
        entries: recipeBookEntries,
        discoveryState: _recipeDiscoveryState,
        progression: _flow.progression,
        isShowing: () => _flow.screen == AppScreen.recipeBook,
        onClose: _closeRecipeBook,
      ),
      ShiftMomentComponent(
        momentProvider: () => selectedShiftMoment,
        isShowing: () => _flow.screen == AppScreen.shiftMoment,
        onContinue: _showUpgradeSelection,
      ),
      UpgradeSelectionComponent(
        flow: _flow,
        isShowing: () => _flow.screen == AppScreen.upgradeSelection,
        onConfirm: _confirmUpgradeSelection,
      ),
      TutorialOverlayComponent(
        tutorialState: _tutorialState,
        sourceBoundsProvider: _tutorialSourceBounds,
        targetBoundsProvider: _tutorialTargetBounds,
        onSkip: _skipTutorial,
      ),
    ]);
    _syncCardComponentsFromState();
  }

  bool _handleDragStarted(String cardId) {
    if (!isGameplayInputAllowed ||
        _processingState.isCardLocked(cardId) ||
        _tableState.isConsumed(cardId) ||
        _tableState.isServed(cardId) ||
        !_tutorialState.allowsCard(_tableState.definitionFor(cardId))) {
      return false;
    }
    _activeCardId = cardId;
    _activeDragSnapshot = _tableState.beginCardDrag(cardId);
    _syncCardComponentsFromState();
    _hideInteractionPreviews();
    audio.play(SoundEventId.cardPickUp);
    return true;
  }

  void _updateDragFeedback(String cardId, Vector2 cardPosition) {
    if (_activeCardId != cardId || !isGameplayInputAllowed) return;

    final serviceTarget = _resolveServiceTarget(cardId, cardPosition);
    if (serviceTarget != null) {
      _snapPreview.hide();
      _stackPreview.hide();
      _recipePreview.hide();
      _processingPreview.hide();
      _servicePreview.show(
        serviceTarget.bounds,
        resultName: serviceTarget.resultName,
      );
      return;
    }

    _servicePreview.hide();
    final equipmentTarget = _resolveEquipmentTarget(cardId, cardPosition);
    if (equipmentTarget != null) {
      _snapPreview.hide();
      _stackPreview.hide();
      _recipePreview.hide();
      _processingPreview.show(
        panBounds: equipmentTarget.bounds,
        inputBounds: _cardBoundsAt(
          _processingAttachmentPosition(equipmentTarget.equipmentCardId),
        ),
        isAvailable: equipmentTarget.isAvailable,
      );
      return;
    }

    _processingPreview.hide();
    final target = _resolveStackTarget(cardId, cardPosition);
    if (target != null) {
      _snapPreview.hide();
      final previewGeometry = _tableState.previewGeometryForTarget(
        target.cardId,
      );
      final recipe = _recipeForTarget(cardId, target.cardId);
      if (recipe != null) {
        _stackPreview.hide();
        _recipePreview.show(
          targetBounds: previewGeometry.targetBounds,
          newTopBounds: previewGeometry.newTopBounds,
          recipeName: recipe.displayName,
        );
      } else {
        _recipePreview.hide();
        _stackPreview.show(
          targetBounds: previewGeometry.targetBounds,
          newTopBounds: previewGeometry.newTopBounds,
        );
      }
      return;
    }

    _stackPreview.hide();
    _recipePreview.hide();
    final candidatePosition = _kitchenGrid.snapCandidate(
      Offset(cardPosition.x, cardPosition.y),
    );
    if (candidatePosition == null) {
      _snapPreview.hide();
    } else {
      _snapPreview.showAt(Vector2(candidatePosition.dx, candidatePosition.dy));
    }
  }

  Vector2 _handleDragReleased(String cardId, Vector2 cardPosition) {
    if (_activeCardId != cardId || !isGameplayInputAllowed) {
      return _toVector2(_tableState.placementFor(cardId).currentValidPosition);
    }

    RecipeResolution? recipeResolution;
    final serviceTarget = _resolveServiceTarget(cardId, cardPosition);
    if (serviceTarget != null) {
      final definition = _tableState.definitionFor(cardId);
      final rewardCoins = _flow.progression.upgrades.effectiveRewardFor(
        definition,
      );
      final completion = _orderSystem.tryServe(
        cardId: cardId,
        tableState: _tableState,
        shiftState: _shiftState,
        rewardCoins: rewardCoins,
        enterShiftFeedback: false,
      );
      if (completion == null) {
        _restoreActiveDragSnapshot(cardId);
      } else {
        _cardComponents[cardId]?.triggerValidDrop();
        _tableState.recycleServedResultSources(
          resultCardId: cardId,
          rawDefinitionsById: prototypeRawDefinitionsById,
          handPositions: GameLayout.initialHandCardPositions,
        );
        _flow.progression.addWalletCoins(completion.rewardCoins);
        _persist();
        _shiftMomentTracker.recordSuccessfulService(
          resultDefinition: definition,
          remainingPatienceSeconds: completion.remainingPatienceSeconds,
          combo: _shiftState.currentCombo,
          rewardCoins: completion.rewardCoins,
        );
        if (_tutorialState.serviceCompleted(
          resultType: completion.requestedResultType,
        )) {
          _orderSystem.clearTutorialPatienceProtection();
          _persist();
        }
        _hasPendingPatienceBonus =
            _flow.progression.upgrades.levelFor(UpgradeId.coolHeadedService) >
            0;
        _serviceCounter.triggerSuccessGlow();
        _serviceFeedback.trigger(
          rewardCoins: completion.rewardCoins,
          origin: Offset(cardPosition.x, cardPosition.y),
        );
        _hud
          ..triggerWalletPulse()
          ..triggerComboPulse();
        final milestone = _comboMilestones.record(_shiftState.currentCombo);
        if (milestone != null) {
          _comboFeedback.trigger(milestone);
          audio.play(SoundEventId.comboMilestone);
        }
        _lastSecondFeedbackState.trigger(completion.remainingPatienceSeconds);
        audio.play(SoundEventId.correctService);
        haptics.trigger(
          completion.remainingPatienceSeconds <= 1
              ? HapticEvent.lastSecond
              : HapticEvent.service,
        );
      }
    } else if (_isWrongServiceDrop(cardId, cardPosition)) {
      _restoreActiveDragSnapshot(cardId);
      _serviceCounter.triggerRejection();
      audio.play(SoundEventId.wrongService);
    } else {
      final equipmentTarget = _resolveEquipmentTarget(cardId, cardPosition);
      if (equipmentTarget != null) {
        final durationSeconds =
            equipmentTarget.processingDefinition.action ==
                ProcessingAction.cookPatty
            ? _flow.progression.upgrades.effectivePanDuration()
            : equipmentTarget.processingDefinition.baseDurationSeconds;
        final started =
            equipmentTarget.isAvailable &&
            _processingState.tryStartProcessing(
              tableState: _tableState,
              equipmentCardId: equipmentTarget.equipmentCardId,
              inputCardId: cardId,
              attachedInputPosition: _processingAttachmentPosition(
                equipmentTarget.equipmentCardId,
              ),
              definition: equipmentTarget.processingDefinition,
              durationSeconds: durationSeconds,
            );
        if (!started) _restoreActiveDragSnapshot(cardId);
        if (started) {
          _cardComponents[cardId]?.triggerValidDrop();
          audio.play(SoundEventId.equipmentStart);
          _tutorialState.processingStarted(
            inputCardId: cardId,
            equipmentCardId: equipmentTarget.equipmentCardId,
          );
        }
      } else {
        final target = _resolveStackTarget(cardId, cardPosition);
        final wasStacked =
            target != null &&
            _tableState.tryStackCardOnTarget(cardId, target.cardId);
        if (wasStacked) {
          _cardComponents[cardId]?.triggerStackLanding();
          audio.play(SoundEventId.stackCreate);
          haptics.trigger(HapticEvent.cardSnap);
          recipeResolution = _tryResolveRecipeAfterStackMutation(cardId);
        }
        if (!wasStacked) {
          final snappedPosition = _kitchenGrid.snapCandidate(
            Offset(cardPosition.x, cardPosition.y),
          );
          if (snappedPosition != null) {
            _tableState.commitKitchenTablePlacement(cardId, snappedPosition);
            _cardComponents[cardId]?.triggerValidDrop();
            haptics.trigger(HapticEvent.cardSnap);
          } else {
            _restoreActiveDragSnapshot(cardId);
          }
        }
      }
    }

    _syncCardComponentsFromState(
      resultPopCardId: recipeResolution?.resultCardId,
    );
    if (recipeResolution != null) {
      if (_recipeDiscoveryState.discover(recipeResolution.recipeId)) {
        _persist();
      }
      _tutorialState.recipeResolved(recipeId: recipeResolution.recipeId);
      _recipeFeedback.trigger(
        anchor: recipeResolution.basePosition,
        text: _tableState
            .definitionFor(recipeResolution.resultCardId)
            .displayName
            .toUpperCase(),
      );
      audio.play(SoundEventId.recipeComplete);
      haptics.trigger(HapticEvent.recipeComplete);
    }
    audio.play(SoundEventId.cardDrop);
    _hideInteractionPreviews();
    return _toVector2(_tableState.placementFor(cardId).currentValidPosition);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flow.screen != AppScreen.gameplay ||
        _shiftState.phase != ShiftPhase.active) {
      return;
    }
    _advanceActiveGameplay(_lastSecondFeedbackState.scaleDelta(dt));
  }

  void _advanceActiveGameplay(double dt) {
    _tutorialState.advance(dt);
    if (_shiftState.advanceActiveTime(dt)) {
      _endShift();
      return;
    }
    for (final completedJob in _processingState.advanceForShift(
      deltaSeconds: dt,
      shiftPhase: _shiftState.phase,
    )) {
      _completeProcessing(completedJob);
    }
    for (final expiredSlot in _orderSystem.advancePatience(dt)) {
      _handleCustomerFailure(expiredSlot);
    }
    for (final refillSlot in _orderSystem.advanceFeedback(dt)) {
      final receivesBonus = _hasPendingPatienceBonus;
      final patience = _flow.progression.upgrades.nextOrderPatienceDuration(
        hasPendingBonus: receivesBonus,
        baseDurationSeconds: refillSlot.definition.basePatienceSeconds,
      );
      _orderSystem.refillCustomer(
        refillSlot.definition.id,
        totalPatienceSeconds: patience,
      );
      if (receivesBonus) _hasPendingPatienceBonus = false;
    }
    _syncCardComponentsFromState();
  }

  void _completeProcessing(ProcessingJob completedJob) {
    final definition = prototypeProcessingDefinitions.firstWhere(
      (candidate) => candidate.action == completedJob.action,
    );
    final equipmentPosition = _tableState
        .placementFor(completedJob.equipmentCardId)
        .currentValidPosition;
    _tableState.completeProcessedCard(
      cardId: completedJob.inputCardId,
      completedDefinition: definition.outputDefinition,
      outputPosition: _processingOutputResolver.resolve(equipmentPosition),
    );
    if (definition.outputDefinition.type == CardType.crispyFries) {
      _tableState.recordResultLineage(
        resultCardId: completedJob.inputCardId,
        sourceCardIds: [completedJob.inputCardId],
      );
      if (_recipeDiscoveryState.discover('crispy_fries')) _persist();
    }
    _cardComponents[completedJob.inputCardId]?.triggerResultPop();
    audio.play(SoundEventId.equipmentComplete);
    haptics.trigger(HapticEvent.processingComplete);
  }

  void _handleCustomerFailure(CustomerSlotState slot) {
    if (!_orderSystem.failCustomer(slot.definition.id) ||
        !_shiftState.recordMissedOrder(enterFeedback: false)) {
      return;
    }
    _failureFeedback.trigger();
    _comboMilestones.record(0);
    _hud.triggerComboPulse();
    audio.play(SoundEventId.orderFailed);
  }

  void _togglePause() {
    if (_shiftState.pause()) {
      _cancelActiveDrag();
      _syncCardComponentsFromState();
    }
  }

  void _resumeShift() {
    if (_shiftState.resume()) _syncCardComponentsFromState();
  }

  void _endShift() {
    _cancelActiveDrag();
    _processingState.clearActiveJob();
    _resetPreparationState();
    _orderSystem.closeActiveOrder();
    _tutorialState.finishFirstShiftSafely();
    _orderSystem.clearTutorialPatienceProtection();
    _hasPendingPatienceBonus = false;
    _shiftState.endShift();
    _flow.showResults();
    _persist();
    audio.play(SoundEventId.shiftComplete);
    _hideInteractionPreviews();
    _syncCardComponentsFromState();
  }

  void _startShiftFromMenu() {
    if (_flow.startShift()) {
      final startsTutorial = _tutorialState.startFirstShift();
      _prepareFreshShift(tutorialFirstOrder: startsTutorial);
    }
  }

  void _showUpgradeSelection() {
    _flow.showUpgradeSelection();
  }

  void _continueAfterResults() {
    if (selectedShiftMoment != null) {
      _flow.showShiftMoment();
    } else {
      _flow.showUpgradeSelection();
    }
  }

  void _confirmUpgradeSelection() {
    if (_flow.confirmUpgrade() != null) {
      _persist();
      _prepareFreshShift();
    }
  }

  void _prepareFreshShift({bool tutorialFirstOrder = false}) {
    _cancelActiveDrag();
    _resetPreparationState();
    _orderSystem.startShift(tutorialFirstOrder: tutorialFirstOrder);
    _hasPendingPatienceBonus = false;
    _shiftState.walletCoins = _flow.progression.walletCoins;
    _shiftState.startNewShift();
    _shiftMomentTracker.startShift(day: _flow.progression.currentDay);
    _hideInteractionPreviews();
    _syncCardComponentsFromState();
  }

  void _resetPreparationState() {
    _processingState.clearActiveJob();
    _tableState.resetPrototypePreparationState(
      ingredientDefinitions: prototypeCycleIngredientDefinitions,
      handPositions: GameLayout.initialHandCardPositions,
      equipmentDefinitions: prototypeEquipmentDefinitions,
      equipmentTablePositions: GameLayout.initialEquipmentTablePositions,
      resultCardIds: const [
        'classic_burger_01',
        'deluxe_burger_01',
        'spicy_burger_01',
      ],
    );
  }

  void _restoreActiveDragSnapshot(String cardId) {
    final snapshot = _activeDragSnapshot;
    if (snapshot == null || snapshot.cardId != cardId) {
      throw StateError('Missing drag snapshot for $cardId.');
    }
    _tableState.restoreCardDragSnapshot(snapshot);
    _cardComponents[cardId]?.triggerInvalidDrop();
    audio.play(SoundEventId.invalidDrop);
  }

  void _cancelActiveDrag() {
    final cardId = _activeCardId;
    final snapshot = _activeDragSnapshot;
    if (cardId != null && snapshot != null && snapshot.cardId == cardId) {
      _tableState.restoreCardDragSnapshot(snapshot);
      _cardComponents[cardId]?.cancelActiveDrag();
    }
    _activeCardId = null;
    _activeDragSnapshot = null;
    _hideInteractionPreviews();
  }

  void _hideInteractionPreviews() {
    _snapPreview.hide();
    _stackPreview.hide();
    _recipePreview.hide();
    _servicePreview.hide();
    _processingPreview.hide();
  }

  void _openRecipeBook() {
    if (_flow.showRecipeBook()) {
      _cancelActiveDrag();
      _syncCardComponentsFromState();
    }
  }

  void _closeRecipeBook() {
    if (_flow.closeRecipeBook()) _syncCardComponentsFromState();
  }

  void _openSettings() {
    if (_flow.showSettings()) audio.play(SoundEventId.buttonTap);
  }

  void _closeSettings() {
    if (_flow.closeSettings()) audio.play(SoundEventId.buttonTap);
  }

  void _settingsChanged() {
    audio.play(SoundEventId.buttonTap);
    _persist();
  }

  void _replayTutorial() {
    _tutorialState.resetForReplay();
    audio.play(SoundEventId.buttonTap);
    _persist();
  }

  void _resetSave() {
    unawaited(_saveService?.reset());
    _flow.progression.reset();
    _recipeDiscoveryState.reset();
    _tutorialState.resetForReplay();
    settings.reset();
    _flow.resetToMainMenu();
    _resetPreparationState();
    _shiftState.walletCoins = _flow.progression.walletCoins;
    _hideInteractionPreviews();
    _syncCardComponentsFromState();
  }

  void _skipTutorial() {
    if (_tutorialState.skip()) {
      _orderSystem.clearTutorialPatienceProtection();
      _syncCardComponentsFromState();
      _persist();
    }
  }

  SaveData _currentSaveData() => SaveData(
    day: _flow.progression.currentDay,
    wallet: _flow.progression.walletCoins,
    upgradeLevels: {
      for (final entry in _flow.progression.upgrades.levels.entries)
        entry.key.name: entry.value,
    },
    discoveredRecipeIds: _recipeDiscoveryState.discoveredRecipeIds,
    tutorialStatus: _tutorialState.status,
    settings: settings,
  );

  void _persist() {
    final service = _saveService;
    if (service != null) unawaited(service.save(_currentSaveData()));
  }

  List<Rect> _tutorialSourceBounds() {
    if (!_tutorialState.isActive) return const [];
    final ids = switch (_tutorialState.currentStep) {
      TutorialStep.cookPatty => const ['patty_01'],
      TutorialStep.buildClassicBurger => const [
        'bread_01',
        'patty_01',
        'cheese_01',
      ],
      TutorialStep.serveClassicBurger => const ['classic_burger_01'],
    };
    return ids
        .where((id) => _tableState.tableCardIdsInRenderOrder.contains(id))
        .map(
          (id) =>
              _cardBoundsAt(_tableState.placementFor(id).currentValidPosition),
        )
        .toList(growable: false);
  }

  Rect? _tutorialTargetBounds() {
    if (!_tutorialState.isActive) return null;
    return switch (_tutorialState.currentStep) {
      TutorialStep.cookPatty => _cardBoundsAt(
        _tableState.placementFor('pan_01').currentValidPosition,
      ),
      TutorialStep.buildClassicBurger => GameLayout.kitchenTableBounds,
      TutorialStep.serveClassicBurger => GameLayout.serviceCounterBounds,
    };
  }

  EquipmentTarget? _resolveEquipmentTarget(
    String cardId,
    Vector2 cardPosition,
  ) => _equipmentTargetResolver.resolveTarget(
    draggedCardId: cardId,
    draggedCardPosition: Offset(cardPosition.x, cardPosition.y),
    tableState: _tableState,
    processingState: _processingState,
  );

  Offset _processingAttachmentPosition(String equipmentCardId) {
    final equipmentPosition = _tableState
        .placementFor(equipmentCardId)
        .currentValidPosition;
    return equipmentPosition + GameLayout.processingPattyOffset;
  }

  Rect _cardBoundsAt(Offset position) => Rect.fromLTWH(
    position.dx,
    position.dy,
    GameLayout.cardWidth,
    GameLayout.cardHeight,
  );

  void _handleDragFinished(String cardId) {
    if (_activeCardId == cardId) {
      _activeCardId = null;
      _activeDragSnapshot = null;
      _hideInteractionPreviews();
    }
  }

  StackTarget? _resolveStackTarget(String cardId, Vector2 cardPosition) =>
      _stackTargetResolver.resolve(
        draggedCardId: cardId,
        draggedCardPosition: Offset(cardPosition.x, cardPosition.y),
        tableState: _tableState,
      );

  ServiceTarget? _resolveServiceTarget(String cardId, Vector2 cardPosition) =>
      _serviceTargetResolver.resolve(
        draggedCardId: cardId,
        draggedCardPosition: Offset(cardPosition.x, cardPosition.y),
        tableState: _tableState,
        orderSystem: _orderSystem,
      );

  bool _isWrongServiceDrop(String cardId, Vector2 cardPosition) {
    if (_tableState.definitionFor(cardId).category != CardCategory.result) {
      return false;
    }
    final center = Offset(
      cardPosition.x + (GameLayout.cardWidth / 2),
      cardPosition.y + (GameLayout.cardHeight / 2),
    );
    return GameLayout.serviceCounterBounds.inflate(16).contains(center);
  }

  RecipeResolution? _tryResolveRecipeAfterStackMutation(String cardId) {
    final stack = _tableState.stackForCard(cardId);
    if (stack == null) return null;
    final recipe = _recipeResolver.resolve(
      stack.cardIds.map((memberId) => _tableState.definitionFor(memberId).type),
    );
    return recipe == null
        ? null
        : _tableState.tryResolveRecipeStack(stackId: stack.id, recipe: recipe);
  }

  RecipeDefinition? _recipeForTarget(
    String draggedCardId,
    String targetCardId,
  ) {
    final targetStack = _tableState.stackForCard(targetCardId);
    final memberIds = targetStack?.cardIds ?? [targetCardId];
    return _recipeResolver.resolve([
      ...memberIds.map((memberId) => _tableState.definitionFor(memberId).type),
      _tableState.definitionFor(draggedCardId).type,
    ]);
  }

  void _syncCardComponentsFromState({String? resultPopCardId}) {
    final activeCardIds = _tableState.tableCardIdsInRenderOrder;
    final activeCardIdSet = activeCardIds.toSet();
    final removedCardIds = _cardComponents.keys
        .where((cardId) => !activeCardIdSet.contains(cardId))
        .toList();
    for (final cardId in removedCardIds) {
      _cardComponents.remove(cardId)?.removeFromParent();
    }
    for (final entry in activeCardIds.indexed) {
      final cardId = entry.$2;
      final cardComponent = _cardComponents.putIfAbsent(cardId, () {
        final component = GameCardComponent(
          initialPosition: _toVector2(
            _tableState.placementFor(cardId).currentValidPosition,
          ),
          definition: _tableState.definitionFor(cardId),
          restingPriority: 20 + entry.$1,
          onDragStarted: _handleDragStarted,
          onDragPositionChanged: _updateDragFeedback,
          onDragReleased: _handleDragReleased,
          onDragFinished: _handleDragFinished,
        );
        world.add(component);
        return component;
      });
      cardComponent.applyRestingState(
        cardPosition: _toVector2(
          _tableState.placementFor(cardId).currentValidPosition,
        ),
        priority: 20 + entry.$1,
        definition: _tableState.definitionFor(cardId),
        isLocked: _processingState.isCardLocked(cardId),
        isInteractionLocked:
            !isGameplayInputAllowed ||
            !_tutorialState.allowsCard(_tableState.definitionFor(cardId)),
        isProcessing: _processingState.isProcessingInput(cardId),
      );
      if (cardId == resultPopCardId) cardComponent.triggerResultPop();
    }
  }

  Vector2 _toVector2(Offset position) => Vector2(position.dx, position.dy);
}
