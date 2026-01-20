// ignore_for_file: avoid_print

import 'dart:async';

import 'package:dartzen_ai/src/models/ai_config.dart';
import 'package:dartzen_ai/src/server/ai_budget_enforcer.dart';
import 'package:dartzen_ai/src/server/ai_usage_store_cache.dart';
import 'package:dartzen_cache/dartzen_cache.dart';

/// Small runnable example that wires an in-memory `CacheAIUsageStore` into
/// `AIBudgetEnforcer` for local development and demonstration purposes.
Future<void> main() async {
  // Use the default in-memory cache for examples and tests.
  final cache = CacheFactory.create(const CacheConfig());

  // Create the usage store using the existing client instance.
  final store = CacheAIUsageStore.withClient(
    cache,
    flushInterval: const Duration(milliseconds: 200),
  );

  // Wire into the budget enforcer.
  final enforcer = AIBudgetEnforcer(
    config: AIBudgetConfig(),
    usageTracker: store,
  );

  print('Initial global usage: ${store.getGlobalUsage()}');

  // Record some usage and let the flush persist it.
  enforcer.recordUsage(AIMethod.textGeneration, 2.0);
  print('Recorded 2.0 cost to textGeneration (in-memory surface).');

  await Future<void>.delayed(const Duration(milliseconds: 350));

  // Verify cache contains the value (in-memory cache used by example)
  final now = DateTime.now().toUtc();
  final suffix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final key = 'dartzen:ai:usage:textGeneration:$suffix';
  final persisted = await cache.get<double>(key);
  print('Persisted value from cache: $persisted');

  // Clean up
  await store.close();
}
