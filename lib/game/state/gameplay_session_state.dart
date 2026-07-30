class GameplaySessionState {
  GameplaySessionState({
    this.coins = initialCoins,
    this.combo = 0,
    this.completedOrders = 0,
  });

  static const initialCoins = 120;
  static const serviceRewardCoins = 10;

  int coins;
  int combo;
  int completedOrders;

  void recordSuccessfulService() {
    coins += serviceRewardCoins;
    combo += 1;
    completedOrders += 1;
  }
}
