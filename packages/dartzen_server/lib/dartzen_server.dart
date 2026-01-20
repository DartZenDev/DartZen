/// The `dartzen_server` package provides the application runtime and orchestration layer
/// for DartZen server applications running on Google Cloud Platform.
///
/// It is responsible for:
/// - Process lifecycle (startup and graceful shutdown)
/// - Request routing
/// - Domain invocation (calling domain logic)
/// - Response translation (ZenResult → HTTP via dartzen_transport)
/// - Content serving (opaque bytes/strings from dartzen_storage)
///
/// ## What This Package Is
///
/// `dartzen_server` is:
/// - The **application boundary**
/// - The **runtime entry point**
/// - The **orchestration layer** that wires domain, infrastructure, and transport
/// - **Shelf-native** and **GCP-native** by design
///
/// ## What This Package Is NOT
///
/// `dartzen_server` does NOT:
/// - Abstract over multiple server runtimes
/// - Define or own transport formats (that's `dartzen_transport`)
/// - Provide multi-cloud abstractions
/// - Auto-wire infrastructure
/// - Own domain logic or business rules
///
/// ## Philosophy
///
/// Following the Zen Architecture:
/// - Explicit wiring over hidden magic
/// - Clear ownership boundaries
/// - Deterministic behavior
/// - Fail fast in dev, safe in production
///
/// The application runtime and orchestration layer for DartZen server applications.
library;

export 'src/l10n/server_messages.dart';
export 'src/zen_content_provider.dart';
export 'src/zen_response_translator.dart';
export 'src/zen_server_application.dart';
export 'src/zen_server_config.dart';
