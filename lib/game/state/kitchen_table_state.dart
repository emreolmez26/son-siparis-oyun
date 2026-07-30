import 'dart:ui';

import '../models/card_definition.dart';
import '../models/card_drag_snapshot.dart';
import '../models/card_placement.dart';
import '../models/card_stack.dart';
import '../models/card_zone.dart';
import '../models/recipe_definition.dart';
import '../models/recipe_resolution.dart';
import '../systems/stack_layout.dart';

class KitchenTableState {
  KitchenTableState({
    required List<CardDefinition> definitions,
    required Map<String, Offset> initialHandPositions,
    required StackLayout stackLayout,
  }) : _stackLayout = stackLayout {
    for (final definition in definitions) {
      if (_definitions.containsKey(definition.id)) {
        throw ArgumentError.value(
          definition.id,
          'definitions',
          'Duplicate card ID',
        );
      }
      final initialPosition = initialHandPositions[definition.id];
      if (initialPosition == null) {
        throw ArgumentError.value(
          definition.id,
          'initialHandPositions',
          'Missing hand position',
        );
      }
      _definitions[definition.id] = definition;
      _placements[definition.id] = CardPlacement(
        zone: CardZone.hand,
        currentValidPosition: initialPosition,
        lastValidPosition: initialPosition,
      );
    }
  }

  final StackLayout _stackLayout;
  final Map<String, CardDefinition> _definitions = {};
  final Map<String, CardPlacement> _placements = {};
  final Map<String, CardStack> _stacks = {};
  int _nextStackSequence = 1;

  int get cardCount => _definitions.length;
  int get stackCount => _stacks.length;

  Iterable<CardDefinition> get definitions => _definitions.values;
  Iterable<CardStack> get stacks => _stacks.values;

  List<String> get tableCardIdsInRenderOrder {
    final standaloneCardIds = <String>[];
    final processingCardIds = <String>[];
    final handCardIds = <String>[];
    for (final definition in definitions) {
      final placement = placementFor(definition.id);
      if (placement.zone == CardZone.kitchenTable) {
        standaloneCardIds.add(definition.id);
      } else if (placement.zone == CardZone.processing) {
        processingCardIds.add(definition.id);
      } else if (placement.zone == CardZone.hand) {
        handCardIds.add(definition.id);
      }
    }

    return [
      ...standaloneCardIds,
      for (final stack in _stacks.values) ...stack.cardIds,
      ...processingCardIds,
      ...handCardIds,
    ];
  }

  CardDefinition definitionFor(String cardId) {
    final definition = _definitions[cardId];
    if (definition == null) {
      throw ArgumentError.value(cardId, 'cardId', 'Unknown card');
    }
    return definition;
  }

  CardPlacement placementFor(String cardId) {
    final placement = _placements[cardId];
    if (placement == null) {
      throw ArgumentError.value(cardId, 'cardId', 'Unknown card');
    }
    return placement;
  }

  CardStack stackFor(String stackId) {
    final stack = _stacks[stackId];
    if (stack == null) {
      throw ArgumentError.value(stackId, 'stackId', 'Unknown stack');
    }
    return stack;
  }

  CardStack? stackForCard(String cardId) {
    final stackId = placementFor(cardId).stackId;
    return stackId == null ? null : _stacks[stackId];
  }

  List<String> orderedStackMembers(String stackId) {
    return List.unmodifiable(stackFor(stackId).cardIds);
  }

  bool isInHand(String cardId) => placementFor(cardId).zone == CardZone.hand;

  bool isOnKitchenTable(String cardId) {
    final zone = placementFor(cardId).zone;
    return zone == CardZone.kitchenTable || zone == CardZone.ingredientStack;
  }

  bool isStacked(String cardId) => placementFor(cardId).isStacked;

  bool isProcessing(String cardId) {
    return placementFor(cardId).zone == CardZone.processing;
  }

  bool isConsumed(String cardId) {
    return placementFor(cardId).zone == CardZone.consumed;
  }

  Offset lastValidPositionFor(String cardId) {
    return placementFor(cardId).lastValidPosition;
  }

  CardDragSnapshot beginCardDrag(String cardId) {
    _ensureKnownCard(cardId);
    if (isProcessing(cardId) || isConsumed(cardId)) {
      throw StateError('An inactive card cannot be dragged.');
    }
    final snapshot = CardDragSnapshot(
      cardId: cardId,
      placements: _placements,
      stacks: _stacks,
      nextStackSequence: _nextStackSequence,
    );
    if (isStacked(cardId)) {
      _detachCardFromStack(cardId);
    }
    return snapshot;
  }

  void restoreCardDragSnapshot(CardDragSnapshot snapshot) {
    _ensureKnownCard(snapshot.cardId);
    _placements
      ..clear()
      ..addAll(snapshot.placements);
    _stacks
      ..clear()
      ..addAll(snapshot.stacks);
    _nextStackSequence = snapshot.nextStackSequence;
  }

