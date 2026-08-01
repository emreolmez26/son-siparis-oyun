import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_layout.dart';
import '../models/tutorial_status.dart';
import '../state/tutorial_state.dart';
import 'shell_canvas.dart';

class TutorialOverlayComponent extends PositionComponent with TapCallbacks {
  TutorialOverlayComponent({
    required this.tutorialState,
    required this.sourceBoundsProvider,
    required this.targetBoundsProvider,
    required this.onSkip,
  }) : super(
         size: Vector2(GameLayout.designWidth, GameLayout.designHeight),
         priority: 180,
       );

  final TutorialState tutorialState;
  final List<Rect> Function() sourceBoundsProvider;
  final Rect? Function() targetBoundsProvider;
  final void Function() onSkip;

  static final _panelBounds = Rect.fromCenter(
    center: Offset(640, 142),
    width: 520,
    height: 106,
  );
  static const _skipBounds = Rect.fromLTWH(1004, 111, 62, 28);

  @override
  bool containsLocalPoint(Vector2 point) {
    if (!tutorialState.shouldShowOverlay) return false;
    final offset = Offset(point.x, point.y);
    return _panelBounds.contains(offset) || _skipBounds.contains(offset);
  }

  @override
  void render(Canvas canvas) {
    if (!tutorialState.shouldShowOverlay) return;
    if (tutorialState.status != TutorialStatus.active) {
      _drawCompletion(canvas);
      return;
    }
    final highlights = [...sourceBoundsProvider()];
    final target = targetBoundsProvider();
    if (target != null) highlights.add(target);
    _drawDimmer(canvas, highlights);
    _drawHighlights(canvas, highlights);
    _drawInstruction(canvas, target);
  }

  void _drawDimmer(Canvas canvas, List<Rect> highlights) {
    canvas.saveLayer(size.toRect(), Paint());
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xB7140C08));
    for (final bounds in highlights) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds.inflate(10), const Radius.circular(14)),
        Paint()..blendMode = BlendMode.clear,
      );
    }
    canvas.restore();
  }

  void _drawHighlights(Canvas canvas, List<Rect> highlights) {
    for (final bounds in highlights) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds.inflate(8), const Radius.circular(13)),
        Paint()
          ..color = GameLayout.accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _drawInstruction(Canvas canvas, Rect? target) {
    ShellCanvas.panel(
      canvas,
      _panelBounds,
      color: const Color(0xFF33251E),
      borderColor: GameLayout.panelStrokeColor,
      radius: 15,
      borderWidth: 2,
    );
    final step = tutorialState.currentStep;
    final progress = switch (step) {
      TutorialStep.cookPatty => 'ADIM 1 / 3',
      TutorialStep.buildClassicBurger => 'ADIM 2 / 3',
      TutorialStep.serveClassicBurger => 'ADIM 3 / 3',
    };
    final title = switch (step) {
      TutorialStep.cookPatty => 'İLK SİPARİŞİNİ HAZIRLA',
      TutorialStep.buildClassicBurger => 'MALZEMELERİ BİRLEŞTİR',
      TutorialStep.serveClassicBurger => 'SİPARİŞİ TAMAMLA',
    };
    final instruction = switch (step) {
      TutorialStep.cookPatty => 'Köfte kartını Tava’nın üzerine sürükle.',
      TutorialStep.buildClassicBurger =>
        'Ekmek, Pişmiş Köfte ve Peynir kartlarını sırayla üst üste koy.',
      TutorialStep.serveClassicBurger =>
        'Klasik Burger’i servis bankosuna sürükle.',
    };
    ShellCanvas.label(
      canvas,
      text: progress,
      position: Vector2(_panelBounds.center.dx, _panelBounds.top + 13),
      style: const TextStyle(
        color: Color(0xFFE9A8E8),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: title,
      position: Vector2(_panelBounds.center.dx, _panelBounds.top + 32),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 21,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
      maxWidth: _panelBounds.width - 44,
    );
    ShellCanvas.label(
      canvas,
      text: instruction,
      position: Vector2(_panelBounds.center.dx, _panelBounds.top + 65),
      style: const TextStyle(
        color: GameLayout.mutedTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      align: TextAlign.center,
      maxWidth: _panelBounds.width - 44,
    );
    ShellCanvas.panel(
      canvas,
      _skipBounds,
      color: const Color(0xFF8F171E),
      borderColor: const Color(0xFFD5424F),
      radius: 9,
    );
    ShellCanvas.label(
      canvas,
      text: 'ATLA',
      position: Vector2(_skipBounds.center.dx, _skipBounds.top + 8),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    if (target != null) _drawArrow(canvas, target);
  }

  void _drawArrow(Canvas canvas, Rect target) {
    final start = Offset(_panelBounds.center.dx, _panelBounds.bottom + 6);
    final end = target.center;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(start.dx, end.dy - 72, end.dx, end.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = GameLayout.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 15, end.dy - 8)
      ..lineTo(end.dx - 10, end.dy + 10)
      ..close();
    canvas.drawPath(arrow, Paint()..color = GameLayout.accentColor);
  }

  void _drawCompletion(Canvas canvas) {
    final bounds = Rect.fromCenter(
      center: Offset(640, 270),
      width: 300,
      height: 94,
    );
    ShellCanvas.panel(
      canvas,
      bounds,
      color: const Color(0xFF33251E),
      borderColor: GameLayout.successColor,
      radius: 16,
      borderWidth: 2,
    );
    ShellCanvas.label(
      canvas,
      text: 'HARİKA!',
      position: Vector2(bounds.center.dx, bounds.top + 22),
      style: const TextStyle(
        color: GameLayout.accentColor,
        fontSize: 26,
        fontWeight: FontWeight.w900,
      ),
      align: TextAlign.center,
    );
    ShellCanvas.label(
      canvas,
      text: 'İlk siparişin servise hazır.',
      position: Vector2(bounds.center.dx, bounds.top + 57),
      style: const TextStyle(
        color: GameLayout.primaryTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      align: TextAlign.center,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!tutorialState.isActive) return;
    final point = Offset(event.localPosition.x, event.localPosition.y);
    if (_skipBounds.contains(point)) onSkip();
  }
}
