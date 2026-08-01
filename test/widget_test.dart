import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:son_siparis/game/components/game_card_component.dart';
import 'package:son_siparis/game/components/main_menu_component.dart';
import 'package:son_siparis/game/components/recipe_book_component.dart';
import 'package:son_siparis/game/components/shift_results_component.dart';
import 'package:son_siparis/game/components/tutorial_overlay_component.dart';
import 'package:son_siparis/game/components/upgrade_selection_component.dart';
import 'package:son_siparis/game/data/prototype_card_definitions.dart';
import 'package:son_siparis/game/data/prototype_customer_definitions.dart';
import 'package:son_siparis/game/data/prototype_processing_definitions.dart';
import 'package:son_siparis/game/data/prototype_recipe_definitions.dart';
import 'package:son_siparis/game/data/prototype_upgrade_definitions.dart';
import 'package:son_siparis/game/game_layout.dart';
import 'package:son_siparis/game/kitchen_grid.dart';
import 'package:son_siparis/game/models/app_screen.dart';
import 'package:son_siparis/game/models/card_definition.dart';
import 'package:son_siparis/game/models/order_state.dart';
import 'package:son_siparis/game/models/processing_definition.dart';
import 'package:son_siparis/game/models/processing_job.dart';
import 'package:son_siparis/game/models/shift_phase.dart';
import 'package:son_siparis/game/models/shift_moment.dart';
import 'package:son_siparis/game/models/tutorial_status.dart';
import 'package:son_siparis/game/models/upgrade_id.dart';
import 'package:son_siparis/game/son_siparis_game.dart';
import 'package:son_siparis/game/state/equipment_processing_state.dart';
import 'package:son_siparis/game/state/game_flow_controller.dart';
import 'package:son_siparis/game/state/kitchen_table_state.dart';
import 'package:son_siparis/game/state/order_system.dart';
import 'package:son_siparis/game/state/shift_state.dart';
import 'package:son_siparis/game/state/recipe_discovery_state.dart';
import 'package:son_siparis/game/state/shift_moment_tracker.dart';
import 'package:son_siparis/game/state/tutorial_state.dart';
import 'package:son_siparis/game/state/upgrade_state.dart';
import 'package:son_siparis/game/systems/order_result_generator.dart';
import 'package:son_siparis/game/systems/recipe_resolver.dart';
import 'package:son_siparis/game/systems/stack_layout.dart';
import 'package:son_siparis/game/systems/stack_target_resolver.dart';
import 'package:son_siparis/main.dart';

class TestKitchen {
  TestKitchen()
    : grid = KitchenGrid(
        tableBounds: GameLayout.kitchenTableBounds,
        cardSize: GameLayout.cardSize,
        spacing: GameLayout.kitchenGridSpacing,
        padding: GameLayout.kitchenGridPadding,
      ),
      processing = EquipmentProcessingState(
        processingDurationSeconds: GameLayout.processingDurationSeconds,
      ) {
    final stackLayout = StackLayout(
      cardSize: GameLayout.cardSize,
      paddedTableBounds: grid.paddedTableBounds,
      gridOrigin: grid.origin,
      gridSpacing: grid.spacing,
      levelOffset: GameLayout.stackLevelOffset,
    );
    table = KitchenTableState(
      definitions: prototypeCardDefinitions,
      initialHandPositions: GameLayout.initialHandCardPositions,
      initialEquipmentTablePositions: GameLayout.initialEquipmentTablePositions,
      stackLayout: stackLayout,
    );
  }

  final KitchenGrid grid;
  final EquipmentProcessingState processing;
  late final KitchenTableState table;
  final RecipeResolver recipes = RecipeResolver(
    recipes: prototypeRecipeDefinitions,
  );

  Offset get basePosition => grid.origin;

  String equipmentIdFor(CardType type) => switch (type) {
    CardType.pan => 'pan_01',
    CardType.knife => 'knife_01',
    CardType.fryer => 'fryer_01',
    _ => throw ArgumentError.value(type, 'type'),
  };

  bool start(ProcessingDefinition definition, {double? durationSeconds}) {
    final equipmentId = equipmentIdFor(definition.equipmentType);
    return processing.tryStartProcessing(
      tableState: table,
      equipmentCardId: equipmentId,
      inputCardId: definition.outputDefinition.id,
      attachedInputPosition:
          GameLayout.initialEquipmentTablePositions[equipmentId]!,
      definition: definition,
      durationSeconds: durationSeconds,
    );
  }

  ProcessingJob finish(ProcessingDefinition definition) {
    final equipmentId = equipmentIdFor(definition.equipmentType);
    final job = processing.activeJobForEquipment(equipmentId)!;
    final completed = processing.advanceAll(job.totalDurationSeconds);
    final result = completed.singleWhere(
      (candidate) => candidate.equipmentCardId == equipmentId,
    );
    table.completeProcessedCard(
      cardId: result.inputCardId,
      completedDefinition: definition.outputDefinition,
      outputPosition: basePosition,
    );
    if (definition.outputDefinition.type == CardType.crispyFries) {
      table.recordResultLineage(
        resultCardId: result.inputCardId,
        sourceCardIds: [result.inputCardId],
      );
    }
    return result;
  }

  void makeCookedPatty() {
    table.markCardProcessing('patty_01', basePosition);
    table.completeProcessedCard(
      cardId: 'patty_01',
      completedDefinition: cookedPattyCardDefinition,
      outputPosition: basePosition,
    );
  }

  void makeSlicedTomato() {
    table.markCardProcessing('tomato_01', basePosition);
    table.completeProcessedCard(
      cardId: 'tomato_01',
      completedDefinition: slicedTomatoCardDefinition,
      outputPosition: basePosition,
    );
  }

  String stack(List<String> orderedIds) {
    table.commitKitchenTablePlacement(orderedIds.first, basePosition);
    var targetId = orderedIds.first;
    for (final cardId in orderedIds.skip(1)) {
      expect(table.tryStackCardOnTarget(cardId, targetId), isTrue);
      targetId = cardId;
    }
    return table.stackForCard(targetId)!.id;
  }

  String resolve(List<String> orderedIds) {
    final stackId = stack(orderedIds);
    final recipe = recipes.resolve(
      orderedIds.map((id) => table.definitionFor(id).type),
    );
    expect(recipe, isNotNull);
    return table
        .tryResolveRecipeStack(stackId: stackId, recipe: recipe!)!
        .resultCardId;
  }

  String makeClassicResult() {
    makeCookedPatty();
    return resolve(['bread_01', 'patty_01', 'cheese_01']);
  }

  String makeDeluxeResult() {
    makeCookedPatty();
    makeSlicedTomato();
    return resolve(['bread_01', 'patty_01', 'tomato_01', 'cheese_01']);
  }

  String makeSpicyResult() {
    makeCookedPatty();
    return resolve(['bread_01', 'patty_01', 'hot_sauce_01', 'cheese_01']);
  }
}

OrderSystem threeCustomers({Iterable<int> sequence = const [0, 0, 0]}) =>
    OrderSystem(
      customerDefinitions: prototypeCustomerDefinitions,
      orderGenerator: OrderResultGenerator(
        source: SequenceOrderResultSource(sequence),
      ),
    );

