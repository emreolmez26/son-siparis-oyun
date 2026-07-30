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
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          equipmentRect.inflate(5),
          const Radius.circular(15),
        ),
        Paint()..color = const Color(0x35E46A35),
      );
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
        Paint()..color = const Color(0xFFE46A35),
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
}
