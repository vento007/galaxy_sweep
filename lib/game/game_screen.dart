import 'package:flutter/material.dart';
import 'package:galaxy_sweep/game/cubit/game_cubit.dart';
import 'package:galaxy_sweep/game/game_runtime.dart';
import 'package:galaxy_sweep/services/market_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameCubit _gameCubit;

  @override
  void initState() {
    super.initState();
    _gameCubit = GameCubit(market: BinanceMarketFeed(enableLogging: false));
  }

  @override
  void dispose() {
    _gameCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameRuntime(gameCubit: _gameCubit);
  }
}
