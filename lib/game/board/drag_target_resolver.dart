import 'dart:ui';

import 'package:galaxy_sweep/game/board/board_layout.dart';

class DragTargetResolver {
  const DragTargetResolver({this.intentPixels = 14.0});

  final double intentPixels;

  DragTarget resolve({
    required int sourceIndex,
    required Offset pieceCenter,
    required BoardLayout layout,
  }) {
    final actualIndex = layout.indexAtPosition(pieceCenter);
    final drag = pieceCenter - layout.cellCenterForIndex(sourceIndex);

    if (actualIndex == null) {
      return DragTarget(
        index: sourceIndex,
        source: 'outside',
        actualIndex: null,
        drag: drag,
      );
    }

    if (actualIndex != sourceIndex) {
      return DragTarget(
        index: actualIndex,
        source: 'actual',
        actualIndex: actualIndex,
        drag: drag,
      );
    }

    if (drag.distance < intentPixels) {
      return DragTarget(
        index: sourceIndex,
        source: 'same',
        actualIndex: actualIndex,
        drag: drag,
      );
    }

    final swipeIndex = _neighborIndexFromDrag(sourceIndex, drag, layout);

    return DragTarget(
      index: swipeIndex,
      source: swipeIndex == sourceIndex ? 'same' : 'swipe',
      actualIndex: actualIndex,
      drag: drag,
    );
  }

  int _neighborIndexFromDrag(int sourceIndex, Offset drag, BoardLayout layout) {
    final sourceRow = sourceIndex ~/ layout.boardSize;
    final sourceColumn = sourceIndex % layout.boardSize;
    final rowDelta = _directionForDistance(drag.dy);
    final columnDelta = _directionForDistance(drag.dx);
    final targetRow = (sourceRow + rowDelta).clamp(0, layout.boardSize - 1);
    final targetColumn = (sourceColumn + columnDelta).clamp(
      0,
      layout.boardSize - 1,
    );

    return targetRow * layout.boardSize + targetColumn;
  }

  int _directionForDistance(double distance) {
    if (distance.abs() < intentPixels) {
      return 0;
    }

    return distance.isNegative ? -1 : 1;
  }
}

class DragTarget {
  const DragTarget({
    required this.index,
    required this.source,
    required this.actualIndex,
    required this.drag,
  });

  final int index;
  final String source;
  final int? actualIndex;
  final Offset drag;
}
