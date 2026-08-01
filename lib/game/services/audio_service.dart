import 'package:flutter/services.dart';
import '../models/game_settings.dart';

enum SoundEventId {
  cardPickUp,
  cardDrop,
  invalidDrop,
  stackCreate,
  equipmentStart,
  equipmentComplete,
  recipeComplete,
  correctService,
  wrongService,
  comboMilestone,
  orderFailed,
  buttonTap,
  shiftComplete,
}

abstract interface class AudioService {
  void play(SoundEventId event);
}

class PlatformAudioService implements AudioService {
  PlatformAudioService(this.settings, {void Function()? player})
    : _player = player ?? _playSystemClick;

  final GameSettings settings;
  final void Function() _player;
  final Map<SoundEventId, DateTime> _lastPlayed = {};

  @override
  void play(SoundEventId event) {
    if (!settings.soundEffectsEnabled) return;
    final now = DateTime.now();
    final previous = _lastPlayed[event];
    if (previous != null && now.difference(previous).inMilliseconds < 70) {
      return;
    }
    _lastPlayed[event] = now;
    _player();
  }

  static void _playSystemClick() {
    SystemSound.play(SystemSoundType.click);
  }
}
