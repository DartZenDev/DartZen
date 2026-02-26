part of '../zen_transport.dart';

/// Local development executor.
///
/// Private to the package; not exported.
class _LocalTransportExecutor implements TransportExecutor {
  @override
  Future<TransportResult> send(
    TransportDescriptor descriptor, {
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) => Future.value(
    TransportResult.ok(
      status: 200,
      data: {
        'descriptorId': descriptor.id,
        'payload': payload,
        'idempotencyKey': ?idempotencyKey,
        'channel': descriptor.channel.name,
        'reliability': descriptor.reliability.name,
      },
      requestId: 'local-${DateTime.now().millisecondsSinceEpoch}',
    ),
  );
}
