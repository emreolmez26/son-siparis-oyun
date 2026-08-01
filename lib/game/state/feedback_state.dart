import '../game_layout.dart';

class ComboMilestoneTracker {
  static const milestones = {3, 5, 8, 10};
  final Set<int> _fired = {};

  int? record(int combo) {
    if (combo <= 0) {
      _fired.clear();
      return null;
    }
    if (!milestones.contains(combo) || !_fired.add(combo)) return null;
    return combo;
  }
}

class LastSecondFeedbackState {
  double realSecondsRemaining = 0;
  double servedPatienceSeconds = 0;

  bool get isActive => realSecondsRemaining > 0;

  bool trigger(double remainingPatienceSeconds) {
    if (remainingPatienceSeconds > 1) return false;
    servedPatienceSeconds = remainingPatienceSeconds.clamp(0, 1).toDouble();
    realSecondsRemaining = GameLayout.lastSecondSlowdownRealSeconds;
    return true;
  }

  double scaleDelta(double realDeltaSeconds) {
    if (!isActive || realDeltaSeconds <= 0) return realDeltaSeconds;
    realSecondsRemaining = (realSecondsRemaining - realDeltaSeconds)
        .clamp(0, GameLayout.lastSecondSlowdownRealSeconds)
        .toDouble();
    return realDeltaSeconds * GameLayout.lastSecondTimeScale;
  }
}
