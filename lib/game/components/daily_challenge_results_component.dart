import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../state/daily_challenge_state.dart';
import '../state/shift_state.dart';
import 'shell_canvas.dart';

class DailyChallengeResultsComponent extends PositionComponent
    with TapCallbacks {
  DailyChallengeResultsComponent({
    required this.isShowing,
    required this.challenge,
    required this.shiftState,
    required this.onRetry,
    required this.onMainMenu,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 380,
       );

  final bool Function() isShowing;
  final DailyChallengeState challenge;
  final ShiftState shiftState;
  final void Function() onRetry;
  final void Function() onMainMenu;

  static const _retryBounds = Rect.fromLTWH(390, 610, 230, 58);
  static const _menuBounds = Rect.fromLTWH(660, 610, 230, 58);

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() && super.containsLocalPoint(point);

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    canvas.drawRect(size.toRect(), Paint()..color = GameLayout.backgroundColor);
    ShellCanvas.label(
      canvas,
      text: 'GÜNÜN MÜCADELESİ TAMAMLANDI',
      position: Vector2(640, 68),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 28,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: challenge.activeDateKey ?? '',
      position: Vector2(640, 108),
      style: const TextStyle(color: GameLayout.mutedTextColor, fontSize: 13),
      align: TextAlign.center,
    );
    ShellCanvas.panel(
      canvas,
      const Rect.fromLTWH(280, 146, 720, 410),
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 16,
    );
    ShellCanvas.label(
      canvas,
      text: '${challenge.score.displayedScore}',
      position: Vector2(640, 188),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 54,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    if (challenge.isNewRecord) {
      ShellCanvas.label(
        canvas,
        text: 'YENİ REKOR!',
        position: Vector2(640, 258),
        style: const TextStyle(
          color: GameLayout.successColor,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
      );
    }
    final best =
        challenge.activeBest?.bestScore ?? challenge.score.displayedScore;
    final stats = [
      ('KİŞİSEL EN İYİ', '$best'),
      ('TAMAMLANAN', '${shiftState.completedOrders}'),
      ('EN YÜKSEK KOMBO', 'x${shiftState.highestCombo}'),
      ('KAÇAN', '${shiftState.missedOrders}'),
      ('SABOTAJ SAVUNMA', '${shiftState.sabotagesDefended}'),
      ('SABOTAJ İSABETİ', '${shiftState.sabotagesAffected}'),
    ];
    for (final indexed in stats.indexed) {
      final row = indexed.$1 ~/ 2;
      final column = indexed.$1 % 2;
      final x = 360.0 + column * 360;
      final y = 310.0 + row * 66;
      ShellCanvas.label(
        canvas,
        text: indexed.$2.$1,
        position: Vector2(x, y),
        style: const TextStyle(color: GameLayout.mutedTextColor, fontSize: 10),
      );
      ShellCanvas.label(
        canvas,
        text: indexed.$2.$2,
        position: Vector2(x, y + 20),
        style: const TextStyle(
          color: GameLayout.primaryTextColor,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    _button(canvas, _retryBounds, 'TEKRAR DENE', accent: true);
    _button(canvas, _menuBounds, 'ANA MENÜ');
  }

  void _button(Canvas canvas, Rect bounds, String text, {bool accent = false}) {
    ShellCanvas.panel(
      canvas,
      bounds,
      color: accent ? GameLayout.accentColor : GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 12,
    );
    ShellCanvas.label(
      canvas,
      text: text,
      position: Vector2(bounds.center.dx, bounds.top + 19),
      style: TextStyle(
        color: accent ? const Color(0xFF39250C) : GameLayout.primaryTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isShowing()) return;
    final point = Offset(event.localPosition.x, event.localPosition.y);
    if (_retryBounds.contains(point)) return onRetry();
    if (_menuBounds.contains(point)) onMainMenu();
  }
}
