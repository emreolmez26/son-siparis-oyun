abstract interface class DateProvider {
  DateTime now();
}

class LocalDateProvider implements DateProvider {
  const LocalDateProvider();

  /// The offline MVP intentionally trusts the device calendar. Changing the
  /// device clock can therefore select another challenge; any future online
  /// competition must use a server-authoritative date instead.
  @override
  DateTime now() => DateTime.now();
}

class FixedDateProvider implements DateProvider {
  const FixedDateProvider(this.value);
  final DateTime value;

  @override
  DateTime now() => value;
}

class DailySeedFactory {
  const DailySeedFactory();

  static const namespace = 'son_siparis_daily';
  static const challengeRulesVersion = 1;

  String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int challengeSeed(
    String dateKey, {
    int rulesVersion = challengeRulesVersion,
  }) => stableHash('${namespace}_v$rulesVersion:$dateKey');

  int streamSeed(int challengeSeed, String streamName) =>
      stableHash('$challengeSeed:$streamName');

  int stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final byte in value.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
