import 'dart:async';

import 'loader/loader_stub.dart'
    if (dart.library.ui) 'loader/loader_flutter.dart'
    if (dart.library.io) 'loader/loader_io.dart';

/// Responsible for loading raw localization strings from storage.
///
/// Automatically selects the correct implementation:
/// - **Flutter**: Uses `rootBundle` (assets).
/// - **Server/Dart CLI**: Uses `dart:io` (filesystem).
class ZenLocalizationLoader {
  final _impl = getLoader();

  /// Loads content from [path].
  ///
  /// - On Server: [path] is a filesystem path.
  /// - On Flutter: [path] is an asset key.
  Future<String> load(String path) => _impl.load(path);
}
