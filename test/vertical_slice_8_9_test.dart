import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:son_siparis/game/data/content_unlock_definitions.dart';
import 'package:son_siparis/game/data/market_catalog.dart';
import 'package:son_siparis/game/data/recipe_book_entries.dart';
import 'package:son_siparis/game/models/app_screen.dart';
import 'package:son_siparis/game/models/content_ownership.dart';
import 'package:son_siparis/game/models/daily_challenge_result.dart';
import 'package:son_siparis/game/models/game_mode.dart';
import 'package:son_siparis/game/models/kitchen_loadout.dart';
import 'package:son_siparis/game/models/save_data.dart';
import 'package:son_siparis/game/models/tutorial_status.dart';
import 'package:son_siparis/game/models/upgrade_id.dart';
import 'package:son_siparis/game/services/save_service.dart';
import 'package:son_siparis/game/son_siparis_game.dart';
import 'package:son_siparis/game/state/challenge_score_state.dart';
import 'package:son_siparis/game/state/daily_challenge_state.dart';
import 'package:son_siparis/game/state/loadout_state.dart';
import 'package:son_siparis/game/state/market_state.dart';
import 'package:son_siparis/game/state/recipe_discovery_state.dart';
import 'package:son_siparis/game/state/run_progression_state.dart';
import 'package:son_siparis/game/systems/daily_seed_factory.dart';
import 'package:son_siparis/game/systems/loadout_recipe_resolver.dart';
import 'package:son_siparis/game/systems/order_result_generator.dart';
import 'package:son_siparis/game/systems/sabotage_scheduler.dart';
import 'package:son_siparis/main.dart';

class MemorySaveStore implements SaveStore {
  String? value;
  bool failWrites = false;
  int writes = 0;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    writes++;
    if (failWrites) throw StateError('write failed');
    this.value = value;
  }
}

SaveService serviceFor(MemorySaveStore store) => SaveService(
  store: store,
  knownUpgradeIds: UpgradeId.values.map((id) => id.name).toSet(),
  knownRecipeIds: recipeBookEntries.map((entry) => entry.id).toSet(),
);

({
  RunProgressionState progression,
  ContentOwnership ownership,
  LoadoutState loadout,
  RecipeDiscoveryState discovery,
  MarketState market,
})
marketFixture({int wallet = 600}) {
  final progression = RunProgressionState(walletCoins: wallet);
  final ownership = ContentOwnership();
  final loadout = LoadoutState(ownership: ownership);
  final discovery = RecipeDiscoveryState();
  return (
    progression: progression,
    ownership: ownership,
    loadout: loadout,
    discovery: discovery,
    market: MarketState(
      catalog: marketCatalog,
      progression: progression,
      ownership: ownership,
      loadout: loadout,
      discovery: discovery,
    ),
  );
}

