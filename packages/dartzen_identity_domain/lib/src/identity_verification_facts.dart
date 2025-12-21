import 'package:meta/meta.dart';

/// Domain value object representing external verification facts.
///
/// This object encapsulates verification status from external identity providers
/// without making any policy decisions about lifecycle state.
@immutable
final class IdentityVerificationFacts {
  /// Whether the email address has been verified.
  final bool emailVerified;

  /// Whether the phone number has been verified (optional).
  final bool phoneVerified;

  /// Creates [IdentityVerificationFacts].
  const IdentityVerificationFacts({
    required this.emailVerified,
    this.phoneVerified = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityVerificationFacts &&
          runtimeType == other.runtimeType &&
          emailVerified == other.emailVerified &&
          phoneVerified == other.phoneVerified;

  @override
  int get hashCode => emailVerified.hashCode ^ phoneVerified.hashCode;
}
