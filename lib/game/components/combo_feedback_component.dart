import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class ComboFeedbackComponent extends PositionComponent {
  ComboFeedbackComponent() : super(priority: 104);

  double _remaining = 0;
  String _label = '';

  void trigger(int combo) {
    _label = switch (combo) {
      3 => 'SERVİS SERİSİ x3',
      5 => 'MUTFAK AKIYOR x5',
      8 => 'DURDURULAMAZ x8',
      _ => 'KOMBO CANAVARI x10',
    };
    _remaining = GameLayout.comboFeedbackDurationSeconds;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _remaining = (_remaining - dt)
        .clamp(0, GameLayout.comboFeedbackDurationSeconds)
        .toDouble();
  }

  @override
  void render(Canvas canvas) {
    if (_remaining <= 0) return;
    final alpha = (_remaining / GameLayout.comboFeedbackDurationSeconds * 255)
        .round()
        .clamp(0, 255);
    const bounds = Rect.fromLTWH(475, 300, 330, 54);
    ShellCanvas.panel(
      canvas,
      bounds,
      color: Color.fromARGB(alpha, 83, 49, 13),
      borderColor: Color.fromARGB(alpha, 255, 200, 50),
      radius: 18,
      borderWidth: 3,
    );
    ShellCanvas.label(
      canvas,
      text: _label,
      position: Vector2(bounds.center.dx, bounds.top + 16),
      style: TextStyle(
        color: Color.fromARGB(alpha, 255, 245, 205),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
  }
}
