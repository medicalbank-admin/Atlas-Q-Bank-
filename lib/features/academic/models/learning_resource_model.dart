import 'package:cloud_firestore/cloud_firestore.dart';

enum LearningResourceType {
  pdf,
  video,
  document,
  text,
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
  final String textContent;
  final List<Map<String, dynamic>> contentBlocks;
  final String systemName;
  final int readingMinutes;
  final int versionNumber;
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
    this.textContent = '',
    this.contentBlocks = const [],
    this.systemName = '',
    this.readingMinutes = 0,
    this.versionNumber = 0,
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
      textContent: data['textContent'] as String? ?? '',
      contentBlocks: (data['contentBlocks'] as List?)?.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() ?? const [],
      systemName: data['systemName'] as String? ?? '',
      readingMinutes: (data['readingMinutes'] as num?)?.toInt() ?? 0,
      versionNumber: (data['versionNumber'] as num?)?.toInt() ?? 0,
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
      'textContent': textContent,
      'contentBlocks': contentBlocks,
      'systemName': systemName,
      'readingMinutes': readingMinutes,
      'versionNumber': versionNumber,
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
    String? textContent,
    List<Map<String, dynamic>>? contentBlocks,
    String? systemName,
    int? readingMinutes,
    int? versionNumber,
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
      textContent: textContent ?? this.textContent,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      systemName: systemName ?? this.systemName,
      readingMinutes: readingMinutes ?? this.readingMinutes,
      versionNumber: versionNumber ?? this.versionNumber,
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
