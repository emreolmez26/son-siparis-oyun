import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/customer_area_component.dart';
import 'components/game_card_component.dart';
import 'components/hud_component.dart';
import 'components/kitchen_table_component.dart';
import 'components/player_hand_component.dart';
import 'components/processing_indicator_component.dart';
import 'components/processing_preview_component.dart';
import 'components/recipe_button_component.dart';
import 'components/recipe_feedback_component.dart';
import 'components/recipe_preview_component.dart';
import 'components/service_counter_component.dart';
import 'components/snap_preview_component.dart';
import 'components/stack_preview_component.dart';
import 'data/prototype_card_definitions.dart';
import 'data/prototype_recipe_definitions.dart';
import 'game_layout.dart';
import 'kitchen_grid.dart';
import 'models/card_drag_snapshot.dart';
import 'models/processing_job.dart';
import 'models/recipe_definition.dart';
import 'models/recipe_resolution.dart';
import 'state/equipment_processing_state.dart';
import 'state/kitchen_table_state.dart';
import 'systems/equipment_target_resolver.dart';
import 'systems/processing_output_resolver.dart';
import 'systems/recipe_resolver.dart';
import 'systems/stack_layout.dart';
import 'systems/stack_target_resolver.dart';

class SonSiparisGame extends FlameGame {
  SonSiparisGame()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: GameLayout.designWidth,
          height: GameLayout.designHeight,
        ),
      );

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
  late final EquipmentProcessingState _processingState =
      EquipmentProcessingState(
        processingDurationSeconds: GameLayout.processingDurationSeconds,
      );
  late final SnapPreviewComponent _snapPreview = SnapPreviewComponent();
  late final StackPreviewComponent _stackPreview = StackPreviewComponent();
  late final RecipePreviewComponent _recipePreview = RecipePreviewComponent();
  late final RecipeFeedbackComponent _recipeFeedback =
      RecipeFeedbackComponent();
  late final ProcessingPreviewComponent _processingPreview =
      ProcessingPreviewComponent();
  late final KitchenTableState _tableState = KitchenTableState(
    definitions: prototypeCardDefinitions,
    initialHandPositions: GameLayout.initialHandCardPositions,
    stackLayout: _stackLayout,
  );
  final Map<String, GameCardComponent> _cardComponents = {};
  String? _activeCardId;
  CardDragSnapshot? _activeDragSnapshot;

  @override
  Color backgroundColor() => GameLayout.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();

    final screenComponents = [
      HudComponent(),
      CustomerAreaComponent(),
      RecipeButtonComponent(),
      KitchenTableComponent(),
      ServiceCounterComponent(),
      PlayerHandComponent(),
      _snapPreview,
      _stackPreview,
      _recipePreview,
      _processingPreview,
      _recipeFeedback,
      ProcessingIndicatorComponent(
        jobProvider: () => _processingState.activeJob,
        positionForCard: (cardId) =>
            _tableState.placementFor(cardId).currentValidPosition,
      ),
    ];
    world.addAll(screenComponents);
    _syncCardComponentsFromState();
  }

  void _handleDragStarted(String cardId) {
    if (_processingState.isCardLocked(cardId) ||
        _tableState.isConsumed(cardId)) {
      return;
    }
    _activeCardId = cardId;
    _activeDragSnapshot = _tableState.beginCardDrag(cardId);
    _syncCardComponentsFromState();
    _snapPreview.hide();
    _stackPreview.hide();
    _recipePreview.hide();
    _processingPreview.hide();
  }

  void _updateDragFeedback(String cardId, Vector2 cardPosition) {
    if (_activeCardId != cardId) {
      return;
    }

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
    } else {
      _stackPreview.hide();
      _recipePreview.hide();
      final candidatePosition = _kitchenGrid.snapCandidate(
        Offset(cardPosition.x, cardPosition.y),
      );
      if (candidatePosition == null) {
        _snapPreview.hide();
      } else {
        _snapPreview.showAt(
          Vector2(candidatePosition.dx, candidatePosition.dy),
        );
      }
    }
  }

  Vector2 _handleDragReleased(String cardId, Vector2 cardPosition) {
    RecipeResolution? recipeResolution;
    final equipmentTarget = _resolveEquipmentTarget(cardId, cardPosition);
    if (equipmentTarget != null) {
      final started =
          equipmentTarget.isAvailable &&
          _processingState.tryStartPattyCooking(
            tableState: _tableState,
            equipmentCardId: equipmentTarget.equipmentCardId,
            inputCardId: cardId,
            attachedInputPosition: _processingAttachmentPosition(
              equipmentTarget.equipmentCardId,
            ),
          );
      if (!started) {
        _restoreActiveDragSnapshot(cardId);
      }
    } else {
      final target = _resolveStackTarget(cardId, cardPosition);
      final wasStacked =
          target != null &&
          _tableState.tryStackCardOnTarget(cardId, target.cardId);
      if (wasStacked) {
        recipeResolution = _tryResolveRecipeAfterStackMutation(cardId);
      }
      if (!wasStacked) {
        final snappedPosition = _kitchenGrid.snapCandidate(
          Offset(cardPosition.x, cardPosition.y),
        );
        if (snappedPosition != null) {
          _tableState.commitKitchenTablePlacement(cardId, snappedPosition);
        } else {
          _restoreActiveDragSnapshot(cardId);
        }
      }
    }

    _syncCardComponentsFromState(
      resultPopCardId: recipeResolution?.resultCardId,
    );
    if (recipeResolution != null) {
      _recipeFeedback.trigger(
        anchor: recipeResolution.basePosition,
        text: 'KLASİK BURGER!',
      );
    }
    _snapPreview.hide();
    _stackPreview.hide();
    _recipePreview.hide();
    _processingPreview.hide();
    return _toVector2(_tableState.placementFor(cardId).currentValidPosition);
  }

  void _restoreActiveDragSnapshot(String cardId) {
    final snapshot = _activeDragSnapshot;
    if (snapshot == null || snapshot.cardId != cardId) {
      throw StateError('Missing drag snapshot for $cardId.');
    }
    _tableState.restoreCardDragSnapshot(snapshot);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final completedJob = _processingState.advance(dt);
    if (completedJob != null) {
      _completeProcessing(completedJob);
    }
  }

  void _completeProcessing(ProcessingJob completedJob) {
    final panPosition = _tableState
        .placementFor(completedJob.equipmentCardId)
        .currentValidPosition;
    final outputPosition = _processingOutputResolver.resolve(panPosition);
    _tableState.completeProcessedCard(
      cardId: completedJob.inputCardId,
      completedDefinition: cookedPattyCardDefinition,
      outputPosition: outputPosition,
    );
    _syncCardComponentsFromState();
  }

  EquipmentTarget? _resolveEquipmentTarget(
    String cardId,
    Vector2 cardPosition,
  ) {
    return _equipmentTargetResolver.resolvePattyTarget(
      draggedCardId: cardId,
      draggedCardPosition: Offset(cardPosition.x, cardPosition.y),
      tableState: _tableState,
      processingState: _processingState,
    );
  }

  Offset _processingAttachmentPosition(String equipmentCardId) {
    final panPosition = _tableState
        .placementFor(equipmentCardId)
        .currentValidPosition;
    return panPosition + GameLayout.processingPattyOffset;
  }

  Rect _cardBoundsAt(Offset position) {
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      GameLayout.cardWidth,
      GameLayout.cardHeight,
    );
  }

  void _handleDragFinished(String cardId) {
    if (_activeCardId == cardId) {
      _activeCardId = null;
      _activeDragSnapshot = null;
      _snapPreview.hide();
      _stackPreview.hide();
      _recipePreview.hide();
      _processingPreview.hide();
    }
  }

  StackTarget? _resolveStackTarget(String cardId, Vector2 cardPosition) {
    return _stackTargetResolver.resolve(
      draggedCardId: cardId,
      draggedCardPosition: Offset(cardPosition.x, cardPosition.y),
      tableState: _tableState,
    );
  }

  RecipeResolution? _tryResolveRecipeAfterStackMutation(String cardId) {
    final stack = _tableState.stackForCard(cardId);
    if (stack == null) {
      return null;
    }
    final recipe = _recipeResolver.resolve(
      stack.cardIds.map((memberId) => _tableState.definitionFor(memberId).type),
    );
    if (recipe == null) {
      return null;
    }
    return _tableState.tryResolveRecipeStack(stackId: stack.id, recipe: recipe);
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
        isProcessing: _processingState.isProcessingInput(cardId),
      );
      if (cardId == resultPopCardId) {
        cardComponent.triggerResultPop();
      }
    }
  }

  Vector2 _toVector2(Offset position) => Vector2(position.dx, position.dy);
}
