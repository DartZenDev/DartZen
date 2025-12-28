import 'dart:convert';
import 'dart:io';

import 'cache_client.dart';
import 'cache_errors.dart';

/// GCP Memorystore (Redis) cache implementation.
///
/// This implementation connects to a Redis server and uses the Redis protocol
/// for cache operations. It supports:
/// - SET with TTL
/// - GET
/// - DEL
/// - FLUSHDB (clear)
///
/// Connection lifecycle is explicit and observable through error handling.
///
/// Example:
/// ```dart
/// final cache = MemorystoreCache(
///   host: '10.0.0.3',
///   port: 6379,
///   useTls: true,
///   defaultTtl: Duration(hours: 1),
/// );
/// await cache.set('key', {'data': 'value'});
/// ```
class MemorystoreCache implements CacheClient {
  /// Redis server host address.
  final String host;

  /// Redis server port.
  final int port;

  /// Whether to use TLS for the connection.
  final bool useTls;

  /// Default time-to-live for cache entries.
  final Duration? defaultTtl;

  Socket? _socket;
  bool _connected = false;

  /// Creates a Memorystore cache client.
  ///
  /// The client lazily connects to Redis on the first operation.
  MemorystoreCache({
    required this.host,
    required this.port,
    required this.useTls,
    this.defaultTtl,
  });

  /// Establishes connection to Redis server.
  Future<void> _ensureConnected() async {
    if (_connected && _socket != null) {
      return;
    }

    try {
      if (useTls) {
        _socket = await SecureSocket.connect(
          host,
          port,
          timeout: const Duration(seconds: 5),
        );
      } else {
        _socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 5),
        );
      }
      _connected = true;
    } catch (e, stack) {
      throw CacheConnectionError(
        'Failed to connect to Redis at $host:$port',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// Sends a Redis command and reads the response.
  Future<String> _sendCommand(List<String> args) async {
    await _ensureConnected();

    final socket = _socket;
    if (socket == null) {
      throw const CacheConnectionError('Socket is not initialized');
    }

    try {
      // Build Redis protocol message (RESP)
      final buffer = StringBuffer();
      buffer.write('*${args.length}\r\n');
      for (final arg in args) {
        final bytes = utf8.encode(arg);
        buffer.write('\$${bytes.length}\r\n');
        buffer.write(arg);
        buffer.write('\r\n');
      }

      socket.write(buffer.toString());
      await socket.flush();

      // Read response
      final response = await socket.first;
      return utf8.decode(response);
    } catch (e, stack) {
      _connected = false;
      throw CacheConnectionError(
        'Redis command failed',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> set(String key, Object value, {Duration? ttl}) async {
    try {
      final encoded = jsonEncode(value);
      final effectiveTtl = ttl ?? defaultTtl;

      if (effectiveTtl != null) {
        final seconds = effectiveTtl.inSeconds;
        await _sendCommand(['SETEX', key, seconds.toString(), encoded]);
      } else {
        await _sendCommand(['SET', key, encoded]);
      }
    } on JsonUnsupportedObjectError catch (e, stack) {
      throw CacheSerializationError(
        'Value is not JSON-serializable',
        key,
        cause: e,
        stackTrace: stack,
      );
    } on CacheConnectionError {
      rethrow;
    } catch (e, stack) {
      throw CacheOperationError(
        'Failed to set cache entry',
        'set',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<T?> get<T>(String key) async {
    try {
      final response = await _sendCommand(['GET', key]);

      // Redis returns "$-1\r\n" for null/missing keys
      if (response.startsWith(r'$-1')) {
        return null;
      }

      // Parse bulk string response
      final lines = response.split('\r\n');
      if (lines.length < 2) {
        return null;
      }

      final value = lines[1];
      final decoded = jsonDecode(value);

      if (decoded is! T) {
        throw CacheSerializationError(
          'Stored value type ${decoded.runtimeType} does not match requested type $T',
          key,
        );
      }

      return decoded;
    } on CacheConnectionError {
      rethrow;
    } on CacheSerializationError {
      rethrow;
    } catch (e, stack) {
      throw CacheOperationError(
        'Failed to get cache entry',
        'get',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _sendCommand(['DEL', key]);
    } on CacheConnectionError {
      rethrow;
    } catch (e, stack) {
      throw CacheOperationError(
        'Failed to delete cache entry',
        'delete',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _sendCommand(['FLUSHDB']);
    } on CacheConnectionError {
      rethrow;
    } catch (e, stack) {
      throw CacheOperationError(
        'Failed to clear cache',
        'clear',
        cause: e,
        stackTrace: stack,
      );
    }
  }

  /// Closes the Redis connection.
  ///
  /// This method should be called when the cache is no longer needed
  /// to properly release resources.
  Future<void> close() async {
    await _socket?.close();
    _socket = null;
    _connected = false;
  }
}
