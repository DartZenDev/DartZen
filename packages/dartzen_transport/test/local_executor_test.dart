import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  setUp(ZenTransport.resetTestInstance);

  test('Local executor includes idempotency key when provided', () async {
    const cfg = ZenTransportConfig(isProd: false);
    final transport = ZenTransport(config: cfg);

    const descriptor = TransportDescriptor(
      id: 'local.exec.1',
      channel: TransportChannel.http,
      reliability: TransportReliability.atLeastOnce,
    );

    final res = await transport.send(
      descriptor,
      payload: {'hello': 'world'},
      idempotencyKey: 'idem-123',
    );

    expect(res.success, isTrue);
    expect(res.status, equals(200));
    expect(res.requestId, startsWith('local-'));

    final data = res.data as Map<String, dynamic>;
    expect(data['descriptorId'], equals('local.exec.1'));
    expect(data['payload'], equals({'hello': 'world'}));
    expect(data['idempotencyKey'], equals('idem-123'));
    expect(data['channel'], equals('http'));
    expect(data['reliability'], equals('atLeastOnce'));
  });

  test('Local executor omits idempotency key when not provided', () async {
    const cfg = ZenTransportConfig(isProd: false);
    final transport = ZenTransport(config: cfg);

    const descriptor = TransportDescriptor(
      id: 'local.exec.2',
      channel: TransportChannel.queue,
      reliability: TransportReliability.atMostOnce,
    );

    final res = await transport.send(descriptor, payload: {'n': 1});

    expect(res.success, isTrue);
    final data = res.data as Map<String, dynamic>;
    expect(data['descriptorId'], equals('local.exec.2'));
    expect(data['payload'], equals({'n': 1}));
    expect(data.containsKey('idempotencyKey'), isFalse);
  });
}
