import 'package:flutter_test/flutter_test.dart';

import 'package:son_siparis/game/data/prototype_card_definitions.dart';
import 'package:son_siparis/game/data/prototype_recipe_definitions.dart';
import 'package:son_siparis/game/game_layout.dart';
import 'package:son_siparis/game/kitchen_grid.dart';
import 'package:son_siparis/game/models/card_definition.dart';
import 'package:son_siparis/game/models/card_zone.dart';
import 'package:son_siparis/game/models/processing_job.dart';
import 'package:son_siparis/game/models/recipe_resolution.dart';
import 'package:son_siparis/game/state/equipment_processing_state.dart';
import 'package:son_siparis/game/state/kitchen_table_state.dart';
import 'package:son_siparis/game/systems/equipment_target_resolver.dart';
import 'package:son_siparis/game/systems/processing_output_resolver.dart';
import 'package:son_siparis/game/systems/recipe_resolver.dart';
import 'package:son_siparis/game/systems/stack_layout.dart';
import 'package:son_siparis/game/systems/stack_target_resolver.dart';
import 'package:son_siparis/main.dart';

void main() {
  late KitchenTableState tableState;
  late KitchenGrid grid;
  late StackLayout stackLayout;
  late StackTargetResolver targetResolver;
  late EquipmentProcessingState processingState;
  late EquipmentTargetResolver equipmentTargetResolver;
  late ProcessingOutputResolver processingOutputResolver;
  late RecipeResolver recipeResolver;

  setUp(() {
    grid = KitchenGrid(
      tableBounds: GameLayout.kitchenTableBounds,
      cardSize: GameLayout.cardSize,
      spacing: GameLayout.kitchenGridSpacing,
      padding: GameLayout.kitchenGridPadding,
    );
    stackLayout = StackLayout(
      cardSize: GameLayout.cardSize,
      paddedTableBounds: grid.paddedTableBounds,
      gridOrigin: grid.origin,
      gridSpacing: grid.spacing,
      levelOffset: GameLayout.stackLevelOffset,
    );
    tableState = KitchenTableState(
      definitions: prototypeCardDefinitions,
      initialHandPositions: GameLayout.initialHandCardPositions,
      stackLayout: stackLayout,
    );
    targetResolver = StackTargetResolver(cardSize: GameLayout.cardSize);
    processingState = EquipmentProcessingState(
      processingDurationSeconds: GameLayout.processingDurationSeconds,
    );
    equipmentTargetResolver = EquipmentTargetResolver(
      cardSize: GameLayout.cardSize,
    );
    processingOutputResolver = ProcessingOutputResolver(kitchenGrid: grid);
    recipeResolver = RecipeResolver(recipes: prototypeRecipeDefinitions);
  });

  String createBreadPattyStack() {
    tableState.commitKitchenTablePlacement('bread_01', grid.origin);
    expect(tableState.tryStackCardOnTarget('patty_01', 'bread_01'), isTrue);
    return tableState.stackForCard('bread_01')!.id;
  }

  String createThreeIngredientStack() {
    final stackId = createBreadPattyStack();
    expect(tableState.tryStackCardOnTarget('cheese_01', 'bread_01'), isTrue);
    return stackId;
  }

  void placePanOnTable() {
    tableState.commitKitchenTablePlacement(
      'pan_01',
      grid.snap(grid.origin + const Offset(320, 64)),
    );
  }

  bool startPattyCooking() {
    final panPosition = tableState.placementFor('pan_01').currentValidPosition;
    return processingState.tryStartPattyCooking(
      tableState: tableState,
      equipmentCardId: 'pan_01',
      inputCardId: 'patty_01',
      attachedInputPosition: panPosition + GameLayout.processingPattyOffset,
    );
  }

  ProcessingJob finishPattyCooking() {
    final completedJob = processingState.advance(
      GameLayout.processingDurationSeconds,
    );
    expect(completedJob, isNotNull);
    final panPosition = tableState
        .placementFor(completedJob!.equipmentCardId)
        .currentValidPosition;
    tableState.completeProcessedCard(
      cardId: completedJob.inputCardId,
      completedDefinition: cookedPattyCardDefinition,
      outputPosition: processingOutputResolver.resolve(panPosition),
    );
    return completedJob;
  }

  String createExactBurgerStack() {
    placePanOnTable();
    expect(startPattyCooking(), isTrue);
    finishPattyCooking();
    tableState.commitKitchenTablePlacement('bread_01', grid.origin);
    expect(tableState.tryStackCardOnTarget('patty_01', 'bread_01'), isTrue);
    expect(tableState.tryStackCardOnTarget('cheese_01', 'bread_01'), isTrue);
    return tableState.stackForCard('bread_01')!.id;
  }

  RecipeResolution? resolveStack(String stackId) {
    final recipe = recipeResolver.resolve(
      tableState
          .orderedStackMembers(stackId)
          .map((cardId) => tableState.definitionFor(cardId).type),
    );
    return recipe == null
        ? null
        : tableState.tryResolveRecipeStack(stackId: stackId, recipe: recipe);
  }

  testWidgets('Son Sipariş app can be created', (WidgetTester tester) async {
    await tester.pumpWidget(const SonSiparisApp());

    expect(tester.takeException(), isNull);
  });

  test('registers exactly four cards with unique stable IDs', () {
    final ids = tableState.definitions
        .map((definition) => definition.id)
        .toSet();

    expect(tableState.cardCount, 4);
    expect(ids, {'bread_01', 'patty_01', 'cheese_01', 'pan_01'});
  });

  test('all cards start in the hand at distinct configured positions', () {
    final positions = tableState.definitions
        .map(
          (definition) =>
              tableState.placementFor(definition.id).currentValidPosition,
        )
        .toSet();

    for (final definition in tableState.definitions) {
      expect(tableState.isInHand(definition.id), isTrue);
    }
    expect(positions.length, tableState.cardCount);
  });

  test('a valid placement changes only the placed card', () {
    final cheeseBefore = tableState.placementFor('cheese_01');
    final snappedPosition = grid.snap(grid.origin + const Offset(51, 73));

    tableState.commitKitchenTablePlacement('patty_01', snappedPosition);

    expect(tableState.isOnKitchenTable('patty_01'), isTrue);
    expect(
      tableState.placementFor('patty_01').currentValidPosition,
      snappedPosition,
    );
    expect(tableState.placementFor('cheese_01'), cheeseBefore);
    expect(tableState.isInHand('cheese_01'), isTrue);
  });

  test('an invalid first placement preserves the hand position', () {
    final handPosition = tableState
        .placementFor('bread_01')
        .currentValidPosition;

    expect(tableState.lastValidPositionFor('bread_01'), handPosition);
    expect(tableState.isInHand('bread_01'), isTrue);
  });

  test(
    'an invalid later placement preserves the last valid table position',
    () {
      final snappedPosition = grid.snap(grid.origin + const Offset(79, 48));
      tableState.commitKitchenTablePlacement('pan_01', snappedPosition);

      expect(tableState.lastValidPositionFor('pan_01'), snappedPosition);
      expect(tableState.isOnKitchenTable('pan_01'), isTrue);
    },
  );

  test('repeated updates keep exactly four card instances', () {
    tableState.commitKitchenTablePlacement('bread_01', grid.origin);
    tableState.commitKitchenTablePlacement(
      'bread_01',
      grid.snap(grid.origin + const Offset(95, 64)),
    );

    expect(tableState.cardCount, 4);
    expect(
      tableState.definitions.map((definition) => definition.id).toSet().length,
      4,
    );
  });

  test('ingredient and equipment categories are represented correctly', () {
    expect(
      tableState.definitionFor('bread_01').category,
      CardCategory.ingredient,
    );
    expect(
      tableState.definitionFor('patty_01').category,
      CardCategory.ingredient,
    );
    expect(
      tableState.definitionFor('cheese_01').category,
      CardCategory.ingredient,
    );
    expect(tableState.definitionFor('pan_01').category, CardCategory.equipment);
  });

  test('two standalone ingredients create an ordered stack', () {
    final stackId = createBreadPattyStack();

    expect(tableState.stackCount, 1);
    expect(tableState.orderedStackMembers(stackId), ['bread_01', 'patty_01']);
    expect(tableState.isStacked('bread_01'), isTrue);
    expect(tableState.isStacked('patty_01'), isTrue);
    expect(tableState.hasConsistentCardLocations(), isTrue);
  });

  test('the dragged ingredient becomes the top stack member', () {
    final stackId = createBreadPattyStack();

    expect(tableState.orderedStackMembers(stackId).last, 'patty_01');
    expect(tableState.placementFor('patty_01').stackIndex, 1);
  });

  test('a third ingredient can be added to an existing stack', () {
    final stackId = createThreeIngredientStack();

    expect(tableState.orderedStackMembers(stackId), [
      'bread_01',
      'patty_01',
      'cheese_01',
    ]);
    expect(tableState.placementFor('cheese_01').stackIndex, 2);
  });

  test('ordered stack members are returned from bottom to top', () {
    final stackId = createThreeIngredientStack();

    expect(
      tableState.orderedStackMembers(stackId),
      orderedEquals(['bread_01', 'patty_01', 'cheese_01']),
    );
  });

  test('Tava cannot enter an ingredient stack', () {
    tableState.commitKitchenTablePlacement('bread_01', grid.origin);

    expect(tableState.tryStackCardOnTarget('pan_01', 'bread_01'), isFalse);
    expect(tableState.isInHand('pan_01'), isTrue);
    expect(tableState.stackCount, 0);
  });

  test('an ingredient cannot stack onto Tava', () {
    tableState.commitKitchenTablePlacement('pan_01', grid.origin);

    expect(tableState.tryStackCardOnTarget('bread_01', 'pan_01'), isFalse);
    expect(tableState.isInHand('bread_01'), isTrue);
    expect(tableState.stackCount, 0);
  });

  test('detaching the top card preserves the remaining stack', () {
    final stackId = createThreeIngredientStack();

    tableState.beginCardDrag('cheese_01');

    expect(tableState.orderedStackMembers(stackId), ['bread_01', 'patty_01']);
    expect(tableState.isStacked('cheese_01'), isFalse);
    expect(tableState.isOnKitchenTable('cheese_01'), isTrue);
  });

  test('detaching a middle card preserves remaining member order', () {
    final stackId = createThreeIngredientStack();

    tableState.beginCardDrag('patty_01');

    expect(tableState.orderedStackMembers(stackId), ['bread_01', 'cheese_01']);
    expect(tableState.placementFor('cheese_01').stackIndex, 1);
  });

  test('removing a card from a two-card stack dissolves it', () {
    createBreadPattyStack();

    tableState.beginCardDrag('patty_01');

    expect(tableState.stackCount, 0);
    expect(tableState.isStacked('bread_01'), isFalse);
    expect(tableState.placementFor('bread_01').zone, CardZone.kitchenTable);
    expect(
      tableState.placementFor('bread_01').currentValidPosition,
      grid.origin,
    );
  });

  test('invalid drop restores exact previous stack membership and order', () {
    final stackId = createThreeIngredientStack();
    final placementsBefore = {
      for (final definition in tableState.definitions)
        definition.id: tableState.placementFor(definition.id),
    };

    final snapshot = tableState.beginCardDrag('patty_01');
    tableState.commitKitchenTablePlacement(
      'patty_01',
      grid.snap(grid.origin + const Offset(160, 64)),
    );
    tableState.restoreCardDragSnapshot(snapshot);

    expect(tableState.orderedStackMembers(stackId), [
      'bread_01',
      'patty_01',
      'cheese_01',
    ]);
    for (final entry in placementsBefore.entries) {
      expect(tableState.placementFor(entry.key), entry.value);
    }
  });

  test(
    'a detached card can become standalone at a valid free-grid position',
    () {
      createThreeIngredientStack();
      final freePosition = grid.snap(grid.origin + const Offset(224, 64));

      tableState.beginCardDrag('patty_01');
      tableState.commitKitchenTablePlacement('patty_01', freePosition);

      expect(tableState.isStacked('patty_01'), isFalse);
      expect(tableState.placementFor('patty_01').zone, CardZone.kitchenTable);
      expect(
        tableState.placementFor('patty_01').currentValidPosition,
        freePosition,
      );
    },
  );

  test('a detached ingredient can join another stack', () {
    createBreadPattyStack();
    final cheesePosition = grid.snap(grid.origin + const Offset(256, 64));
    tableState.commitKitchenTablePlacement('cheese_01', cheesePosition);

    tableState.beginCardDrag('patty_01');
    expect(tableState.tryStackCardOnTarget('patty_01', 'cheese_01'), isTrue);

    final newStackId = tableState.stackForCard('cheese_01')!.id;
    expect(tableState.orderedStackMembers(newStackId), [
      'cheese_01',
      'patty_01',
    ]);
  });

  test('dropping back onto the same stack moves the card to the top', () {
    final stackId = createThreeIngredientStack();

    tableState.beginCardDrag('bread_01');
    expect(tableState.tryStackCardOnTarget('bread_01', 'patty_01'), isTrue);

    expect(tableState.orderedStackMembers(stackId), [
      'patty_01',
      'cheese_01',
      'bread_01',
    ]);
  });

  test('empty stacks are removed during stack cleanup', () {
    createBreadPattyStack();

    tableState.beginCardDrag('patty_01');
    tableState.beginCardDrag('bread_01');

    expect(tableState.stackCount, 0);
    expect(tableState.hasConsistentCardLocations(), isTrue);
  });

  test('every card remains in exactly one authoritative location', () {
    createThreeIngredientStack();
    tableState.commitKitchenTablePlacement(
      'pan_01',
      grid.snap(grid.origin + const Offset(320, 64)),
    );

    expect(tableState.hasConsistentCardLocations(), isTrue);
  });

  test('stack mutations never duplicate a card ID across locations', () {
    createThreeIngredientStack();
    tableState.beginCardDrag('patty_01');
    expect(tableState.tryStackCardOnTarget('patty_01', 'bread_01'), isTrue);

    final stackedIds = tableState.stacks
        .expand((stack) => stack.cardIds)
        .toList();
    expect(stackedIds.toSet().length, stackedIds.length);
    expect(stackedIds.length, 3);
    expect(tableState.hasConsistentCardLocations(), isTrue);
  });

  test('stack visual bounds stay within the padded table near its edge', () {
    final edgePosition = grid.snap(grid.validCardPositionBounds.bottomRight);
    tableState.commitKitchenTablePlacement('bread_01', edgePosition);
    tableState.tryStackCardOnTarget('patty_01', 'bread_01');

    final stack = tableState.stackForCard('bread_01')!;
    expect(
      stackLayout.isFullyInsidePaddedTable(
        stack.basePosition,
        stack.cardIds.length,
      ),
      isTrue,
    );
    expect(grid.isAligned(stack.basePosition), isTrue);
  });

  test('stack target resolver chooses the visually topmost ingredient', () {
    tableState.commitKitchenTablePlacement('bread_01', grid.origin);
    tableState.commitKitchenTablePlacement('patty_01', grid.origin);
    final target = targetResolver.resolve(
      draggedCardId: 'cheese_01',
      draggedCardPosition: grid.origin,
      tableState: tableState,
    );

    expect(target?.cardId, 'patty_01');
    expect(
      targetResolver.resolve(
        draggedCardId: 'pan_01',
        draggedCardPosition: grid.origin,
        tableState: tableState,
      ),
      isNull,
    );
  });

  test('raw Köfte is eligible for Tava processing', () {
    placePanOnTable();

    expect(
      processingState.canStartPattyCooking(
        tableState: tableState,
        equipmentCardId: 'pan_01',
        inputCardId: 'patty_01',
      ),
      isTrue,
    );
  });

  test('Ekmek is rejected by Tava processing', () {
    placePanOnTable();

    expect(
      processingState.canStartPattyCooking(
        tableState: tableState,
        equipmentCardId: 'pan_01',
        inputCardId: 'bread_01',
      ),
      isFalse,
    );
  });

  test('Peynir is rejected by Tava processing', () {
    placePanOnTable();

    expect(
      processingState.canStartPattyCooking(
        tableState: tableState,
        equipmentCardId: 'pan_01',
        inputCardId: 'cheese_01',
      ),
      isFalse,
    );
  });

  test('cooked Köfte is rejected by Tava processing', () {
    placePanOnTable();
    expect(startPattyCooking(), isTrue);
    finishPattyCooking();

    expect(
      processingState.canStartPattyCooking(
        tableState: tableState,
        equipmentCardId: 'pan_01',
        inputCardId: 'patty_01',
      ),
      isFalse,
    );
  });

  test('starting a valid process creates exactly one job', () {
    placePanOnTable();

    expect(startPattyCooking(), isTrue);
    expect(processingState.activeJob, isNotNull);
    expect(processingState.activeJob?.id, 'pan_process_01');
  });

  test('the processing job owns pan_01 and patty_01', () {
    placePanOnTable();
    startPattyCooking();

    expect(processingState.activeJob?.equipmentCardId, 'pan_01');
    expect(processingState.activeJob?.inputCardId, 'patty_01');
    expect(processingState.activeJob?.action, ProcessingAction.cookPatty);
  });

  test('patty_01 exists only in the processing zone while active', () {
    placePanOnTable();
    startPattyCooking();

    expect(tableState.placementFor('patty_01').zone, CardZone.processing);
    expect(tableState.isInHand('patty_01'), isFalse);
    expect(tableState.isStacked('patty_01'), isFalse);
    expect(processingState.hasConsistentProcessingLocation(tableState), isTrue);
  });

  test('Tava reports busy while processing', () {
    placePanOnTable();
    startPattyCooking();

    expect(processingState.isEquipmentAvailable('pan_01'), isFalse);
    expect(processingState.isCardLocked('pan_01'), isTrue);
    expect(processingState.isCardLocked('patty_01'), isTrue);
  });

  test('a second job cannot begin while Tava is busy', () {
    placePanOnTable();
    expect(startPattyCooking(), isTrue);
    final activeJob = processingState.activeJob;

    expect(startPattyCooking(), isFalse);
    expect(processingState.activeJob?.id, activeJob?.id);
    expect(tableState.placementFor('patty_01').zone, CardZone.processing);
  });

  test('processing progress is zero at start', () {
    placePanOnTable();
    startPattyCooking();

    expect(processingState.activeJob?.progress, 0);
  });

  test('processing progress advances deterministically with delta time', () {
    placePanOnTable();
    startPattyCooking();

    expect(processingState.advance(1.25), isNull);
    expect(processingState.activeJob?.elapsedSeconds, 1.25);
    expect(processingState.activeJob?.progress, closeTo(1.25 / 3, .0001));
  });

  test('processing progress clamps to one', () {
    placePanOnTable();
    startPattyCooking();

    final completedJob = processingState.advance(99);

    expect(completedJob?.progress, 1);
    expect(completedJob?.elapsedSeconds, GameLayout.processingDurationSeconds);
  });

  test('processing completes exactly once at three seconds', () {
    placePanOnTable();
    startPattyCooking();

    final completedJob = processingState.advance(3);

    expect(completedJob?.status, ProcessingStatus.completed);
    expect(processingState.advance(.1), isNull);
  });

  test('patty keeps its stable instance ID after completion', () {
    placePanOnTable();
    startPattyCooking();
    finishPattyCooking();

    expect(tableState.definitionFor('patty_01').id, 'patty_01');
    expect(tableState.cardCount, 4);
  });

  test('patty transforms from Köfte to Pişmiş Köfte', () {
    placePanOnTable();
    startPattyCooking();
    finishPattyCooking();

    expect(tableState.definitionFor('patty_01').type, CardType.cookedPatty);
    expect(tableState.definitionFor('patty_01').displayName, 'Pişmiş Köfte');
  });

  test('raw Köfte no longer exists after completion', () {
    placePanOnTable();
    startPattyCooking();
    finishPattyCooking();

    expect(
      tableState.definitions.any(
        (definition) => definition.type == CardType.patty,
      ),
      isFalse,
    );
  });

  test('the processing job is removed after completion', () {
    placePanOnTable();
    startPattyCooking();
    finishPattyCooking();

    expect(processingState.activeJob, isNull);
  });

  test('Tava becomes available after completion', () {
    placePanOnTable();
    startPattyCooking();
    finishPattyCooking();

    expect(processingState.isEquipmentAvailable('pan_01'), isTrue);
    expect(processingState.isCardLocked('pan_01'), isFalse);
  });

  test('cooked Köfte is placed at a valid snapped table position', () {
    placePanOnTable();
    startPattyCooking();
    finishPattyCooking();
    final outputPosition = tableState
        .placementFor('patty_01')
        .currentValidPosition;

    expect(tableState.placementFor('patty_01').zone, CardZone.kitchenTable);
    expect(grid.isAligned(outputPosition), isTrue);
    expect(grid.isCardPositionInsidePaddedArea(outputPosition), isTrue);
  });

  test('cooked Köfte can join an ingredient stack', () {
    placePanOnTable();
    tableState.commitKitchenTablePlacement('bread_01', grid.origin);
    startPattyCooking();
    finishPattyCooking();

    expect(tableState.tryStackCardOnTarget('patty_01', 'bread_01'), isTrue);
    expect(tableState.isStacked('patty_01'), isTrue);
  });

  test('Köfte detached from a stack can start processing', () {
    createBreadPattyStack();
    placePanOnTable();
    final snapshot = tableState.beginCardDrag('patty_01');

    expect(startPattyCooking(), isTrue);
    expect(snapshot.cardId, 'patty_01');
    expect(tableState.isProcessing('patty_01'), isTrue);
    expect(tableState.stackCount, 0);
  });

  test('invalid processing target restores exact previous stack state', () {
    final stackId = createBreadPattyStack();
    placePanOnTable();
    final placementsBefore = {
      for (final definition in tableState.definitions)
        definition.id: tableState.placementFor(definition.id),
    };
    final snapshot = tableState.beginCardDrag('patty_01');
    final outsidePanPosition = grid.snap(grid.origin + const Offset(96, 64));

    expect(
      equipmentTargetResolver.resolvePattyTarget(
        draggedCardId: 'patty_01',
        draggedCardPosition: outsidePanPosition,
        tableState: tableState,
        processingState: processingState,
      ),
      isNull,
    );
    tableState.restoreCardDragSnapshot(snapshot);

    expect(tableState.orderedStackMembers(stackId), ['bread_01', 'patty_01']);
    for (final entry in placementsBefore.entries) {
      expect(tableState.placementFor(entry.key), entry.value);
    }
  });

  test('busy-processing rejection preserves the existing job and state', () {
    placePanOnTable();
    startPattyCooking();
    final placementBefore = tableState.placementFor('patty_01');
    final jobBefore = processingState.activeJob;

    expect(startPattyCooking(), isFalse);
    expect(processingState.activeJob?.id, jobBefore?.id);
    expect(tableState.placementFor('patty_01'), placementBefore);
  });

  test('equipment target resolver detects only raw Köfte over Tava', () {
    placePanOnTable();
    final panPosition = tableState.placementFor('pan_01').currentValidPosition;

    expect(
      equipmentTargetResolver
          .resolvePattyTarget(
            draggedCardId: 'patty_01',
            draggedCardPosition: panPosition,
            tableState: tableState,
            processingState: processingState,
          )
          ?.equipmentCardId,
      'pan_01',
    );
    expect(
      equipmentTargetResolver.resolvePattyTarget(
        draggedCardId: 'bread_01',
        draggedCardPosition: panPosition,
        tableState: tableState,
        processingState: processingState,
      ),
      isNull,
    );
  });

  test('exactly four card instances remain throughout processing', () {
    placePanOnTable();
    expect(startPattyCooking(), isTrue);
    expect(tableState.cardCount, 4);
    expect(tableState.hasConsistentCardLocations(), isTrue);
    expect(processingState.hasConsistentProcessingLocation(tableState), isTrue);

    finishPattyCooking();

    expect(tableState.cardCount, 4);
    expect(tableState.hasConsistentCardLocations(), isTrue);
    expect(processingState.hasConsistentProcessingLocation(tableState), isTrue);
  });

  test('an aligned grid position remains unchanged', () {
    final aligned = Offset(
      grid.origin.dx + (GameLayout.kitchenGridSpacing * 5),
      grid.origin.dy + (GameLayout.kitchenGridSpacing * 3),
    );

    expect(grid.snap(aligned), aligned);
    expect(grid.isAligned(aligned), isTrue);
  });

  test('an arbitrary table position snaps to its nearest grid point', () {
    final arbitraryPosition = Offset(grid.origin.dx + 47, grid.origin.dy + 81);

    expect(
      grid.snap(arbitraryPosition),
      Offset(
        grid.origin.dx + GameLayout.kitchenGridSpacing,
        grid.origin.dy + (GameLayout.kitchenGridSpacing * 3),
      ),
    );
  });

  test('positions near left and top clamp to the first valid grid point', () {
    final candidate = grid.snap(
      Offset(grid.origin.dx - 12, grid.origin.dy - 12),
    );

    expect(candidate, grid.origin);
    expect(grid.isCardPositionInsidePaddedArea(candidate), isTrue);
  });

  test('positions near right and bottom clamp to a fully valid grid point', () {
    final candidate = grid.snap(
      Offset(
        grid.validCardPositionBounds.right + 20,
        grid.validCardPositionBounds.bottom + 20,
      ),
    );

    expect(grid.isCardPositionInsidePaddedArea(candidate), isTrue);
    expect(grid.isAligned(candidate), isTrue);
  });

  test('snapped card bounds stay within the padded kitchen table area', () {
    final candidate = grid.snap(
      Offset(
        grid.validCardPositionBounds.right,
        grid.validCardPositionBounds.bottom,
      ),
    );

    final cardBounds = grid.cardBoundsAt(candidate);
    expect(cardBounds.left, greaterThanOrEqualTo(grid.paddedTableBounds.left));
    expect(cardBounds.top, greaterThanOrEqualTo(grid.paddedTableBounds.top));
    expect(cardBounds.right, lessThanOrEqualTo(grid.paddedTableBounds.right));
    expect(cardBounds.bottom, lessThanOrEqualTo(grid.paddedTableBounds.bottom));
  });

  test('repeated snapping is stable and uses only virtual layout values', () {
    final position = Offset(grid.origin.dx + 51, grid.origin.dy + 73);
    final firstSnap = grid.snap(position);

    expect(grid.snap(position), firstSnap);
    expect(grid.snap(firstSnap), firstSnap);
  });

  test('the exact ordered burger types match classic_burger', () {
    final recipe = recipeResolver.resolve(const [
      CardType.bread,
      CardType.cookedPatty,
      CardType.cheese,
    ]);

    expect(recipe?.id, 'classic_burger');
  });

  test('bread, raw KÃ¶fte, and cheese do not match a recipe', () {
    expect(
      recipeResolver.resolve(const [
        CardType.bread,
        CardType.patty,
        CardType.cheese,
      ]),
      isNull,
    );
  });

  test('bread, cheese, and cooked KÃ¶fte do not match a recipe', () {
    expect(
      recipeResolver.resolve(const [
        CardType.bread,
        CardType.cheese,
        CardType.cookedPatty,
      ]),
      isNull,
    );
  });

  test('cooked KÃ¶fte, bread, and cheese do not match a recipe', () {
    expect(
      recipeResolver.resolve(const [
        CardType.cookedPatty,
        CardType.bread,
        CardType.cheese,
      ]),
      isNull,
    );
  });

  test('two-card and four-card type lists do not match a recipe', () {
    expect(
      recipeResolver.resolve(const [CardType.bread, CardType.cookedPatty]),
      isNull,
    );
    expect(
      recipeResolver.resolve(const [
        CardType.bread,
        CardType.cookedPatty,
        CardType.cheese,
        CardType.bread,
      ]),
      isNull,
    );
  });

  test('overlapping standalone ingredients do not resolve a recipe', () {
    placePanOnTable();
    expect(startPattyCooking(), isTrue);
    finishPattyCooking();
    tableState.commitKitchenTablePlacement('bread_01', grid.origin);
    tableState.commitKitchenTablePlacement('cheese_01', grid.origin);

    expect(tableState.stackCount, 0);
    expect(
      tableState.definitions.any((card) => card.id == 'burger_01'),
      isFalse,
    );
  });

  test('a raw-patty stack remains intact and unresolved', () {
    final stackId = createThreeIngredientStack();

    expect(resolveStack(stackId), isNull);
    expect(tableState.orderedStackMembers(stackId), [
      'bread_01',
      'patty_01',
      'cheese_01',
    ]);
    expect(tableState.definitionFor('patty_01').type, CardType.patty);
  });

  test('a wrong-order cooked stack remains intact and unresolved', () {
    placePanOnTable();
    expect(startPattyCooking(), isTrue);
    finishPattyCooking();
    tableState.commitKitchenTablePlacement('bread_01', grid.origin);
    expect(tableState.tryStackCardOnTarget('cheese_01', 'bread_01'), isTrue);
    expect(tableState.tryStackCardOnTarget('patty_01', 'bread_01'), isTrue);
    final stackId = tableState.stackForCard('bread_01')!.id;

    expect(resolveStack(stackId), isNull);
    expect(tableState.orderedStackMembers(stackId), [
      'bread_01',
      'cheese_01',
      'patty_01',
    ]);
    expect(tableState.stackCount, 1);
  });

  test('the exact ingredient stack resolves exactly once', () {
    final stackId = createExactBurgerStack();
    final firstResolution = resolveStack(stackId);

    expect(firstResolution?.recipeId, 'classic_burger');
    expect(
      tableState.tryResolveRecipeStack(
        stackId: stackId,
        recipe: classicBurgerRecipeDefinition,
      ),
      isNull,
    );
    expect(
      tableState.definitions.where((card) => card.id == 'burger_01'),
      hasLength(1),
    );
  });

  test('recipe resolution removes the source stack', () {
    final stackId = createExactBurgerStack();

    expect(resolveStack(stackId), isNotNull);
    expect(tableState.stackCount, 0);
    expect(() => tableState.stackFor(stackId), throwsArgumentError);
  });

  test('recipe sources move to the explicit consumed state', () {
    final stackId = createExactBurgerStack();
    resolveStack(stackId);

    for (final cardId in const ['bread_01', 'patty_01', 'cheese_01']) {
      expect(tableState.placementFor(cardId).zone, CardZone.consumed);
      expect(tableState.isConsumed(cardId), isTrue);
    }
  });

  test('pan remains active and unchanged after recipe resolution', () {
    final stackId = createExactBurgerStack();
    final panPosition = tableState.placementFor('pan_01').currentValidPosition;
    final panDefinition = tableState.definitionFor('pan_01');

    resolveStack(stackId);

    expect(tableState.definitionFor('pan_01'), same(panDefinition));
    expect(tableState.isOnKitchenTable('pan_01'), isTrue);
    expect(tableState.placementFor('pan_01').currentValidPosition, panPosition);
  });

  test(
    'burger_01 has the result definition and former stack base position',
    () {
      final stackId = createExactBurgerStack();
      final basePosition = tableState.stackFor(stackId).basePosition;

      final resolution = resolveStack(stackId);

      expect(resolution?.resultCardId, 'burger_01');
      expect(tableState.cardCount, 5);
      expect(
        tableState.definitionFor('burger_01').type,
        CardType.classicBurger,
      );
      expect(
        tableState.definitionFor('burger_01').displayName,
        'Klasik Burger',
      );
      expect(
        tableState.definitionFor('burger_01').category,
        CardCategory.result,
      );
      expect(
        tableState.definitionFor('burger_01').categoryLabel,
        String.fromCharCodes([83, 79, 78, 85, 0x00C7]),
      );
      expect(
        tableState.placementFor('burger_01').currentValidPosition,
        basePosition,
      );
      expect(grid.isCardPositionInsidePaddedArea(basePosition), isTrue);
    },
  );

  test('burger_01 is independently draggable and grid-snappable', () {
    final stackId = createExactBurgerStack();
    resolveStack(stackId);
    final targetPosition = grid.snap(grid.origin + const Offset(256, 96));

    final snapshot = tableState.beginCardDrag('burger_01');
    tableState.commitKitchenTablePlacement('burger_01', targetPosition);

    expect(snapshot.cardId, 'burger_01');
    expect(tableState.isOnKitchenTable('burger_01'), isTrue);
    expect(tableState.isStacked('burger_01'), isFalse);
    expect(
      tableState.placementFor('burger_01').currentValidPosition,
      targetPosition,
    );
    expect(grid.isAligned(targetPosition), isTrue);
  });

  test('an invalid burger release can restore its previous valid position', () {
    final stackId = createExactBurgerStack();
    resolveStack(stackId);
    final originalPosition = tableState
        .placementFor('burger_01')
        .currentValidPosition;
    final snapshot = tableState.beginCardDrag('burger_01');
    tableState.commitKitchenTablePlacement(
      'burger_01',
      grid.snap(grid.origin + const Offset(352, 96)),
    );
    tableState.restoreCardDragSnapshot(snapshot);

    expect(
      tableState.placementFor('burger_01').currentValidPosition,
      originalPosition,
    );
  });

  test('burger_01 cannot participate in ingredient stacks', () {
    final stackId = createExactBurgerStack();
    resolveStack(stackId);

    expect(tableState.tryStackCardOnTarget('burger_01', 'bread_01'), isFalse);
    expect(tableState.tryStackCardOnTarget('bread_01', 'burger_01'), isFalse);
    expect(tableState.stackCount, 0);
  });

  test('burger_01 cannot activate Tava processing', () {
    final stackId = createExactBurgerStack();
    resolveStack(stackId);

    expect(
      processingState.canStartPattyCooking(
        tableState: tableState,
        equipmentCardId: 'pan_01',
        inputCardId: 'burger_01',
      ),
      isFalse,
    );
  });

  test('detaching and reordering a cooked stack can resolve the recipe', () {
    placePanOnTable();
    expect(startPattyCooking(), isTrue);
    finishPattyCooking();
    tableState.commitKitchenTablePlacement('bread_01', grid.origin);
    tableState.tryStackCardOnTarget('cheese_01', 'bread_01');
    tableState.tryStackCardOnTarget('patty_01', 'bread_01');

    tableState.beginCardDrag('patty_01');
    tableState.commitKitchenTablePlacement(
      'patty_01',
      grid.snap(grid.origin + const Offset(128, 64)),
    );
    tableState.beginCardDrag('cheese_01');
    tableState.commitKitchenTablePlacement(
      'cheese_01',
      grid.snap(grid.origin + const Offset(192, 64)),
    );
    expect(tableState.tryStackCardOnTarget('patty_01', 'bread_01'), isTrue);
    expect(tableState.tryStackCardOnTarget('cheese_01', 'bread_01'), isTrue);
    final correctedStackId = tableState.stackForCard('bread_01')!.id;

    expect(tableState.orderedStackMembers(correctedStackId), [
      'bread_01',
      'patty_01',
      'cheese_01',
    ]);
    expect(resolveStack(correctedStackId), isNotNull);
  });

  test(
    'an invalid final-card drop restores state without creating a burger',
    () {
      placePanOnTable();
      expect(startPattyCooking(), isTrue);
      finishPattyCooking();
      tableState.commitKitchenTablePlacement('bread_01', grid.origin);
      tableState.tryStackCardOnTarget('patty_01', 'bread_01');
      final stackId = tableState.stackForCard('bread_01')!.id;

      final snapshot = tableState.beginCardDrag('cheese_01');
      tableState.commitKitchenTablePlacement(
        'cheese_01',
        grid.snap(grid.origin + const Offset(256, 96)),
      );
      tableState.restoreCardDragSnapshot(snapshot);

      expect(tableState.orderedStackMembers(stackId), ['bread_01', 'patty_01']);
      expect(tableState.isInHand('cheese_01'), isTrue);
      expect(
        tableState.definitions.any((card) => card.id == 'burger_01'),
        isFalse,
      );
    },
  );

  test('all registered cards retain exactly one authoritative zone', () {
    final stackId = createExactBurgerStack();
    resolveStack(stackId);

    expect(tableState.cardCount, 5);
    expect(tableState.hasConsistentCardLocations(), isTrue);
    for (final definition in tableState.definitions) {
      expect(tableState.placementFor(definition.id).zone, isNotNull);
    }
  });

  test('consumed ingredients are absent from the active render order', () {
    final stackId = createExactBurgerStack();
    resolveStack(stackId);
    final activeIds = tableState.tableCardIdsInRenderOrder;

    expect(activeIds, containsAll(['pan_01', 'burger_01']));
    expect(activeIds, isNot(contains('bread_01')));
    expect(activeIds, isNot(contains('patty_01')));
    expect(activeIds, isNot(contains('cheese_01')));
  });
}
