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
    Map<String, Offset> initialEquipmentTablePositions = const {},
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
      final equipmentPosition = initialEquipmentTablePositions[definition.id];
      final resolvedInitialPosition = equipmentPosition ?? initialPosition;
      if (resolvedInitialPosition == null) {
        throw ArgumentError.value(
          definition.id,
          'initialHandPositions',
          'Missing hand position',
        );
      }
      _definitions[definition.id] = definition;
      if (definition.category == CardCategory.ingredient) {
        _baseIngredientDefinitions[definition.id] = definition;
      }
      if (initialPosition != null) {
        _initialHandPositions[definition.id] = initialPosition;
      }
      _placements[definition.id] = CardPlacement(
        zone: equipmentPosition == null ? CardZone.hand : CardZone.kitchenTable,
        currentValidPosition: resolvedInitialPosition,
        lastValidPosition: resolvedInitialPosition,
      );
    }
  }

  final StackLayout _stackLayout;
  final Map<String, CardDefinition> _definitions = {};
  final Map<String, CardDefinition> _baseIngredientDefinitions = {};
  final Map<String, Offset> _initialHandPositions = {};
  final Map<String, CardPlacement> _placements = {};
  final Map<String, CardStack> _stacks = {};
  final Map<String, List<String>> _resultLineages = {};
  int _nextStackSequence = 1;
  int _nextResultSequence = 1;

  int get cardCount => _definitions.length;
  int get stackCount => _stacks.length;

  Iterable<CardDefinition> get definitions => _definitions.values;
  Iterable<CardStack> get stacks => _stacks.values;
  bool containsCard(String cardId) => _definitions.containsKey(cardId);

  void spawnWorkingCard({
    required CardDefinition definition,
    required Offset dragPosition,
  }) {
    if (definition.category != CardCategory.ingredient ||
        _definitions.containsKey(definition.id)) {
      throw ArgumentError.value(
        definition.id,
        'definition',
        'Working-card IDs must be unique ingredients.',
      );
    }
    _definitions[definition.id] = definition;
    _placements[definition.id] = CardPlacement(
      zone: CardZone.dragging,
      currentValidPosition: dragPosition,
      lastValidPosition: dragPosition,
    );
  }

  void updateSpawnedDragPosition(String cardId, Offset dragPosition) {
    _ensureKnownCard(cardId);
    final placement = placementFor(cardId);
    if (placement.zone != CardZone.dragging) {
      throw StateError('Only a newly spawned working card may be updated.');
    }
    _placements[cardId] = CardPlacement(
      zone: CardZone.dragging,
      currentValidPosition: dragPosition,
      lastValidPosition: placement.lastValidPosition,
    );
  }

  void removeSpawnedWorkingCard(String cardId) {
    _ensureKnownCard(cardId);
    if (placementFor(cardId).zone != CardZone.dragging) {
      throw StateError('Only an unplaced spawned card may be removed.');
    }
    _definitions.remove(cardId);
    _placements.remove(cardId);
    _resultLineages.remove(cardId);
  }

  String nextResultRuntimeId(String resultDefinitionId) {
    final baseId = resultDefinitionId.replaceFirst(RegExp(r'_01$'), '');
    final id =
        'result_${baseId}_${_nextResultSequence.toString().padLeft(4, '0')}';
    _nextResultSequence++;
    return id;
  }

  List<String> sourceCardIdsForResult(String resultCardId) =>
      List.unmodifiable(_resultLineages[resultCardId] ?? const []);

  void recordResultLineage({
    required String resultCardId,
    required Iterable<String> sourceCardIds,
  }) {
    _ensureKnownCard(resultCardId);
    _resultLineages[resultCardId] = List.unmodifiable(sourceCardIds.toList());
  }

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

  bool isServed(String cardId) {
    return placementFor(cardId).zone == CardZone.served;
  }

  Offset lastValidPositionFor(String cardId) {
    return placementFor(cardId).lastValidPosition;
  }

  CardDragSnapshot beginCardDrag(String cardId) {
    _ensureKnownCard(cardId);
    if (isProcessing(cardId) || isConsumed(cardId) || isServed(cardId)) {
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
    if (isProcessing(cardId) || isConsumed(cardId) || isServed(cardId)) {
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
    if (isConsumed(cardId) || isServed(cardId)) {
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
        isServed(draggedCardId) ||
        isServed(targetCardId) ||
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
    String? runtimeResultId,
  }) {
    final stack = _stacks[stackId];
    final resultCardId =
        runtimeResultId ?? nextResultRuntimeId(recipe.resultDefinition.id);
    final resultDefinition = recipe.resultDefinition.copyWithId(resultCardId);
    final existingResultPlacement = _placements[resultCardId];
    if (stack == null ||
        (_definitions.containsKey(resultCardId) &&
            (existingResultPlacement == null ||
                (existingResultPlacement.zone != CardZone.served &&
                    existingResultPlacement.zone != CardZone.consumed))) ||
        resultDefinition.category != CardCategory.result ||
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
    _definitions[resultCardId] = resultDefinition;
    _placements[resultCardId] = CardPlacement(
      zone: CardZone.kitchenTable,
      currentValidPosition: basePosition,
      lastValidPosition: basePosition,
    );
    _resultLineages[resultCardId] = List.unmodifiable(sourceCardIds);

    return RecipeResolution(
      recipeId: recipe.id,
      sourceStackId: stack.id,
      sourceCardIds: sourceCardIds,
      basePosition: basePosition,
      resultCardId: resultCardId,
    );
  }

  String completeProcessedResultCard({
    required String inputCardId,
    required CardDefinition resultDefinition,
    required Offset outputPosition,
  }) {
    _ensureKnownCard(inputCardId);
    if (!isProcessing(inputCardId) ||
        resultDefinition.category != CardCategory.result) {
      throw StateError('Only a processing result input can complete.');
    }
    final runtimeBaseId = resultDefinition.type == CardType.crispyFries
        ? 'crispy_fries_01'
        : resultDefinition.id;
    final resultCardId = nextResultRuntimeId(runtimeBaseId);
    _definitions[resultCardId] = resultDefinition.copyWithId(resultCardId);
    _placements[resultCardId] = CardPlacement(
      zone: CardZone.kitchenTable,
      currentValidPosition: outputPosition,
      lastValidPosition: outputPosition,
    );
    _resultLineages[resultCardId] = List.unmodifiable([inputCardId]);
    final inputPlacement = placementFor(inputCardId);
    _placements[inputCardId] = CardPlacement(
      zone: CardZone.consumed,
      currentValidPosition: inputPlacement.currentValidPosition,
      lastValidPosition: inputPlacement.lastValidPosition,
    );
    return resultCardId;
  }

  void resetWorkingCardsForNewShift({
    required Iterable<CardDefinition> equipmentDefinitions,
    required Map<String, Offset> equipmentTablePositions,
  }) {
    _stacks.clear();
    _resultLineages.clear();
    _nextStackSequence = 1;
    _nextResultSequence = 1;
    final equipmentIds = equipmentDefinitions
        .map((definition) => definition.id)
        .toSet();
    _definitions.removeWhere((cardId, _) => !equipmentIds.contains(cardId));
    _placements.removeWhere((cardId, _) => !equipmentIds.contains(cardId));
    for (final definition in equipmentDefinitions) {
      final position = equipmentTablePositions[definition.id];
      if (position == null) {
        throw ArgumentError.value(
          definition.id,
          'equipmentTablePositions',
          'Missing equipment reset position.',
        );
      }
      _definitions[definition.id] = definition;
      _placements[definition.id] = CardPlacement(
        zone: CardZone.kitchenTable,
        currentValidPosition: position,
        lastValidPosition: position,
      );
    }
  }

  bool canMarkCardServed(String cardId) {
    _ensureKnownCard(cardId);
    return placementFor(cardId).zone == CardZone.kitchenTable &&
        definitionFor(cardId).category == CardCategory.result;
  }

  void markCardServed(String cardId) {
    if (!canMarkCardServed(cardId)) {
      throw StateError('Only an active result card can be served.');
    }
    final placement = placementFor(cardId);
    _placements[cardId] = CardPlacement(
      zone: CardZone.served,
      currentValidPosition: placement.currentValidPosition,
      lastValidPosition: placement.lastValidPosition,
    );
  }

  void resetPrototypeCardsForNextOrder({
    required Iterable<CardDefinition> ingredientDefinitions,
    required Map<String, Offset> handPositions,
    required String resultCardId,
  }) {
    final resultPlacement = _placements[resultCardId];
    if (resultPlacement != null && resultPlacement.zone != CardZone.served) {
      throw StateError('The result card must be served before a cycle reset.');
    }

    _stacks.clear();
    _nextStackSequence = 1;
    for (final definition in ingredientDefinitions) {
      final handPosition = handPositions[definition.id];
      if (handPosition == null) {
        throw ArgumentError.value(
          definition.id,
          'handPositions',
          'Missing hand position for reset card.',
        );
      }
      _definitions[definition.id] = definition;
      _placements[definition.id] = CardPlacement(
        zone: CardZone.hand,
        currentValidPosition: handPosition,
        lastValidPosition: handPosition,
      );
    }
  }

  void resetPrototypePreparationState({
    required Iterable<CardDefinition> ingredientDefinitions,
    required Map<String, Offset> handPositions,
    String? resultCardId,
    Iterable<String> resultCardIds = const [],
    Iterable<CardDefinition> equipmentDefinitions = const [],
    Map<String, Offset> equipmentTablePositions = const {},
  }) {
    _stacks.clear();
    _nextStackSequence = 1;
    _nextResultSequence = 1;
    final baseCardIds = <String>{
      ...ingredientDefinitions.map((definition) => definition.id),
      ...equipmentDefinitions.map((definition) => definition.id),
    };
    final inactiveResultIds = <String>{...resultCardIds};
    if (resultCardId != null) {
      inactiveResultIds.add(resultCardId);
    }
    for (final inactiveResultId in inactiveResultIds) {
      if (!_definitions.containsKey(inactiveResultId) ||
          baseCardIds.contains(inactiveResultId)) {
        continue;
      }
      final placement = placementFor(inactiveResultId);
      _placements[inactiveResultId] = CardPlacement(
        zone: CardZone.consumed,
        currentValidPosition: placement.currentValidPosition,
        lastValidPosition: placement.lastValidPosition,
      );
    }
    for (final definition in ingredientDefinitions) {
      final handPosition = handPositions[definition.id];
      if (handPosition == null) {
        throw ArgumentError.value(
          definition.id,
          'handPositions',
          'Missing hand position for reset card.',
        );
      }
      _definitions[definition.id] = definition;
      _placements[definition.id] = CardPlacement(
        zone: CardZone.hand,
        currentValidPosition: handPosition,
        lastValidPosition: handPosition,
      );
    }
    for (final definition in equipmentDefinitions) {
      final tablePosition = equipmentTablePositions[definition.id];
      if (tablePosition == null) {
        throw ArgumentError.value(
          definition.id,
          'equipmentTablePositions',
          'Missing table position for reset equipment.',
        );
      }
      _definitions[definition.id] = definition;
      _placements[definition.id] = CardPlacement(
        zone: CardZone.kitchenTable,
        currentValidPosition: tablePosition,
        lastValidPosition: tablePosition,
      );
    }
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
