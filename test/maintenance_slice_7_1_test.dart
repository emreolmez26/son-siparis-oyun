import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:son_siparis/game/data/prototype_card_definitions.dart';
import 'package:son_siparis/game/data/prototype_recipe_definitions.dart';
import 'package:son_siparis/game/game_layout.dart';
import 'package:son_siparis/game/kitchen_grid.dart';
import 'package:son_siparis/game/models/card_definition.dart';
import 'package:son_siparis/game/models/recipe_definition.dart';
import 'package:son_siparis/game/models/sabotage.dart';
import 'package:son_siparis/game/state/kitchen_table_state.dart';
import 'package:son_siparis/game/state/pantry_supply_state.dart';
import 'package:son_siparis/game/state/rival_state.dart';
import 'package:son_siparis/game/state/shift_state.dart';
import 'package:son_siparis/game/systems/stack_layout.dart';

class RenewableKitchen {
  RenewableKitchen()
    : pantry = PantrySupplyState(
        definitions: prototypeCycleIngredientDefinitions,
        positions: GameLayout.initialHandCardPositions,
        spawnCooldownSeconds: 0,
      ),
      table = KitchenTableState(
        definitions: prototypeEquipmentDefinitions,
        initialHandPositions: const {},
        initialEquipmentTablePositions:
            GameLayout.initialEquipmentTablePositions,
        stackLayout: StackLayout(
          cardSize: GameLayout.cardSize,
          paddedTableBounds: grid.paddedTableBounds,
          gridOrigin: grid.origin,
          gridSpacing: grid.spacing,
          levelOffset: GameLayout.stackLevelOffset,
        ),
      );

  static const grid = KitchenGrid(
    tableBounds: GameLayout.kitchenTableBounds,
    cardSize: GameLayout.cardSize,
    spacing: GameLayout.kitchenGridSpacing,
    padding: GameLayout.kitchenGridPadding,
  );

  final PantrySupplyState pantry;
  final KitchenTableState table;

  String spawn(String supplyId, Offset position) {
    final definition = pantry.takeWorkingDefinition(supplyId)!;
    table.spawnWorkingCard(definition: definition, dragPosition: position);
    table.commitKitchenTablePlacement(definition.id, position);
    return definition.id;
  }

  String spawnUncommitted(String supplyId, Offset position) {
    final definition = pantry.takeWorkingDefinition(supplyId)!;
    table.spawnWorkingCard(definition: definition, dragPosition: position);
    return definition.id;
  }

  void cook(String cardId, Offset output) {
    table.markCardProcessing(cardId, output);
    table.completeProcessedCard(
      cardId: cardId,
      completedDefinition: cookedPattyCardDefinition.copyWithId(cardId),
      outputPosition: output,
    );
  }

  void slice(String cardId, Offset output) {
    table.markCardProcessing(cardId, output);
    table.completeProcessedCard(
      cardId: cardId,
      completedDefinition: slicedTomatoCardDefinition.copyWithId(cardId),
      outputPosition: output,
    );
  }

  String fries(String potatoId, Offset output) {
    table.markCardProcessing(potatoId, output);
    return table.completeProcessedResultCard(
      inputCardId: potatoId,
      resultDefinition: crispyFriesCardDefinition,
      outputPosition: output,
    );
  }

  String stack(List<String> ids, Offset base) {
    table.commitKitchenTablePlacement(ids.first, base);
    for (var index = 1; index < ids.length; index++) {
      expect(table.tryStackCardOnTarget(ids[index], ids[index - 1]), isTrue);
    }
    return table.stackForCard(ids.last)!.id;
  }

  String resolve(List<String> ids, RecipeDefinition recipe, Offset base) {
    final stackId = stack(ids, base);
    return table
        .tryResolveRecipeStack(stackId: stackId, recipe: recipe)!
        .resultCardId;
  }

  Iterable<String> idsOfType(CardType type) => table.definitions
      .where((definition) => definition.type == type)
      .map((definition) => definition.id);
}

ScheduledSabotage maintenanceEvent(
  SabotageType type, {
  Rect? region,
  Offset direction = Offset.zero,
  CardType? fakeType,
  String? equipmentId,
}) => ScheduledSabotage(
  id: 'maintenance_${type.name}',
  type: type,
  scheduledAtSeconds: 18,
  greasyRegion: region,
  slideDirection: direction,
  fakeOrderType: fakeType,
  targetEquipmentId: equipmentId,
);

