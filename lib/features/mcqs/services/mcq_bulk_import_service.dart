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
  static const int batchSize = 400;

  /// Imports validated questions into Firestore.
  ///
  /// Questions are saved as unpublished by default.
  /// Existing questions with the same year, subject, topic
  /// and exact question text are skipped.
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
      throw Exception('Please sign in as an administrator.');
    }

    final isAdmin = await AdminAccessService.isAdmin(
      refreshToken: true,
    );

    if (!isAdmin) {
      throw Exception('Administrator permission is required.');
    }

    final adminUid = user.uid;

    final collection = _firestore.collection(collectionName);

    final uniqueQuestions = <McqModel>[];
    final duplicateDetails = <String>[];
    final uploadedQuestionKeys = <String>{};

    // Check duplicates within the uploaded file first.
    for (final question in questions) {
      final key = _questionKey(question);

      if (uploadedQuestionKeys.contains(key)) {
        duplicateDetails.add(
          'Duplicate in uploaded file: ${question.question}',
        );
        continue;
      }

      uploadedQuestionKeys.add(key);
      uniqueQuestions.add(question);
    }

    final questionsToSave = <McqModel>[];

    // Check whether questions already exist in Firestore.
    for (final question in uniqueQuestions) {
      final existing = await collection
          .where('yearId', isEqualTo: question.yearId)
          .where('subject', isEqualTo: question.subject)
          .where('topic', isEqualTo: question.topic)
          .where('question', isEqualTo: question.question)
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

    // Save in batches below Firestore's 500-write limit.
    int importedCount = 0;

    for (int start = 0;
        start < questionsToSave.length;
        start += batchSize) {
      final end = (start + batchSize < questionsToSave.length)
          ? start + batchSize
          : questionsToSave.length;

      final batch = _firestore.batch();

      for (int i = start; i < end; i++) {
        final question = questionsToSave[i];
        final document = collection.doc();

        batch.set(
          document,
          question.toFirestore(),
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

  String _questionKey(McqModel question) {
    return [
      question.yearId.trim().toLowerCase(),
      question.subject.trim().toLowerCase(),
      question.topic.trim().toLowerCase(),
      question.question.trim().toLowerCase(),
    ].join('::');
  }
}
