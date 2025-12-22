/// The `dartzen_server` package provides the application boundary and orchestration layer
/// for the DartZen ecosystem. It is responsible for:
///
/// - Lifecycle management of the server.
/// - Orchestration of transport layers.
/// - Translation of domain results to HTTP responses.
/// - Serving static content.
///
/// This package adheres to the DartZen philosophy of separating transport and domain concerns.
/// It does not contain any domain logic or models.
///
/// The application boundary and orchestration layer for the DartZen ecosystem.
library;

export 'src/zen_response_translator.dart';
export 'src/zen_server_application.dart';
export 'src/zen_server_config.dart';
export 'src/zen_static_content_provider.dart';
