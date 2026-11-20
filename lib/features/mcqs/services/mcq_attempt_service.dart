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
  /// Saves a legacy summary-only practice attempt.
  ///
  /// New practice sessions should use McqSessionService.
  /// This method deliberately does not create fabricated
  /// individual answer records.
  Future<String> savePracticeSession({
    required int totalQuestions,
    required int correctAnswers,
    required List<String> questionIds,
    required DateTime startedAt,
    String? subject,
    String? topic,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(
        'You must be logged in to save your results.',
      );
    }
    if (totalQuestions <= 0) {
      throw Exception(
        'The practice session contains no questions.',
      );
    }
    if (correctAnswers < 0 ||
        correctAnswers > totalQuestions) {
      throw Exception(
        'The practice score is invalid.',
      );
    }
    if (questionIds.length != totalQuestions ||
        questionIds.any((id) => id.trim().isEmpty) ||
        questionIds.toSet().length != questionIds.length) {
      throw Exception(
        'The question list is invalid or contains duplicates.',
      );
    }
    if (startedAt.isAfter(DateTime.now())) {
      throw Exception(
        'The session start time is invalid.',
      );
    }
    final incorrectAnswers =
        totalQuestions - correctAnswers;
    final percentage =
        (correctAnswers / totalQuestions) * 100;
    final cleanSubject = subject?.trim() ?? '';
    final cleanTopic = topic?.trim() ?? '';
    final result = <String, dynamic>{
      'userId': user.uid,
      'type': 'legacy_summary',
      'legacySummaryOnly': true,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'unansweredQuestions': 0,
      'percentage': percentage,
      'questionIds': questionIds,
      // No individual answers are available through
      // this legacy method, so do not invent them.
      'answers': <Map<String, dynamic>>[],
      'subject': cleanSubject,
      'topic': cleanTopic,
      'subjects': cleanSubject.isEmpty
          ? <String>[]
          : <String>[cleanSubject],
      'topics': cleanTopic.isEmpty
          ? <String>[]
          : <String>[cleanTopic],
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    final document = await _firestore
        .collection('mcq_attempts')
        .add(result);
    return document.id;
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
        'You must be logged in to view your results.',
      );
    }
    if (attemptId.trim().isEmpty) {
      throw Exception(
        'Invalid practice result ID.',
      );
    }
    final document = await _firestore
        .collection('mcq_attempts')
        .doc(attemptId)
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
