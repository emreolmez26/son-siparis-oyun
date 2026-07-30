import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/card_definition.dart';
import '../models/customer_patience_state.dart';
import '../models/customer_slot_state.dart';
import '../models/customer_state.dart';
import '../state/order_system.dart';
import 'shell_canvas.dart';

class CustomerAreaComponent extends PositionComponent {
  CustomerAreaComponent({required this.orderSystem})
    : super(
        position: Vector2(0, GameLayout.customerTop),
        size: Vector2(GameLayout.designWidth, GameLayout.customerHeight),
      );

  final OrderSystem orderSystem;

  static const _customerStyle = TextStyle(
    color: GameLayout.primaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static const _hintStyle = TextStyle(
    color: GameLayout.mutedTextColor,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  static const _slotCenters = <double>[210, 620, 1010];

  @override
  void render(Canvas canvas) {
    for (final entry in orderSystem.slots.indexed) {
      _drawCustomer(canvas, entry.$2, _slotCenters[entry.$1]);
    }
  }

  void _drawCustomer(Canvas canvas, CustomerSlotState slot, double centerX) {
    const avatarCenterY = 42.0;
    const avatarRadius = 25.0;
    final isServed = slot.customer.status == CustomerStatus.served;
    final isFailed = slot.customer.status == CustomerStatus.disappointed;
    final avatarCenter = Offset(centerX, avatarCenterY);
    final accentColor = Color(slot.definition.accentColorValue);
    final avatarColor = isServed
        ? GameLayout.successColor
        : isFailed
        ? const Color(0xFF8D3D38)
        : accentColor;
    canvas.drawCircle(
      avatarCenter,
      avatarRadius + 3,
      Paint()
        ..color = isServed
            ? GameLayout.accentColor
            : isFailed
            ? const Color(0xFFE46A35)
            : GameLayout.panelStrokeColor,
    );
    canvas.drawCircle(avatarCenter, avatarRadius, Paint()..color = avatarColor);
    ShellCanvas.label(
      canvas,
      text: isServed
          ? '✓'
          : isFailed
          ? '!'
          : slot.definition.displayLabel,
      position: Vector2(centerX, 32),
      style: _customerStyle.copyWith(fontSize: isServed ? 20 : 13),
      align: TextAlign.center,
    );

    final orderRect = Rect.fromCenter(
      center: Offset(centerX + 83, 29),
      width: 148,
      height: 38,
    );
    ShellCanvas.panel(
      canvas,
      orderRect,
      color: isServed
          ? const Color(0xFF38502A)
          : isFailed
          ? const Color(0xFF4E2925)
          : GameLayout.panelColor,
      borderColor: isServed
          ? GameLayout.successColor
          : isFailed
          ? const Color(0xFFE46A35)
          : GameLayout.panelStrokeColor,
      radius: 9,
    );
    final requestedType = slot.order?.requestedResultType;
    _drawOrderIcon(
      canvas,
      Offset(orderRect.left + 18, orderRect.center.dy),
      requestedType,
    );
    final label = isServed
        ? 'Servis edildi'
        : isFailed
        ? 'Sipariş kaçtı'
        : _resultLabel(requestedType);
    ShellCanvas.label(
      canvas,
      text: label,
      position: Vector2(orderRect.left + 33, orderRect.top + 11),
      style: _hintStyle.copyWith(
        color: isServed || isFailed
            ? GameLayout.primaryTextColor
            : GameLayout.mutedTextColor,
      ),
      maxWidth: orderRect.width - 38,
    );

    if (slot.hasActiveOrder) {
      _drawPatience(canvas, slot, centerX);
    } else {
      ShellCanvas.label(
        canvas,
        text: isServed ? 'Müşteri mutlu' : 'Yeni sipariş geliyor',
        position: Vector2(centerX, 92),
        style: _hintStyle.copyWith(
          color: isServed ? GameLayout.successColor : const Color(0xFFE46A35),
          fontSize: 10,
        ),
        align: TextAlign.center,
      );
    }
  }

  void _drawPatience(Canvas canvas, CustomerSlotState slot, double centerX) {
    final patience = slot.patience;
    final color = switch (patience.status) {
      CustomerPatienceStatus.safe => GameLayout.successColor,
      CustomerPatienceStatus.warning => GameLayout.accentColor,
      CustomerPatienceStatus.danger ||
      CustomerPatienceStatus.expired => const Color(0xFFE46A35),
    };
    final barRect = Rect.fromCenter(
      center: Offset(centerX, 81),
      width: 108,
      height: 8,
    );
    if (patience.status == CustomerPatienceStatus.danger) {
      final pulse = 1 + (.08 * math.sin(patience.elapsedSeconds * 10));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: barRect.center,
            width: barRect.width * pulse,
            height: barRect.height + 4,
          ),
          const Radius.circular(7),
        ),
        Paint()..color = const Color(0x44E46A35),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(5)),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barRect.width * patience.normalizedRemaining,
          barRect.height,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = color,
    );
    ShellCanvas.label(
      canvas,
      text: '${patience.remainingSeconds.ceil()} sn',
      position: Vector2(centerX, 91),
      style: _hintStyle.copyWith(color: color, fontSize: 10),
      align: TextAlign.center,
    );
  }

  String _resultLabel(CardType? type) => switch (type) {
    CardType.classicBurger => 'Klasik Burger',
    CardType.deluxeBurger => 'Gurme Burger',
    CardType.spicyBurger => 'Ateş Burger',
    CardType.crispyFries => 'Çıtır Patates',
    _ => 'Sipariş hazırlanıyor',
  };

  void _drawOrderIcon(Canvas canvas, Offset center, CardType? type) {
    if (type == CardType.crispyFries) {
      for (final offset in const [Offset(-6, 0), Offset(0, -2), Offset(6, 0)]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center + offset, width: 4, height: 18),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFFF1B52C),
        );
      }
      return;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - 5),
          width: 20,
          height: 7,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFD68B30),
    );
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 22, height: 3),
      Paint()
        ..color = type == CardType.spicyBurger
            ? const Color(0xFFCF4B37)
            : const Color(0xFF6E9D3C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 5),
          width: 20,
          height: 6,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF6A3425),
    );
  }
}
