import '../models/card_definition.dart';

const rawPattyCardDefinition = CardDefinition(
  id: 'patty_01',
  type: CardType.patty,
  displayName: 'Köfte',
  category: CardCategory.ingredient,
);

const cookedPattyCardDefinition = CardDefinition(
  id: 'patty_01',
  type: CardType.cookedPatty,
  displayName: 'Pişmiş Köfte',
  category: CardCategory.ingredient,
);

const classicBurgerCardDefinition = CardDefinition(
  id: 'classic_burger_01',
  type: CardType.classicBurger,
  displayName: 'Klasik Burger',
  category: CardCategory.result,
  baseRewardCoins: 10,
  usesCheeseBonus: true,
);

const deluxeBurgerCardDefinition = CardDefinition(
  id: 'deluxe_burger_01',
  type: CardType.deluxeBurger,
  displayName: 'Gurme Burger',
  category: CardCategory.result,
  baseRewardCoins: 15,
  usesCheeseBonus: true,
);

const spicyBurgerCardDefinition = CardDefinition(
  id: 'spicy_burger_01',
  type: CardType.spicyBurger,
  displayName: 'Ateş Burger',
  category: CardCategory.result,
  baseRewardCoins: 15,
  usesCheeseBonus: true,
);

const breadCardDefinition = CardDefinition(
  id: 'bread_01',
  type: CardType.bread,
  displayName: 'Ekmek',
  category: CardCategory.ingredient,
);

const cheeseCardDefinition = CardDefinition(
  id: 'cheese_01',
  type: CardType.cheese,
  displayName: 'Peynir',
  category: CardCategory.ingredient,
);

const tomatoCardDefinition = CardDefinition(
  id: 'tomato_01',
  type: CardType.tomato,
  displayName: 'Domates',
  category: CardCategory.ingredient,
);

const slicedTomatoCardDefinition = CardDefinition(
  id: 'tomato_01',
  type: CardType.slicedTomato,
  displayName: 'Dilimlenmiş Domates',
  category: CardCategory.ingredient,
);

const hotSauceCardDefinition = CardDefinition(
  id: 'hot_sauce_01',
  type: CardType.hotSauce,
  displayName: 'Acılı Sos',
  category: CardCategory.ingredient,
);

const potatoCardDefinition = CardDefinition(
  id: 'potato_01',
  type: CardType.potato,
  displayName: 'Patates',
  category: CardCategory.ingredient,
);

const crispyFriesCardDefinition = CardDefinition(
  id: 'potato_01',
  type: CardType.crispyFries,
  displayName: 'Çıtır Patates',
  category: CardCategory.result,
  baseRewardCoins: 8,
);

const panCardDefinition = CardDefinition(
  id: 'pan_01',
  type: CardType.pan,
  displayName: 'Tava',
  category: CardCategory.equipment,
);

const knifeCardDefinition = CardDefinition(
  id: 'knife_01',
  type: CardType.knife,
  displayName: 'Bıçak',
  category: CardCategory.equipment,
);

const fryerCardDefinition = CardDefinition(
  id: 'fryer_01',
  type: CardType.fryer,
  displayName: 'Fritöz',
  category: CardCategory.equipment,
);

const prototypeCycleIngredientDefinitions = <CardDefinition>[
  breadCardDefinition,
  rawPattyCardDefinition,
  cheeseCardDefinition,
  tomatoCardDefinition,
  hotSauceCardDefinition,
  potatoCardDefinition,
];

const prototypeEquipmentDefinitions = <CardDefinition>[
  panCardDefinition,
  knifeCardDefinition,
  fryerCardDefinition,
];

const prototypeResultDefinitions = <CardDefinition>[
  classicBurgerCardDefinition,
  deluxeBurgerCardDefinition,
  spicyBurgerCardDefinition,
  crispyFriesCardDefinition,
];

const prototypeRawDefinitionsById = <String, CardDefinition>{
  'bread_01': breadCardDefinition,
  'patty_01': rawPattyCardDefinition,
  'cheese_01': cheeseCardDefinition,
  'tomato_01': tomatoCardDefinition,
  'hot_sauce_01': hotSauceCardDefinition,
  'potato_01': potatoCardDefinition,
};

const prototypeCardDefinitions = <CardDefinition>[
  ...prototypeCycleIngredientDefinitions,
  ...prototypeEquipmentDefinitions,
];
