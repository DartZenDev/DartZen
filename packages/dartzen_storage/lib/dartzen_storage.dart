/// Google Cloud Storage reader for the DartZen ecosystem.
///
/// This package provides a clean, minimal API for reading objects from
/// Google Cloud Storage (GCS). It is explicitly GCS-focused and does not
/// attempt to support other cloud providers.
///
/// ## What This Package Is
///
/// `dartzen_storage` is a platform-level capability package that answers
/// one question: "Where do the bytes come from?"
///
/// It is reusable across all DartZen products: servers, background jobs,
/// AI pipelines, and any other Dart application that needs to fetch data
/// from GCS.
///
/// ## What This Package Is NOT
///
/// - A server package
/// - An HTTP or Shelf middleware
/// - A caching layer (use `dartzen_cache` for that)
/// - A rendering or presentation layer
/// - A localization system
/// - A multi-cloud abstraction
///
/// ## Usage
///
/// All readers must be explicitly configured:
///
/// ```dart
/// import 'package:dartzen_storage/dartzen_storage.dart';
/// import 'package:gcloud/storage.dart';
///
/// final storage = Storage(authClient, project);
/// final reader = GcsStorageReader(
///   storage: storage,
///   bucket: 'my-content-bucket',
///   prefix: 'data/',
/// );
///
/// final object = await reader.read('document.json');
/// if (object != null) {
///   print(object.asString());
/// }
/// ```
///
/// This package follows the DartZen philosophy:
/// - Explicit over implicit
/// - No hidden global state
/// - Fail fast in dev/test
/// - Safe UX in production
library;

export 'src/gcs_storage_config.dart';
export 'src/gcs_storage_reader.dart';
export 'src/storage_object.dart';
export 'src/zen_storage_reader.dart';
