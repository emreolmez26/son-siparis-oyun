import '../models/card_definition.dart';
import '../models/recipe_definition.dart';
import 'prototype_card_definitions.dart';

final classicBurgerRecipeDefinition = RecipeDefinition(
  id: 'classic_burger',
  displayName: 'Klasik Burger',
  requiredCardTypes: const [
    CardType.bread,
    CardType.cookedPatty,
    CardType.cheese,
  ],
  resultDefinition: classicBurgerCardDefinition,
  resultInstanceId: 'burger_01',
);

final prototypeRecipeDefinitions = <RecipeDefinition>[
  classicBurgerRecipeDefinition,
];
