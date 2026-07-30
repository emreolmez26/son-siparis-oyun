import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../state/shift_state.dart';
import 'shell_canvas.dart';

class HudComponent extends PositionComponent with TapCallbacks {
  HudComponent({
    required this.shiftState,
    required this.dayProvider,
    this.onPausePressed,
  }) : super(
         position: Vector2(GameLayout.horizontalPadding, GameLayout.hudTop),
         size: Vector2(
           GameLayout.designWidth - (GameLayout.horizontalPadding * 2),
           GameLayout.hudHeight,
         ),
       );

  final ShiftState shiftState;
  final int Function() dayProvider;
  final void Function()? onPausePressed;

  static const _labelStyle = TextStyle(
    color: GameLayout.mutedTextColor,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const _valueStyle = TextStyle(
    color: GameLayout.primaryTextColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  @override
  void render(Canvas canvas) {
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: GameLayout.hudColor,
      borderColor: GameLayout.panelStrokeColor,
    );

    _drawStat(canvas, 'GÜN 1', 'Akşam Servisi', 22, 164);
    _drawStat(canvas, 'SÜRE', shiftState.formattedRemainingTime, 202, 100);
    _drawStat(
      canvas,
      'KASA',
      '${shiftState.walletCoins}',
      322,
      88,
      prefix: '● ',
    );
    _drawStat(canvas, 'KOMBO', 'x${shiftState.currentCombo}', 430, 102);
    _drawStat(canvas, 'SİPARİŞ', '${shiftState.completedOrders}/10', 550, 104);

    canvas.drawRect(
      Rect.fromLTWH(12, 5, 176, 47),
      Paint()..color = GameLayout.hudColor,
    );
    _drawStat(canvas, 'GÜN ${dayProvider()}', 'Akşam Servisi', 22, 164);
    final pauseRect = _pauseRect;
    ShellCanvas.panel(
      canvas,
      pauseRect,
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 8,
    );
    ShellCanvas.label(
      canvas,
      text: 'Ⅱ',
      position: Vector2(pauseRect.center.dx, 13),
      style: _valueStyle.copyWith(color: GameLayout.accentColor, fontSize: 21),
      align: TextAlign.center,
    );
  }

  Rect get _pauseRect => Rect.fromLTWH(size.x - 58, 9, 42, size.y - 18);

  @override
  void onTapUp(TapUpEvent event) {
    final localPosition = event.localPosition;
    if (_pauseRect.contains(Offset(localPosition.x, localPosition.y))) {
      onPausePressed?.call();
    }
  }

  void _drawStat(
    Canvas canvas,
    String label,
    String value,
    double left,
    double width, {
    String prefix = '',
  }) {
    ShellCanvas.label(
      canvas,
      text: label,
      position: Vector2(left, 10),
      style: _labelStyle,
      maxWidth: width,
    );
    ShellCanvas.label(
      canvas,
      text: '$prefix$value',
      position: Vector2(left, 26),
      style: _valueStyle,
      maxWidth: width,
    );
  }
}
