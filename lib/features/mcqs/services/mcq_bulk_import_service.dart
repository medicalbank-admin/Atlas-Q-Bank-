import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../admin/services/admin_access_service.dart';
import '../models/mcq_model.dart';
class McqBulkSaveResult {
  final int totalQuestions;
  final int importedQuestions;
  final int duplicateQuestions;
  final List<String> duplicateDetails;
  const McqBulkSaveResult({
    required this.totalQuestions,
    required this.importedQuestions,
    required this.duplicateQuestions,
    required this.duplicateDetails,
  });
}
class McqBulkImportService {
  McqBulkImportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const String collectionName = 'mcqs';
  static const String answerKeysCollectionName =
      'mcq_answer_keys';
  // Two writes per question.
  // 250 questions = 500 Firestore writes.
  static const int batchSize = 250;
  Future<McqBulkSaveResult> importQuestions({
    required List<McqModel> questions,
  }) async {
    if (questions.isEmpty) {
      return const McqBulkSaveResult(
        totalQuestions: 0,
        importedQuestions: 0,
        duplicateQuestions: 0,
        duplicateDetails: [],
      );
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(
        'Please sign in as an administrator.',
      );
    }
    final isAdmin = await AdminAccessService.isAdmin(
      refreshToken: true,
    );
    if (!isAdmin) {
      throw Exception(
        'Administrator permission is required.',
      );
    }
    final adminUid = user.uid;
    final collection =
        _firestore.collection(collectionName);
    final answerKeys =
        _firestore.collection(answerKeysCollectionName);
    final uniqueQuestions = <McqModel>[];
    final duplicateDetails = <String>[];
    final uploadedQuestionKeys = <String>{};
    // Validate and detect duplicates inside the uploaded file.
    for (final question in questions) {
      _validateQuestion(question);
      final key = _questionKey(question);
      if (!uploadedQuestionKeys.add(key)) {
        duplicateDetails.add(
          'Duplicate in uploaded file: ${question.question}',
        );
        continue;
      }
      uniqueQuestions.add(question);
    }
    final questionsToSave = <McqModel>[];
    // Check for existing questions in Firestore.
    for (final question in uniqueQuestions) {
      final existing = await collection
          .where('trackType', isEqualTo: question.trackType)
          .where('examSetId', isEqualTo: question.examSetId.trim())
          .where('yearId', isEqualTo: question.yearId.trim())
          .where('subject', isEqualTo: question.subject.trim())
          .where('topic', isEqualTo: question.topic.trim())
          .where('question', isEqualTo: question.question.trim())
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        duplicateDetails.add(
          'Already exists: ${question.question}',
        );
        continue;
      }
      questionsToSave.add(
        question.copyWith(
          createdBy: adminUid,
          isPublished: false,
        ),
      );
    }
    int importedCount = 0;
    for (
      int start = 0;
      start < questionsToSave.length;
      start += batchSize
    ) {
      final end = (start + batchSize <
              questionsToSave.length)
          ? start + batchSize
          : questionsToSave.length;
      final batch = _firestore.batch();
      for (int i = start; i < end; i++) {
        final question = questionsToSave[i];
        final questionDocument = collection.doc();
        final answerDocument =
            answerKeys.doc(questionDocument.id);
        // Public question document.
        // Never include correctAnswer or explanation.
        batch.set(
          questionDocument,
          _buildPublicQuestion(question),
        );
        // Private answer-key document.
        batch.set(
          answerDocument,
          _buildPrivateAnswerKey(question),
        );
      }
      await batch.commit();
      importedCount += end - start;
    }
    return McqBulkSaveResult(
      totalQuestions: questions.length,
      importedQuestions: importedCount,
      duplicateQuestions: duplicateDetails.length,
      duplicateDetails: duplicateDetails,
    );
  }
  Map<String, dynamic> _buildPublicQuestion(
    McqModel question,
  ) {
    return {
      'question': question.question.trim(),
      'options': question.options,
      'yearId': question.yearId.trim(),
      'trackType': question.trackType,
      'pathwayId': question.pathwayId,
      'pathwayName': question.pathwayName,
      'subjectId': question.subjectId,
      'examSetId': question.examSetId,
      'examSetName': question.examSetName,
      'subject': question.subject.trim(),
      'topic': question.topic.trim(),
      'difficulty': question.difficulty.trim(),
      'reference': question.reference.trim(),
      'tags': question.tags,
      'isPublished': false,
      'createdBy': question.createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
  Map<String, dynamic> _buildPrivateAnswerKey(
    McqModel question,
  ) {
    return {
      'correctAnswer':
          question.correctAnswer.trim().toUpperCase(),
      'explanation': question.explanation.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
  void _validateQuestion(McqModel question) {
    if (question.question.trim().isEmpty) {
      throw Exception(
        'An imported question is empty.',
      );
    }
    if (question.options.length < 4 ||
        question.options.length > 5) {
      throw Exception(
        'Every MCQ must have four or five options.',
      );
    }
    if (question.options.any(
      (option) => option.trim().isEmpty,
    )) {
      throw Exception(
        'An MCQ contains an empty option.',
      );
    }
    final normalizedOptions = question.options
        .map((option) => option.trim().toLowerCase())
        .toSet();
    if (normalizedOptions.length != question.options.length) {
      throw Exception(
        'An MCQ contains duplicate options.',
      );
    }
    final answer =
        question.correctAnswer.trim().toUpperCase();
    if (!['A', 'B', 'C', 'D', 'E'].contains(answer)) {
      throw Exception(
        'An MCQ has an invalid correct answer.',
      );
    }
    final answerIndex = 'ABCDE'.indexOf(answer);
    if (answerIndex >= question.options.length) {
      throw Exception(
        'An MCQ answer refers to an option that does not exist.',
      );
    }
    if (!['mbbs', 'licensing', 'past_paper'].contains(question.trackType) ||
        (question.trackType == 'mbbs' && question.yearId.trim().isEmpty) ||
        (question.trackType == 'licensing' && question.pathwayId.trim().isEmpty) ||
        question.examSetId.trim().isEmpty ||
        question.subject.trim().isEmpty ||
        question.topic.trim().isEmpty) {
      throw Exception(
        'Academic year, subject and topic are required.',
      );
    }
  }
  String _questionKey(McqModel question) {
    return [
      question.trackType,
      question.pathwayId.trim().toLowerCase(),
      question.yearId.trim().toLowerCase(),
      question.examSetId.trim().toLowerCase(),
      question.subject.trim().toLowerCase(),
      question.topic.trim().toLowerCase(),
      question.question.trim().toLowerCase(),
    ].join('::');
  }
}
