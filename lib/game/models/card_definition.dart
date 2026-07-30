enum CardCategory { ingredient, equipment, result }

enum CardType {
  bread,
  patty,
  cookedPatty,
  cheese,
  tomato,
  slicedTomato,
  hotSauce,
  potato,
  crispyFries,
  pan,
  knife,
  fryer,
  classicBurger,
  deluxeBurger,
  spicyBurger,
}

class CardDefinition {
  const CardDefinition({
    required this.id,
    required this.type,
    required this.displayName,
    required this.category,
    this.baseRewardCoins = 0,
    this.usesCheeseBonus = false,
  });

  final String id;
  final CardType type;
  final String displayName;
  final CardCategory category;
  final int baseRewardCoins;
  final bool usesCheeseBonus;

  String get categoryLabel {
    return switch (category) {
      CardCategory.ingredient => 'MALZEME',
      CardCategory.equipment => 'EKİPMAN',
      CardCategory.result => 'SONUÇ',
    };
  }
}
