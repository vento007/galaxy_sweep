import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:galaxy_sweep/game/cubit/game_state.dart';
import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/models/board_model.dart';
import 'package:galaxy_sweep/game/board/board_rules.dart';
import 'package:galaxy_sweep/game/board/board_setup.dart';
import 'package:galaxy_sweep/game/board/drag_target_resolver.dart';
import 'package:galaxy_sweep/game_config.dart';
import 'package:galaxy_sweep/models/market_signal.dart';
import 'package:galaxy_sweep/models/piece_visual_state.dart';
import 'package:galaxy_sweep/render/galaxy_explosion.dart';
import 'package:galaxy_sweep/services/market_service.dart';

class GameCubit extends Cubit<GameState> {
  static const int marketTriggerDivisor = 5;
  GameCubit({
    BoardSetup boardSetup = const BoardSetup(),
    BoardRules boardRules = const BoardRules(),
    DragTargetResolver dragTargetResolver = const DragTargetResolver(),
    this.market,
    GameState? initialState,
  }) : _boardSetup = boardSetup,
       _boardRules = boardRules,
       _dragTargetResolver = dragTargetResolver,
       super(initialState ?? GameState.idle(boardSize: boardSize));

  static const double pieceMoveDuration = 0.26;
  static const double pieceSettleTailDuration = 0.14;

  final BoardSetup _boardSetup;
  final BoardRules _boardRules;
  final DragTargetResolver _dragTargetResolver;
  final MarketService? market;
  final Random _random = Random();
  StreamSubscription<MarketTick>? _marketTicks;
  double _gameStartedAt = 0;
  double _lastTickAt = 0;
  int _explosionsTriggered = 0;
  int? _lastWholePriceSeen;

  void startGame(double now) {
    _stopMarket();
    final board = _boardSetup.populate(
      BoardModel(boardSize: state.board.boardSize),
    );
    _gameStartedAt = now;
    _lastTickAt = now;
    _explosionsTriggered = 0;
    _lastWholePriceSeen = null;

    emit(
      GameState(
        phase: const GamePlaying(),
        board: board,
        drag: const DragIdle(),
        marketSignal: null,
      ),
    );
    _startMarket();
  }

  void dragStarted(Offset position, BoardLayout layout) {
    if (!state.isPlaying) {
      return;
    }

    final index = layout.indexAtPosition(position);
    if (index == null) {
      return;
    }

    final board = state.board;
    final piece = board.pieceAtCell(index);
    if (piece == null) {
      return;
    }

    final cellCenter = layout.cellCenterForIndex(index);
    final grabOffset = position - cellCenter;
    final nextBoard = _setPieceVisualState(
      board,
      piece.id,
      PieceDragging(
        pointerPosition: position,
        grabOffset: grabOffset,
        hoveredIndex: index,
      ),
    );

    emit(
      state.copyWith(
        board: nextBoard,
        drag: DragActive(pieceId: piece.id),
      ),
    );
  }

  void dragUpdated(Offset position, BoardLayout layout) {
    if (!state.isPlaying) {
      return;
    }

    final board = state.board;
    final piece = board.draggingPiece;
    if (piece == null) {
      return;
    }

    final visualState = piece.visualState;
    if (visualState is! PieceDragging) {
      return;
    }

    final pieceCenter = position - visualState.grabOffset;
    final actualIndex = layout.indexAtPosition(pieceCenter);
    final hoveredIndex = actualIndex ?? visualState.hoveredIndex;

    final nextBoard = _setPieceVisualState(
      board,
      piece.id,
      PieceDragging(
        pointerPosition: position,
        grabOffset: visualState.grabOffset,
        hoveredIndex: hoveredIndex,
      ),
    );

    emit(
      state.copyWith(
        board: nextBoard,
        drag: DragActive(pieceId: piece.id),
      ),
    );
  }

  void dragEnded(double now, BoardLayout layout) {
    if (!state.isPlaying) {
      return;
    }

    final board = state.board;
    final piece = board.draggingPiece;
    if (piece == null) {
      emit(state.copyWith(drag: const DragIdle()));
      return;
    }

    final visualState = piece.visualState;
    if (visualState is! PieceDragging) {
      emit(state.copyWith(drag: const DragIdle()));
      return;
    }

    final fromIndex = piece.cellIndex;
    final displayDistance = board.distanceToNearestGalaxy(fromIndex);
    final releaseCenter = visualState.pointerPosition - visualState.grabOffset;
    final target = _dragTargetResolver.resolve(
      sourceIndex: fromIndex,
      pieceCenter: releaseCenter,
      layout: layout,
    );
    final fromCenter = target.source == 'outside'
        ? layout.clampToCellCenterArea(releaseCenter)
        : releaseCenter;
    final result = _boardRules.movePiece(
      board,
      pieceId: piece.id,
      toIndex: target.index,
      now: now,
    );
    var nextBoard = result.board;
    final toIndex = result.moved ? target.index : fromIndex;

    nextBoard = _setPieceVisualState(
      nextBoard,
      piece.id,
      PieceMoving(
        fromIndex: fromIndex,
        fromCenter: fromCenter,
        toIndex: toIndex,
        displayDistance: displayDistance,
        startedAt: now,
        duration: pieceMoveDuration,
      ),
    );

    emit(
      state.copyWith(
        board: nextBoard,
        drag: DragSettling(pieceId: piece.id),
      ),
    );
  }

