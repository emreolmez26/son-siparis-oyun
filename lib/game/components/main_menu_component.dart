import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_layout.dart';
import '../state/run_progression_state.dart';
import 'shell_canvas.dart';

class MainMenuComponent extends PositionComponent with TapCallbacks {
  MainMenuComponent({
    required this.isShowing,
    required this.onStartShift,
    required this.onContinue,
    required this.onOpenRecipeBook,
    required this.onOpenSettings,
    required this.onOpenMarket,
    required this.onOpenLoadout,
    required this.onStartDailyChallenge,
    required this.ownedPackCount,
    required this.todayBestLabel,
    required this.canContinue,
    required this.progression,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 300,
       );

  final bool Function() isShowing;
  final void Function() onStartShift;
  final void Function() onContinue;
  final void Function() onOpenRecipeBook;
  final void Function() onOpenSettings;
  final void Function() onOpenMarket;
  final void Function() onOpenLoadout;
  final void Function() onStartDailyChallenge;
  final int Function() ownedPackCount;
  final String Function() todayBestLabel;
  final bool Function() canContinue;
  final RunProgressionState progression;

  static const _backgroundAsset =
      'assets/ui/backgrounds/main_menu_restaurant.png';

  ui.Image? _backgroundImage;

  static final _startBounds = Rect.fromCenter(
    center: const Offset(640, 384),
    width: 356,
    height: 64,
  );
  static const _recipeBookBounds = Rect.fromLTWH(368, 620, 124, 62);
  static const _marketBounds = Rect.fromLTWH(508, 620, 124, 62);
  static const _loadoutBounds = Rect.fromLTWH(648, 620, 124, 62);
  static const _settingsBounds = Rect.fromLTWH(788, 620, 124, 62);
  static final _dailyBounds = Rect.fromCenter(
    center: const Offset(640, 502),
    width: 264,
    height: 44,
  );
  static final _continueBounds = Rect.fromCenter(
    center: const Offset(640, 448),
    width: 328,
    height: 44,
  );

  @override
  void onLoad() {
    super.onLoad();
    unawaited(_loadBackground());
  }

  Future<void> _loadBackground() async {
    final assetData = await rootBundle.load(_backgroundAsset);
    final codec = await ui.instantiateImageCodec(
      assetData.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    _backgroundImage = frame.image;
    codec.dispose();
  }

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() && super.containsLocalPoint(point);

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    final screenBounds = size.toRect();
    final backgroundImage = _backgroundImage;
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage,
        Rect.fromLTWH(
          0,
          0,
          backgroundImage.width.toDouble(),
          backgroundImage.height.toDouble(),
        ),
        screenBounds,
        Paint(),
      );
    } else {
      canvas.drawRect(
        screenBounds,
        Paint()..color = GameLayout.backgroundColor,
      );
    }
    canvas.drawRect(
      screenBounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x26150B06), Color(0x99150B06)],
          stops: [.15, 1],
        ).createShader(screenBounds),
    );
    _drawTopInfo(canvas);
    _labelWithShadow(
      canvas,
      text: 'SON SİPARİŞ',
      position: Vector2(640, 224),
      style: const TextStyle(
        color: Color(0xFFFFCA39),
        fontSize: 47,
        fontWeight: FontWeight.w900,
        letterSpacing: .2,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: 'MUTFAKTA BUGÜN KİM HIZLI?',
      position: Vector2(640, 277),
      style: const TextStyle(
        color: Color(0xFFF4DDAC),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      align: TextAlign.center,
    );
    _drawButton(
      canvas,
      _startBounds,
      text: '▶  VARDİYAYA BAŞLA',
      fillColor: const Color(0xFFFFBE14),
      borderColor: const Color(0xFFFFE08B),
      textColor: const Color(0xFF39250C),
      fontSize: 17,
      shadow: true,
    );
    _drawButton(
      canvas,
      _continueBounds,
      text: canContinue()
          ? '↻  DEVAM ET — GÜN ${progression.currentDay}'
          : '↻  DEVAM ET  ·  KAYIT YOK',
      fillColor: canContinue()
          ? const Color(0xFF3B2A22)
          : const Color(0xFF332722),
      borderColor: const Color(0xFF79624B),
      textColor: canContinue()
          ? const Color(0xFFFFE5B5)
          : const Color(0xFFC3AA8D),
      fontSize: 13,
    );
    _drawButton(
      canvas,
      _dailyBounds,
      text: '✦  GÜNÜN MÜCADELESİ',
      fillColor: const Color(0xFF30221C),
      borderColor: const Color(0xFF9B7437),
      textColor: const Color(0xFFF6D996),
      fontSize: 12,
    );
    const labels = ['TARİF DEFTERİ', 'MARKET', 'AKTİF MUTFAK', 'AYARLAR'];
    const icons = ['▤', '●', '◆', '⚙'];
    const bounds = [
      _recipeBookBounds,
      _marketBounds,
      _loadoutBounds,
      _settingsBounds,
    ];
    for (var index = 0; index < labels.length; index++) {
      final navBounds = bounds[index];
      final isActive = index == 2;
      ShellCanvas.panel(
        canvas,
        navBounds,
        color: isActive ? const Color(0xFF554117) : const Color(0xDC271B16),
        borderColor: isActive
            ? const Color(0xFFFFC527)
            : const Color(0xFF6A513A),
        radius: 11,
        borderWidth: isActive ? 2 : 1,
      );
      ShellCanvas.label(
        canvas,
        text: icons[index],
        position: Vector2(navBounds.center.dx, navBounds.top + 9),
        style: const TextStyle(
          color: Color(0xFFFFD36A),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        align: TextAlign.center,
      );
      ShellCanvas.label(
        canvas,
        text: labels[index],
        position: Vector2(navBounds.center.dx, navBounds.top + 39),
        style: TextStyle(
          color: isActive ? const Color(0xFFFFE2A0) : const Color(0xFFD2BDA1),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
        maxWidth: navBounds.width - 12,
      );
    }
  }

  void _drawTopInfo(Canvas canvas) {
    const bounds = Rect.fromLTWH(826, 30, 412, 82);
    ShellCanvas.panel(
      canvas,
      bounds,
      color: const Color(0xE6251914),
      borderColor: const Color(0xFF6C513A),
      radius: 14,
      borderWidth: 1.5,
    );
    _topStat(
      canvas,
      const Offset(850, 49),
      '●  ${progression.walletCoins} PARA',
    );
    _topStat(
      canvas,
      const Offset(1040, 49),
      '▣  GÜN ${progression.currentDay}',
    );
    _topStat(canvas, const Offset(850, 79), '${ownedPackCount()} / 3 PAKET');
    _topStat(canvas, const Offset(1040, 79), 'REKOR: ${todayBestLabel()}');
  }

  void _topStat(Canvas canvas, Offset position, String text) {
    ShellCanvas.label(
      canvas,
      text: text,
      position: Vector2(position.dx, position.dy),
      style: const TextStyle(
        color: Color(0xFFF6DFB3),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      maxWidth: 172,
    );
  }

  void _drawButton(
    Canvas canvas,
    Rect bounds, {
    required String text,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required double fontSize,
    bool shadow = false,
  }) {
    if (shadow) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bounds.shift(const Offset(0, 7)),
          const Radius.circular(15),
        ),
        Paint()
          ..color = const Color(0x8F120905)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7),
      );
    }
    ShellCanvas.panel(
      canvas,
      bounds,
      color: fillColor,
      borderColor: borderColor,
      radius: 13,
      borderWidth: 1.5,
    );
    ShellCanvas.label(
      canvas,
      text: text,
      position: Vector2(bounds.center.dx, bounds.center.dy - (fontSize * .56)),
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
      maxWidth: bounds.width - 16,
    );
  }

  void _labelWithShadow(
    Canvas canvas, {
    required String text,
    required Vector2 position,
    required TextStyle style,
  }) {
    ShellCanvas.label(
      canvas,
      text: text,
      position: position + Vector2(2, 3),
      style: style.copyWith(color: const Color(0x990E0704)),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: text,
      position: position,
      style: style,
      align: TextAlign.center,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isShowing() &&
        _startBounds.contains(
          Offset(event.localPosition.x, event.localPosition.y),
        )) {
      onStartShift();
      return;
    }
    if (isShowing() &&
        _dailyBounds.contains(
          Offset(event.localPosition.x, event.localPosition.y),
        )) {
      onStartDailyChallenge();
      return;
    }
    if (isShowing() &&
        _recipeBookBounds.contains(
          Offset(event.localPosition.x, event.localPosition.y),
        )) {
      onOpenRecipeBook();
      return;
    }
    if (isShowing() &&
        _marketBounds.contains(
          Offset(event.localPosition.x, event.localPosition.y),
        )) {
      onOpenMarket();
      return;
    }
    if (isShowing() &&
        _continueBounds.contains(
          Offset(event.localPosition.x, event.localPosition.y),
        ) &&
        canContinue()) {
      onContinue();
      return;
    }
    if (isShowing() &&
        _settingsBounds.contains(
          Offset(event.localPosition.x, event.localPosition.y),
        )) {
      onOpenSettings();
      return;
    }
    if (isShowing() &&
        _loadoutBounds.contains(
          Offset(event.localPosition.x, event.localPosition.y),
        )) {
      onOpenLoadout();
    }
  }
}