OrderSystem ordersWithSingleRequestedResult(CardType requestedResultType) {
  final orderSystem = threeCustomers();
  final otherTypes = CardType.values
      .where(
        (type) =>
            type == CardType.classicBurger ||
            type == CardType.deluxeBurger ||
            type == CardType.spicyBurger ||
            type == CardType.crispyFries,
      )
      .where((type) => type != requestedResultType)
      .toList(growable: false);
  for (final entry in orderSystem.slots.indexed) {
    final requestedType = entry.$1 == 0
        ? requestedResultType
        : otherTypes[entry.$1 - 1];
    entry.$2.beginOrder(
      OrderState(
        id: 'acceptance_${entry.$1}',
        requestedResultType: requestedType,
        status: OrderStatus.active,
      ),
      totalPatienceSeconds: entry.$2.definition.basePatienceSeconds,
    );
  }
  return orderSystem;
}

void main() {
  testWidgets('Son Sipariş app can be created', (tester) async {
    await tester.pumpWidget(const SonSiparisApp());
    expect(find.byType(SonSiparisApp), findsOneWidget);
  });

  testWidgets(
    'production shell keeps gameplay card dragging enabled across screens',
    (tester) async {
      final originalPhysicalSize = tester.view.physicalSize;
      final originalDevicePixelRatio = tester.view.devicePixelRatio;
      final originalPadding = tester.view.padding;
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 60, bottom: 60);
      addTearDown(() {
        tester.view.physicalSize = originalPhysicalSize;
        tester.view.devicePixelRatio = originalDevicePixelRatio;
        tester.view.padding = originalPadding;
      });

      final game = SonSiparisGame();
      const gameOffset = Offset(320 / 3, 60);
      const gameScale = 4 / 3;
      Offset screenPosition(Offset worldPosition) =>
          gameOffset + (worldPosition * gameScale);
      Future<void> dragAcrossFrames(Offset start, Offset end) async {
        final gesture = await tester.startGesture(start);
        for (var step = 1; step <= 6; step++) {
          await gesture.moveTo(Offset.lerp(start, end, step / 6)!);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
      }

      Offset supplyCenter(String supplyId) => screenPosition(
        game.pantryState.slotFor(supplyId).position + const Offset(52, 39),
      );
      List<String> activeOfType(CardType type) => game
          .tableState
          .tableCardIdsInRenderOrder
          .where((id) => game.tableState.definitionFor(id).type == type)
          .toList();

      await tester.pumpWidget(SonSiparisApp(game: game));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(screenPosition(const Offset(640, 506)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(screenPosition(const Offset(1035, 125)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(game.flow.screen, AppScreen.gameplay);
      expect(game.isGameplayInputAllowed, isTrue);
      expect(
        game.world.children
            .whereType<MainMenuComponent>()
            .single
            .containsLocalPoint(Vector2.zero()),
        isFalse,
      );
      for (final card in game.world.children.whereType<GameCardComponent>()) {
        expect(card.isInteractionLocked, isFalse);
      }

      final breadHand = supplyCenter('bread_01');
      final breadTable = screenPosition(const Offset(312, 280));
      final invalidBreadTarget = screenPosition(const Offset(640, 632));
      await dragAcrossFrames(breadHand, invalidBreadTarget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(activeOfType(CardType.bread), isEmpty);
      expect(game.pantryState.isAvailable('bread_01'), isTrue);

      await dragAcrossFrames(breadHand, breadTable);
      await tester.pump(const Duration(milliseconds: 100));

      final breadId = activeOfType(CardType.bread).single;
      expect(game.tableState.isOnKitchenTable(breadId), isTrue);
      final firstBreadPosition = game.tableState
          .placementFor(breadId)
          .currentValidPosition;
      final breadPlacedCenter = screenPosition(
        firstBreadPosition + const Offset(52, 39),
      );
      final movedBreadTable = screenPosition(const Offset(584, 420));
      await dragAcrossFrames(breadPlacedCenter, movedBreadTable);
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.tableState.isOnKitchenTable(breadId), isTrue);
      expect(
        game.tableState.placementFor(breadId).currentValidPosition,
        isNot(firstBreadPosition),
      );

      await tester.tapAt(screenPosition(const Offset(1219, 45)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.shiftState.phase, ShiftPhase.paused);
      final pattyHand = supplyCenter('patty_01');
      final pattyTable = screenPosition(const Offset(520, 360));
      await dragAcrossFrames(pattyHand, pattyTable);
      await tester.pump(const Duration(milliseconds: 100));
      expect(activeOfType(CardType.patty), isEmpty);

      await tester.tapAt(screenPosition(const Offset(640, 410)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.shiftState.phase, ShiftPhase.active);
      expect(game.isGameplayInputAllowed, isTrue);
      await dragAcrossFrames(pattyHand, pattyTable);
      await tester.pump(const Duration(milliseconds: 100));
      final pattyId = activeOfType(CardType.patty).single;
      expect(game.tableState.isOnKitchenTable(pattyId), isTrue);

      game.update(GameLayout.shiftDurationSeconds);
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.flow.screen, AppScreen.shiftResults);
      expect(
        game.world.children
            .whereType<ShiftResultsComponent>()
            .single
            .containsLocalPoint(Vector2.zero()),
        isTrue,
      );
      await dragAcrossFrames(breadHand, breadTable);
      await tester.pump(const Duration(milliseconds: 100));
      expect(activeOfType(CardType.bread), isEmpty);

      await tester.tapAt(screenPosition(const Offset(640, 572)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.flow.screen, AppScreen.upgradeSelection);
      await tester.tapAt(screenPosition(const Offset(253, 340)));
      await tester.tapAt(screenPosition(const Offset(640, 608)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.flow.screen, AppScreen.gameplay);
      expect(game.isGameplayInputAllowed, isTrue);
      expect(game.processingState.activeJobs, isEmpty);
      expect(
        game.world.children
            .whereType<UpgradeSelectionComponent>()
            .single
            .containsLocalPoint(Vector2.zero()),
        isFalse,
      );
      for (final card in game.world.children.whereType<GameCardComponent>()) {
        expect(card.isInteractionLocked, isFalse);
      }

      await dragAcrossFrames(breadHand, breadTable);
      await tester.pump(const Duration(milliseconds: 100));
      expect(activeOfType(CardType.bread), hasLength(1));
    },
  );

  test(
    'six ingredients and three equipment instances use unique stable IDs',
    () {
      expect(prototypeCycleIngredientDefinitions, hasLength(6));
      expect(prototypeEquipmentDefinitions, hasLength(3));
      expect(
        prototypeCardDefinitions.map((card) => card.id).toSet(),
        hasLength(9),
      );
    },
  );

  test(
    'equipment begins pre-placed while all ingredients begin in the hand',
    () {
      final kitchen = TestKitchen();
      for (final ingredient in prototypeCycleIngredientDefinitions) {
        expect(kitchen.table.isInHand(ingredient.id), isTrue);
      }
      for (final equipment in prototypeEquipmentDefinitions) {
        expect(kitchen.table.isOnKitchenTable(equipment.id), isTrue);
        expect(
          kitchen.table.placementFor(equipment.id).currentValidPosition,
          GameLayout.initialEquipmentTablePositions[equipment.id],
        );
      }
      expect(kitchen.table.hasConsistentCardLocations(), isTrue);
    },
  );

  test('tomato plus knife produces sliced tomato with the stable ID', () {
    final kitchen = TestKitchen();
    expect(kitchen.start(knifeProcessingDefinition), isTrue);
    final job = kitchen.finish(knifeProcessingDefinition);
    expect(job.action, ProcessingAction.sliceTomato);
    expect(
      kitchen.table.definitionFor('tomato_01').type,
      CardType.slicedTomato,
    );
    expect(kitchen.table.isOnKitchenTable('tomato_01'), isTrue);
  });

  test('potato plus fryer produces directly servable crispy fries', () {
    final kitchen = TestKitchen();
    expect(kitchen.start(fryerProcessingDefinition), isTrue);
    kitchen.finish(fryerProcessingDefinition);
    expect(kitchen.table.definitionFor('potato_01').type, CardType.crispyFries);
    expect(
      kitchen.table.definitionFor('potato_01').category,
      CardCategory.result,
    );
    expect(kitchen.table.sourceCardIdsForResult('potato_01'), ['potato_01']);
  });

  test(
    'patty plus pan preserves its ID and keeps Fast Pan duration scoped',
    () {
      final kitchen = TestKitchen();
      final upgrades = UpgradeState();
      upgrades.increase(prototypeUpgradeDefinitions.first);
      expect(
        kitchen.start(
          panProcessingDefinition,
          durationSeconds: upgrades.effectivePanDuration(),
        ),
        isTrue,
      );
      expect(kitchen.processing.activeJob!.totalDurationSeconds, 2.25);
      kitchen.finish(panProcessingDefinition);
      expect(
        kitchen.table.definitionFor('patty_01').type,
        CardType.cookedPatty,
      );
      expect(kitchen.table.definitionFor('patty_01').id, 'patty_01');
      expect(knifeProcessingDefinition.baseDurationSeconds, 1.5);
      expect(fryerProcessingDefinition.baseDurationSeconds, 2.5);
    },
  );

  test(
    'different equipment jobs run concurrently but one equipment has one job',
    () {
      final kitchen = TestKitchen();
      expect(kitchen.start(panProcessingDefinition), isTrue);
      expect(kitchen.start(knifeProcessingDefinition), isTrue);
      expect(kitchen.start(fryerProcessingDefinition), isTrue);
      expect(kitchen.processing.activeJobs, hasLength(3));
      expect(kitchen.start(panProcessingDefinition), isFalse);
      expect(kitchen.processing.isEquipmentAvailable('knife_01'), isFalse);
    },
  );

  test('pause freezes every active processing job', () {
    final kitchen = TestKitchen();
    final shift = ShiftState();
    kitchen.start(panProcessingDefinition);
    kitchen.start(knifeProcessingDefinition);
    final before = kitchen.processing.activeJobs
        .map((job) => job.elapsedSeconds)
        .toList();
    shift.pause();
    expect(
      kitchen.processing.advanceForShift(
        deltaSeconds: 4,
        shiftPhase: shift.phase,
      ),
      isEmpty,
    );
    expect(
      kitchen.processing.activeJobs.map((job) => job.elapsedSeconds),
      before,
    );
    expect(shift.phase, ShiftPhase.paused);
  });

  test(
    'strict classic, deluxe, and spicy recipes resolve with source lineage',
    () {
      final classic = TestKitchen();
      final classicResult = classic.makeClassicResult();
      expect(classicResult, startsWith('result_classic_burger_'));
      expect(classic.table.sourceCardIdsForResult(classicResult), [
        'bread_01',
        'patty_01',
        'cheese_01',
      ]);

      final deluxe = TestKitchen();
      final deluxeResult = deluxe.makeDeluxeResult();
      expect(deluxeResult, startsWith('result_deluxe_burger_'));
      expect(deluxe.table.sourceCardIdsForResult(deluxeResult), [
        'bread_01',
        'patty_01',
        'tomato_01',
        'cheese_01',
      ]);

      final spicy = TestKitchen();
      final spicyResult = spicy.makeSpicyResult();
      expect(spicyResult, startsWith('result_spicy_burger_'));
      expect(spicy.table.sourceCardIdsForResult(spicyResult), [
        'bread_01',
        'patty_01',
        'hot_sauce_01',
        'cheese_01',
      ]);
    },
  );

  test('recipe prefixes and wrong recipe orders never resolve', () {
    final prefix = TestKitchen();
    prefix.makeCookedPatty();
    prefix.makeSlicedTomato();
    final deluxePrefix = prefix.stack(['bread_01', 'patty_01', 'tomato_01']);
    expect(
      prefix.recipes.resolve(
        prefix.table
            .orderedStackMembers(deluxePrefix)
            .map((id) => prefix.table.definitionFor(id).type),
      ),
      isNull,
    );

    final wrong = TestKitchen();
    wrong.makeCookedPatty();
    final wrongStack = wrong.stack(['bread_01', 'cheese_01', 'patty_01']);
    expect(
      wrong.recipes.resolve(
        wrong.table
            .orderedStackMembers(wrongStack)
            .map((id) => wrong.table.definitionFor(id).type),
      ),
      isNull,
    );
  });

  test('three customers start active with independent patience timers', () {
    final orders = threeCustomers();
    expect(orders.slots, hasLength(3));
    expect(orders.activeSlots, hasLength(3));
    expect(orders.slots.map((slot) => slot.patience.totalSeconds), [
      24,
      18,
      28,
    ]);
    orders.advancePatience(19);
    expect(orders.slots[1].patience.isExpired, isTrue);
    expect(orders.slots[0].patience.isExpired, isFalse);
    expect(orders.slots[2].patience.isExpired, isFalse);
  });

  test('order generation is deterministic and avoids active duplicates', () {
    final first = threeCustomers(sequence: const [0, 0, 0]);
    final second = threeCustomers(sequence: const [0, 0, 0]);
    final firstOrders = first.slots
        .map((slot) => slot.order!.requestedResultType)
        .toList();
    final secondOrders = second.slots
        .map((slot) => slot.order!.requestedResultType)
        .toList();
    expect(firstOrders, secondOrders);
    expect(firstOrders.toSet(), hasLength(3));
  });

  test(
    'service matches the requested result and chooses the most urgent match',
    () {
      final kitchen = TestKitchen();
      final resultId = kitchen.makeClassicResult();
      final orders = threeCustomers();
      for (final slot in orders.slots.take(2)) {
        slot.beginOrder(
          OrderState(
            id: 'manual_${slot.definition.id}',
            requestedResultType: CardType.classicBurger,
            status: OrderStatus.active,
          ),
          totalPatienceSeconds: slot.definition.basePatienceSeconds,
        );
      }
      orders.slots[0].advancePatience(4);
      orders.slots[1].advancePatience(15);
      final shift = ShiftState();
      final completion = orders.tryServe(
        cardId: resultId,
        tableState: kitchen.table,
        shiftState: shift,
        rewardCoins: 10,
        enterShiftFeedback: false,
      );
      expect(completion?.customerId, orders.slots[1].definition.id);
      expect(orders.slots[0].hasActiveOrder, isTrue);
      expect(orders.slots[1].hasFeedback, isTrue);
      expect(kitchen.table.isServed(resultId), isTrue);
      expect(shift.completedOrders, 1);
    },
  );

  test(
    'non-requested results are rejected without consuming cards or combo',
    () {
      final kitchen = TestKitchen();
      final resultId = kitchen.makeSpicyResult();
      final orders = threeCustomers(sequence: const [0, 0, 1]);
      final shift = ShiftState();
      final completion = orders.tryServe(
        cardId: resultId,
        tableState: kitchen.table,
        shiftState: shift,
        rewardCoins: 15,
        enterShiftFeedback: false,
      );
      expect(completion, isNull);
      expect(kitchen.table.isOnKitchenTable(resultId), isTrue);
      expect(shift.currentCombo, 0);
    },
  );

  test('per-result rewards respect Double Cheese and exclude fries', () {
    final upgrades = UpgradeState();
    expect(upgrades.effectiveRewardFor(classicBurgerCardDefinition), 10);
    expect(upgrades.effectiveRewardFor(deluxeBurgerCardDefinition), 15);
    expect(upgrades.effectiveRewardFor(spicyBurgerCardDefinition), 15);
    expect(upgrades.effectiveRewardFor(crispyFriesCardDefinition), 8);
    upgrades.increase(prototypeUpgradeDefinitions[1]);
    expect(upgrades.effectiveRewardFor(classicBurgerCardDefinition), 15);
    expect(upgrades.effectiveRewardFor(deluxeBurgerCardDefinition), 20);
    expect(upgrades.effectiveRewardFor(spicyBurgerCardDefinition), 20);
    expect(upgrades.effectiveRewardFor(crispyFriesCardDefinition), 8);
  });

  test(
    'successful service applies each burger reward to wallet and earnings',
    () {
      final cases = <(String Function(TestKitchen), CardType, int)>[
        ((kitchen) => kitchen.makeClassicResult(), CardType.classicBurger, 10),
        ((kitchen) => kitchen.makeDeluxeResult(), CardType.deluxeBurger, 15),
        ((kitchen) => kitchen.makeSpicyResult(), CardType.spicyBurger, 15),
      ];
      for (final serviceCase in cases) {
        final kitchen = TestKitchen();
        final resultId = serviceCase.$1(kitchen);
        final orders = threeCustomers();
        orders.slots.first.beginOrder(
          OrderState(
            id: 'reward_${serviceCase.$2.name}',
            requestedResultType: serviceCase.$2,
            status: OrderStatus.active,
          ),
          totalPatienceSeconds: regularCustomerDefinition.basePatienceSeconds,
        );
        final shift = ShiftState();
        final completion = orders.tryServe(
          cardId: resultId,
          tableState: kitchen.table,
          shiftState: shift,
          rewardCoins: serviceCase.$3,
          enterShiftFeedback: false,
        );
        expect(completion?.rewardCoins, serviceCase.$3);
        expect(shift.shiftEarnings, serviceCase.$3);
        expect(
          shift.walletCoins,
          GameLayout.initialWalletCoins + serviceCase.$3,
        );
      }
    },
  );

  test(
    'successful service leaves sources consumed and preserves other work',
    () {
      final kitchen = TestKitchen();
      final resultId = kitchen.makeClassicResult();
      kitchen.start(knifeProcessingDefinition);
      kitchen.table.markCardServed(resultId);
      for (final cardId in ['bread_01', 'patty_01', 'cheese_01']) {
        expect(kitchen.table.isConsumed(cardId), isTrue);
      }
      expect(kitchen.processing.activeJobForEquipment('knife_01'), isNotNull);
      expect(kitchen.table.isProcessing('tomato_01'), isTrue);
      expect(kitchen.table.hasConsistentCardLocations(), isTrue);
    },
  );

  test('crispy fries remain served without creating a potato', () {
    final kitchen = TestKitchen();
    kitchen.start(fryerProcessingDefinition);
    kitchen.finish(fryerProcessingDefinition);
    kitchen.table.markCardServed('potato_01');
    expect(kitchen.table.definitionFor('potato_01').type, CardType.crispyFries);
    expect(kitchen.table.isServed('potato_01'), isTrue);
    expect(kitchen.table.isInHand('bread_01'), isTrue);
  });

  test(
    'one customer failure leaves kitchen work intact and resets combo only',
    () {
      final kitchen = TestKitchen();
      kitchen.start(knifeProcessingDefinition);
      kitchen.table.commitKitchenTablePlacement(
        'bread_01',
        kitchen.basePosition,
      );
      final orders = threeCustomers();
      final shift = ShiftState()..recordSuccessfulService(enterFeedback: false);
      final failed = orders.failCustomer(orders.slots[1].definition.id);
      final recorded = shift.recordMissedOrder(enterFeedback: false);
      expect(failed, isTrue);
      expect(recorded, isTrue);
      expect(orders.slots[0].hasActiveOrder, isTrue);
      expect(orders.slots[2].hasActiveOrder, isTrue);
      expect(kitchen.table.isOnKitchenTable('bread_01'), isTrue);
      expect(kitchen.processing.activeJobForEquipment('knife_01'), isNotNull);
      expect(shift.currentCombo, 0);
      expect(shift.missedOrders, 1);
    },
  );

  test('customer feedback refills only its own slot', () {
    final orders = threeCustomers();
    final failedSlot = orders.slots[1];
    final untouchedOrderId = orders.slots[0].order!.id;
    orders.failCustomer(failedSlot.definition.id);
    final refills = orders.advanceFeedback(
      GameLayout.failureFeedbackDurationSeconds,
    );
    expect(refills.single.definition.id, failedSlot.definition.id);
    orders.refillCustomer(
      failedSlot.definition.id,
      totalPatienceSeconds: failedSlot.definition.basePatienceSeconds,
    );
    expect(failedSlot.hasActiveOrder, isTrue);
    expect(orders.slots[0].order!.id, untouchedOrderId);
  });

  test(
    'Cool-Headed applies a single next-refill bonus with customer base patience',
    () {
      final upgrades = UpgradeState();
      upgrades.increase(prototypeUpgradeDefinitions[2]);
      expect(
        upgrades.nextOrderPatienceDuration(
          hasPendingBonus: true,
          baseDurationSeconds: regularCustomerDefinition.basePatienceSeconds,
        ),
        28,
      );
      expect(
        upgrades.nextOrderPatienceDuration(
          hasPendingBonus: false,
          baseDurationSeconds: impatientCustomerDefinition.basePatienceSeconds,
        ),
        18,
      );
    },
  );

  test(
    'new shift state clears temporary jobs and preserves permanent upgrade levels',
    () {
      final kitchen = TestKitchen();
      kitchen.start(panProcessingDefinition);
      kitchen.table.resetPrototypePreparationState(
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
      kitchen.processing.clearActiveJob();
      final upgrades = UpgradeState();
      upgrades.increase(prototypeUpgradeDefinitions.first);
      expect(kitchen.processing.activeJobs, isEmpty);
      expect(kitchen.table.definitionFor('patty_01').type, CardType.patty);
      expect(upgrades.levelFor(UpgradeId.fastPan), 1);
    },
  );

  test(
    'flow remains main menu to gameplay to results to upgrade to next day',
    () {
      final game = SonSiparisGame();
      expect(game.flow.screen, AppScreen.mainMenu);
      game.update(10);
      expect(game.shiftState.remainingShiftSeconds, 90);
      final flow = GameFlowController();
      expect(flow.startShift(), isTrue);
      flow.showResults();
      expect(flow.showUpgradeSelection(), isTrue);
      expect(flow.selectUpgrade(prototypeUpgradeDefinitions.first), isTrue);
      expect(flow.confirmUpgrade(), isNotNull);
      expect(flow.progression.currentDay, 2);
      expect(flow.progression.upgrades.levelFor(UpgradeId.fastPan), 1);
      expect(flow.confirmUpgrade(), isNull);
      expect(flow.progression.currentDay, 2);
    },
  );

  test('all active card states remain in one authoritative zone', () {
    final kitchen = TestKitchen();
    kitchen.start(panProcessingDefinition);
    kitchen.start(knifeProcessingDefinition);
    expect(kitchen.table.hasConsistentCardLocations(), isTrue);
    kitchen.processing.advanceAll(1);
    expect(kitchen.table.hasConsistentCardLocations(), isTrue);
  });

  test('fixed virtual shell constants preserve the landscape design space', () {
    expect(GameLayout.designWidth, 1280);
    expect(GameLayout.designHeight, 720);
    expect(GameLayout.kitchenTableBounds.width, greaterThan(1000));
    expect(GameLayout.handTop, greaterThan(GameLayout.serviceTop));
  });

  test('free placement commits one card at a snapped table position', () {
    final kitchen = TestKitchen();
    final target = kitchen.grid.snap(
      kitchen.basePosition + const Offset(141, 67),
    );
    final snapshot = kitchen.table.beginCardDrag('bread_01');
    kitchen.table.commitKitchenTablePlacement('bread_01', target);

    expect(snapshot.cardId, 'bread_01');
    expect(kitchen.table.isOnKitchenTable('bread_01'), isTrue);
    expect(kitchen.table.placementFor('bread_01').currentValidPosition, target);
    expect(kitchen.grid.isAligned(target), isTrue);
  });

  test('invalid-drop rollback restores the original hand placement', () {
    final kitchen = TestKitchen();
    final original = kitchen.table.placementFor('bread_01');
    final snapshot = kitchen.table.beginCardDrag('bread_01');
    kitchen.table.commitKitchenTablePlacement(
      'bread_01',
      kitchen.grid.snap(kitchen.basePosition + const Offset(192, 96)),
    );
    kitchen.table.restoreCardDragSnapshot(snapshot);

    expect(kitchen.table.placementFor('bread_01'), original);
    expect(kitchen.table.isInHand('bread_01'), isTrue);
  });

  test('grid snapping clamps card bounds inside the padded kitchen table', () {
    final kitchen = TestKitchen();
    final snapped = kitchen.grid.snap(
      Offset(
        kitchen.grid.validCardPositionBounds.right + 48,
        kitchen.grid.validCardPositionBounds.bottom + 48,
      ),
    );

    expect(kitchen.grid.isAligned(snapped), isTrue);
    expect(kitchen.grid.isCardPositionInsidePaddedArea(snapped), isTrue);
    expect(kitchen.grid.snap(snapped), snapped);
  });

  test(
    'ingredient stacks retain order, detach correctly, and rollback exactly',
    () {
      final kitchen = TestKitchen();
      final stackId = kitchen.stack(['bread_01', 'patty_01', 'cheese_01']);
      final snapshot = kitchen.table.beginCardDrag('patty_01');

      expect(kitchen.table.orderedStackMembers(stackId), [
        'bread_01',
        'cheese_01',
      ]);
      expect(kitchen.table.isOnKitchenTable('patty_01'), isTrue);

      kitchen.table.restoreCardDragSnapshot(snapshot);
      expect(kitchen.table.orderedStackMembers(stackId), [
        'bread_01',
        'patty_01',
        'cheese_01',
      ]);
    },
  );

  test('stack targets choose the topmost ingredient and reject equipment', () {
    final kitchen = TestKitchen();
    kitchen.table.commitKitchenTablePlacement('bread_01', kitchen.basePosition);
    kitchen.table.commitKitchenTablePlacement('patty_01', kitchen.basePosition);
    final resolver = StackTargetResolver(cardSize: GameLayout.cardSize);

    expect(
      resolver
          .resolve(
            draggedCardId: 'cheese_01',
            draggedCardPosition: kitchen.basePosition,
            tableState: kitchen.table,
          )
          ?.cardId,
      'patty_01',
    );
    expect(
      resolver.resolve(
        draggedCardId: 'pan_01',
        draggedCardPosition: kitchen.basePosition,
        tableState: kitchen.table,
      ),
      isNull,
    );
  });

  test('Tava rejects invalid inputs and cannot be restarted while busy', () {
    final kitchen = TestKitchen();
    expect(
      kitchen.processing.canStartProcessing(
        tableState: kitchen.table,
        equipmentCardId: 'pan_01',
        inputCardId: 'bread_01',
        definition: panProcessingDefinition,
      ),
      isFalse,
    );
    expect(kitchen.start(panProcessingDefinition), isTrue);
    expect(kitchen.start(panProcessingDefinition), isFalse);
    expect(kitchen.processing.isCardLocked('pan_01'), isTrue);
    expect(kitchen.processing.isCardLocked('patty_01'), isTrue);
  });

  test(
    'processing progress and output remain deterministic and grid-snapped',
    () {
      final kitchen = TestKitchen();
      expect(kitchen.start(panProcessingDefinition), isTrue);
      kitchen.processing.advanceAll(1.25);
      expect(
        kitchen.processing.activeJobForEquipment('pan_01')!.progress,
        closeTo(1.25 / 3, .0001),
      );

      kitchen.finish(panProcessingDefinition);
      final output = kitchen.table
          .placementFor('patty_01')
          .currentValidPosition;
      expect(
        kitchen.table.definitionFor('patty_01').type,
        CardType.cookedPatty,
      );
      expect(kitchen.grid.isAligned(output), isTrue);
      expect(kitchen.grid.isCardPositionInsidePaddedArea(output), isTrue);
      expect(kitchen.processing.isEquipmentAvailable('pan_01'), isTrue);
    },
  );

  test('paused shift time and customer patience do not advance', () {
    final shift = ShiftState();
    final orders = threeCustomers();
    shift.advanceActiveTime(3);
    orders.advancePatience(3);
    final remainingShift = shift.remainingShiftSeconds;
    final regularPatience = orders.slots.first.patience;

    expect(shift.pause(), isTrue);
    expect(shift.advanceActiveTime(10), isFalse);
    if (shift.phase == ShiftPhase.active) orders.advancePatience(10);

    expect(shift.remainingShiftSeconds, remainingShift);
    expect(
      orders.slots.first.patience.elapsedSeconds,
      regularPatience.elapsedSeconds,
    );
    expect(
      orders.slots.first.patience.totalSeconds,
      regularPatience.totalSeconds,
    );
  });

  test('result cards cannot stack or start equipment processing', () {
    final kitchen = TestKitchen();
    final resultId = kitchen.makeClassicResult();

    expect(kitchen.table.tryStackCardOnTarget(resultId, 'tomato_01'), isFalse);
    expect(kitchen.table.tryStackCardOnTarget('tomato_01', resultId), isFalse);
    expect(
      kitchen.processing.canStartProcessing(
        tableState: kitchen.table,
        equipmentCardId: 'pan_01',
        inputCardId: resultId,
        definition: panProcessingDefinition,
      ),
      isFalse,
    );
  });

  test('all three permanent upgrades retain their independent effects', () {
    final upgrades = UpgradeState();
    expect(upgrades.increase(prototypeUpgradeDefinitions[0]), isTrue);
    expect(upgrades.increase(prototypeUpgradeDefinitions[1]), isTrue);
    expect(upgrades.increase(prototypeUpgradeDefinitions[2]), isTrue);

    expect(upgrades.effectivePanDuration(), 2.25);
    expect(upgrades.effectiveRewardFor(classicBurgerCardDefinition), 15);
    expect(
      upgrades.nextOrderPatienceDuration(
        hasPendingBonus: true,
        baseDurationSeconds: impatientCustomerDefinition.basePatienceSeconds,
      ),
      22,
    );
  });

  test('recipe sources stay consumed and never re-enter render order', () {
    final kitchen = TestKitchen();
    final resultId = kitchen.makeClassicResult();
    final activeBeforeService = kitchen.table.tableCardIdsInRenderOrder;

    expect(activeBeforeService, contains(resultId));
    expect(activeBeforeService, isNot(contains('bread_01')));
    expect(activeBeforeService, isNot(contains('patty_01')));
    expect(activeBeforeService, isNot(contains('cheese_01')));
  });

  test('FLOW 1: classic burger serves once without replenishing sources', () {
    final kitchen = TestKitchen();
    expect(kitchen.start(panProcessingDefinition), isTrue);
    kitchen.finish(panProcessingDefinition);
    final resultId = kitchen.resolve(['bread_01', 'patty_01', 'cheese_01']);
    final orders = ordersWithSingleRequestedResult(CardType.classicBurger);
    final shift = ShiftState();

    final completion = orders.tryServe(
      cardId: resultId,
      tableState: kitchen.table,
      shiftState: shift,
      rewardCoins: 10,
      enterShiftFeedback: false,
    );
    expect(completion?.rewardCoins, 10);
    expect(shift.walletCoins, GameLayout.initialWalletCoins + 10);
    expect(kitchen.table.sourceCardIdsForResult(resultId), [
      'bread_01',
      'patty_01',
      'cheese_01',
    ]);
    for (final cardId in ['bread_01', 'patty_01', 'cheese_01']) {
      expect(kitchen.table.isConsumed(cardId), isTrue);
    }
    expect(kitchen.table.isInHand('tomato_01'), isTrue);
  });

  test('FLOW 2: deluxe burger keeps its full consumed lineage', () {
    final kitchen = TestKitchen();
    expect(kitchen.start(panProcessingDefinition), isTrue);
    kitchen.finish(panProcessingDefinition);
    expect(kitchen.start(knifeProcessingDefinition), isTrue);
    kitchen.finish(knifeProcessingDefinition);
    final resultId = kitchen.resolve([
      'bread_01',
      'patty_01',
      'tomato_01',
      'cheese_01',
    ]);
    final orders = ordersWithSingleRequestedResult(CardType.deluxeBurger);
    final shift = ShiftState();

    final completion = orders.tryServe(
      cardId: resultId,
      tableState: kitchen.table,
      shiftState: shift,
      rewardCoins: 15,
      enterShiftFeedback: false,
    );
    expect(completion?.requestedResultType, CardType.deluxeBurger);
    expect(shift.shiftEarnings, 15);
    expect(kitchen.table.sourceCardIdsForResult(resultId), [
      'bread_01',
      'patty_01',
      'tomato_01',
      'cheese_01',
    ]);
    expect(
      kitchen.table.definitionFor('tomato_01').type,
      CardType.slicedTomato,
    );
    expect(kitchen.table.isConsumed('tomato_01'), isTrue);
    expect(kitchen.table.isInHand('hot_sauce_01'), isTrue);
  });

  test('FLOW 3: spicy burger keeps its exact consumed lineage', () {
    final kitchen = TestKitchen();
    expect(kitchen.start(panProcessingDefinition), isTrue);
    kitchen.finish(panProcessingDefinition);
    final resultId = kitchen.resolve([
      'bread_01',
      'patty_01',
      'hot_sauce_01',
      'cheese_01',
    ]);
    final orders = ordersWithSingleRequestedResult(CardType.spicyBurger);
    final shift = ShiftState();

    final completion = orders.tryServe(
      cardId: resultId,
      tableState: kitchen.table,
      shiftState: shift,
      rewardCoins: 15,
      enterShiftFeedback: false,
    );
    expect(completion?.requestedResultType, CardType.spicyBurger);
    expect(shift.walletCoins, GameLayout.initialWalletCoins + 15);
    expect(kitchen.table.sourceCardIdsForResult(resultId), [
      'bread_01',
      'patty_01',
      'hot_sauce_01',
      'cheese_01',
    ]);
    expect(kitchen.table.isConsumed('hot_sauce_01'), isTrue);
    expect(kitchen.table.isInHand('tomato_01'), isTrue);
  });

  test('FLOW 4: crispy fries serve for eight coins without Double Cheese', () {
    final kitchen = TestKitchen();
    final upgrades = UpgradeState()..increase(prototypeUpgradeDefinitions[1]);
    expect(kitchen.start(fryerProcessingDefinition), isTrue);
    kitchen.finish(fryerProcessingDefinition);
    final orders = ordersWithSingleRequestedResult(CardType.crispyFries);
    final shift = ShiftState();
    final reward = upgrades.effectiveRewardFor(
      kitchen.table.definitionFor('potato_01'),
    );

    final completion = orders.tryServe(
      cardId: 'potato_01',
      tableState: kitchen.table,
      shiftState: shift,
      rewardCoins: reward,
      enterShiftFeedback: false,
    );
    expect(completion?.rewardCoins, 8);
    expect(shift.shiftEarnings, 8);
    expect(kitchen.table.definitionFor('potato_01').type, CardType.crispyFries);
    expect(kitchen.table.isServed('potato_01'), isTrue);
  });

  test(
    'FLOW 5: three equipment jobs complete concurrently without duplicates',
    () {
      final kitchen = TestKitchen();
      expect(kitchen.start(panProcessingDefinition), isTrue);
      expect(kitchen.start(knifeProcessingDefinition), isTrue);
      expect(kitchen.start(fryerProcessingDefinition), isTrue);

      final completed = kitchen.processing.advanceAll(3);
      expect(completed, hasLength(3));
      for (final entry in completed.indexed) {
        final definition = prototypeProcessingDefinitions.singleWhere(
          (candidate) => candidate.action == entry.$2.action,
        );
        final output = kitchen.grid.snap(
          kitchen.basePosition + Offset(entry.$1 * 128, 0),
        );
        kitchen.table.completeProcessedCard(
          cardId: entry.$2.inputCardId,
          completedDefinition: definition.outputDefinition,
          outputPosition: output,
        );
        if (definition.outputDefinition.type == CardType.crispyFries) {
          kitchen.table.recordResultLineage(
            resultCardId: entry.$2.inputCardId,
            sourceCardIds: [entry.$2.inputCardId],
          );
        }
      }

      expect(
        kitchen.table.definitionFor('patty_01').type,
        CardType.cookedPatty,
      );
      expect(
        kitchen.table.definitionFor('tomato_01').type,
        CardType.slicedTomato,
      );
      expect(
        kitchen.table.definitionFor('potato_01').type,
        CardType.crispyFries,
      );
      expect(kitchen.processing.activeJobs, isEmpty);
      expect(kitchen.table.hasConsistentCardLocations(), isTrue);
      expect(
        kitchen.table.definitions.map((definition) => definition.id).toSet(),
        hasLength(kitchen.table.cardCount),
      );
    },
  );

  test('FLOW 6: service chooses only the most urgent matching customer', () {
    final kitchen = TestKitchen();
    final resultId = kitchen.makeClassicResult();
    final orders = threeCustomers();
    for (final entry in orders.slots.indexed) {
      entry.$2.beginOrder(
        OrderState(
          id: 'urgent_${entry.$1}',
          requestedResultType: entry.$1 < 2
              ? CardType.classicBurger
              : CardType.spicyBurger,
          status: OrderStatus.active,
        ),
        totalPatienceSeconds: entry.$2.definition.basePatienceSeconds,
      );
    }
    orders.slots[0].advancePatience(4);
    orders.slots[1].advancePatience(15);
    final shift = ShiftState();

    final completion = orders.tryServe(
      cardId: resultId,
      tableState: kitchen.table,
      shiftState: shift,
      rewardCoins: 10,
      enterShiftFeedback: false,
    );

    expect(completion?.customerId, impatientCustomerDefinition.id);
    expect(orders.slots[0].hasActiveOrder, isTrue);
    expect(orders.slots[1].hasFeedback, isTrue);
    expect(orders.slots[2].hasActiveOrder, isTrue);
    expect(shift.completedOrders, 1);
  });

  test(
    'FLOW 7: one failure preserves unrelated prep and only refills its slot',
    () {
      final kitchen = TestKitchen();
      final preparedClassic = kitchen.makeClassicResult();
      expect(kitchen.start(knifeProcessingDefinition), isTrue);
      final orders = threeCustomers();
      final regularOrderId = orders.slots[0].order!.id;
      final foodieOrderId = orders.slots[2].order!.id;
      final shift = ShiftState()..recordSuccessfulService(enterFeedback: false);

      expect(orders.failCustomer(impatientCustomerDefinition.id), isTrue);
      expect(shift.recordMissedOrder(enterFeedback: false), isTrue);
      final refills = orders.advanceFeedback(
        GameLayout.failureFeedbackDurationSeconds,
      );
      expect(refills.single.definition.id, impatientCustomerDefinition.id);
      orders.refillCustomer(
        impatientCustomerDefinition.id,
        totalPatienceSeconds: impatientCustomerDefinition.basePatienceSeconds,
      );

      expect(kitchen.table.isOnKitchenTable(preparedClassic), isTrue);
      expect(kitchen.processing.activeJobForEquipment('knife_01'), isNotNull);
      expect(kitchen.table.isProcessing('tomato_01'), isTrue);
      expect(orders.slots[0].order!.id, regularOrderId);
      expect(orders.slots[2].order!.id, foodieOrderId);
      expect(orders.slots[1].hasActiveOrder, isTrue);
      expect(shift.currentCombo, 0);
      expect(kitchen.table.hasConsistentCardLocations(), isTrue);
    },
  );

  test(
    'FLOW 8: varied shift results, upgrade, and next-shift reset persist run state',
    () {
      final kitchen = TestKitchen();
      final orders = threeCustomers();
      final flow = GameFlowController();
      final shift = ShiftState(walletCoins: flow.progression.walletCoins);
      expect(flow.startShift(), isTrue);
      expect(kitchen.start(knifeProcessingDefinition), isTrue);

      for (final reward in [10, 15, 15, 8]) {
        expect(
          shift.recordSuccessfulService(
            rewardCoins: reward,
            enterFeedback: false,
          ),
          isTrue,
        );
        flow.progression.addWalletCoins(reward);
      }
      expect(shift.advanceActiveTime(GameLayout.shiftDurationSeconds), isTrue);
      flow.showResults();
      expect(flow.screen, AppScreen.shiftResults);
      expect(shift.shiftEarnings, 48);
      expect(flow.progression.walletCoins, GameLayout.initialWalletCoins + 48);

      expect(flow.showUpgradeSelection(), isTrue);
      expect(flow.selectUpgrade(prototypeUpgradeDefinitions[2]), isTrue);
      expect(flow.confirmUpgrade(), isNotNull);
      kitchen.processing.clearActiveJob();
      kitchen.table.resetPrototypePreparationState(
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
      orders.startShift();
      shift
        ..walletCoins = flow.progression.walletCoins
        ..startNewShift();

      expect(flow.progression.currentDay, 2);
      expect(
        flow.progression.upgrades.levelFor(UpgradeId.coolHeadedService),
        1,
      );
      expect(shift.walletCoins, GameLayout.initialWalletCoins + 48);
      expect(kitchen.processing.activeJobs, isEmpty);
      expect(orders.activeSlots, hasLength(3));
      for (final ingredient in prototypeCycleIngredientDefinitions) {
        expect(kitchen.table.isInHand(ingredient.id), isTrue);
      }
      for (final equipment in prototypeEquipmentDefinitions) {
        expect(kitchen.table.isOnKitchenTable(equipment.id), isTrue);
      }
      expect(kitchen.table.hasConsistentCardLocations(), isTrue);
    },
  );

  test('tutorial state is first-shift-only and action-gated', () {
    final tutorial = TutorialState();
    expect(tutorial.startFirstShift(), isTrue);
    expect(tutorial.startFirstShift(), isFalse);
    expect(tutorial.status, TutorialStatus.active);
    expect(tutorial.currentStep, TutorialStep.cookPatty);
    expect(
      tutorial.processingStarted(
        inputCardId: 'bread_01',
        equipmentCardId: 'pan_01',
      ),
      isFalse,
    );
    expect(
      tutorial.processingStarted(
        inputCardId: 'patty_01',
        equipmentCardId: 'pan_01',
      ),
      isTrue,
    );
    expect(tutorial.currentStep, TutorialStep.buildClassicBurger);
    expect(tutorial.recipeResolved(recipeId: 'deluxe_burger'), isFalse);
    expect(tutorial.recipeResolved(recipeId: 'classic_burger'), isTrue);
    expect(tutorial.currentStep, TutorialStep.serveClassicBurger);
    expect(
      tutorial.serviceCompleted(resultType: CardType.deluxeBurger),
      isFalse,
    );
    expect(
      tutorial.serviceCompleted(resultType: CardType.classicBurger),
      isTrue,
    );
    expect(tutorial.status, TutorialStatus.completed);
    expect(tutorial.patienceProtectionActive, isFalse);
    expect(tutorial.startFirstShift(), isFalse);

    final unfinishedTutorial = TutorialState()..startFirstShift();
    unfinishedTutorial.finishFirstShiftSafely();
    expect(unfinishedTutorial.status, TutorialStatus.skipped);
    expect(unfinishedTutorial.startFirstShift(), isFalse);
  });

  test(
    'tutorial skip and patience protection restore normal order behavior',
    () {
      final tutorial = TutorialState()..startFirstShift();
      final orders = threeCustomers();
      orders.startShift(tutorialFirstOrder: true);
      expect(orders.tutorialPatienceProtectionActive, isTrue);
      expect(
        orders.slots.first.order!.requestedResultType,
        CardType.classicBurger,
      );
      expect(orders.advancePatience(999), isNot(contains(orders.slots.first)));
      expect(orders.slots.first.hasActiveOrder, isTrue);
      expect(tutorial.skip(), isTrue);
      orders.clearTutorialPatienceProtection();
      expect(tutorial.status, TutorialStatus.skipped);
      expect(orders.tutorialPatienceProtectionActive, isFalse);
      expect(orders.advancePatience(999), contains(orders.slots.first));
    },
  );

  test('recipe discovery begins known and persists newly created recipes', () {
    final discovery = RecipeDiscoveryState();
    expect(discovery.isDiscovered('classic_burger'), isTrue);
    expect(discovery.isDiscovered('crispy_fries'), isFalse);
    expect(discovery.isDiscovered('deluxe_burger'), isFalse);
    expect(discovery.discover('deluxe_burger'), isTrue);
    expect(discovery.discover('spicy_burger'), isTrue);
    expect(discovery.isDiscovered('deluxe_burger'), isTrue);
    expect(discovery.isDiscovered('spicy_burger'), isTrue);
    expect(discovery.discover('deluxe_burger'), isFalse);
  });

  test('recipe book flow returns to its authoritative prior screen', () {
    final flow = GameFlowController();
    expect(flow.showRecipeBook(), isTrue);
    expect(flow.screen, AppScreen.recipeBook);
    expect(flow.closeRecipeBook(), isTrue);
    expect(flow.screen, AppScreen.mainMenu);
    expect(flow.startShift(), isTrue);
    expect(flow.showRecipeBook(), isTrue);
    expect(flow.isGameplayActive, isFalse);
    expect(flow.closeRecipeBook(), isTrue);
    expect(flow.screen, AppScreen.gameplay);
    expect(flow.showRecipeBook(), isTrue);
    expect(flow.showRecipeBook(), isFalse);
  });

  test('recipe detail rewards use the existing upgrade authority', () {
    final upgrades = UpgradeState();
    expect(upgrades.effectiveRewardFor(deluxeBurgerCardDefinition), 15);
    upgrades.increase(prototypeUpgradeDefinitions[1]);
    expect(upgrades.effectiveRewardFor(deluxeBurgerCardDefinition), 20);
    expect(upgrades.effectiveRewardFor(crispyFriesCardDefinition), 8);
  });

  test('shift moment tracker selects the closest qualifying service first', () {
    final tracker = ShiftMomentTracker()..startShift(day: 4);
    tracker.recordSuccessfulService(
      resultDefinition: classicBurgerCardDefinition,
      remainingPatienceSeconds: 4.2,
      combo: 5,
      rewardCoins: 10,
    );
    tracker.recordSuccessfulService(
      resultDefinition: deluxeBurgerCardDefinition,
      remainingPatienceSeconds: 2.4,
      combo: 2,
      rewardCoins: 15,
    );
    tracker.recordSuccessfulService(
      resultDefinition: spicyBurgerCardDefinition,
      remainingPatienceSeconds: .21,
      combo: 3,
      rewardCoins: 15,
    );
    final moment = tracker.selectMoment();
    expect(moment!.kind, ShiftMomentKind.lastSecond);
    expect(moment.resultName, 'Ateş Burger');
    expect(moment.remainingPatienceSeconds, closeTo(.21, .0001));
    expect(moment.day, 4);
  });

  test(
    'shift moment falls back to combo then reward without a last-second service',
    () {
      final comboTracker = ShiftMomentTracker()..startShift(day: 2);
      comboTracker.recordSuccessfulService(
        resultDefinition: classicBurgerCardDefinition,
        remainingPatienceSeconds: 3.1,
        combo: 3,
        rewardCoins: 10,
      );
      expect(comboTracker.selectMoment()!.kind, ShiftMomentKind.combo);

      final rewardTracker = ShiftMomentTracker()..startShift(day: 3);
      rewardTracker.recordSuccessfulService(
        resultDefinition: deluxeBurgerCardDefinition,
        remainingPatienceSeconds: 3.5,
        combo: 1,
        rewardCoins: 15,
      );
      expect(rewardTracker.selectMoment()!.kind, ShiftMomentKind.reward);
      expect((ShiftMomentTracker()..startShift(day: 1)).selectMoment(), isNull);
    },
  );

  test('results can enter a shift moment and upgrades exactly once', () {
    final flow = GameFlowController();
    flow.startShift();
    flow.showResults();
    expect(flow.showShiftMoment(), isTrue);
    expect(flow.showShiftMoment(), isFalse);
    expect(flow.showUpgradeSelection(), isTrue);
    expect(flow.showUpgradeSelection(), isFalse);
  });

  testWidgets('tutorial accepts real required drag gestures only', (
    tester,
  ) async {
    final originalPhysicalSize = tester.view.physicalSize;
    final originalDevicePixelRatio = tester.view.devicePixelRatio;
    final originalPadding = tester.view.padding;
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 60, bottom: 60);
    addTearDown(() {
      tester.view.physicalSize = originalPhysicalSize;
      tester.view.devicePixelRatio = originalDevicePixelRatio;
      tester.view.padding = originalPadding;
    });
    final game = SonSiparisGame();
    const gameOffset = Offset(320 / 3, 60);
    const gameScale = 4 / 3;
    Offset screen(Offset world) => gameOffset + (world * gameScale);
    Future<void> drag(Offset start, Offset end) async {
      final gesture = await tester.startGesture(screen(start));
      for (var step = 1; step <= 6; step++) {
        await gesture.moveTo(screen(Offset.lerp(start, end, step / 6)!));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 80));
    }

    Offset centerOf(String cardId) {
      final position = game.tableState
          .placementFor(cardId)
          .currentValidPosition;
      return position + const Offset(52, 39);
    }

    Offset pantryCenter(String supplyId) =>
        game.pantryState.slotFor(supplyId).position + const Offset(52, 39);
    String singleActiveType(CardType type) => game
        .tableState
        .tableCardIdsInRenderOrder
        .singleWhere((id) => game.tableState.definitionFor(id).type == type);

    await tester.pumpWidget(SonSiparisApp(game: game));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(screen(const Offset(640, 506)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.tutorialState.status, TutorialStatus.active);
    expect(game.tutorialState.currentStep, TutorialStep.cookPatty);
    expect(
      game.world.children
          .whereType<TutorialOverlayComponent>()
          .single
          .isMounted,
      isTrue,
    );

    await drag(pantryCenter('bread_01'), const Offset(312, 280));
    expect(
      game.tableState.tableCardIdsInRenderOrder.where(
        (id) => game.tableState.definitionFor(id).type == CardType.bread,
      ),
      isEmpty,
    );
    expect(game.pantryState.isAvailable('bread_01'), isTrue);
    await drag(
      pantryCenter('patty_01'),
      game.tableState.placementFor('pan_01').currentValidPosition +
          const Offset(45, 30),
    );
    final rawPattyId = game.processingState.activeJobs.single.inputCardId;
    expect(rawPattyId, startsWith('raw_patty_'));
    expect(game.processingState.isProcessingInput(rawPattyId), isTrue);
    expect(game.tutorialState.currentStep, TutorialStep.buildClassicBurger);

    game.update(GameLayout.processingDurationSeconds + .1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      game.tableState.definitionFor(rawPattyId).type,
      CardType.cookedPatty,
    );
    await drag(pantryCenter('bread_01'), const Offset(320, 280));
    final breadId = singleActiveType(CardType.bread);
    await drag(centerOf(rawPattyId), centerOf(breadId));
    await drag(pantryCenter('cheese_01'), centerOf(rawPattyId));
    final tutorialResultId = game.tableState.definitions
        .singleWhere((definition) => definition.type == CardType.classicBurger)
        .id;
    expect(game.tutorialState.currentStep, TutorialStep.serveClassicBurger);
    await drag(
      centerOf(tutorialResultId),
      GameLayout.serviceCounterBounds.center - const Offset(52, 22),
    );
    expect(game.tutorialState.status, TutorialStatus.completed);
    expect(game.orderSystem.tutorialPatienceProtectionActive, isFalse);
  });

  testWidgets('recipe book blocks and resumes gameplay without time jumps', (
    tester,
  ) async {
    final originalPhysicalSize = tester.view.physicalSize;
    final originalDevicePixelRatio = tester.view.devicePixelRatio;
    final originalPadding = tester.view.padding;
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 60, bottom: 60);
    addTearDown(() {
      tester.view.physicalSize = originalPhysicalSize;
      tester.view.devicePixelRatio = originalDevicePixelRatio;
      tester.view.padding = originalPadding;
    });
    final game = SonSiparisGame();
    const gameOffset = Offset(320 / 3, 60);
    const gameScale = 4 / 3;
    Offset screen(Offset world) => gameOffset + (world * gameScale);
    await tester.pumpWidget(SonSiparisApp(game: game));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(screen(const Offset(640, 506)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(screen(const Offset(1035, 125)));
    await tester.pump(const Duration(milliseconds: 100));
    final elapsed = game.shiftState.elapsedShiftSeconds;
    final patience = game.orderSystem.slots.first.patience.remainingSeconds;
    await tester.tapAt(screen(const Offset(82, 118)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.flow.screen, AppScreen.recipeBook);
    expect(game.isGameplayInputAllowed, isFalse);
    expect(
      game.world.children
          .whereType<RecipeBookComponent>()
          .single
          .containsLocalPoint(Vector2.zero()),
      isTrue,
    );
    game.update(5);
    expect(game.shiftState.elapsedShiftSeconds, elapsed);
    expect(game.orderSystem.slots.first.patience.remainingSeconds, patience);
    await tester.tapAt(screen(const Offset(1200, 45)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.flow.screen, AppScreen.gameplay);
    expect(game.isGameplayInputAllowed, isTrue);
  });
}
