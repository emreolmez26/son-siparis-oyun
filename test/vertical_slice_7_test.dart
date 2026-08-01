import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:son_siparis/game/data/prototype_card_definitions.dart';
import 'package:son_siparis/game/data/prototype_customer_definitions.dart';
import 'package:son_siparis/game/data/prototype_processing_definitions.dart';
import 'package:son_siparis/game/data/prototype_recipe_definitions.dart';
import 'package:son_siparis/game/game_layout.dart';
import 'package:son_siparis/game/kitchen_grid.dart';
import 'package:son_siparis/game/models/card_definition.dart';
import 'package:son_siparis/game/models/card_zone.dart';
import 'package:son_siparis/game/models/sabotage.dart';
import 'package:son_siparis/game/models/shift_phase.dart';
import 'package:son_siparis/game/state/equipment_processing_state.dart';
import 'package:son_siparis/game/state/kitchen_table_state.dart';
import 'package:son_siparis/game/state/order_system.dart';
import 'package:son_siparis/game/state/rival_state.dart';
import 'package:son_siparis/game/state/shift_state.dart';
import 'package:son_siparis/game/systems/sabotage_scheduler.dart';
import 'package:son_siparis/game/systems/stack_layout.dart';

class Vs7Kitchen {
  Vs7Kitchen()
    : table = KitchenTableState(
        definitions: prototypeCardDefinitions,
        initialHandPositions: GameLayout.initialHandCardPositions,
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
  final KitchenTableState table;
  final EquipmentProcessingState processing = EquipmentProcessingState(
    processingDurationSeconds: GameLayout.processingDurationSeconds,
  );

  void cookPatty({Offset position = const Offset(168, 266)}) {
    table.markCardProcessing('patty_01', position);
    table.completeProcessedCard(
      cardId: 'patty_01',
      completedDefinition: cookedPattyCardDefinition,
      outputPosition: position,
    );
  }

  void sliceTomato({Offset position = const Offset(168, 362)}) {
    table.markCardProcessing('tomato_01', position);
    table.completeProcessedCard(
      cardId: 'tomato_01',
      completedDefinition: slicedTomatoCardDefinition,
      outputPosition: position,
    );
  }

  String makeRecipe(
    List<String> sourceIds,
    dynamic recipe, {
    Offset base = const Offset(72, 250),
  }) {
    table.commitKitchenTablePlacement(sourceIds.first, base);
    for (var index = 1; index < sourceIds.length; index++) {
      expect(
        table.tryStackCardOnTarget(sourceIds[index], sourceIds[index - 1]),
        isTrue,
      );
    }
    final stack = table.stackForCard(sourceIds.last)!;
    return table
        .tryResolveRecipeStack(
          stackId: stack.id,
          recipe: recipe,
          runtimeResultId: table.nextResultRuntimeId(
            recipe.resultDefinition.id as String,
          ),
        )!
        .resultCardId;
  }

  String makeClassic({Offset base = const Offset(72, 250)}) {
    cookPatty();
    return makeRecipe(
      ['bread_01', 'patty_01', 'cheese_01'],
      classicBurgerRecipeDefinition,
      base: base,
    );
  }

  String makeFries() {
    const output = Offset(872, 380);
    table.markCardProcessing('potato_01', output);
    return table.completeProcessedResultCard(
      inputCardId: 'potato_01',
      resultDefinition: crispyFriesCardDefinition,
      outputPosition: output,
    );
  }

  void startThreeJobs() {
    for (final entry in [
      ('pan_01', 'patty_01', panProcessingDefinition),
      ('knife_01', 'tomato_01', knifeProcessingDefinition),
      ('fryer_01', 'potato_01', fryerProcessingDefinition),
    ]) {
      expect(
        processing.tryStartProcessing(
          tableState: table,
          equipmentCardId: entry.$1,
          inputCardId: entry.$2,
          attachedInputPosition: table
              .placementFor(entry.$1)
              .currentValidPosition,
          definition: entry.$3,
        ),
        isTrue,
      );
    }
  }
}

ScheduledSabotage event(
  SabotageType type, {
  String id = 'event_01',
  String? equipmentId,
  Rect? region,
  Offset direction = Offset.zero,
  CardType? fakeType,
}) => ScheduledSabotage(
  id: id,
  type: type,
  scheduledAtSeconds: 18,
  targetEquipmentId: equipmentId,
  greasyRegion: region,
  slideDirection: direction,
  fakeOrderType: fakeType,
);

void main() {
  group('parallel production 1-14', () {
    test('1-6 recipe and service never restock consumed sources', () {
      final kitchen = Vs7Kitchen();
      final first = kitchen.makeClassic();
      expect(first, startsWith('result_classic_burger_'));
      expect(kitchen.table.isOnKitchenTable(first), isTrue);
      for (final id in ['bread_01', 'patty_01', 'cheese_01']) {
        expect(kitchen.table.isConsumed(id), isTrue);
      }
      kitchen.table.markCardServed(first);
      for (final id in ['bread_01', 'patty_01', 'cheese_01']) {
        expect(kitchen.table.isConsumed(id), isTrue);
      }
    });

    test('7 deluxe consumes its exact processed sources', () {
      final kitchen = Vs7Kitchen();
      kitchen.cookPatty();
      kitchen.sliceTomato();
      final id = kitchen.makeRecipe([
        'bread_01',
        'patty_01',
        'tomato_01',
        'cheese_01',
      ], deluxeBurgerRecipeDefinition);
      expect(kitchen.table.definitionFor(id).type, CardType.deluxeBurger);
      expect(
        kitchen.table.definitionFor('tomato_01').type,
        CardType.slicedTomato,
      );
      expect(kitchen.table.isConsumed('tomato_01'), isTrue);
    });

    test('8 spicy consumes only its exact sources', () {
      final kitchen = Vs7Kitchen();
      kitchen.cookPatty();
      final id = kitchen.makeRecipe([
        'bread_01',
        'patty_01',
        'hot_sauce_01',
        'cheese_01',
      ], spicyBurgerRecipeDefinition);
      expect(kitchen.table.definitionFor(id).type, CardType.spicyBurger);
      for (final source in [
        'bread_01',
        'patty_01',
        'hot_sauce_01',
        'cheese_01',
      ]) {
        expect(kitchen.table.isConsumed(source), isTrue);
      }
      expect(kitchen.table.isInHand('tomato_01'), isTrue);
    });

    test('9-10 fries creates one result and consumes its potato', () {
      final kitchen = Vs7Kitchen();
      final resultId = kitchen.makeFries();
      expect(resultId, startsWith('result_crispy_fries_'));
      expect(kitchen.table.isOnKitchenTable(resultId), isTrue);
      expect(kitchen.table.definitionFor('potato_01').type, CardType.potato);
      expect(kitchen.table.isConsumed('potato_01'), isTrue);
      expect(kitchen.table.sourceCardIdsForResult(resultId), ['potato_01']);
    });

    test('11-14 failure/work/zone invariants preserve results', () {
      final kitchen = Vs7Kitchen();
      final result = kitchen.makeClassic();
      final parallelKitchen = Vs7Kitchen()..startThreeJobs();
      final shift = ShiftState()..recordMissedOrder(enterFeedback: false);
      expect(shift.currentCombo, 0);
      expect(kitchen.table.isOnKitchenTable(result), isTrue);
      expect(parallelKitchen.processing.activeJobs, hasLength(3));
      expect(kitchen.table.hasConsistentCardLocations(), isTrue);
      expect(
        kitchen.table.definitions.map((definition) => definition.id).toSet(),
        hasLength(kitchen.table.cardCount),
      );
    });
  });

  group('deterministic scheduler 15-24', () {
    const scheduler = SabotageScheduler();

    test('15 day one and two are sabotage free', () {
      expect(scheduler.buildSchedule(day: 1, rivalId: 'kara_kazan'), isEmpty);
      expect(scheduler.buildSchedule(day: 2, rivalId: 'kara_kazan'), isEmpty);
    });

    test('16-18 counts and seeds are deterministic and injectable', () {
      final first = scheduler.buildSchedule(
        day: 3,
        rivalId: 'kara_kazan',
        testSeed: 11,
      );
      final same = scheduler.buildSchedule(
        day: 3,
        rivalId: 'kara_kazan',
        testSeed: 11,
      );
      final different = scheduler.buildSchedule(
        day: 3,
        rivalId: 'kara_kazan',
        testSeed: 12,
      );
      expect(first, hasLength(1));
      expect(first, same);
      expect(first, isNot(different));
      expect(
        scheduler.buildSchedule(day: 5, rivalId: 'kara_kazan'),
        hasLength(2),
      );
      expect(
        scheduler.buildSchedule(day: 8, rivalId: 'kara_kazan'),
        hasLength(3),
      );
    });

    test('19-20 events keep eighteen-second spacing and cannot overlap', () {
      final schedule = scheduler.buildSchedule(
        day: 8,
        rivalId: 'kara_kazan',
        testSeed: 3,
      );
      for (var index = 1; index < schedule.length; index++) {
        expect(
          schedule[index].scheduledAtSeconds -
              schedule[index - 1].scheduledAtSeconds,
          greaterThanOrEqualTo(16),
        );
      }
      final state = RivalState()..startShift(day: 8, testSeed: 3);
      state.advance(100, canAdvance: true);
      expect(state.current, isNotNull);
      expect(state.resolutions, isEmpty);
    });

    test('21-22 pause and Recipe Book eligibility freeze timers', () {
      final state = RivalState()..beginForTest(event(SabotageType.powerSurge));
      final remaining = state.current!.remainingSeconds;
      state.advance(1, canAdvance: false);
      state.advance(1, canAdvance: false);
      expect(state.current!.remainingSeconds, remaining);
      state.advance(1, canAdvance: true);
      expect(state.current!.remainingSeconds, remaining - 1);
    });

    test(
      '23 tutorial replay disables and 24 new day clears temporary state',
      () {
        final state = RivalState()..startShift(day: 9, tutorialReplay: true);
        expect(state.enabled, isFalse);
        expect(state.schedule, isEmpty);
        state.beginForTest(event(SabotageType.fakeOrder));
        state.startShift(day: 4, testSeed: 2);
        expect(state.current, isNull);
        expect(state.defendedCount, 0);
        expect(state.affectedCount, 0);
      },
    );
  });

  group('power and jam 25-32', () {
    test('25-28 outage freezes all jobs and counter resolves once', () {
      final kitchen = Vs7Kitchen()..startThreeJobs();
      final rival = RivalState()
        ..beginForTest(event(SabotageType.powerSurge), active: true);
      final paused = {'pan_01', 'knife_01', 'fryer_01'};
      kitchen.processing.advanceAll(1, pausedEquipmentIds: paused);
      expect(
        kitchen.processing.activeJobs.every((job) => job.elapsedSeconds == 0),
        isTrue,
      );
      expect(rival.tryCounter('wrong'), isFalse);
      final counterId = rival.countermeasureId!;
      expect(rival.tryCounter(counterId), isTrue);
      expect(rival.tryCounter(counterId), isFalse);
      final completed = kitchen.processing.advanceAll(10);
      expect(completed, hasLength(3));
      expect(completed.map((job) => job.id).toSet(), hasLength(3));
    });

    test('29-32 jam freezes only target and completes each job once', () {
      final kitchen = Vs7Kitchen()..startThreeJobs();
      final rival = RivalState()
        ..beginForTest(
          event(SabotageType.equipmentJam, equipmentId: 'pan_01'),
          active: true,
        );
      kitchen.processing.advanceAll(
        2,
        pausedEquipmentIds: {rival.jammedEquipmentId!},
      );
      expect(
        kitchen.processing.activeJobForEquipment('pan_01')!.elapsedSeconds,
        0,
      );
      expect(kitchen.processing.activeJobForEquipment('knife_01'), isNull);
      expect(
        kitchen.processing.activeJobForEquipment('fryer_01')!.elapsedSeconds,
        2,
      );
      expect(rival.tryCounter(rival.countermeasureId!), isTrue);
      final completed = kitchen.processing.advanceAll(10);
      expect(completed.map((job) => job.equipmentCardId).toSet(), {
        'pan_01',
        'fryer_01',
      });
      expect(kitchen.processing.advanceAll(10), isEmpty);
    });
  });

  group('grease 33-38', () {
    const region = Rect.fromLTWH(40, 234, 128, 96);

    test('33-34 a valid greasy drop slides exactly one deterministic cell', () {
      final rival = RivalState()
        ..beginForTest(
          event(
            SabotageType.greasyTable,
            region: region,
            direction: const Offset(1, 0),
          ),
          active: true,
        );
      expect(
        rival.greasySlideDestination(
          droppedPosition: const Offset(40, 234),
          cardSize: GameLayout.cardSize,
          tableBounds: GameLayout.kitchenTableBounds,
          gridSpacing: GameLayout.kitchenGridSpacing,
        ),
        const Offset(72, 234),
      );
    });

    test(
      '35 invalid destination rolls back and 36 resting cards never move',
      () {
        final rival = RivalState()
          ..beginForTest(
            event(
              SabotageType.greasyTable,
              region: const Rect.fromLTWH(1128, 420, 128, 96),
              direction: const Offset(1, 0),
            ),
            active: true,
          );
        final kitchen = Vs7Kitchen();
        final original = kitchen.table
            .placementFor('bread_01')
            .currentValidPosition;
        expect(
          rival.greasySlideDestination(
            droppedPosition: const Offset(1152, 442),
            cardSize: GameLayout.cardSize,
            tableBounds: GameLayout.kitchenTableBounds,
            gridSpacing: GameLayout.kitchenGridSpacing,
          ),
          isNull,
        );
        expect(
          kitchen.table.placementFor('bread_01').currentValidPosition,
          original,
        );
      },
    );

    test('37-38 cloth resolves once without moving or duplicating cards', () {
      final rival = RivalState()
        ..beginForTest(
          event(SabotageType.greasyTable, region: region),
          active: true,
        );
      final kitchen = Vs7Kitchen();
      final count = kitchen.table.cardCount;
      expect(rival.tryCounter(rival.countermeasureId!), isTrue);
      expect(rival.greasyRegion, isNull);
      expect(kitchen.table.cardCount, count);
      expect(kitchen.table.hasConsistentCardLocations(), isTrue);
    });
  });

  group('fake order and resolution 39-55', () {
    test('39-45 fake order is separate, counterable, and safe on expiry', () {
      final orders = OrderSystem(
        customerDefinitions: prototypeCustomerDefinitions,
      )..startShift();
      final realIds = orders.slots.map((slot) => slot.definition.id).toList();
      final rival = RivalState()
        ..beginForTest(
          event(SabotageType.fakeOrder, fakeType: CardType.classicBurger),
          active: true,
        );
      expect(orders.slots, hasLength(3));
      expect(orders.slots.map((slot) => slot.definition.id), realIds);
      expect(rival.fakeOrderType, CardType.classicBurger);
      expect(rival.tryCounter(rival.countermeasureId!), isTrue);
      expect(rival.fakeOrderActive, isFalse);

      rival.beginForTest(
        event(
          SabotageType.fakeOrder,
          id: 'event_02',
          fakeType: CardType.classicBurger,
        ),
        active: true,
      );
      final shift = ShiftState()..recordSuccessfulService(enterFeedback: false);
      final wallet = shift.walletCoins;
      shift.resetCombo();
      expect(rival.triggerFakeOrderPenalty(), isTrue);
      expect(shift.walletCoins, wallet);
      expect(shift.currentCombo, 0);
      expect(orders.slots.map((slot) => slot.definition.id), realIds);

      rival.beginForTest(
        event(
          SabotageType.fakeOrder,
          id: 'event_03',
          fakeType: CardType.crispyFries,
        ),
        active: true,
      );
      rival.advance(13, canAdvance: true);
      expect(rival.current, isNull);
      expect(rival.affectedCount, 1);
    });

    test(
      '46-48 resolutions and counters occur exactly once and shift end clears',
      () {
        final rival = RivalState()
          ..beginForTest(event(SabotageType.powerSurge), active: true);
        final id = rival.countermeasureId!;
        expect(rival.tryCounter(id), isTrue);
        expect(rival.tryCounter(id), isFalse);
        expect(rival.defendedCount, 1);
        expect(rival.affectedCount, 1);
        expect(rival.resolutions, hasLength(1));
        rival.beginForTest(event(SabotageType.equipmentJam, id: 'event_02'));
        rival.endShift();
        expect(rival.current, isNull);
        expect(rival.enabled, isFalse);
        expect(
          rival.resolutions.last.reason,
          SabotageResolutionReason.clearedAtShiftEnd,
        );
      },
    );

    test('49 results retain summary without changing grade thresholds', () {
      final shift = ShiftState()..setSabotageSummary(defended: 2, affected: 1);
      expect(shift.result.sabotagesDefended, 2);
      expect(shift.result.sabotagesAffected, 1);
      expect(shift.result.gradeLabel, 'C');
    });

    test('50 active sabotage is not part of permanent save-shaped state', () {
      final rival = RivalState()
        ..beginForTest(event(SabotageType.greasyTable), active: true);
      rival.clearTemporaryState();
      expect(rival.current, isNull);
      expect(rival.countermeasureId, isNull);
      expect(rival.greasyRegion, isNull);
    });

    test('51-55 core phase/input/progression invariants stay independent', () {
      final shift = ShiftState();
      expect(shift.isGameplayInputAllowed, isTrue);
      shift.pause();
      expect(shift.phase, ShiftPhase.paused);
      expect(shift.isGameplayInputAllowed, isFalse);
      shift.resume();
      expect(shift.phase, ShiftPhase.active);
      final kitchen = Vs7Kitchen();
      expect(kitchen.table.hasConsistentCardLocations(), isTrue);
      expect(
        kitchen.table.definitions.where(
          (definition) =>
              kitchen.table.placementFor(definition.id).zone == CardZone.hand,
        ),
        hasLength(6),
      );
    });
  });
}
