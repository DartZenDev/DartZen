import 'package:dartzen_transport/dartzen_transport.dart';

import 'zen_admin_page.dart';
import 'zen_admin_query.dart';

/// Client for admin CRUD operations via the DartZen transport layer.
///
/// All communication goes through [ZenTransport] using descriptors.
/// No direct HTTP calls, no raw JSON encoding, no Uri construction.
///
/// Route conventions encoded in payloads:
/// - `POST   /v1/admin/{resource}/query`
/// - `GET    /v1/admin/{resource}/{id}`
/// - `POST   /v1/admin/{resource}`
/// - `PATCH  /v1/admin/{resource}/{id}`
/// - `DELETE /v1/admin/{resource}/{id}`
class ZenAdminClient {
  final ZenTransport _transport;

  /// Creates a [ZenAdminClient] backed by the given [transport].
  ZenAdminClient({required ZenTransport transport}) : _transport = transport;

  static const _queryDescriptor = TransportDescriptor(
    id: 'admin.query',
    channel: TransportChannel.http,
    reliability: TransportReliability.atMostOnce,
  );

  static const _fetchDescriptor = TransportDescriptor(
    id: 'admin.fetch',
    channel: TransportChannel.http,
    reliability: TransportReliability.atMostOnce,
  );

  static const _createDescriptor = TransportDescriptor(
    id: 'admin.create',
    channel: TransportChannel.http,
    reliability: TransportReliability.atLeastOnce,
  );

  static const _updateDescriptor = TransportDescriptor(
    id: 'admin.update',
    channel: TransportChannel.http,
    reliability: TransportReliability.atLeastOnce,
  );

  static const _deleteDescriptor = TransportDescriptor(
    id: 'admin.delete',
    channel: TransportChannel.http,
    reliability: TransportReliability.atLeastOnce,
  );

  /// Queries a paginated list of records for [resourceName].
  Future<ZenAdminPage<Map<String, dynamic>>> query(
    String resourceName,
    ZenAdminQuery query,
  ) async {
    final result = await _transport.send(
      _queryDescriptor,
      payload: <String, dynamic>{
        'resource': resourceName,
        'path': '/v1/admin/$resourceName/query',
        'offset': query.offset,
        'limit': query.limit,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Query failed');
    }

    final data = result.data as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>;
    final items = rawItems
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();

    return ZenAdminPage<Map<String, dynamic>>(
      items: items,
      total: data['total'] as int,
      offset: data['offset'] as int,
      limit: data['limit'] as int,
    );
  }

  /// Fetches a single record by [id] for [resourceName].
  Future<Map<String, dynamic>> fetchById(String resourceName, String id) async {
    final result = await _transport.send(
      _fetchDescriptor,
      payload: <String, dynamic>{
        'resource': resourceName,
        'path': '/v1/admin/$resourceName/$id',
        'id': id,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Fetch failed');
    }

    return Map<String, dynamic>.from(result.data as Map<dynamic, dynamic>);
  }

  /// Creates a new record for [resourceName].
  Future<void> create(String resourceName, Map<String, dynamic> data) async {
    final result = await _transport.send(
      _createDescriptor,
      payload: <String, dynamic>{
        'resource': resourceName,
        'path': '/v1/admin/$resourceName',
        'data': data,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Create failed');
    }
  }

  /// Updates an existing record by [id] for [resourceName].
  Future<void> update(
    String resourceName,
    String id,
    Map<String, dynamic> data,
  ) async {
    final result = await _transport.send(
      _updateDescriptor,
      payload: <String, dynamic>{
        'resource': resourceName,
        'path': '/v1/admin/$resourceName/$id',
        'id': id,
        'data': data,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Update failed');
    }
  }

  /// Deletes a record by [id] for [resourceName].
  Future<void> delete(String resourceName, String id) async {
    final result = await _transport.send(
      _deleteDescriptor,
      payload: <String, dynamic>{
        'resource': resourceName,
        'path': '/v1/admin/$resourceName/$id',
        'id': id,
      },
    );

    if (!result.success) {
      throw ZenTransportException(result.error ?? 'Delete failed');
    }
  }
}
