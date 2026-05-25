import 'package:flutter/foundation.dart';
import 'package:galaxy_sweep/models/board_cell.dart';
import 'package:galaxy_sweep/models/galaxy_blast.dart';
import 'package:galaxy_sweep/models/galaxy_model.dart';
import 'package:galaxy_sweep/models/galaxy_state.dart';
import 'package:galaxy_sweep/models/piece_model.dart';
import 'package:galaxy_sweep/models/piece_visual_state.dart';

@immutable
class BoardModel {
  BoardModel({
    required this.boardSize,
    this.discoveredGalaxies = 0,
    this.explodedGalaxies = 0,
    List<BoardGalaxy> galaxies = const [],
    List<GalaxyBlast> blasts = const [],
    List<BoardPiece> pieces = const [],
  }) : galaxies = List.unmodifiable(galaxies),
       blasts = List.unmodifiable(blasts),
       pieces = List.unmodifiable(pieces),
       cells = List.unmodifiable(_createCells(boardSize));

  final int boardSize;
  final int discoveredGalaxies;
  final int explodedGalaxies;
  final List<BoardGalaxy> galaxies;
  final List<GalaxyBlast> blasts;
  final List<BoardPiece> pieces;
  final List<BoardCell> cells;

  static List<BoardCell> _createCells(int boardSize) {
    return List.generate(
      boardSize * boardSize,
      (index) => BoardCell(row: index ~/ boardSize, column: index % boardSize),
    );
  }

  BoardModel copyWith({
    int? discoveredGalaxies,
    int? explodedGalaxies,
    List<BoardGalaxy>? galaxies,
    List<GalaxyBlast>? blasts,
    List<BoardPiece>? pieces,
  }) {
    return BoardModel(
      boardSize: boardSize,
      discoveredGalaxies: discoveredGalaxies ?? this.discoveredGalaxies,
      explodedGalaxies: explodedGalaxies ?? this.explodedGalaxies,
      galaxies: galaxies ?? this.galaxies,
      blasts: blasts ?? this.blasts,
      pieces: pieces ?? this.pieces,
    );
  }

  int findIndex(int row, int column) {
    return row * boardSize + column;
  }

  BoardPiece? get draggingPiece {
    for (final piece in pieces) {
      if (piece.visualState is PieceDragging) {
        return piece;
      }
    }

    return null;
  }

  BoardPiece? pieceAtCell(int cellIndex, {int? excludingPieceId}) {
    for (final piece in pieces) {
      if (piece.id != excludingPieceId && piece.cellIndex == cellIndex) {
        return piece;
      }
    }

    return null;
  }

  BoardGalaxy? galaxyAtCell(int cellIndex) {
    for (final galaxy in galaxies) {
      if (galaxy.cellIndex == cellIndex) {
        return galaxy;
      }
    }

    return null;
  }

  BoardGalaxy? hiddenGalaxyAtCell(int cellIndex) {
    final galaxy = galaxyAtCell(cellIndex);

    if (galaxy == null || galaxy.state != GalaxyState.hidden) {
      return null;
    }

    return galaxy;
  }

  bool isGalaxyRevealedAtCell(int cellIndex) {
    final galaxy = galaxyAtCell(cellIndex);

    return galaxy != null && galaxy.state != GalaxyState.hidden;
  }

  bool get hasHiddenGalaxies {
    for (final galaxy in galaxies) {
      if (galaxy.state == GalaxyState.hidden) {
        return true;
      }
    }

    return false;
  }

  int get hiddenGalaxyCount {
    var count = 0;

    for (final galaxy in galaxies) {
      if (galaxy.state == GalaxyState.hidden) {
        count++;
      }
    }

    return count;
  }

  int? distanceToNearestGalaxy(int index) {
    final row = index ~/ boardSize;
    final column = index % boardSize;
    int? nearest;

    for (final galaxy in galaxies) {
      if (galaxy.state != GalaxyState.hidden) {
        continue;
      }

      final galaxyRow = galaxy.cellIndex ~/ boardSize;
      final galaxyColumn = galaxy.cellIndex % boardSize;
      final distance = (row - galaxyRow).abs() + (column - galaxyColumn).abs();

      if (nearest == null || distance < nearest) {
        nearest = distance;
      }
    }

    if (nearest == null || nearest > 6) {
      return null;
    }

    return nearest;
  }
}
