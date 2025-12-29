import 'dart:io';

import 'zen_content_provider.dart';
import 'zen_server_application.dart';

/// Configuration for the [ZenServerApplication].
class ZenServerConfig {
  /// Creates a [ZenServerConfig].
  const ZenServerConfig({
    this.address = '0.0.0.0',
    this.port = 8080,
    this.contentProvider = const FileContentProvider('public'),
    this.contentRoutes = const {},
  });

  /// The address to bind the server to.
  final String address;

  /// The port to listen on.
  final int port;

  /// The provider for content.
  ///
  /// The server treats content as opaque bytes/strings and has no knowledge
  /// of what content exists or what keys mean.
  final ZenContentProvider contentProvider;

  /// Maps HTTP paths to content keys.
  ///
  /// This is application-level configuration—the server package does not
  /// define any routes. All content routing decisions belong to the
  /// application layer.
  ///
  /// Example:
  /// ```dart
  /// contentRoutes: {
  ///   '/terms': 'legal/terms.html',
  ///   '/privacy': 'legal/privacy.html',
  ///   '/docs/api': 'documentation/api.json',
  /// }
  /// ```
  final Map<String, String> contentRoutes;

  /// Resolves the bind address.
  Object get bindAddress =>
      address == '0.0.0.0' ? InternetAddress.anyIPv4 : address;
}
