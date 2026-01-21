part of '../zen_transport.dart';

/// Production/cloud executor.
///
/// Private to the package; not exported.
class _CloudTransportExecutor implements TransportExecutor {
  @override
  Future<TransportResult> send(
    TransportDescriptor descriptor, {
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) => Future.value(
    // Placeholder implementation to be replaced with actual cloud
    // transport. Keeping behavior consistent with a success response to
    // avoid breaking early adopters while the facade stabilizes.
    TransportResult.ok(
      status: 202,
      data: {
        'accepted': true,
        'descriptorId': descriptor.id,
        'channel': descriptor.channel.name,
      },
      requestId: 'cloud-${DateTime.now().millisecondsSinceEpoch}',
    ),
  );
}
