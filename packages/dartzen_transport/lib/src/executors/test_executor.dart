part of '../zen_transport.dart';

/// Test/in-memory executor used by package tests.
///
/// Private to the package; not exported.
class _TestTransportExecutor implements TransportExecutor {
  @override
  Future<TransportResult> send(
    TransportDescriptor descriptor, {
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async => TransportResult.ok(
    status: 200,
    data: {
      'test': true,
      'descriptorId': descriptor.id,
      'payload': payload,
      'idempotencyKey': ?idempotencyKey,
    },
    requestId: 'test-${DateTime.now().millisecondsSinceEpoch}',
  );
}
