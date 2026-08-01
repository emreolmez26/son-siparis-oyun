class DailyChallengeRecord {
  const DailyChallengeRecord({
    required this.dateKey,
    required this.rulesVersion,
    required this.bestScore,
    required this.completedOrders,
    required this.highestCombo,
    required this.missedOrders,
    required this.sabotagesDefended,
    required this.sabotageHits,
    required this.recordedTimestamp,
  });

  final String dateKey;
  final int rulesVersion;
  final int bestScore;
  final int completedOrders;
  final int highestCombo;
  final int missedOrders;
  final int sabotagesDefended;
  final int sabotageHits;
  final String recordedTimestamp;

  String get storageKey => '$rulesVersion:$dateKey';

  Map<String, Object?> toJson() => {
    'dateKey': dateKey,
    'rulesVersion': rulesVersion,
    'bestScore': bestScore,
    'completedOrders': completedOrders,
    'highestCombo': highestCombo,
    'missedOrders': missedOrders,
    'sabotagesDefended': sabotagesDefended,
    'sabotageHits': sabotageHits,
    'recordedTimestamp': recordedTimestamp,
  };

  static DailyChallengeRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    int value(String key) => raw[key] is num ? (raw[key] as num).toInt() : 0;
    final dateKey = raw['dateKey'];
    final timestamp = raw['recordedTimestamp'];
    final rulesVersion = value('rulesVersion');
    if (dateKey is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey) ||
        timestamp is! String ||
        rulesVersion <= 0) {
      return null;
    }
    return DailyChallengeRecord(
      dateKey: dateKey,
      rulesVersion: rulesVersion,
      bestScore: value('bestScore').clamp(0, 1 << 30),
      completedOrders: value('completedOrders').clamp(0, 1 << 20),
      highestCombo: value('highestCombo').clamp(0, 1 << 20),
      missedOrders: value('missedOrders').clamp(0, 1 << 20),
      sabotagesDefended: value('sabotagesDefended').clamp(0, 1 << 20),
      sabotageHits: value('sabotageHits').clamp(0, 1 << 20),
      recordedTimestamp: timestamp,
    );
  }
}
