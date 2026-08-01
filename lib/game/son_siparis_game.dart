import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/customer_area_component.dart';
import 'components/combo_feedback_component.dart';
import 'components/countermeasure_card_component.dart';
import 'components/game_card_component.dart';
import 'components/hud_component.dart';
import 'components/kitchen_table_component.dart';
import 'components/last_second_feedback_component.dart';
import 'components/kitchen_loadout_component.dart';
import 'components/main_menu_component.dart';
import 'components/market_component.dart';
import 'components/order_failure_feedback_component.dart';
import 'components/pantry_supply_component.dart';
import 'components/pause_overlay_component.dart';
import 'components/player_hand_component.dart';
import 'components/processing_indicator_component.dart';
import 'components/processing_preview_component.dart';
import 'components/recipe_button_component.dart';
import 'components/recipe_book_component.dart';
import 'components/recipe_feedback_component.dart';
import 'components/recipe_preview_component.dart';
import 'components/rival_sabotage_component.dart';
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
import 'components/daily_challenge_results_component.dart';
import 'data/content_unlock_definitions.dart';
import 'data/market_catalog.dart';
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
import 'models/card_zone.dart';
import 'models/content_ownership.dart';
import 'models/game_mode.dart';
import 'models/game_settings.dart';
import 'models/customer_slot_state.dart';
import 'models/processing_job.dart';
import 'models/recipe_definition.dart';
import 'models/recipe_resolution.dart';
import 'models/sabotage.dart';
import 'models/save_data.dart';
import 'models/shift_phase.dart';
import 'models/shift_moment.dart';
import 'models/tutorial_status.dart';
import 'models/upgrade_id.dart';
import 'models/kitchen_loadout.dart';
import 'state/equipment_processing_state.dart';
import 'state/feedback_state.dart';
import 'state/daily_challenge_state.dart';
import 'state/game_flow_controller.dart';
import 'state/kitchen_table_state.dart';
import 'state/order_system.dart';
import 'state/loadout_state.dart';
import 'state/market_state.dart';
import 'state/pantry_supply_state.dart';
import 'state/run_progression_state.dart';
import 'state/shift_state.dart';
import 'state/recipe_discovery_state.dart';
import 'state/rival_state.dart';
import 'state/shift_moment_tracker.dart';
import 'state/tutorial_state.dart';
import 'state/upgrade_state.dart';
import 'services/audio_service.dart';
import 'services/haptic_service.dart';
import 'services/save_service.dart';
import 'systems/equipment_target_resolver.dart';
import 'systems/daily_seed_factory.dart';
import 'systems/loadout_recipe_resolver.dart';
import 'systems/order_result_generator.dart';
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
    int? sabotageTestSeed,
    DateProvider dateProvider = const LocalDateProvider(),
  }) : _initialSaveData = initialSaveData ?? SaveData(),
       _saveService = saveService,
       _sabotageTestSeed = sabotageTestSeed,
       _dateProvider = dateProvider,
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
  final int? _sabotageTestSeed;
  final DateProvider _dateProvider;
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
  late final ContentOwnership _ownership = ContentOwnership(
    ownedPackIds: _initialSaveData.ownedMarketPackIds,
    unlockedIngredientIds: _initialSaveData.unlockedIngredientIds,
    unlockedEquipmentIds: _initialSaveData.unlockedEquipmentIds,
    unlockedRecipeIds: _initialSaveData.unlockedRecipeIds,
  );
  late final LoadoutState _loadoutState = LoadoutState(
    ownership: _ownership,
    initialLoadout: KitchenLoadout(
      ingredientIds: _initialSaveData.selectedIngredientIds,
      equipmentIds: _initialSaveData.selectedEquipmentIds,
    ),
  );
  late final MarketState _marketState = MarketState(
    catalog: marketCatalog,
    progression: _flow.progression,
    ownership: _ownership,
    loadout: _loadoutState,
    discovery: _recipeDiscoveryState,
  );
  late final DailyChallengeState _dailyChallengeState = DailyChallengeState(
    dateProvider: _dateProvider,
    initialRecords: _initialSaveData.dailyChallengeRecords,
  );
  late final ShiftMomentTracker _shiftMomentTracker = ShiftMomentTracker();
  late final RivalState _rivalState = RivalState();
  late final OrderSystem _orderSystem = OrderSystem(
    customerDefinitions: prototypeCustomerDefinitions,
  );
  late final EquipmentProcessingState _processingState =
      EquipmentProcessingState(
        processingDurationSeconds: GameLayout.processingDurationSeconds,
      );
  late final PantrySupplyState _pantryState = PantrySupplyState(
    definitions: prototypeCycleIngredientDefinitions,
    positions: GameLayout.initialHandCardPositions,
  );
  late final KitchenTableState _tableState = KitchenTableState(
    definitions: prototypeEquipmentDefinitions,
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
    modeProvider: () => _gameMode,
    dailyDateProvider: () => _dailyChallengeState.activeDateKey ?? '',
    dailyScoreProvider: () => _dailyChallengeState.score.displayedScore,
    onPausePressed: _togglePause,
  );
  late final ComboFeedbackComponent _comboFeedback = ComboFeedbackComponent();
  late final ComboMilestoneTracker _comboMilestones = ComboMilestoneTracker();
  late final LastSecondFeedbackState _lastSecondFeedbackState =
      LastSecondFeedbackState();

  final Map<String, GameCardComponent> _cardComponents = {};
  final Map<String, PantrySupplyComponent> _pantryComponents = {};
  String? _activeCardId;
  CardDragSnapshot? _activeDragSnapshot;
  bool _activeCardSpawnedFromPantry = false;
  String? _activeSupplyId;
  bool _hasPendingPatienceBonus = false;
  GameMode _gameMode = GameMode.career;
  String? _loadoutFeedback;
  int _wrongServiceSequence = 1;

  ShiftState get shiftState => _shiftState;
  GameFlowController get flow => _flow;
  OrderSystem get orderSystem => _orderSystem;
  EquipmentProcessingState get processingState => _processingState;
  KitchenTableState get tableState => _tableState;
  PantrySupplyState get pantryState => _pantryState;
  TutorialState get tutorialState => _tutorialState;
  RecipeDiscoveryState get recipeDiscoveryState => _recipeDiscoveryState;
  ShiftMomentTracker get shiftMomentTracker => _shiftMomentTracker;
  RivalState get rivalState => _rivalState;
  ContentOwnership get ownership => _ownership;
  LoadoutState get loadoutState => _loadoutState;
  MarketState get marketState => _marketState;
  DailyChallengeState get dailyChallengeState => _dailyChallengeState;
  GameMode get gameMode => _gameMode;
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
      RivalSabotageComponent(
        rivalState: _rivalState,
        positionForCard: (cardId) =>
            _tableState.placementFor(cardId).currentValidPosition,
      ),
      CountermeasureCardComponent(
        rivalState: _rivalState,
        canInteract: () => isGameplayInputAllowed,
        onReleased: _handleCountermeasureReleased,
      ),
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
        onOpenMarket: _openMarket,
        onOpenLoadout: _openLoadout,
        onStartDailyChallenge: _startDailyChallengeFromMenu,
        ownedPackCount: () => _ownership.ownedPackIds.length,
        todayBestLabel: () {
          final key = const DailySeedFactory().dateKey(_dateProvider.now());
          return _dailyChallengeState.bestFor(key)?.bestScore.toString() ??
              'İLK DENEME';
        },
      ),
      MarketComponent(
        isShowing: () => _flow.screen == AppScreen.market,
        catalog: marketCatalog,
        progression: _flow.progression,
        ownership: _ownership,
        marketState: _marketState,
        onPurchase: _purchaseMarketPack,
        onOpenLoadout: _openLoadout,
        onBack: _closeMarket,
      ),
      KitchenLoadoutComponent(
        isShowing: () => _flow.screen == AppScreen.kitchenLoadout,
        ownership: _ownership,
        loadoutState: _loadoutState,
        onToggleIngredient: _toggleLoadoutIngredient,
        onToggleEquipment: _toggleLoadoutEquipment,
        onSave: _saveLoadout,
        onBack: _closeLoadoutWithoutSaving,
        feedbackProvider: () => _loadoutFeedback,
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
        ownership: _ownership,
        loadoutState: _loadoutState,
        modeProvider: () => _gameMode,
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
      DailyChallengeResultsComponent(
        isShowing: () => _flow.screen == AppScreen.dailyChallengeResults,
        challenge: _dailyChallengeState,
        shiftState: _shiftState,
        onRetry: _retryDailyChallenge,
        onMainMenu: _dailyResultsToMainMenu,
      ),
      TutorialOverlayComponent(
        tutorialState: _tutorialState,
        sourceBoundsProvider: _tutorialSourceBounds,
        targetBoundsProvider: _tutorialTargetBounds,
        onSkip: _skipTutorial,
      ),
    ]);
    for (final slot in _pantryState.allSlots) {
      final component = PantrySupplyComponent(
        supplyId: slot.id,
        pantryState: _pantryState,
        isShowing: () =>
            _flow.screen == AppScreen.gameplay &&
            _pantryState.isActive(slot.id),
        canInteract: () =>
            isGameplayInputAllowed &&
            _tutorialState.allowsCard(slot.definition),
        onSpawnStarted: _handleSupplySpawnStarted,
        onSpawnPositionChanged: _handleSupplySpawnPositionChanged,
        onSpawnReleased: _handleSupplySpawnReleased,
        onSpawnFinished: _handleSupplySpawnFinished,
        onSpawnCancelled: _handleSupplySpawnCancelled,
      );
      _pantryComponents[slot.id] = component;
      world.add(component);
    }
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
    _activeCardSpawnedFromPantry = false;
    _activeSupplyId = null;
    _syncCardComponentsFromState();
    _hideInteractionPreviews();
    audio.play(SoundEventId.cardPickUp);
    return true;
  }

  String? _handleSupplySpawnStarted(String supplyId) {
    final slot = _pantryState.slotFor(supplyId);
    if (!isGameplayInputAllowed ||
        !_tutorialState.allowsCard(slot.definition)) {
      return null;
    }
    final workingDefinition = _pantryState.takeWorkingDefinition(supplyId);
    if (workingDefinition == null) return null;
    _tableState.spawnWorkingCard(
      definition: workingDefinition,
      dragPosition: slot.position,
    );
    _activeCardId = workingDefinition.id;
    _activeDragSnapshot = null;
    _activeCardSpawnedFromPantry = true;
    _activeSupplyId = supplyId;
    _hideInteractionPreviews();
    audio.play(SoundEventId.cardPickUp);
    return workingDefinition.id;
  }

  void _handleSupplySpawnPositionChanged(
    String workingCardId,
    Vector2 position,
  ) {
    if (_activeCardId != workingCardId ||
        !_tableState.containsCard(workingCardId)) {
      return;
    }
    _tableState.updateSpawnedDragPosition(
      workingCardId,
      Offset(position.x, position.y),
    );
    _updateDragFeedback(workingCardId, position);
  }

  void _handleSupplySpawnReleased(String workingCardId, Vector2 position) {
    if (_activeCardId != workingCardId) return;
    _handleDragReleased(workingCardId, position);
  }

  void _handleSupplySpawnFinished(String workingCardId) {
    if (_activeCardId != workingCardId) return;
    _activeCardId = null;
    _activeDragSnapshot = null;
    _activeCardSpawnedFromPantry = false;
    _activeSupplyId = null;
    _hideInteractionPreviews();
  }

  void _handleSupplySpawnCancelled(String workingCardId) {
    if (_activeCardId == workingCardId) _cancelActiveDrag();
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
      return _releasedCardPosition(cardId);
    }

    RecipeResolution? recipeResolution;
    final serviceTarget = _resolveServiceTarget(cardId, cardPosition);
    if (_isFakeOrderServiceDrop(cardId, cardPosition)) {
      _restoreActiveDragSnapshot(cardId);
      _shiftState.resetCombo();
      if (_rivalState.triggerFakeOrderPenalty()) {
        if (_gameMode == GameMode.dailyChallenge) {
          _dailyChallengeState.score.recordSabotageHit(
            'fake:${_rivalState.resolutions.last.event.id}',
          );
        }
        _comboMilestones.record(0);
        _hud.triggerComboPulse();
        audio.play(SoundEventId.sabotageHit);
        haptics.trigger(HapticEvent.sabotageHit);
      }
    } else if (serviceTarget != null) {
      final definition = _tableState.definitionFor(cardId);
      final rewardCoins = _gameMode == GameMode.dailyChallenge
          ? definition.baseRewardCoins
          : _flow.progression.upgrades.effectiveRewardFor(definition);
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
        if (_gameMode == GameMode.career) {
          _flow.progression.addWalletCoins(completion.rewardCoins);
          _persist();
        } else {
          _dailyChallengeState.score.recordService(
            transactionId: 'service:${completion.orderId}',
            serviceReward: definition.baseRewardCoins,
            comboAfterService: _shiftState.currentCombo,
            remainingPatienceSeconds: completion.remainingPatienceSeconds,
          );
        }
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
            _gameMode == GameMode.career &&
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
      if (_gameMode == GameMode.dailyChallenge) {
        _dailyChallengeState.score.recordWrongService(
          'wrong:${_wrongServiceSequence++}',
        );
      }
      _serviceCounter.triggerRejection();
      audio.play(SoundEventId.wrongService);
    } else {
      final equipmentTarget = _resolveEquipmentTarget(cardId, cardPosition);
      if (equipmentTarget != null) {
        final durationSeconds =
            _gameMode == GameMode.career &&
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
            final category = _tableState.definitionFor(cardId).category;
            final finalPosition = category == CardCategory.equipment
                ? snappedPosition
                : _rivalState.greasySlideDestination(
                    droppedPosition: snappedPosition,
                    cardSize: GameLayout.cardSize,
                    tableBounds: GameLayout.kitchenTableBounds,
                    gridSpacing: GameLayout.kitchenGridSpacing,
                  );
            if (finalPosition == null) {
              _restoreActiveDragSnapshot(cardId);
            } else {
              _tableState.commitKitchenTablePlacement(cardId, finalPosition);
              _cardComponents[cardId]?.triggerValidDrop();
              haptics.trigger(HapticEvent.cardSnap);
            }
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
      if (_gameMode == GameMode.career &&
          _recipeDiscoveryState.discover(recipeResolution.recipeId)) {
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
    return _releasedCardPosition(cardId);
  }

  Vector2 _releasedCardPosition(String cardId) {
    if (_tableState.containsCard(cardId)) {
      return _toVector2(_tableState.placementFor(cardId).currentValidPosition);
    }
    final supplyId = _activeSupplyId;
    if (supplyId != null) {
      return _toVector2(_pantryState.slotFor(supplyId).position);
    }
    return Vector2.zero();
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
    _pantryState.advance(dt);
    _tutorialState.advance(dt);
    if (_shiftState.advanceActiveTime(dt)) {
      _endShift();
      return;
    }
    final priorSabotage = _rivalState.current;
    _rivalState.advance(dt, canAdvance: !_tutorialState.isActive);
    final currentSabotage = _rivalState.current;
    if (priorSabotage?.event.id != currentSabotage?.event.id &&
        currentSabotage?.phase == SabotagePhase.warning) {
      audio.play(SoundEventId.sabotageWarning);
      haptics.trigger(HapticEvent.sabotageWarning);
    } else if (priorSabotage?.phase == SabotagePhase.warning &&
        currentSabotage?.phase == SabotagePhase.active) {
      audio.play(SoundEventId.sabotageActivated);
      if (_gameMode == GameMode.dailyChallenge &&
          currentSabotage!.event.type != SabotageType.fakeOrder) {
        _dailyChallengeState.score.recordSabotageHit(
          'hit:${currentSabotage.event.id}',
        );
      }
    }
    final pausedEquipmentIds = <String>{
      if (_rivalState.isPowerOutageActive) ...const [
        'pan_01',
        'knife_01',
        'fryer_01',
      ],
      if (_rivalState.jammedEquipmentId case final jammed?) jammed,
    };
    for (final completedJob in _processingState.advanceForShift(
      deltaSeconds: dt,
      shiftPhase: _shiftState.phase,
      pausedEquipmentIds: pausedEquipmentIds,
    )) {
      _completeProcessing(completedJob);
    }
    for (final expiredSlot in _orderSystem.advancePatience(dt)) {
      _handleCustomerFailure(expiredSlot);
    }
    for (final refillSlot in _orderSystem.advanceFeedback(dt)) {
      final receivesBonus = _hasPendingPatienceBonus;
      final patience = _gameMode == GameMode.dailyChallenge
          ? refillSlot.definition.basePatienceSeconds
          : _flow.progression.upgrades.nextOrderPatienceDuration(
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
    final outputPosition = _processingOutputResolver.resolve(equipmentPosition);
    String resultPopCardId = completedJob.inputCardId;
    if (definition.outputDefinition.type == CardType.crispyFries) {
      resultPopCardId = _tableState.completeProcessedResultCard(
        inputCardId: completedJob.inputCardId,
        resultDefinition: definition.outputDefinition,
        outputPosition: outputPosition,
      );
      if (_gameMode == GameMode.career &&
          _recipeDiscoveryState.discover('crispy_fries')) {
        _persist();
      }
    } else {
      _tableState.completeProcessedCard(
        cardId: completedJob.inputCardId,
        completedDefinition: definition.outputDefinition.copyWithId(
          completedJob.inputCardId,
        ),
        outputPosition: outputPosition,
      );
    }
    _syncCardComponentsFromState(resultPopCardId: resultPopCardId);
    audio.play(SoundEventId.equipmentComplete);
    haptics.trigger(HapticEvent.processingComplete);
  }

  void _handleCustomerFailure(CustomerSlotState slot) {
    final failedOrderId = slot.order?.id;
    if (!_orderSystem.failCustomer(slot.definition.id) ||
        !_shiftState.recordMissedOrder(enterFeedback: false)) {
      return;
    }
    _failureFeedback.trigger();
    if (_gameMode == GameMode.dailyChallenge && failedOrderId != null) {
      _dailyChallengeState.score.recordMissedCustomer('miss:$failedOrderId');
    }
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
    _rivalState.endShift();
    _resetPreparationState();
    _orderSystem.closeActiveOrder();
    if (_gameMode == GameMode.career) {
      _tutorialState.finishFirstShiftSafely();
    }
    _orderSystem.clearTutorialPatienceProtection();
    _hasPendingPatienceBonus = false;
    _shiftState.setSabotageSummary(
      defended: _rivalState.defendedCount,
      affected: _rivalState.affectedCount,
    );
    _shiftState.endShift();
    if (_gameMode == GameMode.dailyChallenge) {
      _flow.showDailyChallengeResults();
      unawaited(
        _dailyChallengeState.commitResult(
          completedOrders: _shiftState.completedOrders,
          highestCombo: _shiftState.highestCombo,
          missedOrders: _shiftState.missedOrders,
          sabotagesDefended: _shiftState.sabotagesDefended,
          sabotageHits: _shiftState.sabotagesAffected,
          recordedAt: _dailyChallengeState.now(),
          persistCurrentSnapshot: _persistChecked,
        ),
      );
    } else {
      _flow.showResults();
      _persist();
    }
    audio.play(SoundEventId.shiftComplete);
    _hideInteractionPreviews();
    _syncCardComponentsFromState();
  }

  void _startShiftFromMenu() {
    if (_flow.startShift()) {
      _gameMode = GameMode.career;
      final startsTutorial = _tutorialState.startFirstShift();
      _prepareFreshShift(
        tutorialFirstOrder: startsTutorial,
        loadout: startsTutorial ? KitchenLoadout.starter : _loadoutState.active,
      );
    }
  }

  void _startDailyChallengeFromMenu() {
    if (!_flow.startDailyChallenge()) return;
    _gameMode = GameMode.dailyChallenge;
    _dailyChallengeState.start();
    _prepareFreshShift(
      loadout: const KitchenLoadout(
        ingredientIds: allIngredientIds,
        equipmentIds: allEquipmentIds,
      ),
    );
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
      _prepareFreshShift(loadout: _loadoutState.active);
    }
  }

  void _prepareFreshShift({
    bool tutorialFirstOrder = false,
    KitchenLoadout? loadout,
  }) {
    _cancelActiveDrag();
    _configureRuntimeKitchen(loadout ?? _loadoutState.active);
    _resetPreparationState();
    final supportedTypes = _gameMode == GameMode.dailyChallenge
        ? recipeResultTypes.values.toSet()
        : const LoadoutRecipeResolver().supportedResultTypes(
            loadout: loadout ?? _loadoutState.active,
            unlockedRecipeIds: _ownership.unlockedRecipeIds,
          );
    final orderSeed = _gameMode == GameMode.dailyChallenge
        ? _dailyChallengeState.streamSeed('orders')
        : (_flow.progression.currentDay * 7919) + 731;
    _orderSystem.startShift(
      tutorialFirstOrder: tutorialFirstOrder,
      generator: OrderResultGenerator(
        source: SeededOrderResultSource(orderSeed),
        availableResults: supportedTypes,
      ),
    );
    _hasPendingPatienceBonus = false;
    _shiftState.walletCoins = _flow.progression.walletCoins;
    _shiftState.startNewShift();
    if (_gameMode == GameMode.dailyChallenge) {
      _rivalState.startDailyChallenge(
        seed: _dailyChallengeState.streamSeed('sabotages'),
      );
    } else {
      _rivalState.startShift(
        day: _flow.progression.currentDay,
        tutorialReplay: tutorialFirstOrder,
        testSeed: _sabotageTestSeed,
      );
    }
    _shiftMomentTracker.startShift(day: _flow.progression.currentDay);
    _hideInteractionPreviews();
    _syncCardComponentsFromState();
  }

  void _resetPreparationState() {
    _processingState.clearActiveJob();
    _rivalState.clearTemporaryState();
    _tableState.resetWorkingCardsForNewShift(
      equipmentDefinitions: prototypeEquipmentDefinitions.where(
        (definition) =>
            _activeRuntimeLoadout.equipmentIds.contains(definition.id),
      ),
      equipmentTablePositions: GameLayout.initialEquipmentTablePositions,
    );
    _pantryState.resetForShift();
  }

  KitchenLoadout _activeRuntimeLoadout = KitchenLoadout.starter;

  void _configureRuntimeKitchen(KitchenLoadout loadout) {
    _activeRuntimeLoadout = loadout.copy();
    _pantryState.configureActive(loadout.ingredientIds);
  }

  void _restoreActiveDragSnapshot(String cardId) {
    if (_activeCardSpawnedFromPantry) {
      if (_tableState.containsCard(cardId)) {
        _tableState.removeSpawnedWorkingCard(cardId);
      }
      audio.play(SoundEventId.invalidDrop);
      return;
    }
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
    if (cardId != null && _activeCardSpawnedFromPantry) {
      if (_tableState.containsCard(cardId) &&
          _tableState.placementFor(cardId).zone == CardZone.dragging) {
        _tableState.removeSpawnedWorkingCard(cardId);
      }
      final supplyId = _activeSupplyId;
      if (supplyId != null) _pantryComponents[supplyId]?.cancelActiveSpawn();
    } else if (cardId != null &&
        snapshot != null &&
        snapshot.cardId == cardId) {
      _tableState.restoreCardDragSnapshot(snapshot);
      _cardComponents[cardId]?.cancelActiveDrag();
    }
    _activeCardId = null;
    _activeDragSnapshot = null;
    _activeCardSpawnedFromPantry = false;
    _activeSupplyId = null;
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

  void _openMarket() {
    if (_flow.showMarket()) audio.play(SoundEventId.buttonTap);
  }

  void _closeMarket() {
    if (_flow.closeMarket()) audio.play(SoundEventId.buttonTap);
  }

  void _purchaseMarketPack(String packId) {
    unawaited(
      _marketState.purchase(
        packId: packId,
        isMarketScreen: _flow.screen == AppScreen.market,
        persistCurrentSnapshot: _persistChecked,
      ),
    );
  }

  void _openLoadout() {
    if (_flow.showKitchenLoadout()) {
      _loadoutState.openEditor();
      _loadoutFeedback = null;
      audio.play(SoundEventId.buttonTap);
    }
  }

  void _toggleLoadoutIngredient(String id) {
    if (!_loadoutState.toggleIngredient(id) && !_ownership.ownsIngredient(id)) {
      _loadoutFeedback = 'MARKETTEN AÇILIR';
    } else {
      _loadoutFeedback = null;
    }
  }

  void _toggleLoadoutEquipment(String id) {
    if (!_loadoutState.toggleEquipment(id) && !_ownership.ownsEquipment(id)) {
      _loadoutFeedback = 'MARKETTEN AÇILIR';
    } else {
      _loadoutFeedback = null;
    }
  }

  void _saveLoadout() {
    unawaited(() async {
      final result = await _loadoutState.save(_persistChecked);
      _loadoutFeedback = switch (result) {
        LoadoutSaveResult.saved => 'MUTFAK KAYDEDİLDİ',
        LoadoutSaveResult.invalid => 'EN AZ BİR TARİF HAZIRLANABİLMELİ',
        LoadoutSaveResult.persistenceFailed => 'KAYIT BAŞARISIZ',
        LoadoutSaveResult.noDraft => null,
      };
      if (result == LoadoutSaveResult.saved) _flow.closeKitchenLoadout();
    }());
  }

  void _closeLoadoutWithoutSaving() {
    _loadoutState.closeWithoutSaving();
    _loadoutFeedback = null;
    _flow.closeKitchenLoadout();
  }

  void _retryDailyChallenge() {
    if (!_flow.retryDailyChallenge()) return;
    _gameMode = GameMode.dailyChallenge;
    _dailyChallengeState.start();
    _prepareFreshShift(
      loadout: const KitchenLoadout(
        ingredientIds: allIngredientIds,
        equipmentIds: allEquipmentIds,
      ),
    );
  }

  void _dailyResultsToMainMenu() {
    if (!_flow.dailyResultsToMainMenu()) return;
    _gameMode = GameMode.career;
    _resetPreparationState();
    _syncCardComponentsFromState();
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
    _ownership.reset();
    _loadoutState.reset();
    _dailyChallengeState.resetHistory();
    _tutorialState.resetForReplay();
    settings.reset();
    _flow.resetToMainMenu();
    _gameMode = GameMode.career;
    _configureRuntimeKitchen(KitchenLoadout.starter);
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
    ownedMarketPackIds: _ownership.ownedPackIds,
    unlockedIngredientIds: _ownership.unlockedIngredientIds,
    unlockedEquipmentIds: _ownership.unlockedEquipmentIds,
    unlockedRecipeIds: _ownership.unlockedRecipeIds,
    selectedIngredientIds: _loadoutState.active.ingredientIds,
    selectedEquipmentIds: _loadoutState.active.equipmentIds,
    dailyChallengeRecords: _dailyChallengeState.records,
  );

  void _persist() {
    final service = _saveService;
    if (service != null) unawaited(service.save(_currentSaveData()));
  }

  Future<bool> _persistChecked() async {
    final service = _saveService;
    if (service == null) return true;
    return service.saveChecked(_currentSaveData());
  }

  List<Rect> _tutorialSourceBounds() {
    if (!_tutorialState.isActive) return const [];
    switch (_tutorialState.currentStep) {
      case TutorialStep.cookPatty:
        return [_pantryBounds('patty_01')];
      case TutorialStep.buildClassicBurger:
        return [
          _pantryBounds('bread_01'),
          _pantryBounds('cheese_01'),
          ..._tableState.tableCardIdsInRenderOrder
              .where(
                (id) =>
                    _tableState.definitionFor(id).type == CardType.cookedPatty,
              )
              .map(
                (id) => _cardBoundsAt(
                  _tableState.placementFor(id).currentValidPosition,
                ),
              ),
        ];
      case TutorialStep.serveClassicBurger:
        return _tableState.tableCardIdsInRenderOrder
            .where(
              (id) =>
                  _tableState.definitionFor(id).type == CardType.classicBurger,
            )
            .map(
              (id) => _cardBoundsAt(
                _tableState.placementFor(id).currentValidPosition,
              ),
            )
            .toList(growable: false);
    }
  }

  Rect _pantryBounds(String supplyId) =>
      _cardBoundsAt(_pantryState.slotFor(supplyId).position);

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
  ) {
    final target = _equipmentTargetResolver.resolveTarget(
      draggedCardId: cardId,
      draggedCardPosition: Offset(cardPosition.x, cardPosition.y),
      tableState: _tableState,
      processingState: _processingState,
    );
    if (target == null) return null;
    final disrupted =
        _rivalState.isPowerOutageActive ||
        _rivalState.jammedEquipmentId == target.equipmentCardId;
    return EquipmentTarget(
      equipmentCardId: target.equipmentCardId,
      bounds: target.bounds,
      isAvailable: target.isAvailable && !disrupted,
      processingDefinition: target.processingDefinition,
    );
  }

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
      _activeCardSpawnedFromPantry = false;
      _activeSupplyId = null;
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

  bool _isFakeOrderServiceDrop(String cardId, Vector2 cardPosition) {
    if (!_rivalState.fakeOrderActive ||
        _tableState.definitionFor(cardId).category != CardCategory.result ||
        _tableState.definitionFor(cardId).type != _rivalState.fakeOrderType) {
      return false;
    }
    final center = Offset(
      cardPosition.x + (GameLayout.cardWidth / 2),
      cardPosition.y + (GameLayout.cardHeight / 2),
    );
    return GameLayout.serviceCounterBounds.contains(center);
  }

  bool _handleCountermeasureReleased(String runtimeId, Vector2 center) {
    if (!isGameplayInputAllowed) return false;
    final active = _rivalState.current;
    if (active == null || active.countermeasureId != runtimeId) return false;
    final point = Offset(center.x, center.y);
    final targetBounds = switch (active.event.type) {
      SabotageType.powerSurge => RivalState.fuseBoxBounds,
      SabotageType.equipmentJam =>
        active.event.targetEquipmentId == null
            ? null
            : _cardBoundsAt(
                _tableState
                    .placementFor(active.event.targetEquipmentId!)
                    .currentValidPosition,
              ),
      SabotageType.greasyTable => active.event.greasyRegion,
      SabotageType.fakeOrder => RivalState.fakeTicketBounds,
    };
    if (targetBounds == null || !targetBounds.inflate(10).contains(point)) {
      audio.play(SoundEventId.invalidDrop);
      return false;
    }
    final eventId = active.event.id;
    if (!_rivalState.tryCounter(runtimeId)) return false;
    if (_gameMode == GameMode.dailyChallenge) {
      _dailyChallengeState.score.recordSabotageDefended('defend:$eventId');
    }
    audio.play(SoundEventId.sabotageCountered);
    haptics.trigger(HapticEvent.sabotageCountered);
    return true;
  }

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
        : _tableState.tryResolveRecipeStack(
            stackId: stack.id,
            recipe: recipe,
            runtimeResultId: _tableState.nextResultRuntimeId(
              recipe.resultDefinition.id,
            ),
          );
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
