enum CustomerPatienceStatus { safe, warning, danger, expired }

class CustomerPatienceState {
  const CustomerPatienceState({
    required this.elapsedSeconds,
    required this.totalSeconds,
  });

  final double elapsedSeconds;
  final double totalSeconds;

  double get remainingSeconds =>
      (totalSeconds - elapsedSeconds).clamp(0.0, totalSeconds).toDouble();

  double get normalizedRemaining =>
      (remainingSeconds / totalSeconds).clamp(0.0, 1.0).toDouble();

  bool get isExpired => status == CustomerPatienceStatus.expired;

  CustomerPatienceStatus get status {
    if (remainingSeconds <= 0) {
      return CustomerPatienceStatus.expired;
    }
    if (normalizedRemaining <= .2) {
      return CustomerPatienceStatus.danger;
    }
    if (normalizedRemaining <= .5) {
      return CustomerPatienceStatus.warning;
    }
    return CustomerPatienceStatus.safe;
  }
}
