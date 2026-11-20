import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mcq_model.dart';

class McqSessionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  McqSessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Saves a completed MCQ practice session.
  ///
  /// Unanswered questions are allowed and saved with:
  /// selectedAnswer: null
  /// isAnswered: false
  /// isCorrect: false
  ///
  /// The percentage is calculated against ALL questions.
  Future<String> saveCompletedSession({
    required List<McqModel> questions,
    required Map<String, int?> selectedAnswers,
    required DateTime startedAt,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in before saving your MCQ result.');
    }

    if (questions.isEmpty) {
      throw Exception('There are no questions in this practice session.');
    }

    final questionIds = <String>{};

    int correctAnswers = 0;
    int incorrectAnswers = 0;
    int unansweredQuestions = 0;

    final answerSnapshots = <Map<String, dynamic>>[];

    for (final question in questions) {
      if (question.id.isEmpty) {
        throw Exception('A question has an invalid ID.');
      }

      if (!questionIds.add(question.id)) {
        throw Exception('Duplicate questions were found in this session.');
      }

      if (question.options.length < 4 ||
          question.options.length > 5) {
        throw Exception(
          'Question "${question.id}" has an invalid number of options.',
        );
      }

      if (!question.hasValidAnswer) {
        throw Exception(
          'Question "${question.id}" has an invalid correct answer.',
        );
      }

      final selectedIndex = selectedAnswers[question.id];

      if (selectedIndex != null &&
          (selectedIndex < 0 ||
              selectedIndex >= question.options.length)) {
        throw Exception(
          'An invalid answer was selected for question "${question.id}".',
        );
      }

      final isAnswered = selectedIndex != null;
      final isCorrect =
          isAnswered && selectedIndex == question.correctAnswer;

      if (!isAnswered) {
        unansweredQuestions++;
      } else if (isCorrect) {
        correctAnswers++;
      } else {
        incorrectAnswers++;
      }

      final correctLetter =
          String.fromCharCode(65 + question.correctAnswer);

      final selectedLetter = selectedIndex == null
          ? null
          : String.fromCharCode(65 + selectedIndex);

      answerSnapshots.add({
        'questionId': question.id,
        'question': question.question,
        'options': question.options,
        'selectedAnswer': selectedLetter,
        'correctAnswer': correctLetter,
        'isAnswered': isAnswered,
        'isCorrect': isCorrect,
        'explanation': question.explanation,
        'subject': question.subject,
        'topic': question.topic,
        'difficulty': question.difficulty,
        'reference': question.reference,
      });
    }

    final totalQuestions = questions.length;

    final percentage =
        (correctAnswers / totalQuestions) * 100;

    final subjects = questions
        .map((question) => question.subject.trim())
        .where((subject) => subject.isNotEmpty)
        .toSet()
        .toList();

    final topics = questions
        .map((question) => question.topic.trim())
        .where((topic) => topic.isNotEmpty)
        .toSet()
        .toList();

    final sessionData = <String, dynamic>{
      'userId': user.uid,
      'type': 'practice',
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'unansweredQuestions': unansweredQuestions,
      'percentage': percentage,
      'questionIds': questions.map((question) => question.id).toList(),
      'answers': answerSnapshots,
      'subject': subjects.join(', '),
      'topic': topics.join(', '),
      'subjects': subjects,
      'topics': topics,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final document = await _firestore
        .collection('mcq_attempts')
        .add(sessionData);

    return document.id;
  }

  /// Retrieves one practice session belonging to the signed-in student.
  Future<Map<String, dynamic>?> getMySession(
    String sessionId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in to view your MCQ result.');
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
