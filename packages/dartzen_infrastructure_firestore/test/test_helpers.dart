import 'package:dartzen_infrastructure_firestore/src/l10n/firestore_messages.dart';
import 'package:dartzen_localization/dartzen_localization.dart';
import 'package:dartzen_localization/src/zen_localization_cache.dart';

/// Creates a test FirestoreMessages instance with preloaded messages.
FirestoreMessages createTestMessages() {
  final cache = ZenLocalizationCache();

  // Directly populate the cache with firestore messages
  cache.setGlobal('en', {
    'firestore.error.identity_not_found':
        'The requested identity could not be found.',
    'firestore.error.database_unavailable':
        'The database service is currently unavailable. Please try again later.',
    'firestore.error.storage_operation_failed':
        'The storage operation could not be completed.',
    'firestore.error.permission_denied':
        'You do not have permission to perform this operation.',
    'firestore.error.operation_timeout':
        'The operation took too long and has been cancelled.',
    'firestore.error.corrupted_data':
        'The stored data appears to be invalid or corrupted.',
    'firestore.error.document_not_found':
        'The requested document could not be found.',
    'firestore.error.document_data_null':
        'The document data is missing or invalid.',
    'firestore.error.missing_lifecycle_state':
        'The identity lifecycle state is missing.',
    'firestore.error.unknown_lifecycle_state':
        'The identity lifecycle state is not recognized.',
    'firestore.error.missing_timestamp': 'The creation timestamp is missing.',
  });

  final service = ZenLocalizationService(
    config: const ZenLocalizationConfig(isProduction: false),
    cache: cache,
  );

  return FirestoreMessages(service, 'en');
}
