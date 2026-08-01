import '../models/card_definition.dart';

abstract interface class OrderResultSource {
  int nextInt(int max);
}

class SeededOrderResultSource implements OrderResultSource {
  SeededOrderResultSource(int seed) : _state = seed & 0x7fffffff;

  int _state;

  @override
  int nextInt(int max) {
    assert(max > 0);
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    return _state % max;
  }
}

class SequenceOrderResultSource implements OrderResultSource {
  SequenceOrderResultSource(Iterable<int> values)
    : _values = List<int>.unmodifiable(values);

  final List<int> _values;
  int _index = 0;

  @override
  int nextInt(int max) {
    assert(max > 0);
    if (_values.isEmpty) return 0;
    final value = _values[_index % _values.length];
    _index++;
    return value.abs() % max;
  }
}

class OrderResultGenerator {
  OrderResultGenerator({
    OrderResultSource? source,
    Iterable<CardType> availableResults = defaultAvailableResults,
  }) : _source = source ?? SeededOrderResultSource(731),
       availableResults = List.unmodifiable(availableResults) {
    if (this.availableResults.isEmpty) {
      throw ArgumentError.value(availableResults, 'availableResults');
    }
  }

  static const defaultAvailableResults = <CardType>[
    CardType.classicBurger,
    CardType.deluxeBurger,
    CardType.spicyBurger,
    CardType.crispyFries,
  ];

  final OrderResultSource _source;
  final List<CardType> availableResults;

  CardType nextResult({required Iterable<CardType> activeResults}) {
    final active = activeResults.toSet();
    final candidates = availableResults
        .where((result) => !active.contains(result))
        .toList();
    final pool = candidates.isEmpty ? availableResults : candidates;
    return pool[_source.nextInt(pool.length)];
  }
}
