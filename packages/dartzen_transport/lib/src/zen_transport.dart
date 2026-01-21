import 'package:meta/meta.dart';

import 'config.dart';
import 'descriptors.dart';

part 'executors/cloud_executor.dart';
part 'executors/executor.dart';
part 'executors/local_executor.dart';
part 'executors/test_executor.dart';

/// The single public entry point for executing transport operations.
class ZenTransport {
  ZenTransport._(this._config, this._executor);

  static ZenTransport? _instance;

  /// Global singleton instance using environment-driven configuration.
  static ZenTransport get instance =>
      _instance ??= ZenTransport(config: ZenTransportConfig.fromEnv());

  /// Creates (and sets) the global instance with explicit config.
  ///
  /// This factory never exposes underlying executors and will always resolve
  /// them internally based on the provided configuration.
  factory ZenTransport({required ZenTransportConfig config}) {
    final executor = _resolveExecutor(config);
    final inst = ZenTransport._(config, executor);
    _instance = inst;
    return inst;
  }

  final ZenTransportConfig _config;
  final TransportExecutor _executor;

  /// Current configuration for the transport facade.
  ZenTransportConfig get config => _config;

  /// Sends a payload using the provided descriptor.
  Future<TransportResult> send(
    TransportDescriptor descriptor, {
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) => _executor.send(
    descriptor,
    payload: payload,
    idempotencyKey: idempotencyKey,
  );

  /// Resets the singleton instance (test-only).
  @visibleForTesting
  static void resetTestInstance() {
    _instance = null;
  }

  static TransportExecutor _resolveExecutor(ZenTransportConfig config) {
    if (config.isTest) return _TestTransportExecutor();
    if (config.isProd) return _CloudTransportExecutor();
    return _LocalTransportExecutor();
  }
}
