import 'package:dartzen_core/dartzen_core.dart';
import 'package:redis/redis.dart';

import 'cache_store.dart';

/// A Memorystore-backed implementation of [CacheStore] for production.
///
/// Uses GCP Memorystore (Redis protocol) as the production cache backend.
/// This file isolates `package:redis` imports to ensure tree-shaking
/// effectively removes it in development builds.
class MemorystoreCacheStore implements CacheStore {
  /// Creates a [MemorystoreCacheStore] with the specified [host] and [port].
  MemorystoreCacheStore({this.host = 'localhost', this.port = 6379});

  /// The Redis host.
  final String host;

  /// The Redis port.
  final int port;

  @override
  Future<ZenResult<String?>> get(String key) async {
    try {
      final conn = RedisConnection();
      final command = await conn.connect(host, port);
      final response = await command.get(key);
      await conn.close();

      if (response == null) return const ZenResult.ok(null);

      return ZenResult.ok(response as String);
    } catch (e) {
      return ZenResult.err(ZenUnknownError(e.toString()));
    }
  }

  @override
  Future<ZenResult<void>> set(String key, String value, Duration ttl) async {
    try {
      final conn = RedisConnection();
      final command = await conn.connect(host, port);

      await command.send_object(['SETEX', key, ttl.inSeconds, value]);
      await conn.close();

      return const ZenResult.ok(null);
    } catch (e) {
      return ZenResult.err(ZenUnknownError(e.toString()));
    }
  }

  @override
  Future<ZenResult<void>> delete(String key) async {
    try {
      final conn = RedisConnection();
      final command = await conn.connect(host, port);
      await command.send_object(['DEL', key]);
      await conn.close();
      return const ZenResult.ok(null);
    } catch (e) {
      return ZenResult.err(ZenUnknownError(e.toString()));
    }
  }
}
