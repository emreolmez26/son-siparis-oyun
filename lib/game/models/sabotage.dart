import 'dart:ui';

import 'card_definition.dart';

enum SabotageType { powerSurge, equipmentJam, greasyTable, fakeOrder }

enum SabotagePhase { warning, active }

enum SabotageResolutionReason {
  counteredDuringWarning,
  counteredWhileActive,
  expired,
  triggeredPlayerPenalty,
  clearedAtShiftEnd,
}

enum CountermeasureType { spareFuse, toolbox, cleaningCloth, orderVerifier }

class ScheduledSabotage {
  const ScheduledSabotage({
    required this.id,
    required this.type,
    required this.scheduledAtSeconds,
    this.targetEquipmentId,
    this.greasyRegion,
    this.slideDirection = Offset.zero,
    this.fakeOrderType,
  });

  final String id;
  final SabotageType type;
  final double scheduledAtSeconds;
  final String? targetEquipmentId;
  final Rect? greasyRegion;
  final Offset slideDirection;
  final CardType? fakeOrderType;

  @override
  bool operator ==(Object other) =>
      other is ScheduledSabotage &&
      id == other.id &&
      type == other.type &&
      scheduledAtSeconds == other.scheduledAtSeconds &&
      targetEquipmentId == other.targetEquipmentId &&
      greasyRegion == other.greasyRegion &&
      slideDirection == other.slideDirection &&
      fakeOrderType == other.fakeOrderType;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    scheduledAtSeconds,
    targetEquipmentId,
    greasyRegion,
    slideDirection,
    fakeOrderType,
  );
}

class ActiveSabotage {
  const ActiveSabotage({
    required this.event,
    required this.phase,
    required this.remainingSeconds,
    required this.countermeasureId,
  });

  final ScheduledSabotage event;
  final SabotagePhase phase;
  final double remainingSeconds;
  final String countermeasureId;

  ActiveSabotage copyWith({SabotagePhase? phase, double? remainingSeconds}) =>
      ActiveSabotage(
        event: event,
        phase: phase ?? this.phase,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        countermeasureId: countermeasureId,
      );
}

class SabotageResolution {
  const SabotageResolution({required this.event, required this.reason});

  final ScheduledSabotage event;
  final SabotageResolutionReason reason;
}

extension SabotageTypePresentation on SabotageType {
  String get displayName => switch (this) {
    SabotageType.powerSurge => 'Elektrik Dalgalanması',
    SabotageType.equipmentJam => 'Ekipman Sıkışması',
    SabotageType.greasyTable => 'Yağlı Tezgâh',
    SabotageType.fakeOrder => 'Sahte Sipariş',
  };

  String get warningText => switch (this) {
    SabotageType.powerSurge => 'ELEKTRİK DALGALANIYOR!',
    SabotageType.equipmentJam => 'EKİPMAN SIKIŞMAK ÜZERE!',
    SabotageType.greasyTable => 'TEZGÂHA YAĞ DÖKÜLDÜ!',
    SabotageType.fakeOrder => 'ŞÜPHELİ BİR SİPARİŞ GELDİ!',
  };

  CountermeasureType get countermeasure => switch (this) {
    SabotageType.powerSurge => CountermeasureType.spareFuse,
    SabotageType.equipmentJam => CountermeasureType.toolbox,
    SabotageType.greasyTable => CountermeasureType.cleaningCloth,
    SabotageType.fakeOrder => CountermeasureType.orderVerifier,
  };
}

extension CountermeasurePresentation on CountermeasureType {
  String get displayName => switch (this) {
    CountermeasureType.spareFuse => 'Yedek Sigorta',
    CountermeasureType.toolbox => 'Alet Çantası',
    CountermeasureType.cleaningCloth => 'Temizlik Bezi',
    CountermeasureType.orderVerifier => 'Sipariş Doğrulayıcı',
  };
}
