import '../models/recipe_book_entry.dart';
import 'prototype_card_definitions.dart';

const recipeBookEntries = <RecipeBookEntry>[
  RecipeBookEntry(
    id: 'classic_burger',
    displayName: 'Klasik Burger',
    category: RecipeBookCategory.burgers,
    orderedInputs: ['Ekmek', 'Pişmiş Köfte', 'Peynir'],
    preparation: ['Köfte + Tava'],
    resultDefinition: classicBurgerCardDefinition,
  ),
  RecipeBookEntry(
    id: 'deluxe_burger',
    displayName: 'Gurme Burger',
    category: RecipeBookCategory.burgers,
    orderedInputs: ['Ekmek', 'Pişmiş Köfte', 'Dilimlenmiş Domates', 'Peynir'],
    preparation: ['Köfte + Tava', 'Domates + Bıçak'],
    resultDefinition: deluxeBurgerCardDefinition,
  ),
  RecipeBookEntry(
    id: 'spicy_burger',
    displayName: 'Ateş Burger',
    category: RecipeBookCategory.burgers,
    orderedInputs: ['Ekmek', 'Pişmiş Köfte', 'Acılı Sos', 'Peynir'],
    preparation: ['Köfte + Tava'],
    resultDefinition: spicyBurgerCardDefinition,
  ),
  RecipeBookEntry(
    id: 'crispy_fries',
    displayName: 'Çıtır Patates',
    category: RecipeBookCategory.sides,
    orderedInputs: ['Patates'],
    preparation: ['Patates + Fritöz'],
    resultDefinition: crispyFriesCardDefinition,
  ),
  RecipeBookEntry(
    id: 'secret_placeholder_01',
    displayName: 'Keşfedilmedi',
    category: RecipeBookCategory.secrets,
    orderedInputs: [],
    preparation: [],
    resultDefinition: null,
    isPlaceholder: true,
  ),
  RecipeBookEntry(
    id: 'secret_placeholder_02',
    displayName: 'Keşfedilmedi',
    category: RecipeBookCategory.secrets,
    orderedInputs: [],
    preparation: [],
    resultDefinition: null,
    isPlaceholder: true,
  ),
];
