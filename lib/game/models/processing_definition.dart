import 'card_definition.dart';
import 'processing_job.dart';

class ProcessingDefinition {
  const ProcessingDefinition({
    required this.id,
    required this.equipmentType,
    required this.inputType,
    required this.outputDefinition,
    required this.action,
    required this.baseDurationSeconds,
  });

  final String id;
  final CardType equipmentType;
  final CardType inputType;
  final CardDefinition outputDefinition;
  final ProcessingAction action;
  final double baseDurationSeconds;
}
