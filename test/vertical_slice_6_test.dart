import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:son_siparis/game/models/app_screen.dart';
import 'package:son_siparis/game/models/game_settings.dart';
import 'package:son_siparis/game/models/save_data.dart';
import 'package:son_siparis/game/models/tutorial_status.dart';
import 'package:son_siparis/game/models/upgrade_id.dart';
import 'package:son_siparis/game/services/audio_service.dart';
import 'package:son_siparis/game/services/haptic_service.dart';
import 'package:son_siparis/game/services/save_service.dart';
import 'package:son_siparis/game/son_siparis_game.dart';
import 'package:son_siparis/game/state/feedback_state.dart';
import 'package:son_siparis/game/state/game_flow_controller.dart';
import 'package:son_siparis/game/state/run_progression_state.dart';
import 'package:son_siparis/game/state/tutorial_state.dart';

void main() {
  group('settings feedback gates', () {
    test('settings defaults are on/on/on', () {
      final settings = GameSettings();
      expect(settings.soundEffectsEnabled, isTrue);
      expect(settings.musicEnabled, isTrue);
      expect(settings.hapticsEnabled, isTrue);
    });

    test('disabled sound prevents the platform player call', () {
      var calls = 0;
      final service = PlatformAudioService(
        GameSettings(soundEffectsEnabled: false),
        player: () => calls++,
      );
      service.play(SoundEventId.cardPickUp);
      expect(calls, 0);
    });

    test('enabled sound invokes the player once', () {
      var calls = 0;
      final service = PlatformAudioService(
        GameSettings(),
        player: () => calls++,
      );
      service.play(SoundEventId.cardPickUp);
      expect(calls, 1);
    });

    test('disabled haptics prevents the platform performer call', () {
      var calls = 0;
      final service = PlatformHapticService(
        GameSettings(hapticsEnabled: false),
        performer: (_) => calls++,
      );
      service.trigger(HapticEvent.service);
      expect(calls, 0);
    });

    test('enabled haptics forwards the exact event', () {
      HapticEvent? received;
      final service = PlatformHapticService(
        GameSettings(),
        performer: (event) => received = event,
      );
      service.trigger(HapticEvent.recipeComplete);
      expect(received, HapticEvent.recipeComplete);
    });
  });

  group('feedback state', () {
    test('combo milestones fire once in a combo chain', () {
      final tracker = ComboMilestoneTracker();
      expect(tracker.record(3), 3);
      expect(tracker.record(3), isNull);
      expect(tracker.record(5), 5);
      expect(tracker.record(8), 8);
      expect(tracker.record(10), 10);
    });

    test('combo reset restores milestone eligibility', () {
      final tracker = ComboMilestoneTracker();
      expect(tracker.record(3), 3);
      expect(tracker.record(0), isNull);
      expect(tracker.record(3), 3);
    });

    test('last-second feedback only triggers at one second or less', () {
      final feedback = LastSecondFeedbackState();
      expect(feedback.trigger(1.01), isFalse);
      expect(feedback.isActive, isFalse);
      expect(feedback.trigger(1), isTrue);
      expect(feedback.servedPatienceSeconds, 1);
    });

    test(
      'last-second slowdown is bounded and does not change future deltas',
      () {
        final feedback = LastSecondFeedbackState()..trigger(.42);
        final slowed = feedback.scaleDelta(.1);
        expect(slowed, lessThan(.1));
        for (var index = 0; index < 4; index++) {
          feedback.scaleDelta(.1);
        }
        expect(feedback.isActive, isFalse);
        expect(feedback.scaleDelta(.1), .1);
      },
    );
  });

  group('save schema and recovery', () {
    test('default save creates day 1, wallet 120, and no progress', () {
      final data = SaveData();
      expect(data.schemaVersion, 1);
      expect(data.day, 1);
      expect(data.wallet, 120);
      expect(data.hasProgress, isFalse);
    });

    test('valid v1 save loads all stable fields', () {
      final data = SaveData.fromJson(
        {
          'schemaVersion': 1,
          'day': 4,
          'wallet': 415,
          'upgradeLevels': {'fastPan': 2},
          'discoveredRecipeIds': ['classic_burger', 'deluxe_burger'],
          'tutorialStatus': 'completed',
          'settings': {
            'soundEffectsEnabled': false,
            'musicEnabled': true,
            'hapticsEnabled': false,
          },
        },
        knownUpgradeIds: _upgradeIds,
        knownRecipeIds: _recipeIds,
      );
      expect(data.day, 4);
      expect(data.wallet, 415);
      expect(data.upgradeLevels['fastPan'], 2);
      expect(data.discoveredRecipeIds, contains('deluxe_burger'));
      expect(data.tutorialStatus, TutorialStatus.completed);
      expect(data.settings.soundEffectsEnabled, isFalse);
      expect(data.settings.hapticsEnabled, isFalse);
    });

    test('missing fields recover with defaults', () {
      final data = SaveData.fromJson(
        const {'schemaVersion': 1},
        knownUpgradeIds: _upgradeIds,
        knownRecipeIds: _recipeIds,
      );
      expect(data.day, 1);
      expect(data.wallet, 120);
      expect(data.settings.musicEnabled, isTrue);
    });

    test('invalid upgrade levels clamp to zero through three', () {
      final data = SaveData.fromJson(
        {
          'upgradeLevels': {'fastPan': -9, 'doubleCheese': 99},
        },
        knownUpgradeIds: _upgradeIds,
        knownRecipeIds: _recipeIds,
      );
      expect(data.upgradeLevels['fastPan'], 0);
      expect(data.upgradeLevels['doubleCheese'], 3);
    });

    test('unknown IDs are ignored', () {
      final data = SaveData.fromJson(
        {
          'upgradeLevels': {'mystery': 2},
          'discoveredRecipeIds': ['mystery_recipe'],
        },
        knownUpgradeIds: _upgradeIds,
        knownRecipeIds: _recipeIds,
      );
      expect(data.upgradeLevels, isEmpty);
      expect(data.discoveredRecipeIds, isNot(contains('mystery_recipe')));
    });

    test('future schema loads safe defaults', () {
      final data = SaveData.fromJson(
        const {'schemaVersion': 99, 'day': 50},
        knownUpgradeIds: _upgradeIds,
        knownRecipeIds: _recipeIds,
      );
      expect(data.day, 1);
      expect(data.wallet, 120);
    });

    test('corrupted JSON loads safe defaults without crashing', () async {
      final store = MemorySaveStore('not-json');
      final service = _service(store);
      final data = await service.load();
      expect(data.day, 1);
      expect(data.wallet, 120);
    });

    test('settings toggles persist through save and reload', () async {
      final store = MemorySaveStore();
      final service = _service(store);
      await service.save(
        SaveData(
          settings: GameSettings(
            soundEffectsEnabled: false,
            musicEnabled: false,
            hapticsEnabled: true,
          ),
        ),
      );
      final loaded = await service.load();
      expect(loaded.settings.soundEffectsEnabled, isFalse);
      expect(loaded.settings.musicEnabled, isFalse);
      expect(loaded.settings.hapticsEnabled, isTrue);
    });

    test('reset clears persisted data and returns defaults', () async {
      final store = MemorySaveStore();
      final service = _service(store);
      await service.save(SaveData(day: 5, wallet: 900));
      await service.reset();
      expect((await service.load()).day, 1);
      expect(store.value, isNull);
    });

    test('save-write failure is non-fatal', () async {
      final service = _service(FailingSaveStore());
      await expectLater(service.save(SaveData(day: 2)), completes);
    });
  });

  group('startup and menu flow', () {
    test('Settings is accessible only from main menu', () {
      final flow = GameFlowController();
      expect(flow.showSettings(), isTrue);
      expect(flow.screen, AppScreen.settings);
      expect(flow.closeSettings(), isTrue);
      expect(flow.startShift(), isTrue);
      expect(flow.showSettings(), isFalse);
    });

    test('Continue is disabled for default save', () {
      expect(SonSiparisGame(initialSaveData: SaveData()).canContinue, isFalse);
    });

    test('Continue is enabled when permanent progress exists', () {
      expect(
        SonSiparisGame(initialSaveData: SaveData(day: 2)).canContinue,
        isTrue,
      );
    });

    test('relaunch restores permanent state and starts at main menu', () {
      final game = SonSiparisGame(
        initialSaveData: SaveData(
          day: 7,
          wallet: 725,
          upgradeLevels: const {'fastPan': 3},
          discoveredRecipeIds: const {
            'classic_burger',
            'crispy_fries',
            'spicy_burger',
          },
          tutorialStatus: TutorialStatus.completed,
        ),
      );
      expect(game.flow.screen, AppScreen.mainMenu);
      expect(game.flow.progression.currentDay, 7);
      expect(game.flow.progression.walletCoins, 725);
      expect(game.flow.progression.levelFor(UpgradeId.fastPan), 3);
      expect(game.recipeDiscoveryState.isDiscovered('spicy_burger'), isTrue);
      expect(game.tutorialState.status, TutorialStatus.completed);
    });

    test('active tutorial or shift state is not restored after relaunch', () {
      final game = SonSiparisGame(
        initialSaveData: SaveData(tutorialStatus: TutorialStatus.active),
      );
      expect(game.flow.screen, AppScreen.mainMenu);
      expect(game.tutorialState.status, TutorialStatus.notStarted);
      expect(game.shiftState.elapsedShiftSeconds, 0);
    });

    test('progression reset restores day wallet and upgrades', () {
      final progression = RunProgressionState(currentDay: 4, walletCoins: 500);
      progression.advanceDay();
      progression.reset();
      expect(progression.currentDay, 1);
      expect(progression.walletCoins, 120);
      expect(UpgradeId.values.map(progression.levelFor), everyElement(0));
    });

    test('tutorial replay returns tutorial to not started', () {
      final tutorial = TutorialState(initialStatus: TutorialStatus.completed);
      tutorial.resetForReplay();
      expect(tutorial.status, TutorialStatus.notStarted);
      expect(tutorial.patienceProtectionActive, isFalse);
    });
  });
}

const _upgradeIds = {'fastPan', 'doubleCheese', 'coolHeadedService'};
const _recipeIds = {
  'classic_burger',
  'crispy_fries',
  'deluxe_burger',
  'spicy_burger',
};

SaveService _service(SaveStore store) => SaveService(
  store: store,
  knownUpgradeIds: _upgradeIds,
  knownRecipeIds: _recipeIds,
);

class MemorySaveStore implements SaveStore {
  MemorySaveStore([this.value]);
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    jsonDecode(value);
    this.value = value;
  }
}

class FailingSaveStore implements SaveStore {
  @override
  Future<void> clear() async => throw StateError('expected');

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async => throw StateError('expected');
}
