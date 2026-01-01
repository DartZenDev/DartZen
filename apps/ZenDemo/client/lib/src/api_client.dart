import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:zen_demo_contracts/zen_demo_contracts.dart';

/// HTTP client for ZenDemo API.
class ZenDemoApiClient {
  ZenDemoApiClient({required this.baseUrl});

  final String baseUrl;

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
