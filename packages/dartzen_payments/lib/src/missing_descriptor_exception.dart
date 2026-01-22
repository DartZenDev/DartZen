import 'package:meta/meta.dart';

/// Thrown when a required `PaymentDescriptor` is not provided.
@immutable
final class MissingDescriptorException implements Exception {
  /// Human-readable error message describing the missing descriptor.
  final String message;

  /// Create a [MissingDescriptorException].
  ///
  /// The optional [message] defaults to 'Missing PaymentDescriptor'.
  const MissingDescriptorException([
    this.message = 'Missing PaymentDescriptor',
  ]);

  @override
  String toString() => 'MissingDescriptorException: $message';
}
