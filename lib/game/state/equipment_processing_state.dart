import 'dart:ui';

import '../data/prototype_processing_definitions.dart';
import '../models/processing_definition.dart';
import '../models/processing_job.dart';
import '../models/shift_phase.dart';
import 'kitchen_table_state.dart';

class EquipmentProcessingState {
  EquipmentProcessingState({required this.processingDurationSeconds})
    : assert(processingDurationSeconds > 0);

  final double processingDurationSeconds;
  final Map<String, ProcessingJob> _activeJobsByEquipment = {};
  int _nextJobSequence = 1;

  /// Compatibility convenience for the original single-pan prototype.
  ProcessingJob? get activeJob => _activeJobsByEquipment.isEmpty
      ? null
      : _activeJobsByEquipment.values.first;

  List<ProcessingJob> get activeJobs =>
      List.unmodifiable(_activeJobsByEquipment.values);

  ProcessingJob? activeJobForEquipment(String equipmentCardId) =>
      _activeJobsByEquipment[equipmentCardId];

  void clearActiveJob() => _activeJobsByEquipment.clear();

  void clearJobForEquipment(String equipmentCardId) {
    _activeJobsByEquipment.remove(equipmentCardId);
  }

  bool isEquipmentAvailable(String equipmentCardId) =>
      !_activeJobsByEquipment.containsKey(equipmentCardId);

  bool isCardLocked(String cardId) => _activeJobsByEquipment.values.any(
    (job) => job.equipmentCardId == cardId || job.inputCardId == cardId,
  );

  bool isProcessingInput(String cardId) =>
      _activeJobsByEquipment.values.any((job) => job.inputCardId == cardId);

  ProcessingDefinition? definitionFor({
    required KitchenTableState tableState,
    required String equipmentCardId,
    required String inputCardId,
  }) {
    final equipmentType = tableState.definitionFor(equipmentCardId).type;
    final inputType = tableState.definitionFor(inputCardId).type;
    for (final definition in prototypeProcessingDefinitions) {
      if (definition.equipmentType == equipmentType &&
          definition.inputType == inputType) {
        return definition;
      }
    }
    return null;
  }

  bool canStartProcessing({
    required KitchenTableState tableState,
    required String equipmentCardId,
    required String inputCardId,
    ProcessingDefinition? definition,
  }) {
    final processingDefinition =
        definition ??
        definitionFor(
          tableState: tableState,
          equipmentCardId: equipmentCardId,
          inputCardId: inputCardId,
        );
    return processingDefinition != null &&
        isEquipmentAvailable(equipmentCardId) &&
        tableState.isOnKitchenTable(equipmentCardId) &&
        tableState.definitionFor(equipmentCardId).type ==
            processingDefinition.equipmentType &&
        tableState.definitionFor(inputCardId).type ==
            processingDefinition.inputType &&
        !tableState.isProcessing(inputCardId);
  }

  bool tryStartProcessing({
    required KitchenTableState tableState,
    required String equipmentCardId,
    required String inputCardId,
    required Offset attachedInputPosition,
    required ProcessingDefinition definition,
    double? durationSeconds,
  }) {
    if (!canStartProcessing(
      tableState: tableState,
      equipmentCardId: equipmentCardId,
      inputCardId: inputCardId,
      definition: definition,
    )) {
      return false;
    }

    tableState.markCardProcessing(inputCardId, attachedInputPosition);
    _activeJobsByEquipment[equipmentCardId] = ProcessingJob(
      id: '${definition.id}_${_nextJobSequence.toString().padLeft(2, '0')}',
      equipmentCardId: equipmentCardId,
      inputCardId: inputCardId,
      action: definition.action,
      elapsedSeconds: 0,
      totalDurationSeconds: durationSeconds ?? definition.baseDurationSeconds,
      status: ProcessingStatus.active,
    );
    _nextJobSequence++;
    return true;
  }

  bool canStartPattyCooking({
    required KitchenTableState tableState,
    required String equipmentCardId,
    required String inputCardId,
  }) => canStartProcessing(
    tableState: tableState,
    equipmentCardId: equipmentCardId,
    inputCardId: inputCardId,
    definition: panProcessingDefinition,
  );

  bool tryStartPattyCooking({
    required KitchenTableState tableState,
    required String equipmentCardId,
    required String inputCardId,
    required Offset attachedInputPosition,
    double? durationSeconds,
  }) => tryStartProcessing(
    tableState: tableState,
    equipmentCardId: equipmentCardId,
    inputCardId: inputCardId,
    attachedInputPosition: attachedInputPosition,
    definition: panProcessingDefinition,
    durationSeconds: durationSeconds ?? processingDurationSeconds,
  );

  /// Advances all active jobs and returns every job completed this frame.
  List<ProcessingJob> advanceAll(double deltaSeconds) {
    if (deltaSeconds <= 0 || _activeJobsByEquipment.isEmpty) {
      return const [];
    }

    final completed = <ProcessingJob>[];
    final entries = _activeJobsByEquipment.entries.toList();
    for (final entry in entries) {
      final activeJob = entry.value;
      final elapsedSeconds = (activeJob.elapsedSeconds + deltaSeconds)
          .clamp(0.0, activeJob.totalDurationSeconds)
          .toDouble();
      if (elapsedSeconds < activeJob.totalDurationSeconds) {
        _activeJobsByEquipment[entry.key] = activeJob.copyWith(
          elapsedSeconds: elapsedSeconds,
        );
        continue;
      }
      completed.add(
        activeJob.copyWith(
          elapsedSeconds: activeJob.totalDurationSeconds,
          status: ProcessingStatus.completed,
        ),
      );
      _activeJobsByEquipment.remove(entry.key);
    }
    return completed;
  }

  List<ProcessingJob> advanceForShift({
    required double deltaSeconds,
    required ShiftPhase shiftPhase,
  }) => shiftPhase == ShiftPhase.active ? advanceAll(deltaSeconds) : const [];

  /// Compatibility helper for the original one-job tests.
  ProcessingJob? advance(double deltaSeconds) {
    final completed = advanceAll(deltaSeconds);
    return completed.isEmpty ? null : completed.first;
  }

  bool hasConsistentProcessingLocation(KitchenTableState tableState) {
    if (_activeJobsByEquipment.isEmpty) {
      return !tableState.definitions.any(
        (definition) => tableState.isProcessing(definition.id),
      );
    }
    return _activeJobsByEquipment.values.every(
          (job) =>
              tableState.isProcessing(job.inputCardId) &&
              !tableState.isProcessing(job.equipmentCardId),
        ) &&
        tableState.hasConsistentCardLocations();
  }
}
