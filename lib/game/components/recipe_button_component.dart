import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class RecipeButtonComponent extends PositionComponent with TapCallbacks {
  RecipeButtonComponent({
    required this.isShowing,
    required this.onOpenRecipeBook,
  }) : super(
         position: Vector2(GameLayout.horizontalPadding, 100),
         size: Vector2(116, 36),
       );

  final bool Function() isShowing;
  final void Function() onOpenRecipeBook;

  static const _labelStyle = TextStyle(
    color: GameLayout.primaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  @override
  bool containsLocalPoint(Vector2 point) =>
      isShowing() && super.containsLocalPoint(point);

  @override
  void render(Canvas canvas) {
    if (!isShowing()) return;
    ShellCanvas.panel(
      canvas,
      size.toRect(),
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 8,
    );
    ShellCanvas.label(
      canvas,
      text: '▤  Tarifler',
      position: Vector2(size.x / 2, 10),
      style: _labelStyle,
      align: TextAlign.center,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isShowing()) onOpenRecipeBook();
  }
}
