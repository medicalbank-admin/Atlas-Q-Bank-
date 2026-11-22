import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

class McqSessionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;

  // Set by the GitHub Actions build from the repository variable MCQ_API_URL.
  static const String _apiBaseUrl = String.fromEnvironment('MCQ_API_URL');

  McqSessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in before continuing.');
    if (_apiBaseUrl.trim().isEmpty) {
      throw Exception(
        'The secure MCQ service is not configured yet. Please try again after the next app update.',
      );
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your sign-in could not be verified. Please sign in again.');
    }

    final base = _apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base$endpoint');
    final http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw Exception('The secure MCQ service could not be reached. Please check your internet connection and try again.');
    }

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      data = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw Exception('The secure MCQ service returned an invalid response.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(
        data['message']?.toString() ??
            'The MCQ request could not be completed. Please try again.',
      );
    }
    return data;
  }

  /// Starts a server-timed session and receives its fixed question list.
  Future<Map<String, dynamic>> startSession({String? examSetId}) async {
    final payload = <String, dynamic>{
      if (examSetId != null && examSetId.trim().isNotEmpty)
        'examSetId': examSetId.trim(),
    };
    final data = await _post('/start', payload);
    final ids = data['questionIds'];
    if (data['sessionId'] is! String ||
        ids is! List ||
        ids.isEmpty ||
        data['durationMinutes'] is! num) {
      throw Exception('The server returned an invalid practice session.');
    }
    return {
      'sessionId': data['sessionId'],
      'questionIds': ids.map((id) => id.toString()).toList(),
      'durationMinutes': (data['durationMinutes'] as num).toInt(),
      'expiresAt': data['expiresAt']?.toString() ?? '',
    };
  }

  /// Sends selected option indexes. The Worker owns timing, answer keys and scoring.
  Future<String> saveCompletedSession({
    required String sessionId,
    required Map<String, int?> selectedAnswers,
  }) async {
    if (sessionId.trim().isEmpty) {
      throw Exception('The practice session is invalid.');
    }
    final data = await _post('/submit', {
      'sessionId': sessionId.trim(),
      'selectedAnswers': selectedAnswers,
    });
    final attemptId = data['attemptId']?.toString();
    if (attemptId == null || attemptId.isEmpty) {
      throw Exception('The server did not return a valid result ID.');
    }
    return attemptId;
  }

  /// Retrieves one practice result belonging to the signed-in student.
  Future<Map<String, dynamic>?> getMySession(String sessionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please log in to view your MCQ result.');
    }
    if (sessionId.trim().isEmpty) {
      throw Exception('Invalid practice session ID.');
    }
    final document = await _firestore
        .collection('mcq_attempts')
        .doc(sessionId)
        .get();
    if (!document.exists) return null;
    final data = document.data();
    if (data == null || data['userId'] != user.uid) return null;
    return {...data, 'id': document.id};
  }
}
