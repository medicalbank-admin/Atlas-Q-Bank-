import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
class McqSessionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  McqSessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');
  /// Starts a server-timed session and receives its fixed question list.
  Future<Map<String, dynamic>> startSession({String? examSetId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in before starting practice.');
    final callable = _functions.httpsCallable('startMcqPractice');
    try {
      final response = await callable.call({
        if (examSetId != null && examSetId.trim().isNotEmpty)
          'examSetId': examSetId.trim(),
      });
      if (response.data is! Map) throw Exception('The server returned an invalid session.');
      final data = Map<String, dynamic>.from(response.data as Map);
      final ids = data['questionIds'];
      if (data['success'] != true ||
          data['sessionId'] is! String ||
          ids is! List ||
          ids.isEmpty ||
          data['durationMinutes'] is! num) {
        throw Exception(data['message']?.toString() ?? 'The practice session could not be started.');
      }
      return {
        'sessionId': data['sessionId'],
        'questionIds': ids.map((id) => id.toString()).toList(),
        'durationMinutes': (data['durationMinutes'] as num).toInt(),
        'expiresAt': data['expiresAt']?.toString() ?? '',
      };
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? 'Unable to start practice. Please try again.');
    }
  }

  /// Sends only selected option indexes. The server owns the session,
  /// timer, question list, answer keys and scoring.
  Future<String> saveCompletedSession({
    required String sessionId,
    required Map<String, int?> selectedAnswers,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('Please log in before submitting your practice.');
    }
    if (sessionId.trim().isEmpty) throw Exception('The practice session is invalid.');
    final callable = _functions.httpsCallable('submitMcqPractice');
    try {
      final response = await callable.call({
        'sessionId': sessionId.trim(),
        'selectedAnswers': selectedAnswers,
      });
      if (response.data is! Map) throw Exception('The server returned an invalid result.');
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'The practice could not be submitted.');
      }
      final attemptId = data['attemptId']?.toString();
      if (attemptId == null || attemptId.isEmpty) {
        throw Exception('The server did not return a valid result ID.');
      }
      return attemptId;
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? 'Secure practice submission failed. Please try again.');
    }
  }
  /// Retrieves one practice session belonging to the signed-in student.
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
    if (!document.exists) {
      return null;
    }
    final data = document.data();
    if (data == null || data['userId'] != user.uid) {
      return null;
    }
    return {
      ...data,
      'id': document.id,
    };
  }
}
