import 'package:shelf/shelf.dart';

import '../zen_content_provider.dart';

/// Handler for serving content.
///
/// This handler is a pure transport coordinator:
/// - Calls the provider for content
/// - Returns Response.ok(content) with correct Content-Type if found
/// - Returns Response.notFound() if not found
///
/// The handler contains no presentation logic, no localization, and no
/// semantic understanding of the content. It only moves bytes, status codes,
/// and metadata (content type) from storage to HTTP responses.
class ContentHandler {
  /// Creates a [ContentHandler] with the given [_provider].
  ///
  /// If [fallbackKey] is provided, the handler will attempt to serve
  /// that content when the requested key is not found.
  const ContentHandler(this._provider, {String? fallbackKey})
    : _fallbackKey = fallbackKey;

  final ZenContentProvider _provider;
  final String? _fallbackKey;

  /// Serves content by key.
  ///
  /// Returns:
  /// - Response.ok(content) with correct Content-Type if content is found
  /// - Response.ok(fallbackContent) if primary not found but fallback is
  /// - Response.notFound() if no content is available
  Future<Response> handle(Request request, String key) async {
    final content = await _provider.getByKey(key);

    if (content != null) {
      return Response.ok(
        content.data,
        headers: {'Content-Type': content.contentType},
      );
    }

    // Try fallback key if configured
    if (_fallbackKey != null) {
      final fallbackContent = await _provider.getByKey(_fallbackKey);
      if (fallbackContent != null) {
        return Response.ok(
          fallbackContent.data,
          headers: {'Content-Type': fallbackContent.contentType},
        );
      }
    }

    // No content available
    return Response.notFound(null);
  }
}
