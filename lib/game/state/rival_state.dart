import 'dart:ui';

import '../models/card_definition.dart';
import '../models/sabotage.dart';
import '../systems/sabotage_scheduler.dart';

class RivalState {
  RivalState({SabotageScheduler scheduler = const SabotageScheduler()})
    : _scheduler = scheduler;

  static const rivalId = 'kara_kazan';
  static const rivalName = 'KARA KAZAN';
  static const warningDurationSeconds = 2.5;
  static const responsePosition = Offset(1128, 610);
  static const fuseBoxBounds = Rect.fromLTWH(1132, 462, 92, 52);
  static const fakeTicketBounds = Rect.fromLTWH(1000, 104, 228, 82);

  final SabotageScheduler _scheduler;
  List<ScheduledSabotage> _schedule = const [];
  final List<SabotageResolution> _resolutions = [];
  final Set<String> _affectedEventIds = {};
  ActiveSabotage? _current;
  int _nextScheduleIndex = 0;
  int _counterSequence = 1;
  double _elapsedSeconds = 0;
  double _feedbackRemaining = 0;
  String? _feedbackText;

  bool enabled = false;
  int seed = 0;
  int defendedCount = 0;
  int affectedCount = 0;

  List<ScheduledSabotage> get schedule => List.unmodifiable(_schedule);
  List<SabotageResolution> get resolutions => List.unmodifiable(_resolutions);
  ActiveSabotage? get current => _current;
  bool get hasWarning => _current?.phase == SabotagePhase.warning;
  bool get hasActiveSabotage => _current?.phase == SabotagePhase.active;
  String? get countermeasureId => _current?.countermeasureId;
  CountermeasureType? get countermeasureType =>
      _current?.event.type.countermeasure;
  String? get feedbackText => _feedbackRemaining > 0 ? _feedbackText : null;
  bool get isPowerOutageActive =>
      hasActiveSabotage && _current!.event.type == SabotageType.powerSurge;
  String? get jammedEquipmentId =>
      hasActiveSabotage && _current!.event.type == SabotageType.equipmentJam
      ? _current!.event.targetEquipmentId
      : null;
  Rect? get greasyRegion =>
      hasActiveSabotage && _current!.event.type == SabotageType.greasyTable
      ? _current!.event.greasyRegion
      : null;
  bool get fakeOrderActive =>
      hasActiveSabotage && _current!.event.type == SabotageType.fakeOrder;
  CardType? get fakeOrderType =>
      fakeOrderActive ? _current!.event.fakeOrderType : null;

  void startShift({
    required int day,
    bool tutorialReplay = false,
    int? testSeed,
  }) {
    clearTemporaryState();
    enabled = day >= 3 && !tutorialReplay;
    seed = testSeed ?? day;
    _schedule = enabled
        ? _scheduler.buildSchedule(
            day: day,
            rivalId: rivalId,
            testSeed: testSeed,
          )
        : const [];
    defendedCount = 0;
    affectedCount = 0;
    _resolutions.clear();
    _affectedEventIds.clear();
    _elapsedSeconds = 0;
    _nextScheduleIndex = 0;
    _counterSequence = 1;
  }

  void startDailyChallenge({required int seed}) {
    clearTemporaryState();
    enabled = true;
    this.seed = seed;
    _schedule = _scheduler.buildSchedule(
      day: 5,
      rivalId: rivalId,
      testSeed: seed,
    );
    defendedCount = 0;
    affectedCount = 0;
    _resolutions.clear();
    _affectedEventIds.clear();
    _elapsedSeconds = 0;
    _nextScheduleIndex = 0;
    _counterSequence = 1;
  }

