import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Talks only to the authenticated MCQ Worker. Correct answers never travel
/// to the device until the student's daily response has been submitted.
class DailyChallengeService {
  DailyChallengeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _baseUrl = String.fromEnvironment('MCQ_API_URL');

  Future<Map<String, dynamic>> _request(String path,
      [Map<String, dynamic> body = const {}]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in to start the daily challenge.');
    if (_baseUrl.trim().isEmpty) {
      throw Exception('The secure challenge service is not configured in this app build.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your sign-in could not be verified. Please sign in again.');
    }
    final response = await _client.post(
      Uri.parse('${_baseUrl.trim().replaceAll(RegExp(r'/+$'), '')}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 45));
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      data = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw Exception('The daily challenge service returned an invalid response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message']?.toString() ??
          'The daily challenge could not be loaded. Please try again.');
    }
    return data;
  }

  Future<Map<String, dynamic>> startToday() => _request('/daily/start');
  Future<Map<String, dynamic>> loadStatus() => _request('/daily/status');
  Future<Map<String, dynamic>> submitAnswer(int selectedAnswer) =>
      _request('/daily/submit', {'selectedAnswer': selectedAnswer});
}
