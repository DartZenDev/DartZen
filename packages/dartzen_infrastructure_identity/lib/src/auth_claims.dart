import 'package:meta/meta.dart';

/// Represents verified authentication claims from an external authentication system.
///
/// This class encapsulates ONLY the allowed auth claims as specified in the
/// architectural constraints. It represents facts, not intent.
///
/// Token verification happens outside this package. This class assumes
/// all data is already trusted.
@immutable
class AuthClaims {
  /// External unique identifier (e.g., Firebase UID, Google subject).
  ///
  /// This is mapped to a stable external reference and NEVER becomes
  /// a domain ID by itself.
  final String subject;

  /// Provider identifier (e.g., 'google.com', 'github.com', 'firebase').
  ///
  /// Stored as origin metadata only. NEVER influences roles, authority,
  /// or lifecycle.
  final String providerId;

  /// Email address if present in claims.
  ///
  /// Passed through as-is. NEVER normalized, lowercased, or validated here.
  final String? email;

  /// Whether the email has been verified by the provider.
  ///
  /// Mapped to a domain signal, NOT a lifecycle transition.
  /// The domain decides what this means.
  final bool emailVerified;

  /// When the token was issued (Unix timestamp in seconds).
  ///
  /// Used ONLY for traceability and logging. NEVER used to infer identity state.
  final int? issuedAt;

  /// When the token expires (Unix timestamp in seconds).
  ///
  /// Used ONLY for traceability and logging. NEVER used to infer identity state.
  final int? expiresAt;

  /// Creates an [AuthClaims] instance with verified authentication facts.
  ///
  /// All parameters represent external authentication facts that have
  /// already been verified. No validation or transformation is performed.
  const AuthClaims({
    required this.subject,
    required this.providerId,
    this.email,
    this.emailVerified = false,
    this.issuedAt,
    this.expiresAt,
  });

  /// Creates [AuthClaims] from a raw claims map.
  ///
  /// Extracts only the allowed claims as defined in the architectural constraints.
  /// Any additional claims are explicitly ignored to prevent leakage into domain behavior.
  ///
  /// Returns null if required fields ([subject], [providerId]) are missing or invalid.
  static AuthClaims? fromMap(Map<String, dynamic> claims) {
    final subject = claims['sub'] ?? claims['subject'];
    final providerId =
        // ignore: avoid_dynamic_calls
        claims['firebase']?['sign_in_provider'] ??
        claims['provider_id'] ??
        claims['providerId'];

    if (subject is! String || subject.isEmpty) return null;
    if (providerId is! String || providerId.isEmpty) return null;

    final email = claims['email'];
    final emailVerified = claims['email_verified'] == true;
    final issuedAt = claims['iat'];
    final expiresAt = claims['exp'];

    return AuthClaims(
      subject: subject,
      providerId: providerId,
      email: email is String ? email : null,
      emailVerified: emailVerified,
      issuedAt: issuedAt is int ? issuedAt : null,
      expiresAt: expiresAt is int ? expiresAt : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthClaims &&
          runtimeType == other.runtimeType &&
          subject == other.subject &&
          providerId == other.providerId &&
          email == other.email &&
          emailVerified == other.emailVerified &&
          issuedAt == other.issuedAt &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode =>
      subject.hashCode ^
      providerId.hashCode ^
      email.hashCode ^
      emailVerified.hashCode ^
      issuedAt.hashCode ^
      expiresAt.hashCode;

  @override
  String toString() =>
      'AuthClaims('
      'subject: $subject, '
      'providerId: $providerId, '
      'email: $email, '
      'emailVerified: $emailVerified, '
      'issuedAt: $issuedAt, '
      'expiresAt: $expiresAt)';
}
