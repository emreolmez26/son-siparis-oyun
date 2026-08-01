import 'package:flutter/services.dart';
import '../models/game_settings.dart';

enum HapticEvent {
  cardSnap,
  processingComplete,
  recipeComplete,
  service,
  lastSecond,
  sabotageWarning,
  sabotageCountered,
  sabotageHit,
}

abstract interface class HapticService {
  void trigger(HapticEvent event);
}

class PlatformHapticService implements HapticService {
  PlatformHapticService(
    this.settings, {
    void Function(HapticEvent event)? performer,
  }) : _performer = performer ?? _performPlatformHaptic;

  final GameSettings settings;
  final void Function(HapticEvent event) _performer;

  @override
  void trigger(HapticEvent event) {
    if (!settings.hapticsEnabled) return;
    _performer(event);
  }

  static void _performPlatformHaptic(HapticEvent event) {
    switch (event) {
      case HapticEvent.cardSnap:
      case HapticEvent.processingComplete:
      case HapticEvent.sabotageWarning:
        HapticFeedback.lightImpact();
        return;
      case HapticEvent.recipeComplete:
      case HapticEvent.service:
      case HapticEvent.sabotageCountered:
      case HapticEvent.sabotageHit:
        HapticFeedback.mediumImpact();
        return;
      case HapticEvent.lastSecond:
        HapticFeedback.heavyImpact();
        return;
    }
  }
}
