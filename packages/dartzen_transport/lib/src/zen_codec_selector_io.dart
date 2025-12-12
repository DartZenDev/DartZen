import 'zen_transport_header.dart';

/// Native platform (mobile/server/desktop) codec selector.
///
/// On native platforms in production mode, use MessagePack for efficiency.
ZenTransportFormat selectPlatformCodec() => ZenTransportFormat.msgpack;
