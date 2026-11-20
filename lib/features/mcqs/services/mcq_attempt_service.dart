import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class McqAttemptService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  McqAttemptService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  /// Legacy result saving is disabled.
  ///
  /// Scores must be calculated by the secure backend.
  @Deprecated(
    'Use McqSessionService.saveCompletedSession instead.',
  )
  Future<String> savePracticeSession({
    required int totalQuestions,
    required int correctAnswers,
    required List<String> questionIds,
    required DateTime startedAt,
    String? subject,
    String? topic,
  }) async {
    throw UnsupportedError(
      'Direct client-side result submission is disabled. '
      'Use the secure MCQ practice session service.',
    );
  }
  /// Watches the signed-in student's practice history.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyAttempts({
    int limit = 50,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(
        'You must be logged in to view your results.',
      );
    }
    if (limit < 1 || limit > 100) {
      throw Exception(
        'The history limit must be between 1 and 100.',
      );
    }
    return _firestore
        .collection('mcq_attempts')
        .where('userId', isEqualTo: user.uid)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots();
  }
  /// Loads one attempt belonging to the signed-in student.
  Future<Map<String, dynamic>?> getMyAttempt(
    String attemptId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(
        'You must be logged in to view this result.',
      );
    }
    final cleanAttemptId = attemptId.trim();
    if (cleanAttemptId.isEmpty) {
      throw Exception('Invalid practice result ID.');
    }
    final document = await _firestore
        .collection('mcq_attempts')
        .doc(cleanAttemptId)
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
