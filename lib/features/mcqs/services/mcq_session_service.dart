import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mcq_model.dart';

class McqSessionService {
  McqSessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Saves a completed practice session with a snapshot of every question
  /// and answer. This supports detailed result review later.
  Future<String> saveCompletedSession({
    required List<McqModel> questions,
    required List<int?> selectedAnswers,
    required DateTime startedAt,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to save your practice result.');
    }

    if (questions.isEmpty) {
      throw Exception('There are no questions in this session.');
    }

    if (questions.length != selectedAnswers.length) {
      throw Exception('The answer list does not match the questions.');
    }

    if (selectedAnswers.any((answer) => answer == null)) {
      throw Exception('Please answer every question before finishing.');
    }

    var correctAnswers = 0;

    final answerSnapshots = <Map<String, dynamic>>[];

    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final selectedIndex = selectedAnswers[i]!;

      if (selectedIndex < 0 ||
          selectedIndex >= question.options.length) {
        throw Exception('An answer is invalid.');
      }

      final selectedLetter = String.fromCharCode(65 + selectedIndex);
      final isCorrect = selectedLetter == question.correctAnswer;

      if (isCorrect) {
        correctAnswers++;
      }

      answerSnapshots.add({
        'questionId': question.id,
        'question': question.question,
        'options': question.options,
        'selectedAnswer': selectedLetter,
        'correctAnswer': question.correctAnswer,
        'isCorrect': isCorrect,
        'explanation': question.explanation,
        'subject': question.subject,
        'topic': question.topic,
        'difficulty': question.difficulty,
        'reference': question.reference,
      });
    }

    final totalQuestions = questions.length;
    final incorrectAnswers = totalQuestions - correctAnswers;
    final percentage =
        (correctAnswers / totalQuestions * 100).round();

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

    final document = await _firestore
        .collection('mcq_attempts')
        .add({
      'userId': user.uid,
      'type': 'practice',
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'percentage': percentage,
      'questionIds': questions.map((question) => question.id).toList(),
      'answers': answerSnapshots,
      'subject': subjects.length == 1 ? subjects.first : 'Mixed subjects',
      'topic': topics.length == 1 ? topics.first : 'Mixed topics',
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  /// Retrieves one practice result belonging to the current student.
  Future<Map<String, dynamic>> getMySession(String sessionId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to view your result.');
    }

    final document = await _firestore
        .collection('mcq_attempts')
        .doc(sessionId)
        .get();

    if (!document.exists) {
      throw Exception('Practice result not found.');
    }

    final data = document.data()!;

    if (data['userId'] != user.uid) {
      throw Exception('You cannot access another student’s result.');
    }

    return data;
  }
}
