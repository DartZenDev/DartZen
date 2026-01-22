import 'package:dartzen_core/dartzen_core.dart';
import 'package:meta/meta.dart';

/// Configuration for ZenTransport environment-driven behavior.
@immutable
class ZenTransportConfig {
  /// Creates a configuration object for transport behavior.
  const ZenTransportConfig({required this.isProd, this.isTest = false});

  /// Creates config based on the global runtime environment.
  ///
  /// Uses `dzIsPrd` from dartzen_core. No consumer-controlled axis allowed.
  factory ZenTransportConfig.fromEnv() =>
      const ZenTransportConfig(isProd: dzIsPrd);

  /// Whether the runtime is production.
  final bool isProd;

  /// Internal-only test switch for package tests/framework harnesses.
  final bool isTest;

  /// Returns a copy with selected fields overridden.
  ZenTransportConfig copyWith({bool? isProd, bool? isTest}) =>
      ZenTransportConfig(
        isProd: isProd ?? this.isProd,
        isTest: isTest ?? this.isTest,
      );
}