  void commitKitchenTablePlacement(String cardId, Offset snappedPosition) {
    _ensureKnownCard(cardId);
    if (isProcessing(cardId) || isConsumed(cardId)) {
      throw StateError('An inactive card cannot be placed on the table.');
    }
    if (isStacked(cardId)) {
      _detachCardFromStack(cardId);
    }
    _placements[cardId] = CardPlacement(
      zone: CardZone.kitchenTable,
      currentValidPosition: snappedPosition,
      lastValidPosition: snappedPosition,
    );
  }

  void markCardProcessing(String cardId, Offset attachedPosition) {
    _ensureKnownCard(cardId);
    if (isConsumed(cardId)) {
      throw StateError('A consumed card cannot start processing.');
    }
    if (isStacked(cardId)) {
      _detachCardFromStack(cardId);
    }
    _placements[cardId] = CardPlacement(
      zone: CardZone.processing,
      currentValidPosition: attachedPosition,
      lastValidPosition: attachedPosition,
    );
  }

  void completeProcessedCard({
    required String cardId,
    required CardDefinition completedDefinition,
    required Offset outputPosition,
  }) {
    _ensureKnownCard(cardId);
    if (!isProcessing(cardId)) {
      throw StateError('Only a processing card can complete.');
    }
    if (completedDefinition.id != cardId) {
      throw ArgumentError.value(
        completedDefinition.id,
        'completedDefinition.id',
        'The completed definition must retain the card ID.',
      );
    }
    _definitions[cardId] = completedDefinition;
    _placements[cardId] = CardPlacement(
      zone: CardZone.kitchenTable,
      currentValidPosition: outputPosition,
      lastValidPosition: outputPosition,
    );
  }

  bool tryStackCardOnTarget(String draggedCardId, String targetCardId) {
    _ensureKnownCard(draggedCardId);
    _ensureKnownCard(targetCardId);
    if (draggedCardId == targetCardId ||
        !_isIngredient(draggedCardId) ||
        !_isIngredient(targetCardId) ||
        isConsumed(draggedCardId) ||
        isConsumed(targetCardId) ||
        isProcessing(draggedCardId) ||
        !isOnKitchenTable(targetCardId)) {
      return false;
    }

    if (isStacked(draggedCardId)) {
      _detachCardFromStack(draggedCardId);
    }

    final targetStack = stackForCard(targetCardId);
    if (targetStack != null) {
      _applyStackLayout(
        targetStack.copyWith(cardIds: [...targetStack.cardIds, draggedCardId]),
      );
      return true;
    }

    final targetPosition = placementFor(targetCardId).currentValidPosition;
    _applyStackLayout(
      CardStack(
        id: _nextStackId(),
        cardIds: [targetCardId, draggedCardId],
        basePosition: targetPosition,
      ),
    );
    return true;
  }

  RecipeResolution? tryResolveRecipeStack({
    required String stackId,
    required RecipeDefinition recipe,
  }) {
    final stack = _stacks[stackId];
    if (stack == null ||
        _definitions.containsKey(recipe.resultInstanceId) ||
        recipe.resultDefinition.id != recipe.resultInstanceId ||
        recipe.resultDefinition.category != CardCategory.result ||
        !_stackLayout.isFullyInsidePaddedTable(
          stack.basePosition,
          stack.cardIds.length,
        )) {
      return null;
    }

    if (!_hasExactRecipeTypes(stack.cardIds, recipe.requiredCardTypes)) {
      return null;
    }

    for (var index = 0; index < stack.cardIds.length; index++) {
      final cardId = stack.cardIds[index];
      final placement = _placements[cardId];
      if (placement == null ||
          placement.zone != CardZone.ingredientStack ||
          placement.stackId != stack.id ||
          placement.stackIndex != index) {
        return null;
      }
    }

    final sourceCardIds = List<String>.of(stack.cardIds);
    final basePosition = stack.basePosition;

    _stacks.remove(stack.id);
    for (final cardId in sourceCardIds) {
      final previousPlacement = placementFor(cardId);
      _placements[cardId] = CardPlacement(
        zone: CardZone.consumed,
        currentValidPosition: previousPlacement.currentValidPosition,
        lastValidPosition: previousPlacement.lastValidPosition,
      );
    }
    _definitions[recipe.resultInstanceId] = recipe.resultDefinition;
    _placements[recipe.resultInstanceId] = CardPlacement(
      zone: CardZone.kitchenTable,
      currentValidPosition: basePosition,
      lastValidPosition: basePosition,
    );

    return RecipeResolution(
      recipeId: recipe.id,
      sourceStackId: stack.id,
      sourceCardIds: sourceCardIds,
      basePosition: basePosition,
      resultCardId: recipe.resultInstanceId,
    );
  }

