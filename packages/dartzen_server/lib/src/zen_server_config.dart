import 'dart:io';

import 'zen_server_application.dart';
import 'zen_static_content_provider.dart';

/// Configuration for the [ZenServerApplication].
class ZenServerConfig {
  /// Creates a [ZenServerConfig].
  const ZenServerConfig({
    this.address = '0.0.0.0',
    this.port = 8080,
    this.staticContentProvider = const FileStaticContentProvider('public'),
  });

  /// The address to bind the server to.
  final String address;

  /// The port to listen on.
  final int port;

  /// The provider for static content.
  ///
  /// The server has no knowledge of what content exists or what keys mean.
  final ZenStaticContentProvider staticContentProvider;

  /// Resolves the bind address.
  Object get bindAddress =>
      address == '0.0.0.0' ? InternetAddress.anyIPv4 : address;
}
