import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/shift_result.dart';
import '../state/shift_state.dart';
import 'shell_canvas.dart';

class ShiftResultsComponent extends PositionComponent with TapCallbacks {
  ShiftResultsComponent({
    required this.shiftState,
    required this.isShowing,
    required this.onSelectUpgrades,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 240,
       );

  final ShiftState shiftState;
  final bool Function() isShowing;
  final void Function() onSelectUpgrades;

  Rect get _panelBounds => Rect.fromCenter(
    center: const Offset(GameLayout.designWidth / 2, 370),
    width: 620,
    height: 490,
  );

  Rect get _newShiftBounds => Rect.fromCenter(
    center: Offset(_panelBounds.center.dx, _panelBounds.bottom - 43),
    width: 266,
    height: 46,
  );

  @override
  bool containsLocalPoint(Vector2 point) {
    return isShowing() && super.containsLocalPoint(point);
  }

  @override
  void render(Canvas canvas) {
    if (!isShowing()) {
      return;
    }
    final result = shiftState.result;
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xD20E0907));
    ShellCanvas.panel(
      canvas,
      _panelBounds,
      color: const Color(0xFF2B201A),
      borderColor: GameLayout.accentColor,
      radius: 18,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'SON SİPARİŞ  •  VARDİYA SONUCU',
      position: Vector2(_panelBounds.left + 34, _panelBounds.top + 26),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: .6,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: 'VARDİYA TAMAMLANDI',
      position: Vector2(_panelBounds.left + 34, _panelBounds.top + 58),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 27,
        fontWeight: FontWeight.w900,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: 'Akşam servisi sona erdi',
      position: Vector2(_panelBounds.left + 34, _panelBounds.top + 94),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    _drawGrade(canvas, result);

    final statsBounds = Rect.fromLTWH(
      _panelBounds.left + 34,
      _panelBounds.top + 138,
      _panelBounds.width - 68,
      200,
    );
    ShellCanvas.panel(
      canvas,
      statsBounds,
      color: const Color(0xFF211713),
      borderColor: GameLayout.panelStrokeColor,
      radius: 12,
    );
    _drawStat(
      canvas,
      statsBounds,
      20,
      'Tamamlanan Siparişler',
      '${result.completedOrders}',
    );
    _drawStat(
      canvas,
      statsBounds,
      53,
      'Kaçırılan Siparişler',
      '${result.missedOrders}',
      valueColor: const Color(0xFFE47A60),
    );
    _drawStat(
      canvas,
      statsBounds,
      86,
      'En Yüksek Kombo',
      'x${result.highestCombo}',
    );
    _drawStat(
      canvas,
      statsBounds,
      119,
      'Kazanılan Para',
      '+${result.shiftEarnings}',
      valueColor: GameLayout.accentColor,
    );
    _drawStat(
      canvas,
      statsBounds,
      152,
      'Toplam Para',
      '${result.totalWalletCoins}',
      valueColor: GameLayout.accentColor,
    );
    _drawStat(
      canvas,
      statsBounds,
      185,
      'Vardiya Süresi',
      ShiftState.formatDuration(result.durationSeconds),
    );

    ShellCanvas.panel(
      canvas,
      _newShiftBounds,
      color: GameLayout.accentColor,
      borderColor: const Color(0xFFFFD86F),
      radius: 12,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'YENİ VARDİYA',
      position: Vector2(_newShiftBounds.center.dx, _newShiftBounds.top + 13),
      style: const TextStyle(
        color: Color(0xFF39250C),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.panel(
      canvas,
      _newShiftBounds,
      color: GameLayout.accentColor,
      borderColor: const Color(0xFFFFD86F),
      radius: 12,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'YÜKSELTMELERİ SEÇ',
      position: Vector2(_newShiftBounds.center.dx, _newShiftBounds.top + 13),
      style: const TextStyle(
        color: Color(0xFF39250C),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _drawGrade(Canvas canvas, ShiftResult result) {
    final circleCenter = Offset(_panelBounds.right - 72, _panelBounds.top + 74);
    canvas.drawCircle(
      circleCenter,
      42,
      Paint()..color = const Color(0xFF5A471C),
    );
    canvas.drawCircle(
      circleCenter,
      42,
      Paint()
        ..color = GameLayout.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    ShellCanvas.label(
      canvas,
      text: result.gradeLabel,
      position: Vector2(circleCenter.dx, circleCenter.dy - 20),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 43,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'AŞÇI NOTU: ${result.gradeLabel}',
      position: Vector2(circleCenter.dx, _panelBounds.top + 125),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
      align: TextAlign.center,
    );
  }

  void _drawStat(
    Canvas canvas,
    Rect bounds,
    double top,
    String label,
    String value, {
    Color valueColor = GameLayout.primaryTextColor,
  }) {
    ShellCanvas.label(
      canvas,
      text: label,
      position: Vector2(bounds.left + 18, bounds.top + top),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: value,
      position: Vector2(bounds.right - 18, bounds.top + top - 1),
      style: TextStyle(
        color: valueColor,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.right,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isShowing()) {
      return;
    }
    final localPosition = event.localPosition;
    if (_newShiftBounds.contains(Offset(localPosition.x, localPosition.y))) {
      onSelectUpgrades();
    }
  }
}
