import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:zen_demo_contracts/zen_demo_contracts.dart';

/// HTTP client for ZenDemo API.
class ZenDemoApiClient {
  /// Creates a [ZenDemoApiClient] with the given [baseUrl].
  ZenDemoApiClient({required this.baseUrl});

  /// The base URL of the ZenDemo API server.
  final String baseUrl;

  /// Sends a ping request to the server.
  ///
  /// Returns a [PingContract] with the server's response.
  /// Throws an [Exception] if the request fails.
  Future<PingContract> ping({required String language}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ping?lang=$language'),
    );

    if (response.statusCode != 200) {
      throw Exception('Ping failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PingContract.fromJson(json);
  }

  /// Gets the user profile from the server.
  ///
  /// Requires Firebase authentication. Returns a [ProfileContract] with the user's profile data.
  /// Throws an [Exception] if authentication fails or the request fails.
  Future<ProfileContract> getProfile({
    required String userId,
    required String language,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('No authentication token available');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile/$userId?lang=$language'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ProfileContract.fromJson(json);
  }

  /// Gets the terms of service from the server.
  ///
  /// Returns a [TermsContract] with the terms content.
  /// Throws an [Exception] if the request fails.
  Future<TermsContract> getTerms({required String language}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/terms?lang=$language'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load terms: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return TermsContract.fromJson(json);
  }
}
