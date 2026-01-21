import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  setUp(ZenTransport.resetTestInstance);

  test('Test executor returns test flag and includes idempotency when provided', () async {
    const cfg = ZenTransportConfig(isProd: false, isTest: true);
    final transport = ZenTransport(config: cfg);

    const descriptor = TransportDescriptor(
      id: 'test.exec.1',
      channel: TransportChannel.event,
      reliability: TransportReliability.exactlyOnce,
    );

    final res = await transport.send(
      descriptor,
      payload: {'x': 42},
      idempotencyKey: 't-id-1',
    );

    expect(res.success, isTrue);
    expect(res.status, equals(200));
    expect(res.requestId, startsWith('test-'));

    final data = res.data as Map<String, dynamic>;
    expect(data['test'], isTrue);
    expect(data['descriptorId'], equals('test.exec.1'));
    expect(data['payload'], equals({'x': 42}));
    expect(data['idempotencyKey'], equals('t-id-1'));
  });

  test('Test executor omits idempotency when not provided', () async {
    const cfg = ZenTransportConfig(isProd: false, isTest: true);
    final transport = ZenTransport(config: cfg);

    const descriptor = TransportDescriptor(
      id: 'test.exec.2',
      channel: TransportChannel.webhook,
      reliability: TransportReliability.atMostOnce,
    );

    final res = await transport.send(descriptor, payload: {'ok': false});

    expect(res.success, isTrue);
    final data = res.data as Map<String, dynamic>;
    expect(data['test'], isTrue);
    expect(data['descriptorId'], equals('test.exec.2'));
    expect(data['payload'], equals({'ok': false}));
    expect(data.containsKey('idempotencyKey'), isFalse);
  });
}
