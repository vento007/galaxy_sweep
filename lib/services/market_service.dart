import 'package:galaxy_sweep/services/binance/binance_service.dart';

class MarketTick {
  const MarketTick({
    required this.price,
    required this.wholePrice,
    required this.isDivisibleByFive,
  });

  final double price;
  final int wholePrice;
  final bool isDivisibleByFive;
}

abstract interface class MarketService {
  Stream<MarketTick> get ticks;

  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

class BinanceMarketFeed implements MarketService {
  BinanceMarketFeed({BinanceMarketService? service, bool enableLogging = false})
    : _service =
          service ??
          BinanceMarketService(
            url: Uri.parse('wss://stream.binance.com:9443/ws/stream'),
            enableLogging: enableLogging,
          );

  final BinanceMarketService _service;

  @override
  Stream<MarketTick> get ticks => _service.updates.map(
    (update) => MarketTick(
      price: update.price,
      wholePrice: update.wholePrice,
      isDivisibleByFive: update.isDivisibleByFive,
    ),
  );

  @override
  Future<void> start() => _service.start();

  @override
  Future<void> stop() => _service.stop();

  @override
  Future<void> dispose() => _service.dispose();
}