  void tick(
    double now, {
    required double explosionSpeed,
    required double foundSpeed,
  }) {
    _lastTickAt = now;
    var board = state.board;
    var boardChanged = false;
    var nextMarketSignal = state.marketSignal;

    if (state.isPlaying) {
      final elapsed = now - _gameStartedAt;
      final shouldHaveTriggered = elapsed ~/ 10;

      while (_explosionsTriggered < shouldHaveTriggered &&
          board.hasHiddenGalaxies) {
        final explosionAt = _gameStartedAt + (_explosionsTriggered + 1) * 10.0;
        final nextBoard = _boardRules.explodeRandomHiddenGalaxy(
          board,
          explosionAt,
          _random,
        );
        if (!identical(nextBoard, board)) {
          board = nextBoard;
          boardChanged = true;
        }
        _explosionsTriggered++;
      }
    }

    if (nextMarketSignal != null && !nextMarketSignal.isActiveAt(now)) {
      nextMarketSignal = null;
    }

    for (final piece in board.pieces) {
      final visualState = piece.visualState;

      if (visualState is PieceMoving &&
          now - visualState.startedAt >=
              visualState.duration + pieceSettleTailDuration) {
        board = _setPieceVisualState(board, piece.id, const PieceIdle());
        boardChanged = true;
      }
    }

    final remainingBlasts = board.blasts
        .where(
          (blast) => !blastFinished(
            blast,
            now,
            explosionSpeed: explosionSpeed,
            foundSpeed: foundSpeed,
          ),
        )
        .toList(growable: false);
    if (remainingBlasts.length != board.blasts.length) {
      board = board.copyWith(blasts: remainingBlasts);
      boardChanged = true;
    }

    final hasMovingPieces = _hasMovingPieces(board);
    final nextDrag = hasMovingPieces ? state.drag : const DragIdle();
    final nextPhase =
        state.isPlaying &&
            !board.hasHiddenGalaxies &&
            !hasMovingPieces &&
            board.blasts.isEmpty
        ? GameOver(startedAt: now)
        : state.phase;

    if (nextPhase is GameOver && state.phase is! GameOver) {
      _stopMarket();
    }

    if (!boardChanged &&
        nextMarketSignal == state.marketSignal &&
        _sameDragState(nextDrag, state.drag) &&
        nextPhase.runtimeType == state.phase.runtimeType) {
      return;
    }

    emit(
      state.copyWith(
        board: board,
        drag: nextDrag,
        phase: nextPhase,
        marketSignal: nextMarketSignal,
      ),
    );
  }

  void triggerMarketSpawnPreview() {
    if (!state.isPlaying) {
      return;
    }

    _triggerMarketSpawn(
      wholePrice: _lastWholePriceSeen ?? 77500,
      message: 'Galaxy Signal Preview',
    );
  }

  void triggerMarketTickPreview() {
    if (!state.isPlaying) {
      return;
    }

    final base = _lastWholePriceSeen ?? 77399;
    final wholePrice = base % 5 == 0 ? base + 5 : base + (5 - base % 5);

    _handleMarketTick(
      MarketTick(
        price: wholePrice.toDouble(),
        wholePrice: wholePrice,
        isDivisibleByFive: true,
      ),
    );
  }

  BoardModel _setPieceVisualState(
    BoardModel board,
    int pieceId,
    PieceVisualState visualState,
  ) {
    final index = board.pieces.indexWhere((piece) => piece.id == pieceId);
    if (index == -1) {
      return board;
    }

    final pieces = List.of(board.pieces);
    pieces[index] = pieces[index].copyWith(visualState: visualState);

    return board.copyWith(pieces: pieces);
  }

  bool _hasMovingPieces(BoardModel board) {
    for (final piece in board.pieces) {
      if (piece.visualState is PieceMoving) {
        return true;
      }
    }

    return false;
  }

  bool _sameDragState(DragState a, DragState b) {
    if (a.runtimeType != b.runtimeType) {
      return false;
    }

    if (a is DragActive && b is DragActive) {
      return a.pieceId == b.pieceId;
    }

    if (a is DragSettling && b is DragSettling) {
      return a.pieceId == b.pieceId;
    }

    return true;
  }

  void _startMarket() {
    final marketService = market;
    if (marketService == null) {
      return;
    }

    _marketTicks ??= marketService.ticks.listen(_handleMarketTick);
    unawaited(marketService.start());
  }

  void _stopMarket() {
    final ticks = _marketTicks;
    if (ticks == null) {
      return;
    }
    _marketTicks = null;
    unawaited(ticks.cancel());

    final marketService = market;
    if (marketService != null) {
      unawaited(marketService.stop());
    }
  }

  void _handleMarketTick(MarketTick tick) {
    final previousWhole = _lastWholePriceSeen;
    _lastWholePriceSeen = tick.wholePrice;
    final matchesTrigger = tick.wholePrice % marketTriggerDivisor == 0;

    debugPrint('price${tick.wholePrice}, can divide by 5: $matchesTrigger');

    if (!state.isPlaying || previousWhole == tick.wholePrice) {
      return;
    }

    if (previousWhole == null || !matchesTrigger) {
      return;
    }

    _triggerMarketSpawn(wholePrice: tick.wholePrice);
  }

  void _triggerMarketSpawn({
    required int wholePrice,
    String message = 'Hidden Galaxy Detected',
  }) {
    final board = _boardRules.addRandomHiddenGalaxy(
      state.board,
      random: _random,
      maxHiddenGalaxies: galaxiesCount,
    );

    if (identical(board, state.board)) {
      return;
    }

    emit(
      state.copyWith(
        board: board,
        marketSignal: MarketSignal(
          startedAt: _lastTickAt,
          wholePrice: wholePrice,
          message: message,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    _stopMarket();
    final marketService = market;
    if (marketService != null) {
      await marketService.dispose();
    }
    return super.close();
  }
}
