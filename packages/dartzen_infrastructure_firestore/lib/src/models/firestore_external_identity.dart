import 'package:dartzen_identity_domain/dartzen_identity_domain.dart';

/// Infrastructure implementation of [ExternalIdentity].
///
/// Used to ferry raw data from Firestore to the domain layer.
class FirestoreExternalIdentity implements ExternalIdentity {
  @override
  final String subject;

  @override
  final Map<String, dynamic> claims;

  /// Creates a [FirestoreExternalIdentity].
  const FirestoreExternalIdentity({
    required this.subject,
    required this.claims,
  });
}
