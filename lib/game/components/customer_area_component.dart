import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import 'shell_canvas.dart';

class CustomerAreaComponent extends PositionComponent {
  CustomerAreaComponent()
    : super(
        position: Vector2(0, GameLayout.customerTop),
        size: Vector2(GameLayout.designWidth, GameLayout.customerHeight),
      );

  static const _customerStyle = TextStyle(
    color: GameLayout.primaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static const _hintStyle = TextStyle(
    color: GameLayout.mutedTextColor,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  @override
  void render(Canvas canvas) {
    _drawCustomer(
      canvas,
      centerX: 330,
      index: 1,
      color: const Color(0xFFB55348),
    );
    _drawCustomer(
      canvas,
      centerX: 640,
      index: 2,
      color: const Color(0xFF679E47),
    );
    _drawCustomer(
      canvas,
      centerX: 950,
      index: 3,
      color: const Color(0xFFD49B37),
    );
  }

  void _drawCustomer(
    Canvas canvas, {
    required double centerX,
    required int index,
    required Color color,
  }) {
    const avatarCenterY = 42.0;
    const avatarRadius = 26.0;
    final avatarCenter = Offset(centerX, avatarCenterY);

    canvas.drawCircle(
      avatarCenter,
      avatarRadius + 3,
      Paint()..color = GameLayout.panelStrokeColor,
    );
    canvas.drawCircle(avatarCenter, avatarRadius, Paint()..color = color);
    ShellCanvas.label(
      canvas,
      text: 'M$index',
      position: Vector2(centerX, 32),
      style: _customerStyle,
      align: TextAlign.center,
    );

    final orderRect = Rect.fromCenter(
      center: Offset(centerX + 66, 29),
      width: 112,
      height: 34,
    );
    ShellCanvas.panel(
      canvas,
      orderRect,
      color: GameLayout.panelColor,
      borderColor: GameLayout.panelStrokeColor,
      radius: 9,
    );
    ShellCanvas.label(
      canvas,
      text: 'Geçici sipariş',
      position: Vector2(orderRect.center.dx, orderRect.top + 10),
      style: _hintStyle,
      align: TextAlign.center,
      maxWidth: orderRect.width - 12,
    );

    final barRect = Rect.fromCenter(
      center: Offset(centerX, 86),
      width: 120,
      height: 8,
    );
    final barRRect = RRect.fromRectAndRadius(barRect, const Radius.circular(4));
    canvas.drawRRect(barRRect, Paint()..color = GameLayout.tableInnerColor);
    final fillRect = Rect.fromLTWH(
      barRect.left,
      barRect.top,
      barRect.width * .68,
      barRect.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(4)),
      Paint()..color = GameLayout.successColor,
    );
    ShellCanvas.label(
      canvas,
      text: 'Sabır göstergesi',
      position: Vector2(centerX, 96),
      style: _hintStyle.copyWith(fontSize: 9),
      align: TextAlign.center,
    );
  }
}
