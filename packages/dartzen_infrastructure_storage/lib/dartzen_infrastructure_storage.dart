/// Storage-backed static content providers for the DartZen ecosystem.
///
/// This package provides infrastructure implementations of
/// `ZenStaticContentProvider` for external storage systems. It does not
/// introduce defaults, fallbacks, or implicit wiring.
///
/// ## Usage
///
/// All providers must be explicitly configured and wired via
/// `ZenServerConfig`:
///
/// ```dart
/// import 'package:dartzen_infrastructure_storage/dartzen_infrastructure_storage.dart';
/// import 'package:dartzen_server/dartzen_server.dart';
/// import 'package:gcloud/storage.dart';
///
/// final storage = Storage(authClient, project);
/// final config = ZenServerConfig(
///   staticContentProvider: GcsStaticContentProvider(
///     storage: storage,
///     bucket: 'my-legal-content',
///     prefix: 'public/',
///   ),
/// );
/// ```
///
/// This package answers only one question: "Where do the bytes come from?"
/// All other concerns (HTTP, localization, presentation) remain outside its scope.
library;

export 'src/gcs_static_content_provider.dart';
