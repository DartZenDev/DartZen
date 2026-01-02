import 'dart:convert';

import 'package:http/http.dart' as http;

import '../converters/firestore_converters.dart';
import '../firestore_types.dart';
import 'firestore_config.dart';

/// Client for interacting with Firestore via REST API.
final class FirestoreRestClient {
  final FirestoreConfig _config;
  final http.Client _httpClient;

  /// Creates a [FirestoreRestClient].
  FirestoreRestClient({
    required FirestoreConfig config,
    http.Client? httpClient,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client();

  /// Gets the project ID.
  String get projectId => _config.projectId!;

  /// Gets the base URL for Firestore REST API.
  String get _baseUrl {
    if (_config.isProduction) {
      return 'https://firestore.googleapis.com/v1/projects/${_config.projectId}/databases/(default)/documents';
    } else {
      return 'http://${_config.emulatorHost}:${_config.emulatorPort}/v1/projects/${_config.projectId}/databases/(default)/documents';
    }
  }

  /// Retrieves a document by its path.
  Future<ZenFirestoreDocument> getDocument(
    String path, {
    String? transactionId,
  }) async {
    final queryParams = transactionId != null
        ? '?transaction=$transactionId'
        : '';
    final url = Uri.parse('$_baseUrl/$path$queryParams');
    final response = await _httpClient.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _mapToDocument(json);
    } else if (response.statusCode == 404) {
      return ZenFirestoreDocument(id: path.split('/').last, path: path);
    } else {
      throw http.ClientException(
        'Failed to get document: ${response.statusCode} ${response.body}',
        url,
      );
    }
  }

  /// Updates a document partially.
  Future<void> patchDocument(String path, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/$path');
    final fields = FirestoreConverters.dataToFields(data);
    final body = jsonEncode({'fields': fields});

    // Determine updateMask (fields to patch)
    final queryParams = data.keys
        .map((k) => 'updateMask.fieldPaths=$k')
        .join('&');
    final patchUrl = Uri.parse('$url?$queryParams');

    final response = await _httpClient.patch(
      patchUrl,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to patch document: ${response.statusCode} ${response.body}',
        patchUrl,
      );
    }
  }

  /// Starts a new transaction.
  Future<String> beginTransaction() async {
    final url = Uri.parse('$_baseUrl:beginTransaction');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['transaction'] as String;
    } else {
      throw http.ClientException(
        'Failed to begin transaction: ${response.statusCode} ${response.body}',
        url,
      );
    }
  }

  /// Commits a set of writes.
  Future<void> commit(
    List<Map<String, dynamic>> writes, {
    String? transactionId,
  }) async {
    final commitUrl = _config.isProduction
        ? 'https://firestore.googleapis.com/v1/projects/${_config.projectId}/databases/(default):commit'
        : 'http://${_config.emulatorHost}:${_config.emulatorPort}/v1/projects/${_config.projectId}/databases/(default)/documents:commit';

    final response = await _httpClient.post(
      Uri.parse(commitUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'writes': writes,
        if (transactionId != null) 'transaction': transactionId,
      }),
    );

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Failed to commit writes: ${response.statusCode} ${response.body}',
        Uri.parse(commitUrl),
      );
    }
  }

  ZenFirestoreDocument _mapToDocument(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final path = name.split('/documents/').last;
    final id = path.split('/').last;
    final fields = json['fields'] as Map<String, dynamic>? ?? {};

    return ZenFirestoreDocument(
      id: id,
      path: path,
      data: FirestoreConverters.fieldsToData(fields),
      createTime: json.containsKey('createTime')
          ? FirestoreConverters.rfc3339ToZenTimestamp(
              json['createTime'] as String,
            )
          : null,
      updateTime: json.containsKey('updateTime')
          ? FirestoreConverters.rfc3339ToZenTimestamp(
              json['updateTime'] as String,
            )
          : null,
    );
  }

  /// Closes the underlying HTTP client.
  void close() {
    _httpClient.close();
  }
}
