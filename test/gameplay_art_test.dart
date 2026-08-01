import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:son_siparis/game/art/gameplay_art.dart';
import 'package:son_siparis/game/components/game_card_component.dart';
import 'package:son_siparis/game/game_layout.dart';
import 'package:son_siparis/game/models/card_definition.dart';
import 'package:son_siparis/game/models/customer_patience_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all accepted production artwork is present and decodes safely',
    () async {
      expect(GameplayArt.productionAssetPaths, hasLength(26));
      for (final assetPath in GameplayArt.productionAssetPaths) {
        final file = File(assetPath);
        expect(await file.exists(), isTrue, reason: assetPath);
        final image = await GameplayArt.decodeValidatedPng(
          await file.readAsBytes(),
        );
        expect(image, isNotNull, reason: assetPath);
        expect(image!.width, lessThanOrEqualTo(512));
        expect(image.height, lessThanOrEqualTo(512));
        image.dispose();
      }
    },
  );

  test('invalid and opaque images fail safely', () async {
    expect(
      await GameplayArt.decodeValidatedPng(Uint8List.fromList([1, 2, 3, 4])),
      isNull,
    );
    final opaquePng = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4//8/AwAI/AL+KDvK0QAAAABJRU5ErkJggg==',
    );
    expect(await GameplayArt.decodeValidatedPng(opaquePng), isNull);
  });

  test('ingredient, result, and equipment mappings are authoritative', () {
    expect(
      GameplayArt.productionAssetPaths,
      contains('assets/ui/gameplay/ingredients/bread.png'),
    );
    expect(
      GameplayArt.productionAssetPaths,
      contains('assets/ui/gameplay/ingredients/raw_patty.png'),
    );
    expect(
      GameplayArt.productionAssetPaths,
      contains('assets/ui/gameplay/ingredients/cheese.png'),
    );
    expect(
      GameplayArt.productionAssetPaths,
      contains('assets/ui/gameplay/ingredients/hot_sauce.png'),
    );
    expect(
      GameplayArt.productionAssetPaths,
      contains('assets/ui/gameplay/ingredients/raw_potato.png'),
    );
    expect(
      GameplayArt.productionAssetPaths,
      contains('assets/ui/gameplay/ingredients/sliced_tomato.png'),
    );
    expect(GameplayArt.instance.cardImage(CardType.tomato), isNull);
    expect(GameplayArt.instance.cardImage(CardType.cookedPatty), isNull);
  });

  test('customer identity remains stable across patience moods', () {
    for (final customerId in const [
      'customer_regular',
      'customer_impatient',
      'customer_foodie',
    ]) {
      final matches = GameplayArt.customerAssets.keys.where(
        (key) => key.startsWith('${customerId}_'),
      );
      expect(matches, hasLength(3));
      expect(
        matches,
        containsAll(<String>[
          '${customerId}_${CustomerPatienceStatus.safe.name}',
          '${customerId}_${CustomerPatienceStatus.warning.name}',
          '${customerId}_${CustomerPatienceStatus.danger.name}',
        ]),
      );
    }
  });

  test('all four prepared results and the rival badge have production art', () {
    expect(
      GameplayArt.productionAssetPaths,
      containsAll(<String>[
        'assets/ui/gameplay/foods/classic_burger.png',
        'assets/ui/gameplay/foods/gourmet_burger.png',
        'assets/ui/gameplay/foods/spicy_burger.png',
        'assets/ui/gameplay/foods/crispy_fries.png',
        GameplayArt.rivalBadgeAsset,
      ]),
    );
  });

  test(
    'equipment art follows busy state without resetting its card bounds',
    () async {
      final assetData = await rootBundle.load(
        'assets/ui/gameplay/equipment/pan_idle.png',
      );
      expect(assetData.lengthInBytes, greaterThan(0));
      await GameplayArt.instance.preload();
      final card = GameCardComponent(
        initialPosition: Vector2(740, 240),
        definition: const CardDefinition(
          id: 'pan_01',
          type: CardType.pan,
          displayName: 'Tava',
          category: CardCategory.equipment,
        ),
        restingPriority: 5,
        onDragStarted: (_) => true,
        onDragPositionChanged: (_, _) {},
        onDragReleased: (_, position) => position,
        onDragFinished: (_) {},
      );
      final initialPosition = card.position.clone();
      final idleArtwork = GameplayArt.instance.cardImage(CardType.pan);
      card.applyRestingState(
        cardPosition: initialPosition,
        priority: 5,
        definition: card.definition,
        isLocked: true,
        isInteractionLocked: false,
        isProcessing: true,
      );

      expect(card.size, Vector2(GameLayout.cardWidth, GameLayout.cardHeight));
      expect(card.position, initialPosition);
      expect(
        GameplayArt.instance.cardImage(CardType.pan, isActive: true),
        isNot(same(idleArtwork)),
      );
      expect(card.isProcessing, isTrue);
    },
  );
}
