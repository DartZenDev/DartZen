import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

/// A simple implementation of [ExternalIdentity] for mapping storage.
class InfrastructureExternalIdentity implements ExternalIdentity {
  @override
  final String subject;

  @override
  final Map<String, dynamic> claims;

  /// Creates an [InfrastructureExternalIdentity].
  const InfrastructureExternalIdentity({
    required this.subject,
    required this.claims,
  });
}
