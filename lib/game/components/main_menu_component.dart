import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../state/run_progression_state.dart';
import 'shell_canvas.dart';

class MainMenuComponent extends PositionComponent with TapCallbacks {
  MainMenuComponent({
    required this.isShowing,
    required this.onStartShift,
    required this.progression,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 300,
       );

  final bool Function() isShowing;
  final void Function() onStartShift;
  final RunProgressionState progression;

  static final _startBounds = Rect.fromCenter(
    center: Offset(640, 506),
    width: 292,
    height: 58,
  );

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() && super.containsLocalPoint(point);

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    canvas.drawRect(size.toRect(), Paint()..color = GameLayout.backgroundColor);
    ShellCanvas.label(
      canvas,
      text: 'SON SİPARİŞ',
      position: Vector2(640, 96),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: .4,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'Kartlarını hazırla. Servis başlıyor.',
      position: Vector2(640, 138),
      style: const TextStyle(color: GameLayout.mutedTextColor, fontSize: 14),
      align: TextAlign.center,
    );
    _drawTopPill(
      canvas,
      const Rect.fromLTWH(42, 28, 154, 38),
      'SEVİYE 1 · GÜN ${progression.currentDay}',
    );
    _drawTopPill(
      canvas,
      const Rect.fromLTWH(1048, 28, 188, 38),
      '● ${progression.walletCoins}  PARA',
    );
    _drawDecorativeCards(canvas);
    ShellCanvas.panel(
      canvas,
      _startBounds,
      color: GameLayout.accentColor,
      borderColor: const Color(0xFFFFD86F),
      radius: 14,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: '▶  VARDİYAYA BAŞLA',
      position: Vector2(_startBounds.center.dx, _startBounds.top + 18),
      style: const TextStyle(
        color: Color(0xFF39250C),
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    final continueBounds = Rect.fromCenter(
      center: const Offset(640, 574),
      width: 292,
      height: 40,
    );
    ShellCanvas.panel(
      canvas,
      continueBounds,
      color: const Color(0xFF3B3029),
      borderColor: GameLayout.panelStrokeColor,
      radius: 10,
    );
    ShellCanvas.label(
      canvas,
      text: 'DEVAM ET  ·  Kayıt yok',
      position: Vector2(640, 587),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      align: TextAlign.center,
    );
    const labels = ['TARİF DEFTERİ', 'KOLEKSİYON', 'AYARLAR'];
    for (var index = 0; index < labels.length; index++) {
      final bounds = Rect.fromLTWH(496 + (index * 100), 626, 86, 48);
      ShellCanvas.panel(
        canvas,
        bounds,
        color: GameLayout.panelColor,
        borderColor: GameLayout.panelStrokeColor,
        radius: 9,
      );
      ShellCanvas.label(
        canvas,
        text: labels[index],
        position: Vector2(bounds.center.dx, bounds.top + 18),
        style: const TextStyle(
          color: GameLayout.mutedTextColor,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
        align: TextAlign.center,
        maxWidth: 76,
      );
    }
  }

  void _drawTopPill(Canvas canvas, Rect bounds, String text) {
    ShellCanvas.panel(
      canvas,
      bounds,
      color: GameLayout.hudColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 9,
    );
    ShellCanvas.label(
      canvas,
      text: text,
      position: Vector2(bounds.center.dx, bounds.top + 11),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      align: TextAlign.center,
    );
  }

  void _drawDecorativeCards(Canvas canvas) {
    const colors = [Color(0xFFFFE9A9), Color(0xFF9EDB67), Color(0xFFE6B2E5)];
    const labels = ['KÖFTE', 'PEYNİR', 'SERVİS'];
    for (var index = 0; index < 3; index++) {
      final bounds = Rect.fromLTWH(
        420 + (index * 150),
        220 + (index == 1 ? 16 : 0),
        126,
        168,
      );
      ShellCanvas.panel(
        canvas,
        bounds,
        color: colors[index],
        borderColor: const Color(0xFFFFD86F),
        radius: 13,
        borderWidth: 2,
      );
      canvas.drawCircle(
        bounds.center.translate(0, -24),
        28,
        Paint()..color = const Color(0x55FFFFFF),
      );
      ShellCanvas.label(
        canvas,
        text: index == 0
            ? '●'
            : index == 1
            ? '▲'
            : '✦',
        position: Vector2(bounds.center.dx, bounds.top + 39),
        style: const TextStyle(
          color: Color(0xFF4A3425),
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
      );
      ShellCanvas.label(
        canvas,
        text: labels[index],
        position: Vector2(bounds.center.dx, bounds.bottom - 28),
        style: const TextStyle(
          color: Color(0xFF4A3425),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
      );
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isShowing() &&
        _startBounds.contains(
          Offset(event.localPosition.x, event.localPosition.y),
        )) {
      onStartShift();
    }
  }
}
