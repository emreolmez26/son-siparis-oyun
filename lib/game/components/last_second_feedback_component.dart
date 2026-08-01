import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../state/feedback_state.dart';
import 'shell_canvas.dart';

class LastSecondFeedbackComponent extends PositionComponent {
  LastSecondFeedbackComponent({required this.state}) : super(priority: 105);

  final LastSecondFeedbackState state;

  @override
  void render(Canvas canvas) {
    if (!state.isActive) return;
    const bounds = Rect.fromLTWH(505, 230, 270, 76);
    ShellCanvas.panel(
      canvas,
      bounds,
      color: const Color(0xE64D2812),
      borderColor: GameLayout.accentColor,
      radius: 18,
      borderWidth: 3,
    );
    ShellCanvas.label(
      canvas,
      text: 'SON ANDA!',
      position: Vector2(640, 242),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: '${state.servedPatienceSeconds.toStringAsFixed(2)} sn kala',
      position: Vector2(640, 275),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      align: TextAlign.center,
    );
  }
}
