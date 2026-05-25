import 'dart:math';

import 'package:galaxy_sweep/models/board_model.dart';
import 'package:galaxy_sweep/game_config.dart';
import 'package:galaxy_sweep/models/galaxy_model.dart';
import 'package:galaxy_sweep/models/piece_model.dart';

class BoardSetup {
  const BoardSetup();

  BoardModel populate(BoardModel model) {
    final galaxyIndices = <int>[];
    final pieceIndices = <int>[];
    final random = Random();

    while (galaxyIndices.length < galaxiesCount) {
      final index = random.nextInt(model.cells.length);

      if (!galaxyIndices.contains(index)) {
        galaxyIndices.add(index);
      }
    }

    while (pieceIndices.length < piecesCount) {
      final index = random.nextInt(model.cells.length);

      if (galaxyIndices.contains(index)) {
        continue;
      }
      if (pieceIndices.contains(index)) {
        continue;
      }

      pieceIndices.add(index);
    }

    final galaxies = [
      for (var i = 0; i < galaxyIndices.length; i++)
        BoardGalaxy(id: i, cellIndex: galaxyIndices[i]),
    ];
    final pieces = [
      for (var i = 0; i < pieceIndices.length; i++)
        BoardPiece(id: i, cellIndex: pieceIndices[i]),
    ];

    return model.copyWith(
      discoveredGalaxies: 0,
      explodedGalaxies: 0,
      galaxies: galaxies,
      blasts: const [],
      pieces: pieces,
    );
  }
}
