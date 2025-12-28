// ignore_for_file: avoid_print

import 'package:dartzen_cache/dartzen_cache.dart';

/// Example demonstrating cache usage.
///
/// The cache automatically selects the appropriate backend:
/// - Development (dzIsPrd == false): In-memory cache
/// - Production (dzIsPrd == true): GCP Memorystore (Redis)
///
/// To test production mode, compile with: -DdZ_ENV=prd
Future<void> cacheExample() async {
  print('=== DartZen Cache Example ===\n');

  // Create cache configuration
  // In development: uses in-memory cache (host/port ignored)
  // In production: uses Memorystore with the specified host/port
  const config = CacheConfig(
    defaultTtl: Duration(minutes: 10),
    memorystoreHost: 'memorystore.example.com',
    memorystorePort: 6379,
  );

  final cache = CacheFactory.create(config);

  try {
    // Store a simple value
    await cache.set('greeting', 'Hello, DartZen!');
    final greeting = await cache.get<String>('greeting');
    print('Greeting: $greeting');

    // Store a complex object
    final user = {
      'id': '123',
      'name': 'Alice',
      'role': 'admin',
      'active': true,
    };
    await cache.set('user:123', user);
    final cachedUser = await cache.get<Map<String, dynamic>>('user:123');
    print('User: $cachedUser');

    // Store with custom TTL
    await cache.set('temp:token', 'xyz', ttl: const Duration(seconds: 5));
    print('Token stored with 5s TTL');

    // Verify token exists
    var token = await cache.get<String>('temp:token');
    print('Token (immediately): $token');

    // Wait for expiration
    print('Waiting for token to expire...');
    await Future<void>.delayed(const Duration(seconds: 6));
    token = await cache.get<String>('temp:token');
    print('Token (after 6s): $token\n');

    // Delete a key
    await cache.delete('greeting');
    final deletedGreeting = await cache.get<String>('greeting');
    print('Greeting after delete: $deletedGreeting');

    // Clear all
    await cache.clear();
    final clearedUser = await cache.get<Map<String, dynamic>>('user:123');
    print('User after clear: $clearedUser\n');

    // Close connection (only needed for Memorystore)
    if (cache is MemorystoreCache) {
      await cache.close();
      print('Connection closed');
    }
  } on CacheConnectionError catch (e) {
    print('Connection error: ${e.message}');
    if (e.cause != null) {
      print('Caused by: ${e.cause}');
    }
  } catch (e) {
    print('Unexpected error: $e\n');
  }
}

/// Example demonstrating error handling.
Future<void> errorHandlingExample() async {
  print('=== Error Handling Example ===\n');

  final cache = CacheFactory.create(const CacheConfig());

  // Serialization error
  try {
    await cache.set('invalid', () => 'function');
  } on CacheSerializationError catch (e) {
    print('Caught serialization error: ${e.message}');
    print('Key: ${e.key}\n');
  }

  // Type mismatch error
  await cache.set('number', 42);
  try {
    await cache.get<String>('number');
  } on CacheSerializationError catch (e) {
    print('Caught type mismatch error: ${e.message}');
    print('Key: ${e.key}\n');
  }
}

void main() async {
  await cacheExample();
  await errorHandlingExample();
}
