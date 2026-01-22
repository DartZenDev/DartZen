import 'dart:async';

import 'package:dartzen_cache/dartzen_cache.dart';

import 'ai_budget_enforcer.dart';

/// Cache-backed `AIUsageStore` implementation using `dartzen_cache`'s
/// `CacheClient` for persistence. Keeps an in-memory synchronous surface for
/// low-latency reads while flushing updates asynchronously to the cache.
final class CacheAIUsageStore implements AIUsageStore {
  /// Creates a store that wraps an existing `CacheClient` instance.
  CacheAIUsageStore.withClient(
    this._cache, {
    Duration flushInterval = const Duration(seconds: 10),
  }) : _flushInterval = flushInterval,
       _methodUsage = {},
       _globalUsage = 0.0 {
    _startFlushTimer();
  }

  /// Convenience factory that builds a `CacheClient` using `CacheFactory`.
  ///
  /// `config` controls memorystore vs in-memory behavior; in production
  /// `CacheFactory` will return a `MemorystoreCache` (Redis-backed).
  static Future<CacheAIUsageStore> connect(
    CacheConfig config, {
    Duration flushInterval = const Duration(seconds: 10),
  }) async {
    final cache = CacheFactory.create(config);
    final store = CacheAIUsageStore.withClient(
      cache,
      flushInterval: flushInterval,
    );
    await store._loadFromCache();
    return store;
  }

  final CacheClient _cache;
  final Duration _flushInterval;

  final Map<String, double> _methodUsage;
  double _globalUsage;

  Timer? _flushTimer;
  bool _closed = false;

  String _nsKey(String base) => 'dartzen:ai:usage:$base:${_yearMonthSuffix()}';

  String _yearMonthSuffix() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _startFlushTimer() {
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      unawaited(_flushToCache());
    });
  }

  Future<void> _loadFromCache() async {
    try {
      final globalKey = _nsKey('global');
      final mkeys = ['textGeneration', 'embeddings', 'classification'];

      final futures = <Future<void>>[];
      futures.add(
        _cache
            .get<double>(globalKey)
            .then((v) {
              _globalUsage = v ?? 0.0;
            })
            .catchError((_) {
              _globalUsage = 0.0;
            }),
      );

      for (final k in mkeys) {
        final mk = _nsKey(k);
        futures.add(
          _cache
              .get<double>(mk)
              .then((v) {
                _methodUsage[k] = v ?? 0.0;
              })
              .catchError((_) {
                _methodUsage[k] = 0.0;
              }),
        );
      }

      await Future.wait(futures);
    } catch (_) {
      // Best-effort; proceed with zeroed in-memory counters
    }
  }

  Future<void> _flushToCache() async {
    if (_closed) return;
    try {
      final seconds = _secondsUntilMonthEnd();
      final ttl = Duration(seconds: seconds);

      await _cache.set(_nsKey('global'), _globalUsage, ttl: ttl);

      for (final entry in _methodUsage.entries) {
        await _cache.set(_nsKey(entry.key), entry.value, ttl: ttl);
      }
    } catch (_) {
      // Swallow errors; persistence is best-effort so runtime isn't impacted.
    }
  }

  int _secondsUntilMonthEnd() {
    final now = DateTime.now().toUtc();
    final nextMonth = (now.month == 12)
        ? DateTime(now.year + 1).toUtc()
        : DateTime(now.year, now.month + 1).toUtc();
    return nextMonth.difference(now).inSeconds + 60; // slack 60s
  }

  // --- AIUsageStore implementation (synchronous surface backed by memory) ---
  @override
  double getGlobalUsage() => _globalUsage;

  @override
  double getMethodUsage(String method) => _methodUsage[method] ?? 0.0;

  @override
  void recordUsage(String method, double cost) {
    _methodUsage[method] = (_methodUsage[method] ?? 0.0) + cost;
    _globalUsage += cost;
    unawaited(_flushToCache());
  }

  @override
  void reset() {
    _methodUsage.clear();
    _globalUsage = 0.0;
    unawaited(_resetCacheKeys());
  }

  Future<void> _resetCacheKeys() async {
    try {
      await _cache.set(_nsKey('global'), 0.0);
      await _cache.set(_nsKey('textGeneration'), 0.0);
      await _cache.set(_nsKey('embeddings'), 0.0);
      await _cache.set(_nsKey('classification'), 0.0);
    } catch (_) {}
  }

  /// Closes the usage store, flushes any pending metrics to the cache,
  /// cancels background timers, and releases any underlying cache
  /// resources (for example a `MemorystoreCache` connection).
  ///
  /// This is best-effort and swallows errors from the underlying cache
  /// close operation so callers can call `close()` during shutdown
  /// without failing the shutdown sequence.
  Future<void> close() async {
    _closed = true;
    _flushTimer?.cancel();
    await _flushToCache();
    try {
      if (_cache is MemorystoreCache) {
        await _cache.close();
      }
    } catch (_) {}
  }
}

/// Helper that intentionally ignores a `Future` result.
///
/// Use this when you want to fire-and-forget an asynchronous operation
/// and intentionally do not await its completion. This avoids analyzer
/// warnings about unawaited futures while making the intention explicit.
void unawaited(Future<void> f) {}
