import 'package:dartzen_core/dartzen_core.dart';

import 'zen_codec_selector_stub.dart'
    if (dart.library.html) 'zen_codec_selector_web.dart'
    if (dart.library.io) 'zen_codec_selector_io.dart';
import 'zen_transport_header.dart';

/// Selects the appropriate transport format based on environment and platform.
///
/// The selection logic follows these rules:
/// - In DEV mode: always use JSON
/// - In PRD mode on web: use JSON
/// - In PRD mode on native (mobile/server/desktop): use MessagePack
///
/// This function uses conditional imports to ensure proper treeshaking.
ZenTransportFormat selectDefaultCodec() {
  if (dzIsDev) {
    return ZenTransportFormat.json;
  }

  // Platform-specific selection in PRD mode
  return selectPlatformCodec();
}
