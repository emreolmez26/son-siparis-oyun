import 'dart:math';
import 'dart:ui';

import '../models/card_definition.dart';
import '../models/sabotage.dart';

class SabotageScheduler {
  const SabotageScheduler();

  List<ScheduledSabotage> buildSchedule({
    required int day,
    required String rivalId,
    int? testSeed,
  }) {
    final count = day <= 2 ? 0 : (day <= 4 ? 1 : (day <= 7 ? 2 : 3));
    if (count == 0) return const [];
    final seed = testSeed ?? _stableSeed(day, rivalId);
    final random = Random(seed);
    final types = SabotageType.values;
    const equipmentIds = ['pan_01', 'knife_01', 'fryer_01'];
    const resultTypes = [
      CardType.classicBurger,
      CardType.deluxeBurger,
      CardType.spicyBurger,
      CardType.crispyFries,
    ];
    const directions = [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ];
    return List.generate(count, (index) {
      final type = types[(seed.abs() + index) % types.length];
      final column = random.nextInt(20);
      final row = random.nextInt(5);
      return ScheduledSabotage(
        id: 'sabotage_${day}_${(index + 1).toString().padLeft(2, '0')}',
        type: type,
        scheduledAtSeconds: 18 + (index * 18).toDouble(),
        targetEquipmentId: type == SabotageType.equipmentJam
            ? equipmentIds[random.nextInt(equipmentIds.length)]
            : null,
        greasyRegion: type == SabotageType.greasyTable
            ? Rect.fromLTWH(
                40 + (column * 32).toDouble(),
                234 + (row * 32).toDouble(),
                128,
                96,
              )
            : null,
        slideDirection: type == SabotageType.greasyTable
            ? directions[random.nextInt(directions.length)]
            : Offset.zero,
        fakeOrderType: type == SabotageType.fakeOrder
            ? resultTypes[random.nextInt(resultTypes.length)]
            : null,
      );
    });
  }

  int _stableSeed(int day, String rivalId) {
    var hash = 17;
    for (final unit in rivalId.codeUnits) {
      hash = 0x1fffffff & ((hash * 31) + unit);
    }
    return 0x1fffffff & ((day * 1009) + hash);
  }
}
