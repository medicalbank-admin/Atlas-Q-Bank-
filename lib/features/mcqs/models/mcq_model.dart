import 'package:cloud_firestore/cloud_firestore.dart';

class McqModel {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String yearId;
  final String subject;
  final String topic;
  final String difficulty;
  final String reference;
  final List<String> tags;
  final bool isPublished;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const McqModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation = '',
    required this.yearId,
    required this.subject,
    required this.topic,
    this.difficulty = 'Medium',
    this.reference = '',
    this.tags = const [],
    this.isPublished = false,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  String get correctOptionText {
    final index = 'ABCDE'.indexOf(correctAnswer.toUpperCase());

    if (index < 0 || index >= options.length) {
      return '';
    }

    return options[index];
  }

  bool get hasValidAnswer {
    final index = 'ABCDE'.indexOf(correctAnswer.toUpperCase());

    return index >= 0 && index < options.length;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer.toUpperCase(),
      'explanation': explanation,
      'yearId': yearId,
      'subject': subject,
      'topic': topic,
      'difficulty': difficulty,
      'reference': reference,
      'tags': tags,
      'isPublished': isPublished,
      'createdBy': createdBy,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory McqModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return McqModel(
      id: document.id,
      question: data['question'] as String? ?? '',
      options: List<String>.from(data['options'] ?? const []),
      correctAnswer:
          (data['correctAnswer'] as String? ?? '').toUpperCase(),
      explanation: data['explanation'] as String? ?? '',
      yearId: data['yearId'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      topic: data['topic'] as String? ?? '',
      difficulty: data['difficulty'] as String? ?? 'Medium',
      reference: data['reference'] as String? ?? '',
      tags: List<String>.from(data['tags'] ?? const []),
      isPublished: data['isPublished'] as bool? ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  McqModel copyWith({
    String? id,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? yearId,
    String? subject,
    String? topic,
    String? difficulty,
    String? reference,
    List<String>? tags,
    bool? isPublished,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return McqModel(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      yearId: yearId ?? this.yearId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      reference: reference ?? this.reference,
      tags: tags ?? this.tags,
      isPublished: isPublished ?? this.isPublished,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
