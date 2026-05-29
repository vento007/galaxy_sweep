enum MarketSignalTriggerMode {
  divisibleBy5('BTC / 5', 5),
  divisibleBy2('BTC / 2', 2),
  every15Seconds('Every 15s', null);

  const MarketSignalTriggerMode(this.label, this.divisor);

  final String label;
  final int? divisor;
}
