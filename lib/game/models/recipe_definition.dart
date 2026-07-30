import 'card_definition.dart';

class RecipeDefinition {
  RecipeDefinition({
    required this.id,
    required this.displayName,
    required List<CardType> requiredCardTypes,
    required this.resultDefinition,
    required this.resultInstanceId,
  }) : requiredCardTypes = List.unmodifiable(requiredCardTypes) {
    if (requiredCardTypes.isEmpty) {
      throw ArgumentError.value(
        requiredCardTypes,
        'requiredCardTypes',
        'A recipe needs at least one required card type.',
      );
    }
    if (resultDefinition.id != resultInstanceId) {
      throw ArgumentError.value(
        resultInstanceId,
        'resultInstanceId',
        'The result definition ID must match the result instance ID.',
      );
    }
  }

  final String id;
  final String displayName;
  final List<CardType> requiredCardTypes;
  final CardDefinition resultDefinition;
  final String resultInstanceId;
}