  ({Rect targetBounds, Rect newTopBounds}) previewGeometryForTarget(
    String targetCardId,
  ) {
    _ensureKnownCard(targetCardId);
    final targetStack = stackForCard(targetCardId);
    final cardCount = targetStack == null ? 2 : targetStack.cardIds.length + 1;
    final requestedBase =
        targetStack?.basePosition ??
        placementFor(targetCardId).currentValidPosition;
    final basePosition = _stackLayout.clampBase(requestedBase, cardCount);
    final topPosition = _stackLayout.positionFor(basePosition, cardCount - 1);
    return (
      targetBounds: _stackLayout.boundsFor(basePosition, cardCount),
      newTopBounds: Rect.fromLTWH(
        topPosition.dx,
        topPosition.dy,
        _stackLayout.cardSize.width,
        _stackLayout.cardSize.height,
      ),
    );
  }

  Rect stackBounds(String stackId) {
    final stack = stackFor(stackId);
    return _stackLayout.boundsFor(stack.basePosition, stack.cardIds.length);
  }

  bool hasConsistentCardLocations() {
    if (_placements.length != _definitions.length) {
      return false;
    }

    final stackedCardIds = <String>{};
    for (final stack in _stacks.values) {
      if (stack.cardIds.toSet().length != stack.cardIds.length) {
        return false;
      }
      for (var index = 0; index < stack.cardIds.length; index++) {
        final cardId = stack.cardIds[index];
        if (!_definitions.containsKey(cardId) ||
            !_isIngredient(cardId) ||
            !stackedCardIds.add(cardId)) {
          return false;
        }
        final placement = _placements[cardId];
        if (placement == null ||
            placement.zone != CardZone.ingredientStack ||
            placement.stackId != stack.id ||
            placement.stackIndex != index) {
          return false;
        }
      }
    }

    for (final cardId in _definitions.keys) {
      final placement = _placements[cardId];
      if (placement == null) {
        return false;
      }
      if (placement.zone == CardZone.ingredientStack) {
        if (!stackedCardIds.contains(cardId)) {
          return false;
        }
      } else if (placement.stackId != null || placement.stackIndex != null) {
        return false;
      }
    }

    return true;
  }

  bool _hasExactRecipeTypes(
    List<String> cardIds,
    List<CardType> requiredCardTypes,
  ) {
    if (cardIds.length != requiredCardTypes.length) {
      return false;
    }
    for (var index = 0; index < cardIds.length; index++) {
      if (definitionFor(cardIds[index]).type != requiredCardTypes[index]) {
        return false;
      }
    }
    return true;
  }

  void _detachCardFromStack(String cardId) {
    final placement = placementFor(cardId);
    final stackId = placement.stackId;
    if (stackId == null) {
      return;
    }
    final stack = stackFor(stackId);
    final remainingCardIds = stack.cardIds
        .where((memberId) => memberId != cardId)
        .toList();
    final detachedPosition = placement.currentValidPosition;

    _stacks.remove(stackId);
    _placements[cardId] = CardPlacement(
      zone: CardZone.kitchenTable,
      currentValidPosition: detachedPosition,
      lastValidPosition: detachedPosition,
    );

    if (remainingCardIds.length >= 2) {
      _applyStackLayout(stack.copyWith(cardIds: remainingCardIds));
    } else if (remainingCardIds.length == 1) {
      final remainingCardId = remainingCardIds.single;
      _placements[remainingCardId] = CardPlacement(
        zone: CardZone.kitchenTable,
        currentValidPosition: stack.basePosition,
        lastValidPosition: stack.basePosition,
      );
    }
  }

  void _applyStackLayout(CardStack requestedStack) {
    final basePosition = _stackLayout.clampBase(
      requestedStack.basePosition,
      requestedStack.cardIds.length,
    );
    final stack = requestedStack.copyWith(basePosition: basePosition);
    _stacks[stack.id] = stack;
    for (var index = 0; index < stack.cardIds.length; index++) {
      final cardId = stack.cardIds[index];
      final position = _stackLayout.positionFor(basePosition, index);
      _placements[cardId] = CardPlacement(
        zone: CardZone.ingredientStack,
        currentValidPosition: position,
        lastValidPosition: position,
        stackId: stack.id,
        stackIndex: index,
      );
    }
  }

  bool _isIngredient(String cardId) {
    return definitionFor(cardId).category == CardCategory.ingredient;
  }

  String _nextStackId() {
    final stackId =
        'ingredient_stack_${_nextStackSequence.toString().padLeft(2, '0')}';
    _nextStackSequence++;
    return stackId;
  }

  void _ensureKnownCard(String cardId) {
    if (!_definitions.containsKey(cardId)) {
      throw ArgumentError.value(cardId, 'cardId', 'Unknown card');
    }
  }
}
