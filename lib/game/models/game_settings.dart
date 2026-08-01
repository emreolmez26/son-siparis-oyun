class GameSettings {
  GameSettings({
    this.soundEffectsEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
  });

  bool soundEffectsEnabled;
  bool musicEnabled;
  bool hapticsEnabled;

  void reset() {
    soundEffectsEnabled = true;
    musicEnabled = true;
    hapticsEnabled = true;
  }
}
