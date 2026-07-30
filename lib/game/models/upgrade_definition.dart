import 'upgrade_id.dart';

class UpgradeDefinition {
  const UpgradeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconIdentifier,
    this.maximumLevel = 3,
  });

  final UpgradeId id;
  final String name;
  final String description;
  final String category;
  final String iconIdentifier;
  final int maximumLevel;
}
