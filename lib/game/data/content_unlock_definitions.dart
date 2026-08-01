import '../models/card_definition.dart';

const allIngredientIds = {
  'bread_01',
  'patty_01',
  'cheese_01',
  'tomato_01',
  'hot_sauce_01',
  'potato_01',
};
const allEquipmentIds = {'pan_01', 'knife_01', 'fryer_01'};
const allRecipeIds = {
  'classic_burger',
  'deluxe_burger',
  'spicy_burger',
  'crispy_fries',
};
const allMarketPackIds = {'pack_spicy', 'pack_gourmet', 'pack_fryer'};

const contentDisplayNames = <String, String>{
  'bread_01': 'Ekmek',
  'patty_01': 'Köfte',
  'cheese_01': 'Peynir',
  'tomato_01': 'Domates',
  'hot_sauce_01': 'Acılı Sos',
  'potato_01': 'Patates',
  'pan_01': 'Tava',
  'knife_01': 'Bıçak',
  'fryer_01': 'Fritöz',
  'classic_burger': 'Klasik Burger',
  'deluxe_burger': 'Gurme Burger',
  'spicy_burger': 'Ateş Burger',
  'crispy_fries': 'Çıtır Patates',
};

const recipeRequiredIngredientIds = <String, Set<String>>{
  'classic_burger': {'bread_01', 'patty_01', 'cheese_01'},
  'deluxe_burger': {'bread_01', 'patty_01', 'cheese_01', 'tomato_01'},
  'spicy_burger': {'bread_01', 'patty_01', 'cheese_01', 'hot_sauce_01'},
  'crispy_fries': {'potato_01'},
};
const recipeRequiredEquipmentIds = <String, Set<String>>{
  'classic_burger': {'pan_01'},
  'deluxe_burger': {'pan_01', 'knife_01'},
  'spicy_burger': {'pan_01'},
  'crispy_fries': {'fryer_01'},
};
const recipeResultTypes = <String, CardType>{
  'classic_burger': CardType.classicBurger,
  'deluxe_burger': CardType.deluxeBurger,
  'spicy_burger': CardType.spicyBurger,
  'crispy_fries': CardType.crispyFries,
};
