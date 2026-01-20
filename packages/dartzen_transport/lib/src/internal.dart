/// Internal exports for testing and framework integration.
///
/// **DO NOT IMPORT FROM THIS FILE** - this is for internal framework use only.
/// @internal
library;

export 'internal/client/zen_client.dart' show ZenClient, requestIdHeaderName;
export 'internal/server/transport_middleware.dart'
    show transportMiddleware, zenResponse;
export 'internal/websocket/zen_websocket.dart' show ZenWebSocket;
