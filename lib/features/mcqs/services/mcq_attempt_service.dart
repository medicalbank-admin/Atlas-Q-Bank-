import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class McqAttemptService {
  McqAttemptService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Legacy result saving is disabled.
  ///
  /// Client-submitted scores cannot be trusted.
  /// New practice sessions must use McqSessionService,
  /// which submits answers to the secure backend function.
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
      'Legacy MCQ result submission is disabled. '
      'Please use the secure MCQ practice session service.',
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
  Future<DocumentSnapshot<Map<String, dynamic>>> getMyAttempt(
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
      throw Exception(
        'Invalid practice result ID.',
      );
    }

    final document = await _firestore
        .collection('mcq_attempts')
        .doc(cleanAttemptId)
        .get();

    if (!document.exists) {
      throw Exception(
        'Practice result not found.',
      );
    }

    if (document.data()?['userId'] != user.uid) {
      throw Exception(
        'You are not allowed to view this result.',
      );
    }

    return document;
  }
}
