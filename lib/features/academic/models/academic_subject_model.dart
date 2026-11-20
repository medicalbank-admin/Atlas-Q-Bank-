
import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicSubjectModel {
  final String id;
  final String yearId;
  final String name;
  final String description;
  final String? imageUrl;
  final int displayOrder;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AcademicSubjectModel({
    required this.id,
    required this.yearId,
    required this.name,
    this.description = '',
    this.imageUrl,
    this.displayOrder = 0,
    this.isPublished = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AcademicSubjectModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return AcademicSubjectModel(
      id: snapshot.id,
      yearId: data['yearId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 0,
      isPublished: data['isPublished'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'yearId': yearId,
      'name': name.trim(),
      'description': description.trim(),
      'imageUrl': imageUrl,
      'displayOrder': displayOrder,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AcademicSubjectModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    int? displayOrder,
    bool? isPublished,
    DateTime? updatedAt,
  }) {
    return AcademicSubjectModel(
      id: id,
      yearId: yearId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
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
