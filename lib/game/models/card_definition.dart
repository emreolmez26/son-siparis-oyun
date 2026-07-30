enum CardCategory { ingredient, equipment, result }

enum CardType { bread, patty, cookedPatty, cheese, pan, classicBurger }

class CardDefinition {
  const CardDefinition({
    required this.id,
    required this.type,
    required this.displayName,
    required this.category,
  });

  final String id;
  final CardType type;
  final String displayName;
  final CardCategory category;

  String get categoryLabel {
    return switch (category) {
      CardCategory.ingredient => 'MALZEME',
      CardCategory.equipment => 'EKİPMAN',
      CardCategory.result => 'SONUÇ',
    };
  }
}
