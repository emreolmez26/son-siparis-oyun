import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/game_settings.dart';
import 'shell_canvas.dart';

class SettingsComponent extends PositionComponent with TapCallbacks {
  SettingsComponent({
    required this.isShowing,
    required this.settings,
    required this.onSettingsChanged,
    required this.onReplayTutorial,
    required this.onResetConfirmed,
    required this.onBack,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 360,
       );

  final bool Function() isShowing;
  final GameSettings settings;
  final void Function() onSettingsChanged;
  final void Function() onReplayTutorial;
  final void Function() onResetConfirmed;
  final void Function() onBack;
  bool isResetConfirmationShowing = false;

  static const _soundBounds = Rect.fromLTWH(760, 180, 118, 42);
  static const _musicBounds = Rect.fromLTWH(760, 244, 118, 42);
  static const _hapticsBounds = Rect.fromLTWH(760, 308, 118, 42);
  static const _tutorialBounds = Rect.fromLTWH(500, 396, 280, 48);
  static const _resetBounds = Rect.fromLTWH(500, 462, 280, 48);
  static const _backBounds = Rect.fromLTWH(548, 558, 184, 46);
  static const _cancelBounds = Rect.fromLTWH(475, 407, 146, 44);
  static const _confirmBounds = Rect.fromLTWH(659, 407, 146, 44);

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() && super.containsLocalPoint(point);

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    canvas.drawRect(size.toRect(), Paint()..color = GameLayout.backgroundColor);
    ShellCanvas.label(
      canvas,
      text: 'AYARLAR',
      position: Vector2(640, 82),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 34,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    const panel = Rect.fromLTWH(382, 132, 516, 408);
    ShellCanvas.panel(
      canvas,
      panel,
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 18,
      borderWidth: 2,
    );
    _row(
      canvas,
      'SES EFEKTLERİ',
      180,
      _soundBounds,
      settings.soundEffectsEnabled,
    );
    _row(canvas, 'MÜZİK', 244, _musicBounds, settings.musicEnabled);
    _row(canvas, 'TİTREŞİM', 308, _hapticsBounds, settings.hapticsEnabled);
    _button(canvas, _tutorialBounds, 'EĞİTİMİ TEKRARLA');
    _button(
      canvas,
      _resetBounds,
      'KAYIT VERİSİNİ SIFIRLA',
      color: const Color(0xFF5D302A),
    );
    _button(canvas, _backBounds, 'GERİ', color: GameLayout.accentColor);
    if (isResetConfirmationShowing) _drawConfirmation(canvas);
  }

  void _row(
    Canvas canvas,
    String label,
    double top,
    Rect bounds,
    bool enabled,
  ) {
    ShellCanvas.label(
      canvas,
      text: label,
      position: Vector2(424, top + 11),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
    ShellCanvas.panel(
      canvas,
      bounds,
      color: enabled ? GameLayout.successColor : const Color(0xFF43352D),
      borderColor: enabled
          ? const Color(0xFFA9D986)
          : GameLayout.panelStrokeColor,
      radius: 21,
    );
    ShellCanvas.label(
      canvas,
      text: enabled ? 'AÇIK' : 'KAPALI',
      position: Vector2(bounds.center.dx, bounds.top + 13),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _button(Canvas canvas, Rect bounds, String text, {Color? color}) {
    ShellCanvas.panel(
      canvas,
      bounds,
      color: color ?? const Color(0xFF49382E),
      borderColor: GameLayout.panelStrokeColor,
      radius: 11,
    );
    ShellCanvas.label(
      canvas,
      text: text,
      position: Vector2(bounds.center.dx, bounds.top + 15),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }

  void _drawConfirmation(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xB8000000));
    const bounds = Rect.fromLTWH(410, 270, 460, 210);
    ShellCanvas.panel(
      canvas,
      bounds,
      color: GameLayout.hudColor,
      borderColor: GameLayout.accentColor,
      radius: 16,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'Tüm ilerleme silinecek. Emin misin?',
      position: Vector2(640, 325),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      align: TextAlign.center,
    );
    _button(canvas, _cancelBounds, 'İPTAL');
    _button(canvas, _confirmBounds, 'SIFIRLA', color: const Color(0xFFA64135));
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isShowing()) return;
    final point = Offset(event.localPosition.x, event.localPosition.y);
    if (isResetConfirmationShowing) {
      if (_cancelBounds.contains(point)) isResetConfirmationShowing = false;
      if (_confirmBounds.contains(point)) {
        isResetConfirmationShowing = false;
        onResetConfirmed();
      }
      return;
    }
    if (_soundBounds.contains(point)) {
      settings.soundEffectsEnabled = !settings.soundEffectsEnabled;
      onSettingsChanged();
    } else if (_musicBounds.contains(point)) {
      settings.musicEnabled = !settings.musicEnabled;
      onSettingsChanged();
    } else if (_hapticsBounds.contains(point)) {
      settings.hapticsEnabled = !settings.hapticsEnabled;
      onSettingsChanged();
    } else if (_tutorialBounds.contains(point)) {
      onReplayTutorial();
    } else if (_resetBounds.contains(point)) {
      isResetConfirmationShowing = true;
    } else if (_backBounds.contains(point)) {
      onBack();
    }
  }
}
