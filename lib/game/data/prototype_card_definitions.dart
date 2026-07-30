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
  id: 'burger_01',
  type: CardType.classicBurger,
  displayName: 'Klasik Burger',
  category: CardCategory.result,
);

const prototypeCardDefinitions = <CardDefinition>[
  CardDefinition(
    id: 'bread_01',
    type: CardType.bread,
    displayName: 'Ekmek',
    category: CardCategory.ingredient,
  ),
  rawPattyCardDefinition,
  CardDefinition(
    id: 'cheese_01',
    type: CardType.cheese,
    displayName: 'Peynir',
    category: CardCategory.ingredient,
  ),
  CardDefinition(
    id: 'pan_01',
    type: CardType.pan,
    displayName: 'Tava',
    category: CardCategory.equipment,
  ),
];
