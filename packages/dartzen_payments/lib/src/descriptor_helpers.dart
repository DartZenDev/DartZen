import 'missing_descriptor_exception.dart';
import 'payment_descriptor.dart';

/// Ensure descriptor is present and valid. Throws [MissingDescriptorException]
/// if the descriptor is missing or invalid.
void ensureValidDescriptor(PaymentDescriptor? descriptor) {
  if (descriptor == null) {
    throw const MissingDescriptorException('PaymentDescriptor is required');
  }
  if (descriptor.id.trim().isEmpty) {
    throw const MissingDescriptorException(
      'PaymentDescriptor.id must be non-empty',
    );
  }
}
