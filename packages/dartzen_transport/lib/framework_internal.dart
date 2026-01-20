/// **FRAMEWORK-ONLY INTERNAL API - DO NOT USE IN APPLICATION CODE**
///
/// This library provides internal transport components for the DartZen framework
/// to integrate transport clients into executor tasks. Only the DartZen framework
/// should import from this library. Application code must use ZenExecutor to
/// execute tasks that require HTTP, WebSocket, or server middleware.
///
/// Importing this library outside the framework violates the executor-only
/// pattern and creates escape hatches for direct network I/O.
library;

export 'src/internal/client/zen_client.dart'
    show ZenClient, requestIdHeaderName;
export 'src/internal/server/transport_middleware.dart'
    show transportMiddleware, zenResponse;
export 'src/internal/websocket/zen_websocket.dart' show ZenWebSocket;
