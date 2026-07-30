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
  resultInstanceId: 'classic_burger_01',
);

final deluxeBurgerRecipeDefinition = RecipeDefinition(
  id: 'deluxe_burger',
  displayName: 'Gurme Burger',
  requiredCardTypes: const [
    CardType.bread,
    CardType.cookedPatty,
    CardType.slicedTomato,
    CardType.cheese,
  ],
  resultDefinition: deluxeBurgerCardDefinition,
  resultInstanceId: 'deluxe_burger_01',
);

final spicyBurgerRecipeDefinition = RecipeDefinition(
  id: 'spicy_burger',
  displayName: 'Ateş Burger',
  requiredCardTypes: const [
    CardType.bread,
    CardType.cookedPatty,
    CardType.hotSauce,
    CardType.cheese,
  ],
  resultDefinition: spicyBurgerCardDefinition,
  resultInstanceId: 'spicy_burger_01',
);

final prototypeRecipeDefinitions = <RecipeDefinition>[
  classicBurgerRecipeDefinition,
  deluxeBurgerRecipeDefinition,
  spicyBurgerRecipeDefinition,
];
