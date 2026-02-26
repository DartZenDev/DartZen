import 'package:dartzen_transport/dartzen_transport.dart';

/// A mock admin transport that returns fake data for the example app.
///
/// Simulates a small set of "users" in memory. Supports query, fetch,
/// create, update, and delete operations keyed by the `admin.*` descriptor
/// ids used by [ZenAdminClient].
class MockAdminTransport {
  final List<Map<String, dynamic>> _users = [
    {'id': '1', 'name': 'Alice', 'email': 'alice@example.com'},
    {'id': '2', 'name': 'Bob', 'email': 'bob@example.com'},
    {'id': '3', 'name': 'Charlie', 'email': 'charlie@example.com'},
  ];

  int _nextId = 4;

  /// Handles a transport-like send call and returns a [TransportResult].
  Future<TransportResult> handle(
    TransportDescriptor descriptor,
    Map<String, dynamic> payload,
  ) async {
    // Simulate network latency.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return switch (descriptor.id) {
      'admin.query' => _query(payload),
      'admin.fetch' => _fetch(payload),
      'admin.create' => _create(payload),
      'admin.update' => _update(payload),
      'admin.delete' => _delete(payload),
      _ => TransportResult.err(
          error: 'Unknown descriptor: ${descriptor.id}',
        ),
    };
  }

  TransportResult _query(Map<String, dynamic> payload) {
    final offset = payload['offset'] as int? ?? 0;
    final limit = payload['limit'] as int? ?? 20;
    final page = _users.skip(offset).take(limit).toList();

    return TransportResult.ok(
      data: <String, dynamic>{
        'items': page,
        'total': _users.length,
        'offset': offset,
        'limit': limit,
      },
    );
  }

  TransportResult _fetch(Map<String, dynamic> payload) {
    final id = payload['id'] as String;
    final user = _users.where((u) => u['id'] == id).firstOrNull;
    if (user == null) {
      return TransportResult.err(error: 'Not found');
    }
    return TransportResult.ok(data: user);
  }

  TransportResult _create(Map<String, dynamic> payload) {
    final data = payload['data'] as Map<String, dynamic>;
    final user = <String, dynamic>{
      'id': '${_nextId++}',
      ...data,
    };
    _users.add(user);
    return TransportResult.ok(data: user);
  }

  TransportResult _update(Map<String, dynamic> payload) {
    final id = payload['id'] as String;
    final data = payload['data'] as Map<String, dynamic>;
    final index = _users.indexWhere((u) => u['id'] == id);
    if (index == -1) {
      return TransportResult.err(error: 'Not found');
    }
    _users[index] = <String, dynamic>{
      'id': id,
      ..._users[index],
      ...data,
    };
    return TransportResult.ok(data: _users[index]);
  }

  TransportResult _delete(Map<String, dynamic> payload) {
    final id = payload['id'] as String;
    _users.removeWhere((u) => u['id'] == id);
    return TransportResult.ok();
  }
}
