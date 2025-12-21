/// Transparent caching layer for DartZen Identity infrastructure.
///
/// This package provides high-performance, in-memory caching for
/// [IdentityProvider] and [IdentityHooks], allowing for faster
/// discovery and resolution without leaking domain logic.
library;

import 'package:dartzen_identity_domain/dartzen_identity_domain.dart'
    show IdentityProvider, IdentityHooks;

export 'src/cache_backend.dart';
export 'src/cache_config.dart';
export 'src/cache_identity_repository.dart';
export 'src/cache_store.dart';
export 'src/in_memory_cache_store.dart';
export 'src/memorystore_cache_store.dart';
