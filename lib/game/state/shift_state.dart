import '../game_layout.dart';
import '../models/shift_phase.dart';
import '../models/shift_result.dart';

class ShiftState {
  ShiftState({
    this.shiftDurationSeconds = GameLayout.shiftDurationSeconds,
    this.walletCoins = GameLayout.initialWalletCoins,
  }) : assert(shiftDurationSeconds > 0);

  final double shiftDurationSeconds;
  int walletCoins;
  ShiftPhase phase = ShiftPhase.active;
  double elapsedShiftSeconds = 0;
  int completedOrders = 0;
  int missedOrders = 0;
  int currentCombo = 0;
  int highestCombo = 0;
  int shiftEarnings = 0;
  int successfulServices = 0;
  int sabotagesDefended = 0;
  int sabotagesAffected = 0;

  double get remainingShiftSeconds =>
      (shiftDurationSeconds - elapsedShiftSeconds)
          .clamp(0.0, shiftDurationSeconds)
          .toDouble();

  bool get isGameplayInputAllowed => phase == ShiftPhase.active;

  String get formattedRemainingTime => formatDuration(remainingShiftSeconds);

  static String formatDuration(double durationSeconds) {
    final wholeSeconds = durationSeconds.ceil().clamp(0, 359999).toInt();
    final minutes = wholeSeconds ~/ 60;
    final seconds = wholeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool advanceActiveTime(double deltaSeconds) {
    if (deltaSeconds <= 0 || phase != ShiftPhase.active) {
      return false;
    }
    elapsedShiftSeconds = (elapsedShiftSeconds + deltaSeconds)
        .clamp(0.0, shiftDurationSeconds)
        .toDouble();
    if (remainingShiftSeconds > 0) {
      return false;
    }
    phase = ShiftPhase.ended;
    return true;
  }

  bool pause() {
    if (phase != ShiftPhase.active) {
      return false;
    }
    phase = ShiftPhase.paused;
    return true;
  }

  bool resume() {
    if (phase != ShiftPhase.paused) {
      return false;
    }
    phase = ShiftPhase.active;
    return true;
  }

  bool recordSuccessfulService({
    int rewardCoins = GameLayout.successfulServiceRewardCoins,
    bool enterFeedback = true,
  }) {
    if (phase != ShiftPhase.active) {
      return false;
    }
    walletCoins += rewardCoins;
    shiftEarnings += rewardCoins;
    currentCombo += 1;
    highestCombo = currentCombo > highestCombo ? currentCombo : highestCombo;
    completedOrders += 1;
    successfulServices += 1;
    if (enterFeedback) {
      phase = ShiftPhase.serviceFeedback;
    }
    return true;
  }

  bool recordMissedOrder({bool enterFeedback = true}) {
    if (phase != ShiftPhase.active) {
      return false;
    }
    missedOrders += 1;
    currentCombo = 0;
    if (enterFeedback) {
      phase = ShiftPhase.failureFeedback;
    }
    return true;
  }

  void resetCombo() {
    currentCombo = 0;
  }

  void setSabotageSummary({required int defended, required int affected}) {
    sabotagesDefended = defended;
    sabotagesAffected = affected;
  }

  void finishFeedback() {
    if (phase != ShiftPhase.serviceFeedback &&
        phase != ShiftPhase.failureFeedback) {
      return;
    }
    phase = remainingShiftSeconds <= 0 ? ShiftPhase.ended : ShiftPhase.active;
  }

  void endShift() {
    phase = ShiftPhase.ended;
  }

  ShiftResult get result => ShiftResult(
    completedOrders: completedOrders,
    missedOrders: missedOrders,
    highestCombo: highestCombo,
    shiftEarnings: shiftEarnings,
    totalWalletCoins: walletCoins,
    durationSeconds: shiftDurationSeconds,
    sabotagesDefended: sabotagesDefended,
    sabotagesAffected: sabotagesAffected,
  );

  void startNewShift() {
    phase = ShiftPhase.active;
    elapsedShiftSeconds = 0;
    completedOrders = 0;
    missedOrders = 0;
    currentCombo = 0;
    highestCombo = 0;
    shiftEarnings = 0;
    successfulServices = 0;
    sabotagesDefended = 0;
    sabotagesAffected = 0;
  }
}
