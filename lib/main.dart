import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/son_siparis_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const SonSiparisApp());
}

class SonSiparisApp extends StatelessWidget {
  const SonSiparisApp({super.key, this.game});

  /// An optional game instance keeps the production shell testable without
  /// changing its normal one-game-per-app behavior.
  final SonSiparisGame? game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1B120E),
        body: SafeArea(child: GameWidget(game: game ?? SonSiparisGame())),
      ),
    );
  }
}