void main() {
  group('Market and permanent ownership 1-12', () {
    test('fresh v2 profile has starter content and exact catalog prices', () {
      final data = SaveData();
      expect(data.schemaVersion, 2);
      expect(data.ownedMarketPackIds, isEmpty);
      expect(data.unlockedIngredientIds, ContentOwnership.starterIngredientIds);
      expect(data.unlockedEquipmentIds, ContentOwnership.starterEquipmentIds);
      expect(data.unlockedRecipeIds, ContentOwnership.starterRecipeIds);
      expect(data.selectedIngredientIds, KitchenLoadout.starter.ingredientIds);
      expect(data.selectedEquipmentIds, KitchenLoadout.starter.equipmentIds);
      expect(
        const LoadoutRecipeResolver().supportedRecipeIds(
          loadout: KitchenLoadout.starter,
          unlockedRecipeIds: data.unlockedRecipeIds,
        ),
        {'classic_burger'},
      );
      expect(marketCatalog.map((pack) => pack.priceCoins), [180, 240, 220]);
    });

    test('successful purchases unlock exact content and deduct once', () async {
      final fixture = marketFixture();
      var writes = 0;
      final first = await fixture.market.purchase(
        packId: 'pack_gourmet',
        isMarketScreen: true,
        persistCurrentSnapshot: () async {
          writes++;
          return true;
        },
      );
      expect(first, MarketPurchaseResult.success);
      expect(fixture.progression.walletCoins, 360);
      expect(fixture.ownership.ownedPackIds, {'pack_gourmet'});
      expect(fixture.ownership.unlockedIngredientIds, contains('tomato_01'));
      expect(fixture.ownership.unlockedEquipmentIds, contains('knife_01'));
      expect(fixture.ownership.unlockedRecipeIds, contains('deluxe_burger'));
      expect(fixture.discovery.isDiscovered('deluxe_burger'), isTrue);
      expect(fixture.loadout.active.ingredientIds, contains('tomato_01'));
      expect(fixture.loadout.active.equipmentIds, contains('knife_01'));
      expect(writes, 1);

      final repeated = await fixture.market.purchase(
        packId: 'pack_gourmet',
        isMarketScreen: true,
        persistCurrentSnapshot: () async {
          writes++;
          return true;
        },
      );
      expect(repeated, MarketPurchaseResult.alreadyOwned);
      expect(fixture.progression.walletCoins, 360);
      expect(writes, 1);
    });

    test('insufficient funds and invalid screen change nothing', () async {
      final fixture = marketFixture(wallet: 120);
      expect(
        await fixture.market.purchase(
          packId: 'pack_spicy',
          isMarketScreen: true,
          persistCurrentSnapshot: () async => true,
        ),
        MarketPurchaseResult.insufficientFunds,
      );
      expect(
        await fixture.market.purchase(
          packId: 'pack_spicy',
          isMarketScreen: false,
          persistCurrentSnapshot: () async => true,
        ),
        MarketPurchaseResult.invalidScreen,
      );
      expect(fixture.progression.walletCoins, 120);
      expect(fixture.ownership.ownedPackIds, isEmpty);
    });

    test('persistence failure rolls back the complete transaction', () async {
      final fixture = marketFixture();
      final result = await fixture.market.purchase(
        packId: 'pack_fryer',
        isMarketScreen: true,
        persistCurrentSnapshot: () async => throw StateError('disk full'),
      );
      expect(result, MarketPurchaseResult.persistenceFailed);
      expect(fixture.progression.walletCoins, 600);
      expect(fixture.ownership.ownedPackIds, isEmpty);
      expect(fixture.ownership.ownsIngredient('potato_01'), isFalse);
      expect(fixture.ownership.ownsEquipment('fryer_01'), isFalse);
      expect(fixture.discovery.isDiscovered('crispy_fries'), isFalse);
      expect(fixture.loadout.active, isNotNull);
    });

    test(
      'an in-flight purchase rejects repeated taps without double debit',
      () async {
        final fixture = marketFixture();
        final writeGate = Completer<bool>();
        final first = fixture.market.purchase(
          packId: 'pack_spicy',
          isMarketScreen: true,
          persistCurrentSnapshot: () => writeGate.future,
        );
        expect(fixture.market.transactionRunning, isTrue);
        expect(
          await fixture.market.purchase(
            packId: 'pack_spicy',
            isMarketScreen: true,
            persistCurrentSnapshot: () async => true,
          ),
          MarketPurchaseResult.transactionRunning,
        );
        expect(fixture.progression.walletCoins, 420);
        writeGate.complete(true);
        expect(await first, MarketPurchaseResult.success);
        expect(fixture.progression.walletCoins, 420);
      },
    );

    test('purchased ownership and recipes persist after relaunch', () async {
      final store = MemorySaveStore();
      final service = serviceFor(store);
      final data = SaveData(
        wallet: 360,
        ownedMarketPackIds: const {'pack_gourmet'},
        unlockedIngredientIds: const {
          ...ContentOwnership.starterIngredientIds,
          'tomato_01',
        },
        unlockedEquipmentIds: const {
          ...ContentOwnership.starterEquipmentIds,
          'knife_01',
        },
        unlockedRecipeIds: const {'classic_burger', 'deluxe_burger'},
        discoveredRecipeIds: const {'classic_burger', 'deluxe_burger'},
        selectedIngredientIds: const {
          ...ContentOwnership.starterIngredientIds,
          'tomato_01',
        },
        selectedEquipmentIds: const {'pan_01', 'knife_01'},
      );
      expect(await service.saveChecked(data), isTrue);
      final loaded = await service.load();
      expect(loaded.ownedMarketPackIds, {'pack_gourmet'});
      expect(loaded.unlockedRecipeIds, contains('deluxe_burger'));
      expect(loaded.discoveredRecipeIds, contains('deluxe_burger'));
      expect(loaded.selectedEquipmentIds, contains('knife_01'));
    });

    test(
      'buying all three packs unlocks the complete authored catalog',
      () async {
        final fixture = marketFixture(wallet: 1000);
        for (final pack in marketCatalog) {
          expect(
            await fixture.market.purchase(
              packId: pack.id,
              isMarketScreen: true,
              persistCurrentSnapshot: () async => true,
            ),
            MarketPurchaseResult.success,
          );
        }
        expect(fixture.progression.walletCoins, 360);
        expect(fixture.ownership.ownedPackIds, allMarketPackIds);
        expect(fixture.ownership.unlockedIngredientIds, allIngredientIds);
        expect(fixture.ownership.unlockedEquipmentIds, allEquipmentIds);
        expect(fixture.ownership.unlockedRecipeIds, allRecipeIds);
        expect(fixture.loadout.active.ingredientIds, allIngredientIds);
        expect(fixture.loadout.active.equipmentIds, allEquipmentIds);
      },
    );
  });

  group('Active Kitchen 13-24', () {
    test('only owned content toggles and editor close discards changes', () {
      final ownership = ContentOwnership();
      final state = LoadoutState(ownership: ownership)..openEditor();
      expect(state.toggleIngredient('tomato_01'), isFalse);
      expect(state.toggleEquipment('knife_01'), isFalse);
      expect(state.toggleIngredient('cheese_01'), isTrue);
      expect(state.draft!.ingredientIds, isNot(contains('cheese_01')));
      state.closeWithoutSaving();
      expect(state.active.ingredientIds, contains('cheese_01'));
    });

    test('capacity is enforced for ingredients and equipment', () {
      final ownership = ContentOwnership(
        unlockedIngredientIds: allIngredientIds,
        unlockedEquipmentIds: allEquipmentIds,
        unlockedRecipeIds: allRecipeIds,
      );
      final state = LoadoutState(
        ownership: ownership,
        initialLoadout: const KitchenLoadout(
          ingredientIds: allIngredientIds,
          equipmentIds: allEquipmentIds,
        ),
      )..openEditor();
      expect(state.draft!.ingredientIds, hasLength(6));
      expect(state.draft!.equipmentIds, hasLength(3));
      expect(state.toggleIngredient('bread_01'), isTrue);
      expect(state.toggleIngredient('bread_01'), isTrue);
      expect(state.draft!.ingredientIds, hasLength(6));
    });

    test('invalid loadout cannot save; valid one persists once', () async {
      final ownership = ContentOwnership();
      final state = LoadoutState(ownership: ownership)..openEditor();
      state.toggleEquipment('pan_01');
      var writes = 0;
      expect(
        await state.save(() async {
          writes++;
          return true;
        }),
        LoadoutSaveResult.invalid,
      );
      expect(writes, 0);
      state.toggleEquipment('pan_01');
      expect(
        await state.save(() async {
          writes++;
          return true;
        }),
        LoadoutSaveResult.saved,
      );
      expect(writes, 1);
    });

    test('supported order pool never produces an impossible result', () {
      final supported = const LoadoutRecipeResolver().supportedResultTypes(
        loadout: KitchenLoadout.starter,
        unlockedRecipeIds: ContentOwnership.starterRecipeIds,
      );
      final generator = OrderResultGenerator(
        source: SeededOrderResultSource(55),
        availableResults: supported,
      );
      final results = List.generate(
        20,
        (_) => generator.nextResult(activeResults: const []),
      );
      expect(results.toSet(), hasLength(1));
      expect(results.first.name, 'classicBurger');
    });
  });

  group('Save schema v2 25-34', () {
    test(
      'valid v1 migration preserves progress and grandfathers all content',
      () {
        final migrated = SaveData.fromJson(
          {
            'schemaVersion': 1,
            'day': 7,
            'wallet': 777,
            'upgradeLevels': {'fastPan': 2},
            'discoveredRecipeIds': ['classic_burger'],
            'tutorialStatus': TutorialStatus.completed.name,
          },
          knownUpgradeIds: UpgradeId.values.map((id) => id.name).toSet(),
          knownRecipeIds: allRecipeIds,
        );
        expect(migrated.schemaVersion, 2);
        expect(migrated.day, 7);
        expect(migrated.wallet, 777);
        expect(migrated.ownedMarketPackIds, allMarketPackIds);
        expect(migrated.unlockedIngredientIds, allIngredientIds);
        expect(migrated.unlockedEquipmentIds, allEquipmentIds);
        expect(migrated.unlockedRecipeIds, allRecipeIds);
        expect(migrated.selectedIngredientIds, allIngredientIds);
        expect(migrated.selectedEquipmentIds, allEquipmentIds);
        expect(migrated.dailyChallengeRecords, isEmpty);
      },
    );

    test('SaveService writes a migrated v1 profile back as v2', () async {
      final store = MemorySaveStore()
        ..value = jsonEncode({'schemaVersion': 1, 'day': 3, 'wallet': 250});
      final loaded = await serviceFor(store).load();
      expect(loaded.schemaVersion, 2);
      expect(store.writes, 1);
      expect(jsonDecode(store.value!)['schemaVersion'], 2);
    });

    test('missing/unknown v2 values sanitize to a valid starter loadout', () {
      final data = SaveData.fromJson(
        {
          'schemaVersion': 2,
          'ownedMarketPackIds': ['unknown_pack'],
          'unlockedIngredientIds': ['unknown', 'potato_01'],
          'unlockedEquipmentIds': ['unknown'],
          'unlockedRecipeIds': ['unknown'],
          'selectedIngredientIds': ['potato_01', 'unknown'],
          'selectedEquipmentIds': ['fryer_01', 'unknown'],
        },
        knownUpgradeIds: const {},
        knownRecipeIds: allRecipeIds,
      );
      expect(data.ownedMarketPackIds, isEmpty);
      expect(
        data.unlockedIngredientIds,
        containsAll(['bread_01', 'patty_01', 'cheese_01']),
      );
      expect(data.selectedIngredientIds, KitchenLoadout.starter.ingredientIds);
      expect(data.selectedEquipmentIds, KitchenLoadout.starter.equipmentIds);
    });

    test(
      'future schema and corrupted JSON recover without ownership',
      () async {
        final future = SaveData.fromJson(
          {
            'schemaVersion': 99,
            'ownedMarketPackIds': allMarketPackIds.toList(),
          },
          knownUpgradeIds: const {},
          knownRecipeIds: allRecipeIds,
        );
        expect(future.ownedMarketPackIds, isEmpty);
        final store = MemorySaveStore()..value = '{bad';
        final recovered = await serviceFor(store).load();
        expect(recovered.schemaVersion, 2);
        expect(recovered.ownedMarketPackIds, isEmpty);
      },
    );
  });

  group('Daily seed and deterministic streams 35-41', () {
    const factory = DailySeedFactory();
    test('same date/version is stable and different dates differ', () {
      final first = factory.challengeSeed('2026-08-01');
      expect(first, factory.challengeSeed('2026-08-01'));
      expect(first, isNot(factory.challengeSeed('2026-08-02')));
      expect(first, factory.stableHash('son_siparis_daily_v1:2026-08-01'));
    });

    test('order and sabotage streams are deterministic and independent', () {
      final base = factory.challengeSeed('2026-08-01');
      final orderSeed = factory.streamSeed(base, 'orders');
      final sabotageSeed = factory.streamSeed(base, 'sabotages');
      expect(orderSeed, isNot(sabotageSeed));
      final firstOrders = OrderResultGenerator(
        source: SeededOrderResultSource(orderSeed),
      );
      final secondOrders = OrderResultGenerator(
        source: SeededOrderResultSource(orderSeed),
      );
      expect(
        List.generate(
          12,
          (_) => firstOrders.nextResult(activeResults: const []),
        ),
        List.generate(
          12,
          (_) => secondOrders.nextResult(activeResults: const []),
        ),
      );
      const scheduler = SabotageScheduler();
      final firstSchedule = scheduler.buildSchedule(
        day: 5,
        rivalId: 'kara_kazan',
        testSeed: sabotageSeed,
      );
      final secondSchedule = scheduler.buildSchedule(
        day: 5,
        rivalId: 'kara_kazan',
        testSeed: sabotageSeed,
      );
      expect(firstSchedule, hasLength(2));
      expect(
        firstSchedule
            .map((entry) => '${entry.type.name}:${entry.scheduledAtSeconds}')
            .toList(),
        secondSchedule
            .map((entry) => '${entry.type.name}:${entry.scheduledAtSeconds}')
            .toList(),
      );
    });

    test('injected date provider authoritatively controls the date', () {
      final state = DailyChallengeState(
        dateProvider: FixedDateProvider(DateTime(2030, 2, 3)),
      )..start();
      expect(state.activeDateKey, '2030-02-03');
      expect(state.activeSeed, factory.challengeSeed('2030-02-03'));
    });
  });

  group('Authoritative scoring 52-62', () {
    test(
      'service formula uses reward, post-service combo, and floored patience',
      () {
        final score = ChallengeScoreState();
        expect(
          score.recordService(
            transactionId: 'service:1',
            serviceReward: 10,
            comboAfterService: 3,
            remainingPatienceSeconds: 8.49,
          ),
          isTrue,
        );
        expect(score.displayedScore, 1234);
        expect(
          score.recordService(
            transactionId: 'service:1',
            serviceReward: 10,
            comboAfterService: 3,
            remainingPatienceSeconds: 8.49,
          ),
          isFalse,
        );
        expect(score.displayedScore, 1234);
      },
    );

    test('all score events are exact, once-only, and clamp visually', () {
      final score = ChallengeScoreState();
      expect(score.recordSabotageDefended('defend:1'), isTrue);
      expect(score.recordSabotageDefended('defend:1'), isFalse);
      score.recordMissedCustomer('miss:1');
      score.recordSabotageHit('hit:1');
      score.recordWrongService('wrong:1');
      expect(score.rawScore, -750);
      expect(score.displayedScore, 0);
      expect(score.entries.map((entry) => entry.points), [
        250,
        -500,
        -200,
        -300,
      ]);
    });

    test('fake order has one sabotage-hit transaction, not wrong service', () {
      final score = ChallengeScoreState();
      score.recordSabotageHit('fake:event_1');
      score.recordSabotageHit('fake:event_1');
      expect(score.entries, hasLength(1));
      expect(score.rawScore, -200);
    });
  });

  group('Personal best 63-70', () {
    test('first/higher replace; lower/equal do not write', () async {
      final state = DailyChallengeState(
        dateProvider: FixedDateProvider(DateTime(2026, 8, 1)),
      )..start();
      var writes = 0;
      state.score.recordService(
        transactionId: 'one',
        serviceReward: 10,
        comboAfterService: 1,
        remainingPatienceSeconds: 0,
      );
      expect(
        await state.commitResult(
          completedOrders: 1,
          highestCombo: 1,
          missedOrders: 0,
          sabotagesDefended: 0,
          sabotageHits: 0,
          recordedAt: DateTime.utc(2026, 8, 1),
          persistCurrentSnapshot: () async {
            writes++;
            return true;
          },
        ),
        isTrue,
      );
      expect(writes, 1);
      expect(state.activeBest?.bestScore, 1050);

      state.start();
      state.score.recordService(
        transactionId: 'higher',
        serviceReward: 20,
        comboAfterService: 1,
        remainingPatienceSeconds: 0,
      );
      expect(
        await state.commitResult(
          completedOrders: 1,
          highestCombo: 1,
          missedOrders: 0,
          sabotagesDefended: 0,
          sabotageHits: 0,
          recordedAt: DateTime.utc(2026, 8, 1, 2),
          persistCurrentSnapshot: () async {
            writes++;
            return true;
          },
        ),
        isTrue,
      );
      expect(writes, 2);
      expect(state.activeBest?.bestScore, 2050);

      state.start();
      state.score.recordService(
        transactionId: 'equal',
        serviceReward: 20,
        comboAfterService: 1,
        remainingPatienceSeconds: 0,
      );
      expect(
        await state.commitResult(
          completedOrders: 1,
          highestCombo: 1,
          missedOrders: 0,
          sabotagesDefended: 0,
          sabotageHits: 0,
          recordedAt: DateTime.utc(2026, 8, 1, 3),
          persistCurrentSnapshot: () async {
            writes++;
            return true;
          },
        ),
        isFalse,
      );
      expect(writes, 2);
      expect(state.activeBest?.bestScore, 2050);

      state.start();
      expect(
        await state.commitResult(
          completedOrders: 0,
          highestCombo: 0,
          missedOrders: 1,
          sabotagesDefended: 0,
          sabotageHits: 0,
          recordedAt: DateTime.utc(2026, 8, 1, 1),
          persistCurrentSnapshot: () async {
            writes++;
            return true;
          },
        ),
        isFalse,
      );
      expect(writes, 2);
      expect(state.activeBest?.bestScore, 2050);
    });

    test('records are date/rules isolated and history prunes to 30', () {
      final records = <String, DailyChallengeRecord>{};
      for (var day = 1; day <= 35; day++) {
        final date = '2026-07-${day.toString().padLeft(2, '0')}';
        final record = DailyChallengeRecord(
          dateKey: date,
          rulesVersion: 1,
          bestScore: day,
          completedOrders: 0,
          highestCombo: 0,
          missedOrders: 0,
          sabotagesDefended: 0,
          sabotageHits: 0,
          recordedTimestamp: DateTime.utc(2026, 7, 1).toIso8601String(),
        );
        records[record.storageKey] = record;
      }
      final encoded = SaveData(dailyChallengeRecords: records).toJson();
      final decoded = SaveData.fromJson(
        encoded,
        knownUpgradeIds: const {},
        knownRecipeIds: allRecipeIds,
      );
      expect(decoded.dailyChallengeRecords, hasLength(30));
      expect(decoded.dailyChallengeRecords.keys, contains('1:2026-07-35'));
      expect(
        decoded.dailyChallengeRecords.keys,
        isNot(contains('1:2026-07-01')),
      );
    });
  });

  group('GameWidget flow/isolation 42-51 and 71-81', () {
    testWidgets('fresh career uses starter pantry/equipment/orders', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final game = SonSiparisGame();
      await tester.pumpWidget(SonSiparisApp(game: game));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(640, 384));
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.gameMode, GameMode.career);
      expect(
        game.pantryState.slots.map((slot) => slot.id).toSet(),
        KitchenLoadout.starter.ingredientIds,
      );
      expect(
        game.tableState.definitions.map((definition) => definition.id).toSet(),
        {'pan_01'},
      );
      expect(
        game.orderSystem.activeSlots
            .map((slot) => slot.order!.requestedResultType.name)
            .toSet(),
        {'classicBurger'},
      );
    });

    testWidgets('Daily Challenge is all-content and career-isolated', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final initial = SaveData(
        day: 4,
        wallet: 555,
        upgradeLevels: const {'fastPan': 2},
      );
      final game = SonSiparisGame(
        initialSaveData: initial,
        dateProvider: FixedDateProvider(DateTime(2026, 8, 1)),
      );
      await tester.pumpWidget(SonSiparisApp(game: game));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(640, 502));
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.gameMode, GameMode.dailyChallenge);
      expect(
        game.pantryState.slots.map((slot) => slot.id).toSet(),
        allIngredientIds,
      );
      expect(
        game.tableState.definitions.map((definition) => definition.id).toSet(),
        allEquipmentIds,
      );
      expect(game.rivalState.schedule, hasLength(2));
      expect(game.tutorialState.isActive, isFalse);
      expect(game.flow.progression.currentDay, 4);
      expect(game.flow.progression.walletCoins, 555);
      final firstSeed = game.dailyChallengeState.activeSeed;
      final firstOrders = game.orderSystem.activeSlots
          .map((slot) => slot.order!.requestedResultType)
          .toList();

      game.update(90);
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.flow.screen, AppScreen.dailyChallengeResults);
      expect(game.flow.progression.currentDay, 4);
      expect(game.flow.progression.walletCoins, 555);
      expect(game.flow.screen, isNot(AppScreen.upgradeSelection));

      await tester.tapAt(const Offset(505, 639));
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.flow.screen, AppScreen.gameplay);
      expect(game.dailyChallengeState.activeSeed, firstSeed);
      expect(
        game.orderSystem.activeSlots
            .map((slot) => slot.order!.requestedResultType)
            .toList(),
        firstOrders,
      );
    });
  });
}
