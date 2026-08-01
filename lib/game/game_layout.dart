import 'package:flutter/material.dart';

abstract final class GameLayout {
  static const double designWidth = 1280;
  static const double designHeight = 720;

  static const double horizontalPadding = 24;
  static const double hudTop = 18;
  static const double hudHeight = 54;
  static const double customerTop = 92;
  static const double customerHeight = 108;
  static const double tableTop = 218;
  static const double tableHeight = 312;
  static const double serviceTop = 546;
  static const double serviceWidth = 760;
  static const double serviceHeight = 44;
  static const double handTop = 600;
  static const double handHeight = 96;

  static const double cardWidth = 104;
  static const double cardHeight = 78;
  static const double handCardTop = handTop + ((handHeight - cardHeight) / 2);
  static const Map<String, Offset> initialHandCardPositions = {
    'bread_01': Offset(304, handCardTop),
    'patty_01': Offset(418, handCardTop),
    'cheese_01': Offset(532, handCardTop),
    'tomato_01': Offset(646, handCardTop),
    'hot_sauce_01': Offset(760, handCardTop),
    'potato_01': Offset(874, handCardTop),
  };
  static const Map<String, Offset> initialEquipmentTablePositions = {
    'pan_01': Offset(740, 240),
    'knife_01': Offset(740, 352),
    'fryer_01': Offset(1000, 296),
  };
  static const double kitchenGridSpacing = 32;
  static const double kitchenGridPadding = 16;
  static const double stackHorizontalOffset = 6;
  static const double stackVerticalOffset = 18;
  static const Offset stackLevelOffset = Offset(
    stackHorizontalOffset,
    stackVerticalOffset,
  );
  static const Size cardSize = Size(cardWidth, cardHeight);
  static const double processingDurationSeconds = 3;
  static const double knifeProcessingDurationSeconds = 1.5;
  static const double fryerProcessingDurationSeconds = 2.5;
  static const double recipeFeedbackDurationSeconds = .7;
  static const double resultCardPopDurationSeconds = .65;
  static const double cardPickupScale = 1.05;
  static const double validDropFeedbackSeconds = .14;
  static const double invalidDropReturnSeconds = .20;
  static const double stackLandingFeedbackSeconds = .18;
  static const double lastSecondSlowdownRealSeconds = .32;
  static const double lastSecondTimeScale = .42;
  static const double comboFeedbackDurationSeconds = .85;
  static const double shiftDurationSeconds = 90;
  static const double customerPatienceDurationSeconds = 22;
  static const double serviceFeedbackDurationSeconds = .8;
  static const double failureFeedbackDurationSeconds = .8;
  static const int initialWalletCoins = 120;
  static const int successfulServiceRewardCoins = 10;
  static const Offset processingPattyOffset = Offset(8, -14);
  static const double processingOutputHorizontalOffset =
      cardWidth + kitchenGridSpacing;

  static const Rect kitchenTableBounds = Rect.fromLTWH(
    horizontalPadding,
    tableTop,
    designWidth - (horizontalPadding * 2),
    tableHeight,
  );

  static const Rect serviceCounterBounds = Rect.fromLTWH(
    (designWidth - serviceWidth) / 2,
    serviceTop,
    serviceWidth,
    serviceHeight,
  );

  static const Color backgroundColor = Color(0xFF1B120E);
  static const Color hudColor = Color(0xFF2B201A);
  static const Color panelColor = Color(0xFF33251E);
  static const Color panelStrokeColor = Color(0xFF5D4638);
  static const Color tableColor = Color(0xFF2A1B14);
  static const Color tableInnerColor = Color(0xFF211510);
  static const Color serviceColor = Color(0xFF4A3425);
  static const Color handColor = Color(0xFF261A15);
  static const Color accentColor = Color(0xFFF6B60B);
  static const Color successColor = Color(0xFF7EBB58);
  static const Color mutedTextColor = Color(0xFFCAB8AA);
  static const Color primaryTextColor = Color(0xFFFFF8F1);

  static bool isFullyInsideKitchenTable(Rect cardBounds) {
    return cardBounds.left >= kitchenTableBounds.left &&
        cardBounds.top >= kitchenTableBounds.top &&
        cardBounds.right <= kitchenTableBounds.right &&
        cardBounds.bottom <= kitchenTableBounds.bottom;
  }
}
