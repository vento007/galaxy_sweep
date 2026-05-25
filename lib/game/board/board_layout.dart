import 'dart:math' as math;
import 'dart:ui';

BoardLayout createBoardLayout(
  Size size, {
  required int boardSize,
  required double gap,
}) {
  return BoardLayout(canvasSize: size, boardSize: boardSize, gap: gap);
}

class BoardLayout {
  BoardLayout({
    required this.canvasSize,
    required this.boardSize,
    required this.gap,
  });
  final Size canvasSize;
  final int boardSize;
  final double gap;

  late final double margin = (canvasSize.shortestSide * 0.035).clamp(
    10.0,
    28.0,
  );
  late final double side = math.max(
    0.0,
    math.min(canvasSize.width - margin * 2, canvasSize.height - margin * 2),
  );

  late final Rect boardRect = Rect.fromCenter(
    center: Offset(canvasSize.width / 2, canvasSize.height / 2),
    width: side,
    height: side,
  );

  late final double cellSize = side / boardSize;

  int? indexAtPosition(Offset position) {
    if (!boardRect.contains(position)) return null;
    final column = ((position.dx - boardRect.left) / cellSize).floor();
    final row = ((position.dy - boardRect.top) / cellSize).floor();

    if (row < 0 || row >= boardSize) return null;
    if (column < 0 || column >= boardSize) return null;

    return row * boardSize + column;
  }

  Rect rectForCell(int row, int column) {
    return Rect.fromLTWH(
      boardRect.left + column * cellSize + gap,
      boardRect.top + row * cellSize + gap,
      cellSize - gap * 2,
      cellSize - gap * 2,
    );
  }

  Rect cellBoundsForIndex(int index) {
    final row = index ~/ boardSize;
    final column = index % boardSize;

    return Rect.fromLTWH(
      boardRect.left + column * cellSize,
      boardRect.top + row * cellSize,
      cellSize,
      cellSize,
    );
  }

  Offset cellCenterForIndex(int index) {
    return cellBoundsForIndex(index).center;
  }

  Offset clampToCellCenterArea(Offset point) {
    final halfCell = cellSize / 2;

    return Offset(
      point.dx.clamp(boardRect.left + halfCell, boardRect.right - halfCell),
      point.dy.clamp(boardRect.top + halfCell, boardRect.bottom - halfCell),
    );
  }
}
