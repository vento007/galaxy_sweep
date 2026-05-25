class MarketSignal {
  const MarketSignal({
    required this.startedAt,
    required this.wholePrice,
    this.message = 'Hidden Galaxy Detected',
  });

  static const double durationSeconds = 3.0;

  final double startedAt;
  final int wholePrice;
  final String message;

  bool isActiveAt(double now) {
    return now - startedAt < durationSeconds;
  }
}
