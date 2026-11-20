import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicTopicModel {
  final String id;
  final String yearId;
  final String subjectId;
  final String title;
  final String description;
  final int displayOrder;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AcademicTopicModel({
    required this.id,
    required this.yearId,
    required this.subjectId,
    required this.title,
    this.description = '',
    this.displayOrder = 0,
    this.isPublished = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AcademicTopicModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return AcademicTopicModel(
      id: snapshot.id,
      yearId: data['yearId'] as String? ?? '',
      subjectId: data['subjectId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 0,
      isPublished: data['isPublished'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'yearId': yearId,
      'subjectId': subjectId,
      'title': title.trim(),
      'description': description.trim(),
      'displayOrder': displayOrder,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AcademicTopicModel copyWith({
    String? title,
    String? description,
    int? displayOrder,
    bool? isPublished,
    DateTime? updatedAt,
  }) {
    return AcademicTopicModel(
      id: id,
      yearId: yearId,
      subjectId: subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}
