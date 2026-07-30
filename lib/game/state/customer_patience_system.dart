import '../models/customer_patience_state.dart';
import '../models/shift_phase.dart';

class CustomerPatienceSystem {
  CustomerPatienceSystem({required this.totalDurationSeconds})
    : assert(totalDurationSeconds > 0);

  double totalDurationSeconds;
  double _elapsedSeconds = 0;

  CustomerPatienceState get state => CustomerPatienceState(
    elapsedSeconds: _elapsedSeconds,
    totalSeconds: totalDurationSeconds,
  );

  bool get isExpired => state.status == CustomerPatienceStatus.expired;

  void beginNextOrder({double? totalDurationSeconds}) {
    if (totalDurationSeconds != null) {
      assert(totalDurationSeconds > 0);
      this.totalDurationSeconds = totalDurationSeconds;
    }
    _elapsedSeconds = 0;
  }

  bool advance({
    required double deltaSeconds,
    required ShiftPhase shiftPhase,
    required bool hasActiveOrder,
  }) {
    if (deltaSeconds <= 0 ||
        shiftPhase != ShiftPhase.active ||
        !hasActiveOrder ||
        isExpired) {
      return false;
    }

    _elapsedSeconds = (_elapsedSeconds + deltaSeconds)
        .clamp(0.0, totalDurationSeconds)
        .toDouble();
    return isExpired;
  }
}
