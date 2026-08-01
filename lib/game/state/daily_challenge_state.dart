import '../models/daily_challenge_result.dart';
import '../systems/daily_seed_factory.dart';
import 'challenge_score_state.dart';

class DailyChallengeState {
  DailyChallengeState({
    DateProvider dateProvider = const LocalDateProvider(),
    DailySeedFactory seedFactory = const DailySeedFactory(),
    Map<String, DailyChallengeRecord> initialRecords = const {},
  }) : _dateProvider = dateProvider,
       _seedFactory = seedFactory,
       _records = {...initialRecords};

  final DateProvider _dateProvider;
  final DailySeedFactory _seedFactory;
  final Map<String, DailyChallengeRecord> _records;
  final ChallengeScoreState score = ChallengeScoreState();
  String? activeDateKey;
  int? activeSeed;
  bool resultCommitted = false;
  bool isNewRecord = false;

  static const rulesVersion = DailySeedFactory.challengeRulesVersion;

  Map<String, DailyChallengeRecord> get records => Map.unmodifiable(_records);
  DailyChallengeRecord? bestFor(String dateKey) =>
      _records['$rulesVersion:$dateKey'];
  DailyChallengeRecord? get activeBest =>
      activeDateKey == null ? null : bestFor(activeDateKey!);
  DateTime now() => _dateProvider.now();

  void start() {
    activeDateKey = _seedFactory.dateKey(_dateProvider.now());
    activeSeed = _seedFactory.challengeSeed(activeDateKey!);
    score.reset();
    resultCommitted = false;
    isNewRecord = false;
  }

  int streamSeed(String name) {
    final seed = activeSeed;
    if (seed == null) throw StateError('Daily Challenge is not active.');
    return _seedFactory.streamSeed(seed, name);
  }

  Future<bool> commitResult({
    required int completedOrders,
    required int highestCombo,
    required int missedOrders,
    required int sabotagesDefended,
    required int sabotageHits,
    required DateTime recordedAt,
    required Future<bool> Function() persistCurrentSnapshot,
  }) async {
    if (resultCommitted || activeDateKey == null) return false;
    resultCommitted = true;
    final prior = activeBest;
    final candidate = DailyChallengeRecord(
      dateKey: activeDateKey!,
      rulesVersion: rulesVersion,
      bestScore: score.displayedScore,
      completedOrders: completedOrders,
      highestCombo: highestCombo,
      missedOrders: missedOrders,
      sabotagesDefended: sabotagesDefended,
      sabotageHits: sabotageHits,
      recordedTimestamp: recordedAt.toUtc().toIso8601String(),
    );
    if (prior != null && candidate.bestScore <= prior.bestScore) {
      isNewRecord = false;
      return false;
    }
    final previousRecords = {..._records};
    _records[candidate.storageKey] = candidate;
    _prune();
    var persisted = false;
    try {
      persisted = await persistCurrentSnapshot();
    } on Object {
      persisted = false;
    }
    if (!persisted) {
      _records
        ..clear()
        ..addAll(previousRecords);
      resultCommitted = false;
      return false;
    }
    isNewRecord = true;
    return true;
  }

  void _prune() {
    final entries = _records.entries.toList()
      ..sort((a, b) {
        final byDate = b.value.dateKey.compareTo(a.value.dateKey);
        return byDate != 0 ? byDate : b.key.compareTo(a.key);
      });
    for (final entry in entries.skip(30)) {
      _records.remove(entry.key);
    }
  }

  void resetHistory() => _records.clear();
}
