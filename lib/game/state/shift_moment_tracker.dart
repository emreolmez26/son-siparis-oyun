import '../models/card_definition.dart';
import '../models/shift_moment.dart';

class ShiftMomentTracker {
  _RecordedService? _closestLastSecondService;
  _RecordedService? _highestRewardService;
  _RecordedService? _highestComboService;
  int _day = 1;

  void startShift({required int day}) {
    _day = day;
    _closestLastSecondService = null;
    _highestRewardService = null;
    _highestComboService = null;
  }

  void recordSuccessfulService({
    required CardDefinition resultDefinition,
    required double remainingPatienceSeconds,
    required int combo,
    required int rewardCoins,
  }) {
    final service = _RecordedService(
      resultDefinition: resultDefinition,
      remainingPatienceSeconds: remainingPatienceSeconds,
      combo: combo,
      rewardCoins: rewardCoins,
    );
    if (remainingPatienceSeconds <= 3.0 &&
        (_closestLastSecondService == null ||
            remainingPatienceSeconds <
                _closestLastSecondService!.remainingPatienceSeconds)) {
      _closestLastSecondService = service;
    }
    if (_highestComboService == null || combo > _highestComboService!.combo) {
      _highestComboService = service;
    }
    if (_highestRewardService == null ||
        rewardCoins > _highestRewardService!.rewardCoins) {
      _highestRewardService = service;
    }
  }

  ShiftMoment? selectMoment() {
    final closest = _closestLastSecondService;
    if (closest != null) return _momentFor(closest, ShiftMomentKind.lastSecond);
    final combo = _highestComboService;
    if (combo != null && combo.combo >= 3) {
      return _momentFor(combo, ShiftMomentKind.combo);
    }
    final reward = _highestRewardService;
    if (reward != null) return _momentFor(reward, ShiftMomentKind.reward);
    return null;
  }

  ShiftMoment _momentFor(_RecordedService service, ShiftMomentKind kind) =>
      ShiftMoment(
        kind: kind,
        resultType: service.resultDefinition.type,
        resultName: service.resultDefinition.displayName,
        day: _day,
        combo: service.combo,
        rewardCoins: service.rewardCoins,
        remainingPatienceSeconds: kind == ShiftMomentKind.lastSecond
            ? service.remainingPatienceSeconds
            : null,
      );
}

class _RecordedService {
  const _RecordedService({
    required this.resultDefinition,
    required this.remainingPatienceSeconds,
    required this.combo,
    required this.rewardCoins,
  });

  final CardDefinition resultDefinition;
  final double remainingPatienceSeconds;
  final int combo;
  final int rewardCoins;
}