  void advance(double dt, {required bool canAdvance}) {
    if (!enabled || !canAdvance || dt <= 0) return;
    _elapsedSeconds += dt;
    _feedbackRemaining = (_feedbackRemaining - dt).clamp(0, 10).toDouble();
    final active = _current;
    if (active == null) {
      if (_nextScheduleIndex < _schedule.length &&
          _elapsedSeconds >= _schedule[_nextScheduleIndex].scheduledAtSeconds) {
        _beginWarning(_schedule[_nextScheduleIndex]);
        _nextScheduleIndex++;
      }
      return;
    }

    final remaining = active.remainingSeconds - dt;
    if (remaining > 0) {
      _current = active.copyWith(remainingSeconds: remaining);
      return;
    }
    if (active.phase == SabotagePhase.warning) {
      _current = active.copyWith(
        phase: SabotagePhase.active,
        remainingSeconds: _activeDuration(active.event.type),
      );
      if (active.event.type != SabotageType.fakeOrder) {
        _markAffected(active.event.id);
      }
      return;
    }
    resolve(SabotageResolutionReason.expired);
  }

  void beginForTest(ScheduledSabotage event, {bool active = false}) {
    enabled = true;
    _beginWarning(event);
    if (active) {
      _current = _current!.copyWith(
        phase: SabotagePhase.active,
        remainingSeconds: _activeDuration(event.type),
      );
      if (event.type != SabotageType.fakeOrder) {
        _markAffected(event.id);
      }
    }
  }

  bool tryCounter(String runtimeId) {
    final active = _current;
    if (active == null || active.countermeasureId != runtimeId) return false;
    return resolve(
      active.phase == SabotagePhase.warning
          ? SabotageResolutionReason.counteredDuringWarning
          : SabotageResolutionReason.counteredWhileActive,
    );
  }

  bool triggerFakeOrderPenalty() {
    if (!fakeOrderActive) return false;
    _markAffected(_current!.event.id);
    _feedbackText = 'SAHTE SİPARİŞ!';
    _feedbackRemaining = 1.2;
    return resolve(SabotageResolutionReason.triggeredPlayerPenalty);
  }

  bool resolve(SabotageResolutionReason reason) {
    final active = _current;
    if (active == null ||
        _resolutions.any((entry) => entry.event.id == active.event.id)) {
      return false;
    }
    _resolutions.add(SabotageResolution(event: active.event, reason: reason));
    if (reason == SabotageResolutionReason.counteredDuringWarning ||
        reason == SabotageResolutionReason.counteredWhileActive) {
      defendedCount++;
      _feedbackText = 'SABOTAJ ENGELLENDİ';
      _feedbackRemaining = 1.2;
    }
    _current = null;
    return true;
  }

  void endShift() {
    if (_current != null) resolve(SabotageResolutionReason.clearedAtShiftEnd);
    enabled = false;
  }

  void clearTemporaryState() {
    _current = null;
    _schedule = const [];
    _nextScheduleIndex = 0;
    _elapsedSeconds = 0;
    _feedbackRemaining = 0;
    _feedbackText = null;
  }

  Offset? greasySlideDestination({
    required Offset droppedPosition,
    required Size cardSize,
    required Rect tableBounds,
    required double gridSpacing,
  }) {
    final active = _current;
    final region = greasyRegion;
    if (active == null || region == null) return droppedPosition;
    final bounds = droppedPosition & cardSize;
    if (!region.contains(bounds.center)) return droppedPosition;
    final destination =
        droppedPosition +
        Offset(
          active.event.slideDirection.dx * gridSpacing,
          active.event.slideDirection.dy * gridSpacing,
        );
    final destinationBounds = destination & cardSize;
    final isInside =
        destinationBounds.left >= tableBounds.left &&
        destinationBounds.top >= tableBounds.top &&
        destinationBounds.right <= tableBounds.right &&
        destinationBounds.bottom <= tableBounds.bottom;
    return isInside ? destination : null;
  }

  void _beginWarning(ScheduledSabotage event) {
    _current = ActiveSabotage(
      event: event,
      phase: SabotagePhase.warning,
      remainingSeconds: warningDurationSeconds,
      countermeasureId:
          'counter_${event.type.name}_${_counterSequence.toString().padLeft(4, '0')}',
    );
    _counterSequence++;
  }

  double _activeDuration(SabotageType type) => switch (type) {
    SabotageType.powerSurge => 5,
    SabotageType.equipmentJam => 7,
    SabotageType.greasyTable => 11,
    SabotageType.fakeOrder => 12,
  };

  void _markAffected(String eventId) {
    if (_affectedEventIds.add(eventId)) affectedCount++;
  }
}
