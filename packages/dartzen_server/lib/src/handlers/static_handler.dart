import 'package:shelf/shelf.dart';

import '../zen_static_content_provider.dart';

/// Handler for serving static content.
///
/// This handler is a pure transport coordinator:
/// - Calls the provider for content
/// - Returns Response.ok(content) if found
/// - Returns Response.notFound() if not found
///
/// The handler contains no HTML, no localization, and no presentation logic.
/// It only moves bytes and status codes.
class StaticHandler {
  /// Creates a [StaticHandler] with the given [_provider].
  ///
  /// If [fallbackKey] is provided, the handler will attempt to serve
  /// that content when the requested key is not found.
  const StaticHandler(this._provider, {String? fallbackKey})
    : _fallbackKey = fallbackKey;

  final ZenStaticContentProvider _provider;
  final String? _fallbackKey;

  /// Serves static content by key.
  ///
  /// Returns:
  /// - Response.ok(content) if content is found
  /// - Response.ok(fallbackContent) if primary not found but fallback is
  /// - Response.notFound() if no content is available
  Future<Response> handle(Request request, String key) async {
    final content = await _provider.getByKey(key);

    if (content != null) {
      return Response.ok(content, headers: {'Content-Type': 'text/html'});
    }

    // Try fallback key if configured
    if (_fallbackKey != null) {
      final fallbackContent = await _provider.getByKey(_fallbackKey);
      if (fallbackContent != null) {
        return Response.ok(
          fallbackContent,
          headers: {'Content-Type': 'text/html'},
        );
      }
    }

    // No content available
    return Response.notFound(null);
  }
}
