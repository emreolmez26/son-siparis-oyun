import 'card_definition.dart';

enum RecipeBookCategory { burgers, sides, secrets }

class RecipeBookEntry {
  const RecipeBookEntry({
    required this.id,
    required this.displayName,
    required this.category,
    required this.orderedInputs,
    required this.preparation,
    required this.resultDefinition,
    this.isPlaceholder = false,
  });

  final String id;
  final String displayName;
  final RecipeBookCategory category;
  final List<String> orderedInputs;
  final List<String> preparation;
  final CardDefinition? resultDefinition;
  final bool isPlaceholder;

  int get ingredientCount => orderedInputs.length;
}
