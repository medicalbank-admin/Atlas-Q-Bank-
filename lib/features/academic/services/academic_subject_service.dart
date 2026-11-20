import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/services/admin_access_service.dart';
import '../models/academic_subject_model.dart';

class AcademicSubjectService {
  AcademicSubjectService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>>
      get _subjects =>
          _firestore.collection('academic_subjects');

  /// Displays subjects belonging to a particular academic year.
  static Stream<List<AcademicSubjectModel>> watchSubjects(
    String yearId,
  ) {
    return _subjects
        .where('yearId', isEqualTo: yearId)
        .orderBy('displayOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AcademicSubjectModel.fromFirestore)
              .toList(),
        );
  }

  /// Creates a new subject.
  static Future<String> createSubject({
    required String yearId,
    required String name,
    String description = '',
    int displayOrder = 0,
  }) async {
    await _requireAdmin();

    if (yearId.trim().isEmpty) {
      throw ArgumentError('Academic year is required.');
    }

    if (name.trim().isEmpty) {
      throw ArgumentError('Subject name is required.');
    }

    final now = DateTime.now();
    final document = _subjects.doc();

    final subject = AcademicSubjectModel(
      id: document.id,
      yearId: yearId,
      name: name.trim(),
      description: description.trim(),
      displayOrder: displayOrder,
      isPublished: false,
      createdAt: now,
      updatedAt: now,
    );

    await document.set(subject.toFirestore());

    return document.id;
  }

  /// Updates an existing subject.
  static Future<void> updateSubject(
    AcademicSubjectModel subject,
  ) async {
    await _requireAdmin();

    if (subject.id.trim().isEmpty) {
      throw ArgumentError('Subject ID is required.');
    }

    if (subject.name.trim().isEmpty) {
      throw ArgumentError('Subject name is required.');
    }

    await _subjects.doc(subject.id).update({
      ...subject.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Publishes or unpublishes a subject.
  static Future<void> setPublished({
    required String subjectId,
    required bool isPublished,
  }) async {
    await _requireAdmin();

    await _subjects.doc(subjectId).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a subject.
  static Future<void> deleteSubject(
    String subjectId,
  ) async {
    await _requireAdmin();

    if (subjectId.trim().isEmpty) {
      throw ArgumentError('Subject ID is required.');
    }

    await _subjects.doc(subjectId).delete();
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
