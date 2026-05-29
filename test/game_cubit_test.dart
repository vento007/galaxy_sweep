import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_sweep/game/cubit/game_cubit.dart';
import 'package:galaxy_sweep/game/cubit/game_state.dart';
import 'package:galaxy_sweep/game/board/board_layout.dart';
import 'package:galaxy_sweep/models/board_model.dart';
import 'package:galaxy_sweep/game/board/board_setup.dart';
import 'package:galaxy_sweep/game_config.dart';
import 'package:galaxy_sweep/models/galaxy_model.dart';
import 'package:galaxy_sweep/models/market_signal_trigger_mode.dart';
import 'package:galaxy_sweep/models/piece_model.dart';
import 'package:galaxy_sweep/models/piece_visual_state.dart';
import 'package:galaxy_sweep/render/galaxy_explosion.dart';
import 'package:galaxy_sweep/services/market_service.dart';

class FakeMarketService implements MarketService {
  int startCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  final controller = StreamController<MarketTick>.broadcast();

  @override
  Stream<MarketTick> get ticks => controller.stream;

  @override
  Future<void> start() async {
    startCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await controller.close();
  }
}

class FixedBoardSetup extends BoardSetup {
  const FixedBoardSetup(this.board);

  final BoardModel board;

  @override
  BoardModel populate(BoardModel model) => board;
}

int _divisiblePriceAtOrAfter(int price, int divisor) {
  var next = price;
  while (next % divisor != 0) {
    next++;
  }

  return next;
}

int _nonDivisiblePriceAtOrAfter(int price, int divisor) {
  var next = price;
  while (next % divisor == 0) {
    next++;
  }

  return next;
}

