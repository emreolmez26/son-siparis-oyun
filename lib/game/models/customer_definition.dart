class CustomerDefinition {
  const CustomerDefinition({
    required this.id,
    required this.displayName,
    required this.displayLabel,
    required this.basePatienceSeconds,
    required this.accentColorValue,
  });

  final String id;
  final String displayName;
  final String displayLabel;
  final double basePatienceSeconds;
  final int accentColorValue;
}