void main() {
  group('renewable pantry supply', () {
    test('1-3 and 6: supplies remain while unique copies coexist', () {
      final kitchen = RenewableKitchen();
      final breadA = kitchen.spawn('bread_01', const Offset(120, 260));
      final breadB = kitchen.spawn('bread_01', const Offset(320, 260));
      final cheeseA = kitchen.spawn('cheese_01', const Offset(120, 380));
      final cheeseB = kitchen.spawn('cheese_01', const Offset(320, 380));

      expect(breadA, isNot(breadB));
      expect(cheeseA, isNot(cheeseB));
      expect(kitchen.idsOfType(CardType.bread), hasLength(2));
      expect(kitchen.idsOfType(CardType.cheese), hasLength(2));
      expect(kitchen.pantry.isAvailable('bread_01'), isTrue);
      expect(kitchen.pantry.isAvailable('cheese_01'), isTrue);
      expect(kitchen.table.containsCard('bread_01'), isFalse);
      expect(kitchen.table.containsCard('cheese_01'), isFalse);
    });

    test('4-5: a second raw patty exists while the first processes', () {
      final kitchen = RenewableKitchen();
      final pattyA = kitchen.spawn('patty_01', const Offset(160, 260));
      kitchen.table.markCardProcessing(pattyA, const Offset(690, 300));
      final pattyB = kitchen.spawn('patty_01', const Offset(360, 260));

      expect(kitchen.table.isProcessing(pattyA), isTrue);
      expect(kitchen.table.definitionFor(pattyB).type, CardType.patty);
      expect(kitchen.table.isOnKitchenTable(pattyB), isTrue);
      expect(kitchen.pantry.isAvailable('patty_01'), isTrue);
    });

    test('11-14: one spawn, invalid removal, and placed-card rollback', () {
      final kitchen = RenewableKitchen();
      final initialCount = kitchen.table.cardCount;
      final invalidId = kitchen.spawnUncommitted(
        'bread_01',
        const Offset(356, 648),
      );
      expect(kitchen.table.cardCount, initialCount + 1);
      kitchen.table.removeSpawnedWorkingCard(invalidId);
      expect(kitchen.table.cardCount, initialCount);
      expect(kitchen.pantry.isAvailable('bread_01'), isTrue);

      final placedId = kitchen.spawn('bread_01', const Offset(160, 280));
      final previous = kitchen.table.placementFor(placedId);
      final snapshot = kitchen.table.beginCardDrag(placedId);
      kitchen.table.commitKitchenTablePlacement(
        placedId,
        const Offset(500, 380),
      );
      kitchen.table.restoreCardDragSnapshot(snapshot);
      expect(kitchen.table.cardCount, initialCount + 1);
      expect(kitchen.table.placementFor(placedId), previous);
    });

    test('19-20 and 24: physical zones exclude pantry and counters', () {
      final kitchen = RenewableKitchen();
      for (var index = 0; index < 3; index++) {
        kitchen.spawn('bread_01', Offset(120.0 + (index * 130), 270));
      }
      final physicalIds = kitchen.table.definitions
          .map((definition) => definition.id)
          .toList();
      expect(physicalIds.toSet(), hasLength(physicalIds.length));
      expect(kitchen.table.hasConsistentCardLocations(), isTrue);
      expect(kitchen.pantry.slotCount, 6);
      for (final slot in kitchen.pantry.slots) {
        expect(physicalIds, isNot(contains(slot.id)));
      }

      final rival = RivalState()
        ..beginForTest(maintenanceEvent(SabotageType.powerSurge), active: true);
      expect(rival.countermeasureId, startsWith('counter_'));
      expect(
        kitchen.pantry.slots.map((slot) => slot.id),
        isNot(contains(rival.countermeasureId)),
      );
    });
  });

  group('parallel preparations', () {
    test('7-10: two partial and completed burgers remain independent', () {
      final kitchen = RenewableKitchen();
      final breadA = kitchen.spawn('bread_01', const Offset(120, 250));
      final breadB = kitchen.spawn('bread_01', const Offset(420, 250));
      final pattyA = kitchen.spawn('patty_01', const Offset(120, 360));
      final pattyB = kitchen.spawn('patty_01', const Offset(420, 360));
      final cheeseA = kitchen.spawn('cheese_01', const Offset(120, 450));
      final cheeseB = kitchen.spawn('cheese_01', const Offset(420, 450));
      kitchen.cook(pattyA, const Offset(220, 330));
      kitchen.cook(pattyB, const Offset(520, 330));

      final stackA = kitchen.stack([breadA, pattyA], const Offset(120, 250));
      final stackB = kitchen.stack([breadB, pattyB], const Offset(420, 250));
      expect(kitchen.table.stackCount, 2);

      expect(kitchen.table.tryStackCardOnTarget(cheeseA, pattyA), isTrue);
      final burgerA = kitchen.table
          .tryResolveRecipeStack(
            stackId: stackA,
            recipe: classicBurgerRecipeDefinition,
          )!
          .resultCardId;
      expect(kitchen.table.stackFor(stackB).cardIds, [breadB, pattyB]);
      expect(kitchen.table.isOnKitchenTable(burgerA), isTrue);

      expect(kitchen.table.tryStackCardOnTarget(cheeseB, pattyB), isTrue);
      final burgerB = kitchen.table
          .tryResolveRecipeStack(
            stackId: stackB,
            recipe: classicBurgerRecipeDefinition,
          )!
          .resultCardId;
      expect(burgerA, isNot(burgerB));
      expect(kitchen.idsOfType(CardType.classicBurger), hasLength(2));
      for (final source in [breadA, pattyA, cheeseA, breadB, pattyB, cheeseB]) {
        expect(kitchen.table.isConsumed(source), isTrue);
      }
      expect(kitchen.pantry.slots.every((slot) => slot.isAvailable), isTrue);
    });

    test('15-18: gourmet, duplicate produce, and fries coexist', () {
      final kitchen = RenewableKitchen();
      final waitingBread = kitchen.spawn('bread_01', const Offset(110, 250));
      final tomatoes = [
        kitchen.spawn('tomato_01', const Offset(250, 250)),
        kitchen.spawn('tomato_01', const Offset(390, 250)),
      ];
      final potatoes = [
        kitchen.spawn('potato_01', const Offset(530, 250)),
        kitchen.spawn('potato_01', const Offset(670, 250)),
      ];
      final gourmetBread = kitchen.spawn('bread_01', const Offset(110, 400));
      final patty = kitchen.spawn('patty_01', const Offset(250, 400));
      final cheese = kitchen.spawn('cheese_01', const Offset(390, 400));
      kitchen.cook(patty, const Offset(250, 400));
      kitchen.slice(tomatoes.first, const Offset(530, 400));
      final gourmet = kitchen.resolve(
        [gourmetBread, patty, tomatoes.first, cheese],
        deluxeBurgerRecipeDefinition,
        const Offset(110, 400),
      );
      final fries = kitchen.fries(potatoes.first, const Offset(760, 390));

      expect(kitchen.table.isOnKitchenTable(waitingBread), isTrue);
      expect(kitchen.table.isOnKitchenTable(tomatoes.last), isTrue);
      expect(kitchen.table.isOnKitchenTable(potatoes.last), isTrue);
      expect(kitchen.table.isOnKitchenTable(gourmet), isTrue);
      expect(kitchen.table.isOnKitchenTable(fries), isTrue);
      expect(kitchen.pantry.isAvailable('tomato_01'), isTrue);
      expect(kitchen.pantry.isAvailable('potato_01'), isTrue);
    });
  });

  group('ownership and sabotage safety', () {
    test('21: customer failure preserves unrelated preparation', () {
      final kitchen = RenewableKitchen();
      final bread = kitchen.spawn('bread_01', const Offset(120, 270));
      final potato = kitchen.spawn('potato_01', const Offset(360, 270));
      final shift = ShiftState()..recordMissedOrder(enterFeedback: false);
      expect(shift.missedOrders, 1);
      expect(kitchen.table.isOnKitchenTable(bread), isTrue);
      expect(kitchen.table.isOnKitchenTable(potato), isTrue);
    });

    test('22: grease moves only the newly dropped working instance', () {
      final kitchen = RenewableKitchen();
      final resting = kitchen.spawn('bread_01', const Offset(160, 280));
      final dropped = kitchen.spawn('bread_01', const Offset(360, 280));
      final rival = RivalState()
        ..beginForTest(
          maintenanceEvent(
            SabotageType.greasyTable,
            region: const Rect.fromLTWH(300, 220, 260, 220),
            direction: const Offset(1, 0),
          ),
          active: true,
        );
      final destination = rival.greasySlideDestination(
        droppedPosition: kitchen.table
            .placementFor(dropped)
            .currentValidPosition,
        cardSize: GameLayout.cardSize,
        tableBounds: GameLayout.kitchenTableBounds,
        gridSpacing: GameLayout.kitchenGridSpacing,
      )!;
      kitchen.table.commitKitchenTablePlacement(dropped, destination);

      expect(
        kitchen.table.placementFor(resting).currentValidPosition,
        const Offset(160, 280),
      );
      expect(destination, const Offset(392, 280));
    });

    test('23: fake-order rollback preserves the same result instance', () {
      final kitchen = RenewableKitchen();
      final bread = kitchen.spawn('bread_01', const Offset(120, 250));
      final patty = kitchen.spawn('patty_01', const Offset(220, 250));
      final cheese = kitchen.spawn('cheese_01', const Offset(320, 250));
      kitchen.cook(patty, const Offset(220, 250));
      final result = kitchen.resolve(
        [bread, patty, cheese],
        classicBurgerRecipeDefinition,
        const Offset(120, 250),
      );
      final prior = kitchen.table.placementFor(result);
      final snapshot = kitchen.table.beginCardDrag(result);
      kitchen.table.commitKitchenTablePlacement(result, const Offset(800, 500));
      kitchen.table.restoreCardDragSnapshot(snapshot);

      expect(kitchen.table.placementFor(result), prior);
      expect(kitchen.idsOfType(CardType.classicBurger), [result]);
    });

    test('power and jam never alter pantry availability', () {
      final kitchen = RenewableKitchen();
      for (final event in [
        maintenanceEvent(SabotageType.powerSurge),
        maintenanceEvent(SabotageType.equipmentJam, equipmentId: 'pan_01'),
      ]) {
        final rival = RivalState()..beginForTest(event, active: true);
        expect(rival.hasActiveSabotage, isTrue);
        expect(kitchen.pantry.slots.every((slot) => slot.isAvailable), isTrue);
      }
    });
  });

  test('end-to-end: two burgers reward twice without replenishment', () {
    final kitchen = RenewableKitchen();
    final breadA = kitchen.spawn('bread_01', const Offset(110, 250));
    final breadB = kitchen.spawn('bread_01', const Offset(410, 250));
    final pattyA = kitchen.spawn('patty_01', const Offset(110, 370));
    final pattyB = kitchen.spawn('patty_01', const Offset(410, 370));
    final cheeseA = kitchen.spawn('cheese_01', const Offset(110, 460));
    final cheeseB = kitchen.spawn('cheese_01', const Offset(410, 460));

    kitchen.table.markCardProcessing(pattyA, const Offset(690, 300));
    expect(kitchen.table.isOnKitchenTable(breadB), isTrue);
    expect(kitchen.table.isOnKitchenTable(pattyB), isTrue);
    expect(kitchen.table.isOnKitchenTable(cheeseB), isTrue);
    kitchen.table.completeProcessedCard(
      cardId: pattyA,
      completedDefinition: cookedPattyCardDefinition.copyWithId(pattyA),
      outputPosition: const Offset(220, 320),
    );
    final burgerA = kitchen.resolve(
      [breadA, pattyA, cheeseA],
      classicBurgerRecipeDefinition,
      const Offset(110, 250),
    );

    kitchen.cook(pattyB, const Offset(520, 320));
    final burgerB = kitchen.resolve(
      [breadB, pattyB, cheeseB],
      classicBurgerRecipeDefinition,
      const Offset(410, 250),
    );
    expect(kitchen.table.isOnKitchenTable(burgerA), isTrue);
    expect(kitchen.table.isOnKitchenTable(burgerB), isTrue);

    final shift = ShiftState();
    kitchen.table.markCardServed(burgerA);
    expect(shift.recordSuccessfulService(enterFeedback: false), isTrue);
    expect(kitchen.table.isOnKitchenTable(burgerB), isTrue);
    kitchen.table.markCardServed(burgerB);
    expect(shift.recordSuccessfulService(enterFeedback: false), isTrue);
    expect(shift.successfulServices, 2);
    expect(shift.shiftEarnings, 20);
    expect(kitchen.pantry.slots.every((slot) => slot.isAvailable), isTrue);
    expect(kitchen.table.hasConsistentCardLocations(), isTrue);
    expect(
      kitchen.table.definitions
          .where((definition) => definition.category == CardCategory.ingredient)
          .where((definition) => !kitchen.table.isConsumed(definition.id)),
      isEmpty,
    );
  });

  test('new shift clears working instances but keeps six pantry slots', () {
    final kitchen = RenewableKitchen();
    kitchen.spawn('bread_01', const Offset(120, 260));
    kitchen.spawn('potato_01', const Offset(320, 260));
    kitchen.table.resetWorkingCardsForNewShift(
      equipmentDefinitions: prototypeEquipmentDefinitions,
      equipmentTablePositions: GameLayout.initialEquipmentTablePositions,
    );
    kitchen.pantry.resetForShift();

    expect(kitchen.table.cardCount, 3);
    expect(
      kitchen.table.definitions.every(
        (definition) => definition.category == CardCategory.equipment,
      ),
      isTrue,
    );
    expect(kitchen.pantry.slotCount, 6);
    expect(kitchen.pantry.slots.every((slot) => slot.isAvailable), isTrue);
  });
}
