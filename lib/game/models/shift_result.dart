enum ShiftGrade { s, a, b, c }

class ShiftResult {
  const ShiftResult({
    required this.completedOrders,
    required this.missedOrders,
    required this.highestCombo,
    required this.shiftEarnings,
    required this.totalWalletCoins,
    required this.durationSeconds,
    this.sabotagesDefended = 0,
    this.sabotagesAffected = 0,
  });

  final int completedOrders;
  final int missedOrders;
  final int highestCombo;
  final int shiftEarnings;
  final int totalWalletCoins;
  final double durationSeconds;
  final int sabotagesDefended;
  final int sabotagesAffected;

  ShiftGrade get grade {
    if (completedOrders >= 8 && missedOrders == 0) {
      return ShiftGrade.s;
    }
    if (completedOrders >= 6) {
      return ShiftGrade.a;
    }
    if (completedOrders >= 3) {
      return ShiftGrade.b;
    }
    return ShiftGrade.c;
  }

  String get gradeLabel => grade.name.toUpperCase();
}
