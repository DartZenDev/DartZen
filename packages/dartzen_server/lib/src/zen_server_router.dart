import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'handlers/content_handler.dart';
import 'handlers/health_handler.dart';
import 'zen_content_provider.dart';

/// Router for the `dartzen_server`.
///
/// Defines the minimal routing structure for the server skeleton.
/// All content routes are configured at the application level—the server
/// package does not define any routes.
class ZenServerRouter {
  /// Creates a [ZenServerRouter] with the given [_contentProvider] and
  /// optional [_contentRoutes].
  const ZenServerRouter(
    this._contentProvider, {
    Map<String, String> contentRoutes = const {},
  }) : _contentRoutes = contentRoutes;

  final ZenContentProvider _contentProvider;
  final Map<String, String> _contentRoutes;

  /// Creates and configures the router.
  Router get router {
    final router = Router();
    final contentHandler = ContentHandler(_contentProvider);

    // Health endpoint
    router.get('/health', HealthHandler.handle);
    router.get('/ping', HealthHandler.handle);

    // Register content routes from application configuration
    for (final entry in _contentRoutes.entries) {
      router.get(
        entry.key,
        (Request request) => contentHandler.handle(request, entry.value),
      );
    }

    return router;
  }
}
