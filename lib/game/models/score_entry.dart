enum ScoreEventType {
  successfulService,
  sabotageDefended,
  missedCustomer,
  sabotageHit,
  wrongService,
}

class ScoreEntry {
  const ScoreEntry({
    required this.transactionId,
    required this.type,
    required this.points,
  });

  final String transactionId;
  final ScoreEventType type;
  final int points;
}
