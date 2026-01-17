import 'package:meta/meta.dart';

import 'models/execution_overrides.dart';
import 'zen_executor.dart';

/// Configuration for [ZenExecutor] specifying the default destination for heavy tasks.
///
/// This configuration enforces explicit ownership and determinism:
/// - **queueId**: The Cloud Tasks queue name for heavy task dispatch.
/// - **serviceUrl**: The base URL of the service handling heavy tasks.
///
/// These values are **required** and fix the default routing destination.
/// Per-call overrides are possible via [ExecutionOverrides], but the absence
/// of an override always means using these constructor-provided values.
///
/// **No implicit fallbacks, env lookups, or magic defaults.**
@immutable
class ZenExecutorConfig {
  /// Creates an executor configuration with explicit destination parameters.
  ///
  /// Both [queueId] and [serviceUrl] are required to ensure deterministic
  /// routing and explicit ownership of heavy task execution.
  const ZenExecutorConfig({required this.queueId, required this.serviceUrl});

  /// The Cloud Tasks queue identifier for heavy task dispatch.
  final String queueId;

  /// The base URL of the service that will handle heavy tasks.
  ///
  /// Example: `https://my-service.run.app`
  final String serviceUrl;
}
