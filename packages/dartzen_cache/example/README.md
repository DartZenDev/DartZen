# DartZen Cache Example

This directory contains example code demonstrating the usage of `dartzen_cache`.

## Running the Example

```bash
cd example
dart run main.dart
```

## Examples Included

1. **In-Memory Cache** — Basic operations with TTL
2. **Error Handling** — Handling serialization and type errors
3. **Memorystore (Redis)** — Commented out by default, requires Redis server

## Memorystore Example

To run the Memorystore example:

1. Start a local Redis server:
   ```bash
   redis-server
   ```

2. Uncomment the `memorystoreExample()` call in `main.dart`

3. Run the example:
   ```bash
   dart run main.dart
   ```
