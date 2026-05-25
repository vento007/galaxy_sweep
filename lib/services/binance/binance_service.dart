import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket/web_socket.dart';

typedef WebSocketConnector = Future<WebSocket> Function(Uri url);

class BinanceTickerUpdate {
  const BinanceTickerUpdate({
    required this.price,
    required this.wholePrice,
    required this.isDivisibleByFive,
  });

  final double price;
  final int wholePrice;
  final bool isDivisibleByFive;
}

BinanceTickerUpdate? parseBinanceTickerUpdate(Map<String, dynamic> message) {
  Map<String, dynamic>? payload;

  final nestedData = message['data'];
  if (nestedData is Map) {
    payload = Map<String, dynamic>.from(nestedData);
  } else {
    payload = message;
  }

  final priceValue = payload['c'] ?? payload['price'];
  if (priceValue == null) {
    return null;
  }

  final price = double.tryParse(priceValue.toString());
  if (price == null) {
    return null;
  }

  final wholePrice = price.floor();

  return BinanceTickerUpdate(
    price: price,
    wholePrice: wholePrice,
    isDivisibleByFive: wholePrice % 5 == 0,
  );
}

class BinanceMarketService {
  BinanceMarketService({
    required this.url,
    this.connector = WebSocket.connect,
    this.reconnectDelay = const Duration(seconds: 3),
    this.stallTimeout = const Duration(seconds: 15),
    this.watchdogInterval = const Duration(seconds: 5),
    this.enableLogging = false,
    DateTime Function()? nowProvider,
  }) : _now = nowProvider ?? DateTime.now;

  final Uri url;
  final WebSocketConnector connector;
  final Duration reconnectDelay;
  final Duration stallTimeout;
  final Duration watchdogInterval;
  final bool enableLogging;
  final DateTime Function() _now;

  static const Map<String, dynamic> _subscribePayload = {
    'id': 1,
    'params': ['btcusdt@ticker'],
    'method': 'SUBSCRIBE',
  };

  final StreamController<BinanceTickerUpdate> _updates =
      StreamController<BinanceTickerUpdate>.broadcast();

  WebSocket? _socket;
  StreamSubscription<WebSocketEvent>? _subscription;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;
  DateTime? _lastTickerAt;
  bool _started = false;
  bool _connecting = false;
  bool _disposed = false;

  Stream<BinanceTickerUpdate> get updates => _updates.stream;

  Future<void> start() async {
    if (_disposed || _started) {
      return;
    }

    _started = true;
    await _connect();
  }

  Future<void> stop() async {
    _started = false;
    _cancelReconnect();
    await _closeConnection();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    await stop();
    await _updates.close();
  }

  Future<void> _connect() async {
    if (!_started || _disposed || _connecting || _socket != null) {
      return;
    }

    _connecting = true;
    try {
      _log('connecting to $url');
      final socket = await connector(url);
      if (!_started || _disposed) {
        await socket.close();
        return;
      }

      _socket = socket;
      _log('connected');
      _socket!.sendText(jsonEncode(_subscribePayload));
      _log('subscribed to btcusdt@ticker');

      _subscription = _socket!.events.listen(_handleEvent);
      _startWatchdog();
    } catch (exception) {
      _log('connect error: $exception');
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _handleEvent(WebSocketEvent event) {
    switch (event) {
      case TextDataReceived(text: final text):
        _handleTextMessage(text);
      case BinaryDataReceived():
        break;
      case CloseReceived(code: final code, reason: final reason):
        _log('closed code=$code reason=$reason');
        unawaited(_handleDisconnect());
    }
  }

  void _handleTextMessage(String text) {
    try {
      final message = jsonDecode(text);
      if (message is! Map) {
        _log('ignored non-map message');
        return;
      }

      final data = Map<String, dynamic>.from(message);
      final tickerUpdate = parseBinanceTickerUpdate(data);
      if (tickerUpdate == null) {
        _log('ignored non-ticker message');
        return;
      }

      _lastTickerAt = _now();
      _updates.add(tickerUpdate);
    } catch (exception) {
      _log('parse error: $exception');
    }
  }

  Future<void> _handleDisconnect() async {
    if (!_started || _disposed) {
      return;
    }

    await _closeConnection();
    _scheduleReconnect();
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(watchdogInterval, (_) {
      final lastTickerAt = _lastTickerAt;
      if (!_started || _disposed || lastTickerAt == null) {
        return;
      }

      if (_now().difference(lastTickerAt) <= stallTimeout) {
        return;
      }

      _log('stalled, reconnecting');
      unawaited(_restartConnection());
    });
  }

  Future<void> _restartConnection() async {
    if (!_started || _disposed || _connecting || _reconnectTimer != null) {
      return;
    }

    await _closeConnection();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_started || _disposed || _reconnectTimer != null) {
      return;
    }

    _log('reconnecting in ${reconnectDelay.inMilliseconds}ms');
    _reconnectTimer = Timer(reconnectDelay, () {
      _reconnectTimer = null;
      unawaited(_connect());
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _closeConnection() async {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _lastTickerAt = null;

    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();

    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {}
    }
  }

  void _log(String message) {
    if (enableLogging) {
      debugPrint('Binance: $message');
    }
  }
}
