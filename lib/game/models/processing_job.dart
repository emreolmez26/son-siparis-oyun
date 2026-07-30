enum ProcessingAction { cookPatty, sliceTomato, fryPotato }

enum ProcessingStatus { active, completed }

class ProcessingJob {
  const ProcessingJob({
    required this.id,
    required this.equipmentCardId,
    required this.inputCardId,
    required this.action,
    required this.elapsedSeconds,
    required this.totalDurationSeconds,
    required this.status,
  });

  final String id;
  final String equipmentCardId;
  final String inputCardId;
  final ProcessingAction action;
  final double elapsedSeconds;
  final double totalDurationSeconds;
  final ProcessingStatus status;

  double get progress {
    return (elapsedSeconds / totalDurationSeconds).clamp(0.0, 1.0).toDouble();
  }

  double get remainingSeconds => (totalDurationSeconds - elapsedSeconds)
      .clamp(0.0, totalDurationSeconds)
      .toDouble();

  ProcessingJob copyWith({double? elapsedSeconds, ProcessingStatus? status}) {
    return ProcessingJob(
      id: id,
      equipmentCardId: equipmentCardId,
      inputCardId: inputCardId,
      action: action,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalDurationSeconds: totalDurationSeconds,
      status: status ?? this.status,
    );
  }
}
