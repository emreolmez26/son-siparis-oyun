import 'dart:ui';

import '../models/card_definition.dart';
import '../models/processing_job.dart';
import 'kitchen_table_state.dart';

class EquipmentProcessingState {
  EquipmentProcessingState({required this.processingDurationSeconds})
    : assert(processingDurationSeconds > 0);

  final double processingDurationSeconds;
  ProcessingJob? _activeJob;
  int _nextJobSequence = 1;

  ProcessingJob? get activeJob => _activeJob;

  bool isEquipmentAvailable(String equipmentCardId) {
    return _activeJob?.equipmentCardId != equipmentCardId;
  }

  bool isCardLocked(String cardId) {
    final job = _activeJob;
    return job != null &&
        (job.equipmentCardId == cardId || job.inputCardId == cardId);
  }

  bool isProcessingInput(String cardId) => _activeJob?.inputCardId == cardId;

  bool canStartPattyCooking({
    required KitchenTableState tableState,
    required String equipmentCardId,
    required String inputCardId,
  }) {
    return isEquipmentAvailable(equipmentCardId) &&
        tableState.isOnKitchenTable(equipmentCardId) &&
        tableState.definitionFor(equipmentCardId).type == CardType.pan &&
        tableState.definitionFor(inputCardId).type == CardType.patty &&
        !tableState.isProcessing(inputCardId);
  }

  bool tryStartPattyCooking({
    required KitchenTableState tableState,
    required String equipmentCardId,
    required String inputCardId,
    required Offset attachedInputPosition,
  }) {
    if (!canStartPattyCooking(
      tableState: tableState,
      equipmentCardId: equipmentCardId,
      inputCardId: inputCardId,
    )) {
      return false;
    }

    tableState.markCardProcessing(inputCardId, attachedInputPosition);
    _activeJob = ProcessingJob(
      id: 'pan_process_${_nextJobSequence.toString().padLeft(2, '0')}',
      equipmentCardId: equipmentCardId,
      inputCardId: inputCardId,
      action: ProcessingAction.cookPatty,
      elapsedSeconds: 0,
      totalDurationSeconds: processingDurationSeconds,
      status: ProcessingStatus.active,
    );
    _nextJobSequence++;
    return true;
  }

  ProcessingJob? advance(double deltaSeconds) {
    final activeJob = _activeJob;
    if (activeJob == null) {
      return null;
    }

    final elapsedSeconds = (activeJob.elapsedSeconds + deltaSeconds)
        .clamp(0.0, activeJob.totalDurationSeconds)
        .toDouble();
    if (elapsedSeconds < activeJob.totalDurationSeconds) {
      _activeJob = activeJob.copyWith(elapsedSeconds: elapsedSeconds);
      return null;
    }

    final completedJob = activeJob.copyWith(
      elapsedSeconds: activeJob.totalDurationSeconds,
      status: ProcessingStatus.completed,
    );
    _activeJob = null;
    return completedJob;
  }

  bool hasConsistentProcessingLocation(KitchenTableState tableState) {
    final activeJob = _activeJob;
    if (activeJob == null) {
      return !tableState.definitions.any(
        (definition) => tableState.isProcessing(definition.id),
      );
    }
    return tableState.isProcessing(activeJob.inputCardId) &&
        !tableState.isProcessing(activeJob.equipmentCardId) &&
        tableState.cardCount == 4;
  }
}
