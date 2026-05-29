class MarketSignal {
  const MarketSignal({
    required this.startedAt,
    required this.wholePrice,
    this.region,
    this.message = 'Hidden Galaxy Detected',
  });

  static const double durationSeconds = 5.0;

  final double startedAt;
  final int wholePrice;
  final MarketSignalRegion? region;
  final String message;

  bool isActiveAt(double now) {
    return now - startedAt < durationSeconds;
  }
}

class MarketSignalRegion {
  const MarketSignalRegion({
    required this.startRow,
    required this.startColumn,
    required this.size,
  });

  final int startRow;
  final int startColumn;
  final int size;

  bool containsCellIndex(int cellIndex, int boardSize) {
    final row = cellIndex ~/ boardSize;
    final column = cellIndex % boardSize;

    return row >= startRow &&
        row < startRow + size &&
        column >= startColumn &&
        column < startColumn + size;
  }
}
