class KitchenLoadout {
  const KitchenLoadout({
    required this.ingredientIds,
    required this.equipmentIds,
  });

  static const maxIngredientCount = 6;
  static const maxEquipmentCount = 3;
  static const starter = KitchenLoadout(
    ingredientIds: {'bread_01', 'patty_01', 'cheese_01'},
    equipmentIds: {'pan_01'},
  );

  final Set<String> ingredientIds;
  final Set<String> equipmentIds;

  KitchenLoadout copy() => KitchenLoadout(
    ingredientIds: {...ingredientIds},
    equipmentIds: {...equipmentIds},
  );
}
