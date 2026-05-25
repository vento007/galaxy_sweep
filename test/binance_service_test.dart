import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_sweep/services/binance/binance_service.dart';
import 'package:web_socket/testing.dart';
import 'package:web_socket/web_socket.dart';

void main() {
  test('parses nested Binance ticker message', () {
    final update = parseBinanceTickerUpdate({
      'stream': 'btcusdt@ticker',
      'data': {'c': '108245.78'},
    });

    expect(update, isNotNull);
    expect(update!.price, 108245.78);
    expect(update.wholePrice, 108245);
    expect(update.isDivisibleByFive, isTrue);
  });

  test('returns null for non ticker message', () {
    final update = parseBinanceTickerUpdate({'result': null, 'id': 1});

    expect(update, isNull);
  });

  test('start connects once and emits ticker updates', () async {
    final (client, server) = fakes();
    var connectCalls = 0;
    final service = BinanceMarketService(
      url: Uri.parse('wss://example.test/ws'),
      connector: (_) async {
        connectCalls++;
        return client;
      },
    );

    await service.start();
    await service.start();

    expect(connectCalls, 1);

    final subscribeEvent = await server.events.first;
    switch (subscribeEvent) {
      case TextDataReceived(text: final text):
        final payload = jsonDecode(text) as Map<String, dynamic>;
        expect(payload['method'], 'SUBSCRIBE');
      default:
        fail('expected subscribe payload');
    }

    final nextUpdate = service.updates.first;
    server.sendText(jsonEncode({'c': '77371.15'}));
    final update = await nextUpdate;

    expect(update.price, 77371.15);
    expect(update.wholePrice, 77371);
    expect(update.isDivisibleByFive, isFalse);

    await service.dispose();
  });

  test('reconnects after socket close', () async {
    final (clientOne, serverOne) = fakes();
    final (clientTwo, serverTwo) = fakes();
    var connectCalls = 0;

    final service = BinanceMarketService(
      url: Uri.parse('wss://example.test/ws'),
      reconnectDelay: Duration.zero,
      connector: (_) async {
        connectCalls++;
        return connectCalls == 1 ? clientOne : clientTwo;
      },
    );

    await service.start();
    await serverOne.events.first;

    await serverOne.close(1000, 'done');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(connectCalls, 2);

    final subscribeEvent = await serverTwo.events.first;
    expect(subscribeEvent, isA<TextDataReceived>());

    await service.dispose();
  });

  test('retries after an initial connect failure', () async {
    final (client, server) = fakes();
    var connectCalls = 0;

    final service = BinanceMarketService(
      url: Uri.parse('wss://example.test/ws'),
      reconnectDelay: Duration.zero,
      connector: (_) async {
        connectCalls++;
        if (connectCalls == 1) {
          throw StateError('boom');
        }
        return client;
      },
    );

    await service.start();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(connectCalls, 2);

    final subscribeEvent = await server.events.first;
    expect(subscribeEvent, isA<TextDataReceived>());

    await service.dispose();
  });

  test('stop prevents reconnect after connect failure', () async {
    var connectCalls = 0;

    final service = BinanceMarketService(
      url: Uri.parse('wss://example.test/ws'),
      reconnectDelay: const Duration(milliseconds: 10),
      connector: (_) async {
        connectCalls++;
        throw StateError('boom');
      },
    );

    await service.start();
    expect(connectCalls, 1);

    await service.stop();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(connectCalls, 1);

    await service.dispose();
  });

  test('dispose prevents reconnect after connect failure', () async {
    var connectCalls = 0;

    final service = BinanceMarketService(
      url: Uri.parse('wss://example.test/ws'),
      reconnectDelay: const Duration(milliseconds: 10),
      connector: (_) async {
        connectCalls++;
        throw StateError('boom');
      },
    );

    await service.start();
    expect(connectCalls, 1);

    await service.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(connectCalls, 1);
  });

  test('watchdog reconnects after ticker stall', () async {
    final (clientOne, serverOne) = fakes();
    final (clientTwo, serverTwo) = fakes();
    var connectCalls = 0;
    var now = DateTime(2026, 1, 1, 12, 0, 0);

    final service = BinanceMarketService(
      url: Uri.parse('wss://example.test/ws'),
      reconnectDelay: Duration.zero,
      stallTimeout: const Duration(milliseconds: 1),
      watchdogInterval: const Duration(milliseconds: 1),
      nowProvider: () => now,
      connector: (_) async {
        connectCalls++;
        return connectCalls == 1 ? clientOne : clientTwo;
      },
    );

    await service.start();
    await serverOne.events.first;

    serverOne.sendText(jsonEncode({'c': '77370.00'}));
    await service.updates.first;

    now = now.add(const Duration(seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(connectCalls, 2);

    final subscribeEvent = await serverTwo.events.first;
    expect(subscribeEvent, isA<TextDataReceived>());

    await service.dispose();
  });
}
