import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/processing_job.dart';
import 'shell_canvas.dart';

class ProcessingIndicatorComponent extends PositionComponent {
  ProcessingIndicatorComponent({
    required this.jobsProvider,
    required this.positionForCard,
  }) : super(priority: _indicatorPriority);

  static const _indicatorPriority = 95;
  final List<ProcessingJob> Function() jobsProvider;
  final Offset Function(String cardId) positionForCard;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    for (final job in jobsProvider()) {
      final equipmentPosition = positionForCard(job.equipmentCardId);
      final equipmentRect = Rect.fromLTWH(
        equipmentPosition.dx,
        equipmentPosition.dy,
        GameLayout.cardWidth,
        GameLayout.cardHeight,
      );
      final actionColor = switch (job.action) {
        ProcessingAction.cookPatty => const Color(0xFFE97932),
        ProcessingAction.sliceTomato => const Color(0xFF9DDAF1),
        ProcessingAction.fryPotato => const Color(0xFFF2C347),
      };
      final pulse = .5 + (.5 * ((_elapsed * 6) % 1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          equipmentRect.inflate(5),
          const Radius.circular(15),
        ),
        Paint()..color = actionColor.withValues(alpha: .12 + (.14 * pulse)),
      );
      _drawActionMotion(canvas, equipmentRect, job.action, actionColor);
      final barRect = Rect.fromLTWH(
        equipmentRect.left + 10,
        equipmentRect.bottom - 11,
        equipmentRect.width - 20,
        5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
        Paint()..color = const Color(0x55000000),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            barRect.left,
            barRect.top,
            barRect.width * job.progress,
            barRect.height,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = actionColor,
      );
      ShellCanvas.label(
        canvas,
        text:
            '${_actionLabel(job.action)} ${job.remainingSeconds.toStringAsFixed(1)} sn',
        position: Vector2(equipmentRect.center.dx, equipmentRect.top - 8),
        style: const TextStyle(
          color: GameLayout.accentColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
        align: TextAlign.center,
      );
    }
  }

  String _actionLabel(ProcessingAction action) => switch (action) {
    ProcessingAction.cookPatty => 'Pişiyor',
    ProcessingAction.sliceTomato => 'Dilimleniyor',
    ProcessingAction.fryPotato => 'Kızarıyor',
  };

  void _drawActionMotion(
    Canvas canvas,
    Rect bounds,
    ProcessingAction action,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    switch (action) {
      case ProcessingAction.cookPatty:
        final lift = (_elapsed * 18) % 10;
        for (final x in [
          bounds.left + 32,
          bounds.center.dx,
          bounds.right - 32,
        ]) {
          canvas.drawArc(
            Rect.fromLTWH(x - 5, bounds.top - 10 - lift, 10, 14),
            0,
            3.14,
            false,
            paint..style = PaintingStyle.stroke,
          );
        }
        return;
      case ProcessingAction.sliceTomato:
        final shift = (_elapsed * 60) % 36;
        canvas.drawLine(
          Offset(bounds.left + 25 + shift, bounds.top + 12),
          Offset(bounds.left + 9 + shift, bounds.top + 32),
          paint,
        );
        return;
      case ProcessingAction.fryPotato:
        for (var index = 0; index < 3; index++) {
          final rise = ((_elapsed * 22) + (index * 9)) % 25;
          canvas.drawCircle(
            Offset(
              bounds.center.dx - 18 + (index * 18),
              bounds.top + 32 - rise,
            ),
            2.5,
            paint..style = PaintingStyle.fill,
          );
        }
        return;
    }
  }
}
