import '../models/market_pack_definition.dart';

const marketCatalog = <MarketPackDefinition>[
  MarketPackDefinition(
    id: 'pack_spicy',
    displayName: 'ATEŞ PAKETİ',
    priceCoins: 180,
    description: 'Acılı Sos ve Ateş Burger tarifini açar.',
    ingredientIds: {'hot_sauce_01'},
    equipmentIds: {},
    recipeIds: {'spicy_burger'},
  ),
  MarketPackDefinition(
    id: 'pack_gourmet',
    displayName: 'GURME TEZGÂHI',
    priceCoins: 240,
    description: 'Domates, Bıçak ve Gurme Burger tarifini açar.',
    ingredientIds: {'tomato_01'},
    equipmentIds: {'knife_01'},
    recipeIds: {'deluxe_burger'},
  ),
  MarketPackDefinition(
    id: 'pack_fryer',
    displayName: 'FRİTÖZ İSTASYONU',
    priceCoins: 220,
    description: 'Patates, Fritöz ve Çıtır Patates tarifini açar.',
    ingredientIds: {'potato_01'},
    equipmentIds: {'fryer_01'},
    recipeIds: {'crispy_fries'},
  ),
];
