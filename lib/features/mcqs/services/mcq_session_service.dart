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
  /// Submits answers to the secure backend.
  ///
  /// The client sends question IDs and selected option indexes only.
  /// Correct answers and scores are calculated by the backend.
  Future<String> saveCompletedSession({
    required List<String> questionIds,
    required Map<String, int?> selectedAnswers,
    required DateTime startedAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(
        'Please log in before submitting your MCQ practice.',
      );
    }
    if (questionIds.isEmpty || questionIds.length > 100) {
      throw Exception(
        'A practice session must contain between 1 and 100 questions.',
      );
    }
    if (startedAt.isAfter(DateTime.now())) {
      throw Exception('The practice session start time is invalid.');
    }
    if (DateTime.now().difference(startedAt).inHours > 24) {
      throw Exception('The practice session has expired.');
    }
    if (questionIds.toSet().length != questionIds.length) {
      throw Exception('Duplicate questions are not allowed.');
    }
    final selectedAnswerPayload = <String, dynamic>{};
    for (final questionId in questionIds) {
      if (questionId.trim().isEmpty) {
        throw Exception('A question has an invalid ID.');
      }
      final selectedIndex = selectedAnswers[questionId];
      if (selectedIndex != null &&
          (selectedIndex < 0 || selectedIndex > 4)) {
        throw Exception('An invalid answer was selected.');
      }
      selectedAnswerPayload[questionId] = selectedIndex;
    }
    final callable = _functions.httpsCallable('submitMcqPractice');
    try {
      final response = await callable.call({
        'questionIds': questionIds,
        'selectedAnswers': selectedAnswerPayload,
        'startedAt': startedAt.toIso8601String(),
      });
      if (response.data is! Map) {
        throw Exception('The server returned an invalid response.');
      }
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ??
              'The practice could not be submitted.',
        );
      }
      final attemptId = data['attemptId']?.toString();
      if (attemptId == null || attemptId.isEmpty) {
        throw Exception('The server did not return a valid result ID.');
      }
      return attemptId;
    } on FirebaseFunctionsException catch (error) {
      throw Exception(
        error.message ??
            'Secure practice submission failed. Please try again.',
      );
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
