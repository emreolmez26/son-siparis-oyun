import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/processing_job.dart';
import 'shell_canvas.dart';

class ProcessingIndicatorComponent extends PositionComponent {
  ProcessingIndicatorComponent({
    required this.jobProvider,
    required this.positionForCard,
  }) : super(priority: _indicatorPriority);

  static const _indicatorPriority = 95;
  final ProcessingJob? Function() jobProvider;
  final Offset Function(String cardId) positionForCard;

  @override
  void render(Canvas canvas) {
    final job = jobProvider();
    if (job == null) {
      return;
    }

    final panPosition = positionForCard(job.equipmentCardId);
    final panRect = Rect.fromLTWH(
      panPosition.dx,
      panPosition.dy,
      GameLayout.cardWidth,
      GameLayout.cardHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panRect.inflate(5), const Radius.circular(15)),
      Paint()..color = const Color(0x35E46A35),
    );

    final barRect = Rect.fromLTWH(
      panRect.left + 12,
      panRect.bottom - 12,
      panRect.width - 24,
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
      text: 'Pişiyor ${job.remainingSeconds.toStringAsFixed(1)} sn',
      position: Vector2(panRect.center.dx, panRect.top - 8),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      align: TextAlign.center,
    );
  }
}
