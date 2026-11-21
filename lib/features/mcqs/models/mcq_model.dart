import 'package:cloud_firestore/cloud_firestore.dart';

class McqModel {
  final String id, question, correctAnswer, explanation, yearId, subject,
      topic, difficulty, reference, createdBy, trackType, pathwayId,
      pathwayName, subjectId, examSetId, examSetName;
  final List<String> options, tags;
  final bool isPublished;
  final DateTime? createdAt, updatedAt;

  const McqModel({
    required this.id, required this.question, required this.options,
    required this.correctAnswer, this.explanation = '',
    this.yearId = '', required this.subject, required this.topic,
    this.difficulty = 'Medium', this.reference = '', this.tags = const [],
    this.isPublished = false, this.createdBy = '',
    this.trackType = 'mbbs', this.pathwayId = '', this.pathwayName = '',
    this.subjectId = '', this.examSetId = '', this.examSetName = '',
    this.createdAt, this.updatedAt,
  });

  String get correctOptionText {
    final i = 'ABCDE'.indexOf(correctAnswer.toUpperCase());
    return i < 0 || i >= options.length ? '' : options[i];
  }
  bool get hasValidAnswer {
    final i = 'ABCDE'.indexOf(correctAnswer.toUpperCase());
    return i >= 0 && i < options.length;
  }

  Map<String, dynamic> toFirestore() => {
    'question': question, 'options': options,
    'correctAnswer': correctAnswer.toUpperCase(),
    'explanation': explanation, 'yearId': yearId,
    'subject': subject, 'topic': topic, 'difficulty': difficulty,
    'reference': reference, 'tags': tags, 'isPublished': isPublished,
    'createdBy': createdBy, 'trackType': trackType,
    'pathwayId': pathwayId, 'pathwayName': pathwayName,
    'subjectId': subjectId, 'examSetId': examSetId,
    'examSetName': examSetName,
    'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory McqModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return McqModel(
      id: doc.id, question: d['question'] as String? ?? '',
      options: List<String>.from(d['options'] ?? const []),
      correctAnswer: (d['correctAnswer'] as String? ?? '').toUpperCase(),
      explanation: d['explanation'] as String? ?? '',
      yearId: d['yearId'] as String? ?? '', subject: d['subject'] as String? ?? '',
      topic: d['topic'] as String? ?? '', difficulty: d['difficulty'] as String? ?? 'Medium',
      reference: d['reference'] as String? ?? '', tags: List<String>.from(d['tags'] ?? const []),
      isPublished: d['isPublished'] as bool? ?? false, createdBy: d['createdBy'] as String? ?? '',
      trackType: d['trackType'] as String? ?? 'mbbs',
      pathwayId: d['pathwayId'] as String? ?? '', pathwayName: d['pathwayName'] as String? ?? '',
      subjectId: d['subjectId'] as String? ?? '', examSetId: d['examSetId'] as String? ?? '',
      examSetName: d['examSetName'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  McqModel copyWith({
    String? id, String? question, List<String>? options, String? correctAnswer,
    String? explanation, String? yearId, String? subject, String? topic,
    String? difficulty, String? reference, List<String>? tags,
    bool? isPublished, String? createdBy, String? trackType,
    String? pathwayId, String? pathwayName, String? subjectId,
    String? examSetId, String? examSetName, DateTime? createdAt, DateTime? updatedAt,
  }) => McqModel(
    id: id ?? this.id, question: question ?? this.question,
    options: options ?? this.options, correctAnswer: correctAnswer ?? this.correctAnswer,
    explanation: explanation ?? this.explanation, yearId: yearId ?? this.yearId,
    subject: subject ?? this.subject, topic: topic ?? this.topic,
    difficulty: difficulty ?? this.difficulty, reference: reference ?? this.reference,
    tags: tags ?? this.tags, isPublished: isPublished ?? this.isPublished,
    createdBy: createdBy ?? this.createdBy, trackType: trackType ?? this.trackType,
    pathwayId: pathwayId ?? this.pathwayId, pathwayName: pathwayName ?? this.pathwayName,
    subjectId: subjectId ?? this.subjectId, examSetId: examSetId ?? this.examSetId,
    examSetName: examSetName ?? this.examSetName,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}
