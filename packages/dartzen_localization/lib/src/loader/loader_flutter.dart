import 'dart:async';

import 'package:flutter/services.dart';

import 'loader_stub.dart';

/// Loads assets on Flutter (Mobile, Web, Desktop).
class ZenLocalizationLoaderFlutter implements ZenLocalizationLoaderImpl {
  @override
  Future<String> load(String path) async {
    // Flutter assets are typically loaded via rootBundle.
    // The path here is assumed to be an asset key.
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      // Map Flutter asset error to something generic or rethrow?
      // Service will catch it.
      rethrow;
    }
  }
}

/// Returns the correct loader implementation.
ZenLocalizationLoaderImpl getLoader() => ZenLocalizationLoaderFlutter();
