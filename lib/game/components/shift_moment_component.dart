import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/shift_moment.dart';
import 'shell_canvas.dart';

class ShiftMomentComponent extends PositionComponent with TapCallbacks {
  ShiftMomentComponent({
    required this.momentProvider,
    required this.isShowing,
    required this.onContinue,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 330,
       );

  final ShiftMoment? Function() momentProvider;
  final bool Function() isShowing;
  final void Function() onContinue;
  bool _showingSoon = false;

  static final _panelBounds = Rect.fromCenter(
    center: Offset(640, 366),
    width: 920,
    height: 490,
  );
  static const _continueBounds = Rect.fromLTWH(776, 562, 290, 52);
  static const _shareBounds = Rect.fromLTWH(776, 490, 190, 42);
  static const _saveBounds = Rect.fromLTWH(976, 490, 90, 42);

  bool get isShowingSoon => _showingSoon;

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() && super.containsLocalPoint(point);

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    final moment = momentProvider();
    if (moment == null) return;
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF17100D));
    ShellCanvas.panel(
      canvas,
      _panelBounds,
      color: const Color(0xFF2C201A),
      borderColor: GameLayout.panelStrokeColor,
      radius: 18,
      borderWidth: 2,
    );
    _drawStoryPanel(canvas, moment);
    _drawStatsPanel(canvas, moment);
  }

  void _drawStoryPanel(Canvas canvas, ShiftMoment moment) {
    final bounds = Rect.fromLTWH(
      _panelBounds.left + 26,
      _panelBounds.top + 26,
      488,
      _panelBounds.height - 52,
    );
    ShellCanvas.panel(
      canvas,
      bounds,
      color: const Color(0xFF211713),
      borderColor: const Color(0xFF4A3425),
      radius: 13,
    );
    ShellCanvas.label(
      canvas,
      text: '⚒  Son Sipariş',
      position: Vector2(bounds.left + 26, bounds.top + 28),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 21,
        fontWeight: FontWeight.w900,
      ),
    );
    final feature = Rect.fromLTWH(
      bounds.left + 26,
      bounds.top + 76,
      bounds.width - 52,
      214,
    );
    ShellCanvas.panel(
      canvas,
      feature,
      color: const Color(0xFF4A3425),
      borderColor: const Color(0xFF6C4C32),
      radius: 12,
    );
    canvas.drawCircle(
      Offset(feature.center.dx - 58, feature.center.dy),
      58,
      Paint()..color = const Color(0x33F6B60B),
    );
    ShellCanvas.label(
      canvas,
      text: _iconFor(moment),
      position: Vector2(feature.center.dx - 58, feature.center.dy - 41),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 72,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: moment.resultName.toUpperCase(),
      position: Vector2(feature.center.dx + 80, feature.center.dy - 31),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
      maxWidth: 180,
    );
    ShellCanvas.label(
      canvas,
      text: '“${_quoteFor(moment)}”',
      position: Vector2(feature.center.dx + 80, feature.center.dy + 19),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      align: TextAlign.center,
      maxWidth: 190,
    );
    ShellCanvas.label(
      canvas,
      text: 'GÜN ${moment.day}  •  MUTFAK KAHRAMANI',
      position: Vector2(bounds.left + 26, bounds.bottom - 72),
      style: const TextStyle(
        color: GameLayout.successColor,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
    ShellCanvas.label(
      canvas,
      text: 'Vardiyadaki en unutulmaz servis.',
      position: Vector2(bounds.left + 26, bounds.bottom - 45),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _drawStatsPanel(Canvas canvas, ShiftMoment moment) {
    final bounds = Rect.fromLTWH(
      _panelBounds.left + 540,
      _panelBounds.top + 26,
      328,
      _panelBounds.height - 52,
    );
    ShellCanvas.label(
      canvas,
      text: 'VARDİYANIN ANI',
      position: Vector2(bounds.left, bounds.top + 12),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
    ShellCanvas.panel(
      canvas,
      Rect.fromLTWH(bounds.left, bounds.top + 42, 148, 27),
      color: const Color(0xFFE9A8E8),
      borderColor: const Color(0xFFFFCCFA),
      radius: 14,
    );
    ShellCanvas.label(
      canvas,
      text: '✦ MUTFAK KAHRAMANI',
      position: Vector2(bounds.left + 74, bounds.top + 50),
      style: const TextStyle(
        color: Color(0xFF57245B),
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: _headlineFor(moment),
      position: Vector2(bounds.left, bounds.top + 85),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
      maxWidth: bounds.width,
    );
    ShellCanvas.label(
      canvas,
      text: 'Bu servis vardiyanın aklında kaldı.',
      position: Vector2(bounds.left, bounds.top + 112),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    _statCard(
      canvas,
      Rect.fromLTWH(bounds.left, bounds.top + 142, 152, 90),
      'KALAN SABIR',
      _patienceValue(moment),
    );
    _statCard(
      canvas,
      Rect.fromLTWH(bounds.right - 152, bounds.top + 142, 152, 90),
      'KOMBO',
      'x${moment.combo}',
    );
    _statCard(
      canvas,
      Rect.fromLTWH(bounds.left, bounds.top + 244, bounds.width, 68),
      'KAZANILAN PARA',
      '+${moment.rewardCoins} Para',
    );
    _drawActionButtons(canvas);
  }

  void _statCard(Canvas canvas, Rect bounds, String label, String value) {
    ShellCanvas.panel(
      canvas,
      bounds,
      color: const Color(0xFF211713),
      borderColor: const Color(0xFF4A3425),
      radius: 10,
    );
    ShellCanvas.label(
      canvas,
      text: label,
      position: Vector2(bounds.center.dx, bounds.top + 14),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: value,
      position: Vector2(bounds.center.dx, bounds.top + 41),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _drawActionButtons(Canvas canvas) {
    for (final button in [_shareBounds, _saveBounds]) {
      ShellCanvas.panel(
        canvas,
        button,
        color: const Color(0xFF3B3029),
        borderColor: GameLayout.panelStrokeColor,
        radius: 9,
      );
    }
    ShellCanvas.label(
      canvas,
      text: '↗  PAYLAŞ',
      position: Vector2(_shareBounds.center.dx, _shareBounds.top + 13),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'KAYDET',
      position: Vector2(_saveBounds.center.dx, _saveBounds.top + 13),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.panel(
      canvas,
      _continueBounds,
      color: GameLayout.accentColor,
      borderColor: const Color(0xFFFFD86F),
      radius: 12,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'DEVAM ET  →',
      position: Vector2(_continueBounds.center.dx, _continueBounds.top + 15),
      style: const TextStyle(
        color: Color(0xFF39250C),
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    if (_showingSoon) {
      ShellCanvas.panel(
        canvas,
        Rect.fromCenter(center: Offset(921, 472), width: 124, height: 28),
        color: const Color(0xFF5D4638),
        borderColor: GameLayout.accentColor,
        radius: 9,
      );
      ShellCanvas.label(
        canvas,
        text: 'Yakında',
        position: Vector2(921, 465),
        style: const TextStyle(
          color: GameLayout.primaryTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
        align: TextAlign.center,
      );
    }
  }

  String _headlineFor(ShiftMoment moment) => switch (moment.kind) {
    ShiftMomentKind.lastSecond =>
      '${moment.remainingPatienceSeconds!.toStringAsFixed(2)} SANİYEYLE KURTARDIN!',
    ShiftMomentKind.combo => 'KOMBO CANAVARI — x${moment.combo}',
    ShiftMomentKind.reward => 'VARDİYANIN EN DEĞERLİ SERVİSİ',
  };

  String _patienceValue(ShiftMoment moment) =>
      moment.remainingPatienceSeconds == null
      ? '—'
      : '${moment.remainingPatienceSeconds!.toStringAsFixed(2)} sn';

  String _iconFor(ShiftMoment moment) => switch (moment.resultName) {
    'Çıtır Patates' => '≋',
    _ => '▰',
  };

  String _quoteFor(ShiftMoment moment) => switch (moment.resultName) {
    'Ateş Burger' => 'Ben sadece biraz acı olsun demiştim.',
    'Gurme Burger' => 'Bunu yemek mi, sergilemek mi gerekiyor?',
    'Klasik Burger' => 'Son anda yetişti ama hakkını verdi.',
    'Çıtır Patates' => 'Bir saniye daha beklesem kendim kızaracaktım.',
    _ => 'Mutfak bunu uzun süre konuşacak.',
  };

  @override
  void onTapUp(TapUpEvent event) {
    if (!isShowing()) return;
    final point = Offset(event.localPosition.x, event.localPosition.y);
    if (_continueBounds.contains(point)) {
      onContinue();
      return;
    }
    if (_shareBounds.contains(point) || _saveBounds.contains(point)) {
      _showingSoon = true;
    }
  }
}
