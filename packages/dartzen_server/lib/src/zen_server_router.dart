import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'handlers/health_handler.dart';
import 'handlers/static_handler.dart';
import 'zen_static_content_provider.dart';

/// Router for the `dartzen_server`.
///
/// Defines the minimal routing structure for the server skeleton.
class ZenServerRouter {
  /// Creates a [ZenServerRouter] with the given [_staticContentProvider].
  const ZenServerRouter(this._staticContentProvider);

  final ZenStaticContentProvider _staticContentProvider;

  /// Creates and configures the router.
  Router get router {
    final router = Router();
    final staticHandler = StaticHandler(_staticContentProvider);

    // Health endpoint
    router.get('/health', HealthHandler.handle);
    router.get('/ping', HealthHandler.handle);

    // Static content - paths map to keys
    router.get(
      '/terms',
      (Request request) => staticHandler.handle(request, 'terms'),
    );

    return router;
  }
}
