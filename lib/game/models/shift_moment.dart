import 'card_definition.dart';

enum ShiftMomentKind { lastSecond, combo, reward }

class ShiftMoment {
  const ShiftMoment({
    required this.kind,
    required this.resultType,
    required this.resultName,
    required this.day,
    required this.combo,
    required this.rewardCoins,
    this.remainingPatienceSeconds,
  });

  final ShiftMomentKind kind;
  final CardType resultType;
  final String resultName;
  final int day;
  final int combo;
  final int rewardCoins;
  final double? remainingPatienceSeconds;
}