void main() {
  test('startGame populates board and enters playing', () {
    final cubit = GameCubit();

    cubit.startGame(0);

    expect(cubit.state.isPlaying, isTrue);
    expect(cubit.state.board.pieces, hasLength(piecesCount));
    expect(cubit.state.board.galaxies, hasLength(galaxiesCount));
    expect(cubit.state.drag, isA<DragIdle>());
    expect(
      cubit.state.marketSignalTriggerMode,
      MarketSignalTriggerMode.divisibleBy5,
    );
  });

  test(
    'dragging to an empty cell moves the piece and settles back to idle',
    () {
      final board = BoardModel(
        boardSize: boardSize,
        pieces: const [BoardPiece(id: 1, cellIndex: 44)],
      );
      final cubit = GameCubit(
        initialState: GameState(
          phase: const GamePlaying(),
          board: board,
          drag: const DragIdle(),
        ),
      );
      final layout = createBoardLayout(
        const Size(600, 600),
        boardSize: boardSize,
        gap: 4,
      );

      cubit.dragStarted(layout.cellCenterForIndex(44), layout);
      cubit.dragUpdated(layout.cellCenterForIndex(45), layout);
      cubit.dragEnded(1.0, layout);

      expect(cubit.state.drag, isA<DragSettling>());
      expect(cubit.state.board.pieces.single.cellIndex, 45);

      cubit.tick(
        1.0 +
            GameCubit.pieceMoveDuration +
            GameCubit.pieceSettleTailDuration +
            0.01,
        explosionSpeed: 1.0,
        foundSpeed: 1.0,
      );

      expect(cubit.state.drag, isA<DragIdle>());
      expect(cubit.state.board.pieces.single.visualState, isA<PieceIdle>());
    },
  );

  test('dragging to an occupied cell keeps the original piece position', () {
    final board = BoardModel(
      boardSize: boardSize,
      pieces: const [
        BoardPiece(id: 1, cellIndex: 44),
        BoardPiece(id: 2, cellIndex: 45),
      ],
    );
    final cubit = GameCubit(
      initialState: GameState(
        phase: const GamePlaying(),
        board: board,
        drag: const DragIdle(),
      ),
    );
    final layout = createBoardLayout(
      const Size(600, 600),
      boardSize: boardSize,
      gap: 4,
    );

    cubit.dragStarted(layout.cellCenterForIndex(44), layout);
    cubit.dragUpdated(layout.cellCenterForIndex(45), layout);
    cubit.dragEnded(1.0, layout);

    expect(cubit.state.board.pieces.first.cellIndex, 44);

    cubit.tick(
      1.0 +
          GameCubit.pieceMoveDuration +
          GameCubit.pieceSettleTailDuration +
          0.01,
      explosionSpeed: 1.0,
      foundSpeed: 1.0,
    );

    expect(cubit.state.drag, isA<DragIdle>());
    expect(cubit.state.board.pieces.first.visualState, isA<PieceIdle>());
  });

  test('discovering the last hidden galaxy waits for the reveal to finish', () {
    final board = BoardModel(
      boardSize: boardSize,
      pieces: const [BoardPiece(id: 1, cellIndex: 44)],
      galaxies: const [BoardGalaxy(id: 1, cellIndex: 45)],
    );
    final cubit = GameCubit(
      initialState: GameState(
        phase: const GamePlaying(),
        board: board,
        drag: const DragIdle(),
      ),
    );
    final layout = createBoardLayout(
      const Size(600, 600),
      boardSize: boardSize,
      gap: 4,
    );

    cubit.dragStarted(layout.cellCenterForIndex(44), layout);
    cubit.dragUpdated(layout.cellCenterForIndex(45), layout);
    cubit.dragEnded(1.0, layout);

    expect(cubit.state.score, 1);
    expect(cubit.state.isPlaying, isTrue);
    expect(cubit.state.board.hiddenGalaxyCount, 0);

    cubit.tick(
      1.0 +
          GameCubit.pieceMoveDuration +
          GameCubit.pieceSettleTailDuration +
          0.01,
      explosionSpeed: 1.0,
      foundSpeed: 1.0,
    );

    expect(cubit.state.isPlaying, isTrue);

    cubit.tick(
      1.0 + GameCubit.pieceMoveDuration + kGalaxyFoundDuration + 0.01,
      explosionSpeed: 1.0,
      foundSpeed: 1.0,
    );

    expect(cubit.state.isGameOver, isTrue);
  });

  test('10 second timer explosion adds a timer blast', () {
    final board = BoardModel(
      boardSize: boardSize,
      galaxies: const [BoardGalaxy(id: 1, cellIndex: 45)],
    );
    final cubit = GameCubit(
      initialState: GameState(
        phase: const GamePlaying(),
        board: board,
        drag: const DragIdle(),
      ),
    );

    cubit.tick(10.01, explosionSpeed: 1.0, foundSpeed: 1.0);

    expect(cubit.state.board.explodedGalaxies, 1);
    expect(cubit.state.board.blasts, isNotEmpty);
  });

  test('market service starts on play and stops on game over', () async {
    final market = FakeMarketService();
    final cubit = GameCubit(
      market: market,
      boardSetup: FixedBoardSetup(
        BoardModel(
          boardSize: boardSize,
          galaxies: const [BoardGalaxy(id: 1, cellIndex: 12)],
        ),
      ),
    );

    cubit.startGame(0);
    expect(market.startCalls, 1);

    cubit.tick(10.0, explosionSpeed: 1.0, foundSpeed: 1.0);
    cubit.tick(50.0, explosionSpeed: 1.0, foundSpeed: 1.0);

    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isGameOver, isTrue);
    expect(market.stopCalls, 1);

    await cubit.close();
    expect(market.disposeCalls, 1);
  });

  test('first observed divisible market tick spawns a hidden galaxy', () async {
    final market = FakeMarketService();
    final cubit = GameCubit(
      market: market,
      boardSetup: FixedBoardSetup(
        BoardModel(
          boardSize: boardSize,
          galaxies: const [BoardGalaxy(id: 1, cellIndex: 0)],
        ),
      ),
    );

    cubit.startGame(10);

    final divisor = cubit.state.marketSignalTriggerMode.divisor!;
    final firstPrice = _divisiblePriceAtOrAfter(77400, divisor);

    market.controller.add(
      MarketTick(
        price: firstPrice.toDouble(),
        wholePrice: firstPrice,
        isDivisibleByFive: firstPrice % 5 == 0,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.marketSignal, isNotNull);
    expect(cubit.state.board.hiddenGalaxyCount, 2);

    await cubit.close();
  });

  test(
    'market signal triggers once when entering a divisible bucket',
    () async {
      final market = FakeMarketService();
      final cubit = GameCubit(
        market: market,
        boardSetup: FixedBoardSetup(
          BoardModel(
            boardSize: boardSize,
            galaxies: const [BoardGalaxy(id: 1, cellIndex: 0)],
          ),
        ),
      );

      cubit.startGame(10);

      final divisor = cubit.state.marketSignalTriggerMode.divisor!;
      final nonDivisiblePrice = _nonDivisiblePriceAtOrAfter(77398, divisor);
      final divisiblePrice = _divisiblePriceAtOrAfter(
        nonDivisiblePrice + 1,
        divisor,
      );

      market.controller.add(
        MarketTick(
          price: nonDivisiblePrice + 0.12,
          wholePrice: nonDivisiblePrice,
          isDivisibleByFive: nonDivisiblePrice % 5 == 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.marketSignal, isNull);

      market.controller.add(
        MarketTick(
          price: divisiblePrice.toDouble(),
          wholePrice: divisiblePrice,
          isDivisibleByFive: divisiblePrice % 5 == 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.marketSignal, isNotNull);
      expect(cubit.state.marketSignal!.wholePrice, divisiblePrice);
      expect(cubit.state.board.hiddenGalaxyCount, 2);
      final addedGalaxy = cubit.state.board.galaxies.firstWhere(
        (galaxy) => galaxy.id != 1,
      );
      final signalRegion = cubit.state.marketSignal!.region;
      expect(signalRegion, isNotNull);
      expect(
        signalRegion!.containsCellIndex(addedGalaxy.cellIndex, boardSize),
        isTrue,
      );

      final firstStartedAt = cubit.state.marketSignal!.startedAt;

      market.controller.add(
        MarketTick(
          price: divisiblePrice + 0.25,
          wholePrice: divisiblePrice,
          isDivisibleByFive: divisiblePrice % 5 == 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.marketSignal!.startedAt, firstStartedAt);
      expect(cubit.state.board.hiddenGalaxyCount, 2);

      await cubit.close();
    },
  );

  test('market signal can use divisible by 2 mode', () async {
    final market = FakeMarketService();
    final cubit = GameCubit(
      market: market,
      boardSetup: FixedBoardSetup(
        BoardModel(
          boardSize: boardSize,
          galaxies: const [BoardGalaxy(id: 1, cellIndex: 0)],
        ),
      ),
    );

    cubit.setMarketSignalTriggerMode(MarketSignalTriggerMode.divisibleBy2);
    cubit.startGame(10);

    market.controller.add(
      const MarketTick(
        price: 73702,
        wholePrice: 73702,
        isDivisibleByFive: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.marketSignal, isNotNull);
    expect(cubit.state.board.hiddenGalaxyCount, 2);

    await cubit.close();
  });

  test(
    'changing market signal mode can trigger at the same whole price',
    () async {
      final market = FakeMarketService();
      final cubit = GameCubit(
        market: market,
        boardSetup: FixedBoardSetup(
          BoardModel(
            boardSize: boardSize,
            galaxies: const [BoardGalaxy(id: 1, cellIndex: 0)],
          ),
        ),
      );

      cubit.startGame(10);
      market.controller.add(
        const MarketTick(
          price: 73662,
          wholePrice: 73662,
          isDivisibleByFive: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.marketSignal, isNull);

      cubit.setMarketSignalTriggerMode(MarketSignalTriggerMode.divisibleBy2);
      market.controller.add(
        const MarketTick(
          price: 73662,
          wholePrice: 73662,
          isDivisibleByFive: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.marketSignal, isNotNull);
      expect(cubit.state.board.hiddenGalaxyCount, 2);

      await cubit.close();
    },
  );

  test('market signal can use 15 second timed mode', () {
    final cubit = GameCubit(
      boardSetup: FixedBoardSetup(
        BoardModel(
          boardSize: boardSize,
          galaxies: const [
            BoardGalaxy(id: 1, cellIndex: 0),
            BoardGalaxy(id: 2, cellIndex: 1),
          ],
        ),
      ),
    );

    cubit.setMarketSignalTriggerMode(MarketSignalTriggerMode.every15Seconds);
    cubit.startGame(0);
    cubit.tick(14.9, explosionSpeed: 1.0, foundSpeed: 1.0);
    expect(cubit.state.marketSignal, isNull);

    cubit.tick(15.0, explosionSpeed: 1.0, foundSpeed: 1.0);

    expect(cubit.state.marketSignal, isNotNull);
    expect(cubit.state.board.hiddenGalaxyCount, 2);
  });

  test(
    'market tick does not add a hidden galaxy at the max hidden count',
    () async {
      final market = FakeMarketService();
      final cubit = GameCubit(
        market: market,
        boardSetup: FixedBoardSetup(
          BoardModel(
            boardSize: boardSize,
            galaxies: List.generate(
              galaxiesCount,
              (index) => BoardGalaxy(id: index + 1, cellIndex: index),
            ),
          ),
        ),
      );

      cubit.startGame(5);
      market.controller.add(
        const MarketTick(
          price: 77500,
          wholePrice: 77500,
          isDivisibleByFive: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.marketSignal, isNull);
      expect(cubit.state.board.hiddenGalaxyCount, galaxiesCount);

      await cubit.close();
    },
  );

  test(
    'market tick does not add a hidden galaxy when no open cells remain',
    () async {
      final market = FakeMarketService();
      final cubit = GameCubit(
        market: market,
        boardSetup: FixedBoardSetup(
          BoardModel(
            boardSize: boardSize,
            galaxies: const [BoardGalaxy(id: 1, cellIndex: 0)],
            pieces: List.generate(
              boardSize * boardSize - 1,
              (index) => BoardPiece(id: index + 1, cellIndex: index + 1),
            ),
          ),
        ),
      );

      cubit.startGame(5);
      market.controller.add(
        const MarketTick(
          price: 77500,
          wholePrice: 77500,
          isDivisibleByFive: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.marketSignal, isNull);
      expect(cubit.state.board.hiddenGalaxyCount, 1);

      await cubit.close();
    },
  );

  test('market tick adds one hidden galaxy while playing', () async {
    final market = FakeMarketService();
    final cubit = GameCubit(
      market: market,
      boardSetup: FixedBoardSetup(
        BoardModel(
          boardSize: boardSize,
          galaxies: const [BoardGalaxy(id: 1, cellIndex: 0)],
        ),
      ),
    );

    cubit.startGame(5);
    market.controller.add(
      const MarketTick(
        price: 77500,
        wholePrice: 77500,
        isDivisibleByFive: true,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.marketSignal, isNotNull);
    expect(cubit.state.marketSignal!.message, 'Hidden Galaxy Detected');
    expect(cubit.state.marketSignal!.region, isNotNull);
    expect(cubit.state.board.hiddenGalaxyCount, 2);

    await cubit.close();
  });
}
