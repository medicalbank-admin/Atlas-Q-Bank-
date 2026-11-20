import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/services/admin_access_service.dart';
import '../models/mcq_model.dart';
class McqManagementService {
  McqManagementService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  static const String collectionName = 'mcqs';
  static const String answerKeysCollectionName = 'mcq_answer_keys';
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);
  CollectionReference<Map<String, dynamic>> get _answerKeys =>
      _firestore.collection(answerKeysCollectionName);
  Future<void> _verifyAdmin() async {
    final isAdmin = await AdminAccessService.isAdmin(
      refreshToken: true,
    );
    if (!isAdmin) {
      throw Exception('Administrator permission is required.');
    }
  }
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
      final questions = await Future.wait(
        snapshot.docs.map(_loadAdminQuestion),
      );
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
  Future<McqModel?> getMcq(String id) async {
    await _verifyAdmin();
    if (id.trim().isEmpty) {
      throw Exception('MCQ document ID is required.');
    }
    final document = await _collection.doc(id).get();
    if (!document.exists) {
      return null;
    }
    return _loadAdminQuestion(document);
  }
  Future<String> addMcq(McqModel question) async {
    await _verifyAdmin();
    _validateQuestion(question);
    final document = _collection.doc();
    final preparedQuestion = question.copyWith(
      id: document.id,
      isPublished: false,
    );
    final publicData = preparedQuestion.toFirestore()
      ..remove('correctAnswer')
      ..remove('explanation');
    final answerData = _buildAnswerKey(preparedQuestion);
    final batch = _firestore.batch();
    batch.set(document, publicData);
    batch.set(
      _answerKeys.doc(document.id),
      answerData,
    );
    await batch.commit();
    return document.id;
  }
  Future<void> updateMcq(McqModel question) async {
    await _verifyAdmin();
    _validateQuestion(question);
    if (question.id.trim().isEmpty) {
      throw Exception('MCQ document ID is required.');
    }
    final document = _collection.doc(question.id);
    final answerDocument = _answerKeys.doc(question.id);
    final existing = await document.get();
    if (!existing.exists) {
      throw Exception('MCQ does not exist.');
    }
    final publicData = question.toFirestore()
      ..remove('correctAnswer')
      ..remove('explanation')
      ..remove('createdAt');
    publicData['updatedAt'] = FieldValue.serverTimestamp();
    final answerData = _buildAnswerKey(question);
    final batch = _firestore.batch();
    batch.update(document, publicData);
    batch.set(answerDocument, answerData);
    await batch.commit();
  }
  Future<void> setPublished({
    required String id,
    required bool isPublished,
  }) async {
    await _verifyAdmin();
    if (id.trim().isEmpty) {
      throw Exception('MCQ document ID is required.');
    }
    final document = _collection.doc(id);
    final snapshot = await document.get();
    if (!snapshot.exists) {
      throw Exception('MCQ does not exist.');
    }
    if (isPublished) {
      final answerSnapshot = await _answerKeys.doc(id).get();
      final publicData = snapshot.data() ?? {};
      final hasPrivateAnswer = answerSnapshot.exists &&
          answerSnapshot.data()?['correctAnswer'] != null;
      final hasLegacyAnswer =
          publicData['correctAnswer'] != null;
      if (!hasPrivateAnswer && !hasLegacyAnswer) {
        throw Exception(
          'This question has no answer key. '
          'Edit and save it before publishing.',
        );
      }
    }
    await document.update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  Future<void> deleteMcq(String id) async {
    await _verifyAdmin();
    if (id.trim().isEmpty) {
      throw Exception('MCQ document ID is required.');
    }
    final batch = _firestore.batch();
    batch.delete(_collection.doc(id));
    batch.delete(_answerKeys.doc(id));
    await batch.commit();
  }
  Future<McqModel> _loadAdminQuestion(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final publicData = document.data();
    if (publicData == null) {
      throw StateError(
        'MCQ ${document.id} contains no data.',
      );
    }
    final answerSnapshot =
        await _answerKeys.doc(document.id).get();
    final answerData = answerSnapshot.data() ?? {};
    final correctAnswer = (
      answerData['correctAnswer'] ??
      publicData['correctAnswer'] ??
      ''
    ).toString().toUpperCase();
    final explanation = (
      answerData['explanation'] ??
      publicData['explanation'] ??
      ''
    ).toString();
    final createdAt = publicData['createdAt'];
    final updatedAt = publicData['updatedAt'];
    return McqModel(
      id: document.id,
      question: (publicData['question'] ?? '').toString(),
      options: _stringList(publicData['options']),
      correctAnswer: correctAnswer,
      explanation: explanation,
      yearId: (publicData['yearId'] ?? '').toString(),
      subject: (publicData['subject'] ?? '').toString(),
      topic: (publicData['topic'] ?? '').toString(),
      difficulty:
          (publicData['difficulty'] ?? 'Medium').toString(),
      reference: (publicData['reference'] ?? '').toString(),
      tags: _stringList(publicData['tags']),
      isPublished: publicData['isPublished'] == true,
      createdBy: (publicData['createdBy'] ?? '').toString(),
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : null,
      updatedAt: updatedAt is Timestamp
          ? updatedAt.toDate()
          : null,
    );
  }
  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return [];
    }
    return value.map((item) => item.toString()).toList();
  }
  Map<String, dynamic> _buildAnswerKey(
    McqModel question,
  ) {
    return {
      'correctAnswer': question.correctAnswer.toUpperCase(),
      'explanation': question.explanation,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
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
    for (var i = 0; i < question.options.length; i++) {
      if (question.options[i].trim().isEmpty) {
        throw Exception(
          'Option ${String.fromCharCode(65 + i)} '
          'cannot be empty.',
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
