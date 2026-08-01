import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/card_definition.dart';
import '../models/customer_patience_state.dart';

/// Shared, validated artwork for the gameplay-only visual layer.
///
/// A missing, corrupt, or fully opaque production image is intentionally
/// ignored: each component continues to render its existing code fallback.
class GameplayArt {
  GameplayArt._();

  static final instance = GameplayArt._();

  static const customerAssets = <String, String>{
    'customer_regular_safe': 'assets/ui/gameplay/customers/regular_normal.png',
    'customer_regular_warning':
        'assets/ui/gameplay/customers/regular_impatient.png',
    'customer_regular_danger':
        'assets/ui/gameplay/customers/regular_critical.png',
    'customer_impatient_safe': 'assets/ui/gameplay/customers/hasty_normal.png',
    'customer_impatient_warning':
        'assets/ui/gameplay/customers/hasty_impatient.png',
    'customer_impatient_danger':
        'assets/ui/gameplay/customers/hasty_critical.png',
    'customer_foodie_safe': 'assets/ui/gameplay/customers/gourmet_normal.png',
    'customer_foodie_warning':
        'assets/ui/gameplay/customers/gourmet_impatient.png',
    'customer_foodie_danger':
        'assets/ui/gameplay/customers/gourmet_critical.png',
  };

  static const _cardAssets = <CardType, String>{
    CardType.bread: 'assets/ui/gameplay/ingredients/bread.png',
    CardType.patty: 'assets/ui/gameplay/ingredients/raw_patty.png',
    CardType.cheese: 'assets/ui/gameplay/ingredients/cheese.png',
    CardType.hotSauce: 'assets/ui/gameplay/ingredients/hot_sauce.png',
    CardType.potato: 'assets/ui/gameplay/ingredients/raw_potato.png',
    CardType.slicedTomato: 'assets/ui/gameplay/ingredients/sliced_tomato.png',
    CardType.crispyFries: 'assets/ui/gameplay/foods/crispy_fries.png',
    CardType.classicBurger: 'assets/ui/gameplay/foods/classic_burger.png',
    CardType.deluxeBurger: 'assets/ui/gameplay/foods/gourmet_burger.png',
    CardType.spicyBurger: 'assets/ui/gameplay/foods/spicy_burger.png',
  };

  static const _equipmentAssets = <CardType, List<String>>{
    CardType.pan: [
      'assets/ui/gameplay/equipment/pan_idle.png',
      'assets/ui/gameplay/equipment/pan_active.png',
    ],
    CardType.knife: [
      'assets/ui/gameplay/equipment/knife_idle.png',
      'assets/ui/gameplay/equipment/knife_active.png',
    ],
    CardType.fryer: [
      'assets/ui/gameplay/equipment/fryer_idle.png',
      'assets/ui/gameplay/equipment/fryer_active.png',
    ],
  };

  static const rivalBadgeAsset = 'assets/ui/gameplay/rivals/black_cauldron.png';

  static List<String> get productionAssetPaths => [
    ...customerAssets.values,
    ..._cardAssets.values,
    ..._equipmentAssets.values.expand((paths) => paths),
    rivalBadgeAsset,
  ];

  final Map<String, ui.Image> _images = <String, ui.Image>{};
  Future<void>? _preloadFuture;

  bool get isReady => _images.isNotEmpty;

  Future<void> preload() {
    final inFlight = _preloadFuture;
    if (inFlight != null) return inFlight;
    final loadFuture = Future.wait(
      productionAssetPaths.map(_loadValidatedAsset),
    ).then((_) {});
    _preloadFuture = loadFuture.whenComplete(() {
      // A test/runtime asset bundle can become available after the game itself
      // mounts. Do not permanently cache an all-fallback attempt.
      if (_images.isEmpty) _preloadFuture = null;
    });
    return _preloadFuture!;
  }

  ui.Image? cardImage(CardType type, {bool isActive = false}) {
    final equipment = _equipmentAssets[type];
    if (equipment != null) return _images[equipment[isActive ? 1 : 0]];
    return _images[_cardAssets[type]];
  }

  ui.Image? resultImage(CardType? type) {
    if (type == null) return null;
    return _images[_cardAssets[type]];
  }

  ui.Image? customerImage(String customerId, CustomerPatienceStatus status) {
    final mood = switch (status) {
      CustomerPatienceStatus.safe => 'safe',
      CustomerPatienceStatus.warning => 'warning',
      CustomerPatienceStatus.danger ||
      CustomerPatienceStatus.expired => 'danger',
    };
    return _images[customerAssets['${customerId}_$mood']];
  }

  ui.Image? get rivalBadge => _images[rivalBadgeAsset];

  Future<void> _loadValidatedAsset(String path) async {
    try {
      final data = await rootBundle.load(path);
      final image = await decodeValidatedPng(data.buffer.asUint8List());
      if (image != null) _images[path] = image;
    } catch (_) {
      // Rendering intentionally falls back to the existing vector placeholder.
    }
  }

  static Future<ui.Image?> decodeValidatedPng(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      final image = frame.image;
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (pixels == null || !_hasTransparentAndVisiblePixels(pixels)) {
        image.dispose();
        return null;
      }
      return image;
    } catch (_) {
      return null;
    }
  }

  static bool _hasTransparentAndVisiblePixels(ByteData pixels) {
    var hasTransparent = false;
    var hasVisible = false;
    for (var offset = 3; offset < pixels.lengthInBytes; offset += 4) {
      final alpha = pixels.getUint8(offset);
      hasTransparent |= alpha == 0;
      hasVisible |= alpha > 0;
      if (hasTransparent && hasVisible) return true;
    }
    return false;
  }

  static void drawContained(
    ui.Canvas canvas,
    ui.Image image,
    Rect target, {
    double padding = 0,
  }) {
    final available = target.deflate(padding);
    final sourceWidth = image.width.toDouble();
    final sourceHeight = image.height.toDouble();
    final scale = (available.width / sourceWidth).clamp(
      0.0,
      available.height / sourceHeight,
    );
    final destination = Rect.fromCenter(
      center: available.center,
      width: sourceWidth * scale,
      height: sourceHeight * scale,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, sourceWidth, sourceHeight),
      destination,
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
  }
}
