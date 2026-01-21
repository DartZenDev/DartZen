import 'package:dartzen_transport/dartzen_transport.dart';
import 'package:test/test.dart';

void main() {
  setUp(ZenTransport.resetTestInstance);

  test('factory sets global instance and instance getter returns same', () {
    const cfg = ZenTransportConfig(isProd: false);
    final t = ZenTransport(config: cfg);
    expect(identical(ZenTransport.instance, t), isTrue);
    expect(ZenTransport.instance.config.isProd, isFalse);
  });

  test(
    'factory sets global instance and uses test executor when isTest',
    () async {
      const cfg = ZenTransportConfig(isProd: false, isTest: true);
      final transport = ZenTransport(config: cfg);

      expect(identical(ZenTransport.instance, transport), isTrue);

      const descriptor = TransportDescriptor(
        id: 'op.test',
        channel: TransportChannel.http,
        reliability: TransportReliability.atMostOnce,
      );

      final res = await transport.send(
        descriptor,
        payload: {'a': 1},
        idempotencyKey: 'key-1',
      );

      expect(res.success, isTrue);
      expect(res.status, equals(200));
      expect(res.data, isA<Map<String, dynamic>>());
      final data = res.data as Map<String, dynamic>;
      expect(data['test'], isTrue);
      expect(data['descriptorId'], equals('op.test'));
      expect(data['payload'], equals({'a': 1}));
      expect(data['idempotencyKey'], equals('key-1'));
      expect(res.requestId, startsWith('test-'));
    },
  );

  test('factory resolves local executor when not prod and not test', () async {
    const cfg = ZenTransportConfig(isProd: false);
    final transport = ZenTransport(config: cfg);

    const descriptor = TransportDescriptor(
      id: 'op.local',
      channel: TransportChannel.queue,
      reliability: TransportReliability.atLeastOnce,
    );

    final res = await transport.send(descriptor, payload: {'x': 'y'});

    expect(res.success, isTrue);
    expect(res.status, equals(200));
    final data = res.data as Map;
    expect(data['descriptorId'], equals('op.local'));
    expect(data['payload'], equals({'x': 'y'}));
    expect(data['channel'], equals('queue'));
    expect(data['reliability'], equals('atLeastOnce'));
    expect(res.requestId, startsWith('local-'));
  });

  test('factory resolves cloud executor when isProd', () async {
    const cfg = ZenTransportConfig(isProd: true);
    final transport = ZenTransport(config: cfg);

    const descriptor = TransportDescriptor(
      id: 'op.cloud',
      channel: TransportChannel.event,
      reliability: TransportReliability.exactlyOnce,
    );

    final res = await transport.send(descriptor, payload: {'ok': true});

    expect(res.success, isTrue);
    expect(res.status, equals(202));
    final data = res.data as Map;
    expect(data['accepted'], equals(true));
    expect(data['descriptorId'], equals('op.cloud'));
    expect(data['channel'], equals('event'));
    expect(res.requestId, startsWith('cloud-'));
  });

  test('resetTestInstance produces distinct instances when re-created', () {
    final a = ZenTransport(config: const ZenTransportConfig(isProd: false));
    ZenTransport.resetTestInstance();
    final b = ZenTransport(config: const ZenTransportConfig(isProd: false));
    expect(identical(a, b), isFalse);
  });
}
