import 'package:cloud_firestore/cloud_firestore.dart';

enum LearningResourceType {
  pdf,
  video,
  document,
  presentation,
  externalLink,
}

class LearningResourceModel {
  final String id;
  final String yearId;
  final String subjectId;
  final String topicId;
  final String title;
  final String description;
  final LearningResourceType type;
  final String resourceUrl;
  final String? thumbnailUrl;
  final int displayOrder;
  final bool isPublished;
  final bool isFree;
  final int durationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearningResourceModel({
    required this.id,
    required this.yearId,
    required this.subjectId,
    required this.topicId,
    required this.title,
    this.description = '',
    required this.type,
    required this.resourceUrl,
    this.thumbnailUrl,
    this.displayOrder = 0,
    this.isPublished = false,
    this.isFree = false,
    this.durationMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearningResourceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return LearningResourceModel(
      id: snapshot.id,
      yearId: data['yearId'] as String? ?? '',
      subjectId: data['subjectId'] as String? ?? '',
      topicId: data['topicId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: LearningResourceType.values.firstWhere(
        (value) => value.name == data['type'],
        orElse: () => LearningResourceType.document,
      ),
      resourceUrl: data['resourceUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 0,
      isPublished: data['isPublished'] as bool? ?? false,
      isFree: data['isFree'] as bool? ?? false,
      durationMinutes:
          (data['durationMinutes'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'yearId': yearId,
      'subjectId': subjectId,
      'topicId': topicId,
      'title': title.trim(),
      'description': description.trim(),
      'type': type.name,
      'resourceUrl': resourceUrl.trim(),
      'thumbnailUrl': thumbnailUrl,
      'displayOrder': displayOrder,
      'isPublished': isPublished,
      'isFree': isFree,
      'durationMinutes': durationMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LearningResourceModel copyWith({
    String? title,
    String? description,
    LearningResourceType? type,
    String? resourceUrl,
    String? thumbnailUrl,
    int? displayOrder,
    bool? isPublished,
    bool? isFree,
    int? durationMinutes,
    DateTime? updatedAt,
  }) {
    return LearningResourceModel(
      id: id,
      yearId: yearId,
      subjectId: subjectId,
      topicId: topicId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isPublished: isPublished ?? this.isPublished,
      isFree: isFree ?? this.isFree,
      durationMinutes: durationMinutes ?? this.durationMinutes,
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
