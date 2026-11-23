import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/services/admin_access_service.dart';
import '../models/learning_resource_model.dart';

class LearningResourceService {
  LearningResourceService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>
      get _resources =>
          _firestore.collection('learning_resources');

  /// Watches resources belonging to a specific topic.
  static Stream<List<LearningResourceModel>> watchResources({
    String yearId = '',
    String subjectId = '',
    String topicId = '',
  }) {
    return _resources
        .where('yearId', isEqualTo: yearId)
        .where('subjectId', isEqualTo: subjectId)
        .where('topicId', isEqualTo: topicId)
        .orderBy('displayOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(LearningResourceModel.fromFirestore)
              .toList(),
        );
  }

  /// Creates a learning resource.
  static Future<String> createResource({
    String yearId = '',
    String subjectId = '',
    String topicId = '',
    required String title,
    required LearningResourceType type,
    String resourceUrl = '',
    String description = '',
    String textContent = '',
    String? thumbnailUrl,
    int displayOrder = 0,
    bool isFree = false,
    int durationMinutes = 0,
  }) async {
    await _requireAdmin();

    if (title.trim().isEmpty ||
        (resourceUrl.trim().isEmpty && textContent.trim().isEmpty)) {
      throw ArgumentError(
        'A title and either a resource URL or text content are required.',
      );
    }

    final now = DateTime.now();
    final document = _resources.doc();

    final resource = LearningResourceModel(
      id: document.id,
      yearId: yearId,
      subjectId: subjectId,
      topicId: topicId,
      title: title.trim(),
      description: description.trim(),
      type: type,
      resourceUrl: resourceUrl.trim(),
      textContent: textContent,
      thumbnailUrl: thumbnailUrl,
      displayOrder: displayOrder,
      isPublished: true,
      isFree: isFree,
      durationMinutes: durationMinutes,
      createdAt: now,
      updatedAt: now,
    );

    await document.set(resource.toFirestore());

    return document.id;
  }

  /// Updates an existing resource.
  static Future<void> updateResource(
    LearningResourceModel resource,
  ) async {
    await _requireAdmin();

    if (resource.id.trim().isEmpty ||
        resource.title.trim().isEmpty ||
        (resource.type == LearningResourceType.text
            ? resource.textContent.trim().isEmpty
            : resource.resourceUrl.trim().isEmpty)) {
      throw ArgumentError(
        'A valid resource ID, title and URL are required.',
      );
    }

    await _resources.doc(resource.id).update({
      ...resource.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Publishes or unpublishes a resource.
  static Future<void> setPublished({
    required String resourceId,
    required bool isPublished,
  }) async {
    await _requireAdmin();

    if (resourceId.trim().isEmpty) {
      throw ArgumentError('Resource ID is required.');
    }

    await _resources.doc(resourceId).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a resource record.
  static Future<void> deleteResource(
    String resourceId,
  ) async {
    await _requireAdmin();

    if (resourceId.trim().isEmpty) {
      throw ArgumentError('Resource ID is required.');
    }

    await _resources.doc(resourceId).delete();
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
