import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/services/admin_access_service.dart';
import '../models/mcq_model.dart';

class McqManagementService {
  McqManagementService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'mcqs';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<void> _verifyAdmin() async {
    final isAdmin = await AdminAccessService.isAdmin(
      refreshToken: true,
    );

    if (!isAdmin) {
      throw Exception(
        'Administrator permission is required.',
      );
    }
  }

  /// Watches MCQs with optional academic filters.
  Stream<List<McqModel>> watchMcqs({
    String? yearId,
    String? subject,
    String? topic,
    bool? publishedOnly,
  }) async* {
    await _verifyAdmin();

    Query<Map<String, dynamic>> query = _collection;

    if (yearId != null && yearId.isNotEmpty) {
      query = query.where('yearId', isEqualTo: yearId);
    }

    if (subject != null && subject.isNotEmpty) {
      query = query.where('subject', isEqualTo: subject);
    }

    if (topic != null && topic.isNotEmpty) {
      query = query.where('topic', isEqualTo: topic);
    }

    if (publishedOnly == true) {
      query = query.where('isPublished', isEqualTo: true);
    }

    await for (final snapshot in query.snapshots()) {
      final questions = snapshot.docs
          .map(McqModel.fromFirestore)
          .toList();

      questions.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      yield questions;
    }
  }

  /// Retrieves one MCQ by its Firestore document ID.
  Future<McqModel?> getMcq(String id) async {
    await _verifyAdmin();

    final document = await _collection.doc(id).get();

    if (!document.exists) {
      return null;
    }

    return McqModel.fromFirestore(document);
  }

  /// Adds a new unpublished MCQ.
  Future<String> addMcq(McqModel question) async {
    await _verifyAdmin();
    _validateQuestion(question);

    final document = _collection.doc();

    final data = question.copyWith(
      id: document.id,
      isPublished: false,
    ).toFirestore();

    await document.set(data);

    return document.id;
  }

  /// Updates an existing MCQ without changing its original creation date.
  Future<void> updateMcq(McqModel question) async {
    await _verifyAdmin();
    _validateQuestion(question);

    if (question.id.trim().isEmpty) {
      throw Exception('MCQ document ID is required.');
    }

    final document = _collection.doc(question.id);

    final data = question.toFirestore();

    // Preserve the original creation timestamp.
    data.remove('createdAt');

    data['updatedAt'] = FieldValue.serverTimestamp();

    await document.update(data);
  }

  /// Publishes or unpublishes an MCQ.
  Future<void> setPublished({
    required String id,
    required bool isPublished,
  }) async {
    await _verifyAdmin();

    if (id.trim().isEmpty) {
      throw Exception('MCQ document ID is required.');
    }

    await _collection.doc(id).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes an MCQ permanently.
  Future<void> deleteMcq(String id) async {
    await _verifyAdmin();

    if (id.trim().isEmpty) {
      throw Exception('MCQ document ID is required.');
    }

    await _collection.doc(id).delete();
  }

  /// Validates question data before saving.
  void _validateQuestion(McqModel question) {
    if (question.question.trim().isEmpty) {
      throw Exception('Question cannot be empty.');
    }

    if (question.yearId.trim().isEmpty) {
      throw Exception('Academic year is required.');
    }

    if (question.subject.trim().isEmpty) {
      throw Exception('Subject is required.');
    }

    if (question.topic.trim().isEmpty) {
      throw Exception('Topic is required.');
    }

    if (question.options.length < 4 ||
        question.options.length > 5) {
      throw Exception(
        'An MCQ must have four or five options.',
      );
    }

    for (int i = 0; i < question.options.length; i++) {
      if (question.options[i].trim().isEmpty) {
        throw Exception(
          'Option ${String.fromCharCode(65 + i)} cannot be empty.',
        );
      }
    }

    if (!question.hasValidAnswer) {
      throw Exception(
        'Correct answer must match an available option.',
      );
    }

    const allowedDifficulties = [
      'Easy',
      'Medium',
      'Hard',
    ];

    if (!allowedDifficulties.contains(question.difficulty)) {
      throw Exception(
        'Difficulty must be Easy, Medium or Hard.',
      );
    }
  }
}
