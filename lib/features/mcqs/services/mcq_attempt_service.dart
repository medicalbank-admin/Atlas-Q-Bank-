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

  /// Saves a completed MCQ practice session.
  ///
  /// [questionIds] contains the IDs of the questions attempted.
  /// [startedAt] is the time the practice session began.
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
      throw Exception('You must be logged in to save your results.');
    }

    if (totalQuestions <= 0) {
      throw Exception('The practice session contains no questions.');
    }

    if (correctAnswers < 0 || correctAnswers > totalQuestions) {
      throw Exception('The practice score is invalid.');
    }

    if (questionIds.length != totalQuestions) {
      throw Exception('The question list does not match the session total.');
    }

    final incorrectAnswers = totalQuestions - correctAnswers;
    final percentage =
        (correctAnswers / totalQuestions * 100).round();

    final now = DateTime.now();

    final result = <String, dynamic>{
      'userId': user.uid,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'percentage': percentage,
      'questionIds': questionIds,
      'subject': subject ?? '',
      'topic': topic ?? '',
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': Timestamp.fromDate(now),
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'practice',
    };

    final document = await _firestore
        .collection('mcq_attempts')
        .add(result);

    return document.id;
  }

  /// Loads the signed-in student's previous practice sessions.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyAttempts({
    int limit = 50,
  }) {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to view your results.');
    }

    return _firestore
        .collection('mcq_attempts')
        .where('userId', isEqualTo: user.uid)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Loads one saved attempt belonging to the signed-in student.
  Future<DocumentSnapshot<Map<String, dynamic>>> getMyAttempt(
    String attemptId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to view your results.');
    }

    final document = await _firestore
        .collection('mcq_attempts')
        .doc(attemptId)
        .get();

    if (!document.exists) {
      throw Exception('Practice result not found.');
    }

    if (document.data()?['userId'] != user.uid) {
      throw Exception('You are not allowed to view this result.');
    }

    return document;
  }
}
