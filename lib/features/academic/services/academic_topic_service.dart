import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/services/admin_access_service.dart';
import '../models/academic_topic_model.dart';

class AcademicTopicService {
  AcademicTopicService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>
      get _topics =>
          _firestore.collection('academic_topics');

  /// Watches topics belonging to a specific subject.
  static Stream<List<AcademicTopicModel>> watchTopics({
    required String yearId,
    required String subjectId,
  }) {
    return _topics
        .where('yearId', isEqualTo: yearId)
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('displayOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AcademicTopicModel.fromFirestore)
              .toList(),
        );
  }

  /// Creates a new topic.
  static Future<String> createTopic({
    required String yearId,
    required String subjectId,
    required String title,
    String description = '',
    int displayOrder = 0,
  }) async {
    await _requireAdmin();

    if (yearId.trim().isEmpty ||
        subjectId.trim().isEmpty ||
        title.trim().isEmpty) {
      throw ArgumentError(
        'Academic year, subject and topic title are required.',
      );
    }

    final now = DateTime.now();
    final document = _topics.doc();

    final topic = AcademicTopicModel(
      id: document.id,
      yearId: yearId,
      subjectId: subjectId,
      title: title.trim(),
      description: description.trim(),
      displayOrder: displayOrder,
      isPublished: false,
      createdAt: now,
      updatedAt: now,
    );

    await document.set(topic.toFirestore());

    return document.id;
  }

  /// Updates an existing topic.
  static Future<void> updateTopic(
    AcademicTopicModel topic,
  ) async {
    await _requireAdmin();

    if (topic.id.trim().isEmpty ||
        topic.title.trim().isEmpty) {
      throw ArgumentError(
        'A valid topic ID and title are required.',
      );
    }

    await _topics.doc(topic.id).update({
      ...topic.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Publishes or unpublishes a topic.
  static Future<void> setPublished({
    required String topicId,
    required bool isPublished,
  }) async {
    await _requireAdmin();

    if (topicId.trim().isEmpty) {
      throw ArgumentError('Topic ID is required.');
    }

    await _topics.doc(topicId).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a topic.
  static Future<void> deleteTopic(String topicId) async {
    await _requireAdmin();

    if (topicId.trim().isEmpty) {
      throw ArgumentError('Topic ID is required.');
    }

    await _topics.doc(topicId).delete();
  }

  static Future<void> _requireAdmin() async {
    final allowed = await AdminAccessService.isAdmin(
      refreshToken: true,
    );

    if (!allowed) {
      throw Exception(
        'Permission denied. Administrator access is required.',
      );
    }
  }
}
