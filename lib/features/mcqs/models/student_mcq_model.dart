import 'package:cloud_firestore/cloud_firestore.dart';

class StudentMcqModel {
  final String id;
  final String question;
  final List<String> options;

  final String yearId;
  final String subject;
  final String topic;
  final String difficulty;

  final String reference;
  final List<String> tags;

  const StudentMcqModel({
    required this.id,
    required this.question,
    required this.options,
    required this.yearId,
    required this.subject,
    required this.topic,
    required this.difficulty,
    this.reference = '',
    this.tags = const [],
  });

  factory StudentMcqModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError(
        'MCQ document ${document.id} contains no data.',
      );
    }

    final rawOptions = data['options'];

    final options = rawOptions is List
        ? rawOptions.map((value) => value.toString()).toList()
        : <String>[];

    final rawTags = data['tags'];

    final tags = rawTags is List
        ? rawTags.map((value) => value.toString()).toList()
        : <String>[];

    return StudentMcqModel(
      id: document.id,
      question: (data['question'] ?? '').toString(),
      options: options,
      yearId: (data['yearId'] ?? '').toString(),
      subject: (data['subject'] ?? '').toString(),
      topic: (data['topic'] ?? '').toString(),
      difficulty: (data['difficulty'] ?? 'Medium').toString(),
      reference: (data['reference'] ?? '').toString(),
      tags: tags,
    );
  }

  Map<String, dynamic> toStudentMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'yearId': yearId,
      'subject': subject,
      'topic': topic,
      'difficulty': difficulty,
      'reference': reference,
      'tags': tags,
    };
  }
}
