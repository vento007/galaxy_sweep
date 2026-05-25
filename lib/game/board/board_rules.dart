import 'dart:math';

import 'package:galaxy_sweep/models/board_model.dart';
import 'package:galaxy_sweep/models/galaxy_blast.dart';
import 'package:galaxy_sweep/models/galaxy_model.dart';
import 'package:galaxy_sweep/models/galaxy_state.dart';

class BoardRules {
  const BoardRules();

  MovePieceResult movePiece(
    BoardModel model, {
    required int pieceId,
    required int toIndex,
    required double now,
  }) {
    final pieceIndex = model.pieces.indexWhere((piece) => piece.id == pieceId);

    if (pieceIndex == -1) {
      return MovePieceResult.rejected(model);
    }

    final piece = model.pieces[pieceIndex];

    if (piece.cellIndex == toIndex) {
      return MovePieceResult.rejected(model);
    }

    if (model.pieceAtCell(toIndex, excludingPieceId: pieceId) != null) {
      return MovePieceResult.rejected(model);
    }

    final galaxyIndex = model.galaxies.indexWhere(
      (galaxy) =>
          galaxy.cellIndex == toIndex && galaxy.state == GalaxyState.hidden,
    );
    final discoveredGalaxy = galaxyIndex != -1;
    var discoveredGalaxies = model.discoveredGalaxies;
    var galaxies = model.galaxies;
    var blasts = model.blasts;

    if (discoveredGalaxy) {
      discoveredGalaxies++;
      final galaxy = model.galaxies[galaxyIndex];
      galaxies = List.of(model.galaxies);
      galaxies[galaxyIndex] = galaxy.copyWith(state: GalaxyState.found);
      blasts = List.of(model.blasts)
        ..add(
          GalaxyBlast(
            galaxyId: galaxy.id,
            cellIndex: galaxy.cellIndex,
            kind: GalaxyBlastKind.found,
            startedAt: now,
          ),
        );
    }

    final pieces = List.of(model.pieces);
    pieces[pieceIndex] = piece.copyWith(cellIndex: toIndex);
    final board = model.copyWith(
      discoveredGalaxies: discoveredGalaxies,
      galaxies: galaxies,
      blasts: blasts,
      pieces: pieces,
    );

    return MovePieceResult.accepted(
      board: board,
      discoveredGalaxy: discoveredGalaxy,
    );
  }

  BoardModel explodeRandomHiddenGalaxy(
    BoardModel model,
    double now,
    Random random,
  ) {
    final hiddenIndices = <int>[];

    for (var i = 0; i < model.galaxies.length; i++) {
      if (model.galaxies[i].state == GalaxyState.hidden) {
        hiddenIndices.add(i);
      }
    }

    if (hiddenIndices.isEmpty) {
      return model;
    }

    final galaxyIndex = hiddenIndices[random.nextInt(hiddenIndices.length)];
    final galaxy = model.galaxies[galaxyIndex];
    final galaxies = List.of(model.galaxies);
    galaxies[galaxyIndex] = galaxy.copyWith(state: GalaxyState.exploded);
    final blasts = List.of(model.blasts)
      ..add(
        GalaxyBlast(
          galaxyId: galaxy.id,
          cellIndex: galaxy.cellIndex,
          kind: GalaxyBlastKind.timer,
          startedAt: now,
        ),
      );

    return model.copyWith(
      galaxies: galaxies,
      explodedGalaxies: model.explodedGalaxies + 1,
      blasts: blasts,
    );
  }

  BoardModel addRandomHiddenGalaxy(
    BoardModel model, {
    required Random random,
    required int maxHiddenGalaxies,
  }) {
    if (model.hiddenGalaxyCount >= maxHiddenGalaxies) {
      return model;
    }

    final openCells = <int>[];

    for (final cell in model.cells) {
      final index = model.findIndex(cell.row, cell.column);
      if (model.pieceAtCell(index) != null) {
        continue;
      }
      if (model.galaxyAtCell(index) != null) {
        continue;
      }
      openCells.add(index);
    }

    if (openCells.isEmpty) {
      return model;
    }

    final cellIndex = openCells[random.nextInt(openCells.length)];
    var nextGalaxyId = 0;
    for (final galaxy in model.galaxies) {
      if (galaxy.id >= nextGalaxyId) {
        nextGalaxyId = galaxy.id + 1;
      }
    }

    return model.copyWith(
      galaxies: [
        ...model.galaxies,
        BoardGalaxy(id: nextGalaxyId, cellIndex: cellIndex),
      ],
    );
  }
}

class MovePieceResult {
  const MovePieceResult._({
    required this.board,
    required this.moved,
    required this.discoveredGalaxy,
  });

  const MovePieceResult.rejected(BoardModel board)
    : this._(board: board, moved: false, discoveredGalaxy: false);

  const MovePieceResult.accepted({
    required BoardModel board,
    required bool discoveredGalaxy,
  }) : this._(board: board, moved: true, discoveredGalaxy: discoveredGalaxy);

  final BoardModel board;
  final bool moved;
  final bool discoveredGalaxy;
}
