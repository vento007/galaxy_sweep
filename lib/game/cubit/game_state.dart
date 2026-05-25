import 'package:flutter/foundation.dart';
import 'package:galaxy_sweep/models/board_model.dart';
import 'package:galaxy_sweep/models/market_signal.dart';

const _keepMarketSignal = Object();

@immutable
class GameState {
  const GameState({
    required this.phase,
    required this.board,
    required this.drag,
    this.marketSignal,
  });

  factory GameState.idle({required int boardSize}) {
    return GameState(
      phase: const GameIdle(),
      board: BoardModel(boardSize: boardSize),
      drag: const DragIdle(),
      marketSignal: null,
    );
  }

  final GamePhase phase;
  final BoardModel board;
  final DragState drag;
  final MarketSignal? marketSignal;

  bool get isIdle => phase is GameIdle;
  bool get isPlaying => phase is GamePlaying;
  bool get isGameOver => phase is GameOver;
  int get score => board.discoveredGalaxies;

  GameState copyWith({
    GamePhase? phase,
    BoardModel? board,
    DragState? drag,
    Object? marketSignal = _keepMarketSignal,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      board: board ?? this.board,
      drag: drag ?? this.drag,
      marketSignal: identical(marketSignal, _keepMarketSignal)
          ? this.marketSignal
          : marketSignal as MarketSignal?,
    );
  }
}

sealed class GamePhase {
  const GamePhase();
}

class GameIdle extends GamePhase {
  const GameIdle();
}

class GamePlaying extends GamePhase {
  const GamePlaying();
}

class GameOver extends GamePhase {
  const GameOver({required this.startedAt});

  final double startedAt;
}

sealed class DragState {
  const DragState();
}

class DragIdle extends DragState {
  const DragIdle();
}

class DragActive extends DragState {
  const DragActive({required this.pieceId});

  final int pieceId;
}

class DragSettling extends DragState {
  const DragSettling({required this.pieceId});

  final int pieceId;
}
