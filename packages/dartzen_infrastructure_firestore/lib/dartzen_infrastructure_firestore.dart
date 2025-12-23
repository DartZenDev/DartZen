/// Firestore infrastructure adapter for DartZen Identity.
///
/// This package provides persistence adapters for storing and retrieving
/// Identity domain aggregates using Google Cloud Firestore.
///
/// It implements infrastructure-only concerns and contains no business logic.
library;

export 'src/firestore_identity_cleanup.dart';
export 'src/firestore_identity_repository.dart';

// Note: Mappers, DTOs, and error codes are internal implementation details
// and are not exported to maintain domain purity.
