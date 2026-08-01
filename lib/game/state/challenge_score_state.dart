import '../models/score_entry.dart';

class ChallengeScoreState {
  final List<ScoreEntry> _entries = [];
  final Set<String> _transactionIds = {};

  List<ScoreEntry> get entries => List.unmodifiable(_entries);
  int get rawScore => _entries.fold(0, (sum, entry) => sum + entry.points);
  int get displayedScore => rawScore.clamp(0, 1 << 30);

  bool recordService({
    required String transactionId,
    required int serviceReward,
    required int comboAfterService,
    required double remainingPatienceSeconds,
  }) => _record(
    ScoreEntry(
      transactionId: transactionId,
      type: ScoreEventType.successfulService,
      points:
          (serviceReward * 100) +
          (comboAfterService * 50) +
          (remainingPatienceSeconds * 10).floor(),
    ),
  );

  bool recordSabotageDefended(String transactionId) => _record(
    ScoreEntry(
      transactionId: transactionId,
      type: ScoreEventType.sabotageDefended,
      points: 250,
    ),
  );

  bool recordMissedCustomer(String transactionId) => _record(
    ScoreEntry(
      transactionId: transactionId,
      type: ScoreEventType.missedCustomer,
      points: -500,
    ),
  );

  bool recordSabotageHit(String transactionId) => _record(
    ScoreEntry(
      transactionId: transactionId,
      type: ScoreEventType.sabotageHit,
      points: -200,
    ),
  );

  bool recordWrongService(String transactionId) => _record(
    ScoreEntry(
      transactionId: transactionId,
      type: ScoreEventType.wrongService,
      points: -300,
    ),
  );

  bool _record(ScoreEntry entry) {
    if (!_transactionIds.add(entry.transactionId)) return false;
    _entries.add(entry);
    return true;
  }

  void reset() {
    _entries.clear();
    _transactionIds.clear();
  }
}
