import 'package:cloud_firestore/cloud_firestore.dart';

import '../../admin/services/admin_access_service.dart';

class McqAnswerPositionAudit {
  final int totalQuestions;
  final Map<String, int> distribution;
  final int correctAtA;
  final int alreadyBackedUp;
  final int missingAnswerKey;
  final int invalidAnswerKey;
  final int unsupportedOptions;

  const McqAnswerPositionAudit({
    required this.totalQuestions,
    required this.distribution,
    required this.correctAtA,
    required this.alreadyBackedUp,
    required this.missingAnswerKey,
    required this.invalidAnswerKey,
    required this.unsupportedOptions,
  });

  int get eligible => correctAtA - alreadyBackedUp;
}

class McqAnswerPositionCorrectionResult {
  final int corrected;
  final int skipped;
  final Map<String, int> finalPositions;

  const McqAnswerPositionCorrectionResult({
    required this.corrected,
    required this.skipped,
    required this.finalPositions,
  });
}

class McqAnswerPositionCorrectorService {
  McqAnswerPositionCorrectorService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _questions = 'mcqs';
  static const String _answerKeys = 'mcq_answer_keys';
  static const String _backups = 'mcq_answer_position_backups';
  static const String _backupVersion = 'v1_';
  static const int _questionsPerBatch = 150;

  Future<void> _verifyAdmin() async {
    final allowed = await AdminAccessService.isAdmin(refreshToken: true);
    if (!allowed) {
      throw Exception('Administrator permission is required.');
    }
  }

  Future<McqAnswerPositionAudit> audit() async {
    await _verifyAdmin();

    final questionSnapshot = await _firestore.collection(_questions).get();
    final answerSnapshot = await _firestore.collection(_answerKeys).get();
    final backupSnapshot = await _firestore.collection(_backups).get();

    final answerDocs = {
      for (final doc in answerSnapshot.docs) doc.id: doc.data(),
    };
    final backupIds = backupSnapshot.docs.map((doc) => doc.id).toSet();
    final distribution = <String, int>{
      'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0,
    };
    var correctAtA = 0;
    var alreadyBackedUp = 0;
    var missingAnswerKey = 0;
    var invalidAnswerKey = 0;
    var unsupportedOptions = 0;

    for (final questionDoc in questionSnapshot.docs) {
      final data = questionDoc.data();
      final key = answerDocs[questionDoc.id];
      final rawAnswer = key?['correctAnswer'] ?? data['correctAnswer'];
      if (rawAnswer == null || rawAnswer.toString().trim().isEmpty) {
        missingAnswerKey++;
        continue;
      }
      final answer = rawAnswer.toString().trim().toUpperCase();
      final options = data['options'];
      if (!['A', 'B', 'C', 'D', 'E'].contains(answer) ||
          options is! List ||
          'ABCDE'.indexOf(answer) >= options.length) {
        invalidAnswerKey++;
        continue;
      }
      distribution[answer] = (distribution[answer] ?? 0) + 1;
      if (answer == 'A') {
        correctAtA++;
        if (options.length < 4 || options.length > 5 ||
            options.any((value) => value == null || value.toString().trim().isEmpty)) {
          unsupportedOptions++;
        }
        if (backupIds.contains('$_backupVersion${questionDoc.id}')) {
          alreadyBackedUp++;
        }
      }
    }

    return McqAnswerPositionAudit(
      totalQuestions: questionSnapshot.size,
      distribution: distribution,
      correctAtA: correctAtA,
      alreadyBackedUp: alreadyBackedUp,
      missingAnswerKey: missingAnswerKey,
      invalidAnswerKey: invalidAnswerKey,
      unsupportedOptions: unsupportedOptions,
    );
  }

  Future<McqAnswerPositionCorrectionResult> correctAllA({
    void Function(int completed, int total)? onProgress,
  }) async {
    await _verifyAdmin();

    final questionSnapshot = await _firestore.collection(_questions).get();
    final answerSnapshot = await _firestore.collection(_answerKeys).get();
    final backupSnapshot = await _firestore.collection(_backups).get();

    final answerDocs = {
      for (final doc in answerSnapshot.docs) doc.id: doc.data(),
    };
    final backupIds = backupSnapshot.docs.map((doc) => doc.id).toSet();
    final candidates = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final questionDoc in questionSnapshot.docs) {
      final data = questionDoc.data();
      final key = answerDocs[questionDoc.id];
      final answer = (key?['correctAnswer'] ?? data['correctAnswer'] ?? '')
          .toString().trim().toUpperCase();
      final options = data['options'];
      if (answer != 'A' ||
          backupIds.contains('$_backupVersion${questionDoc.id}') ||
          options is! List ||
          options.length < 4 ||
          options.length > 5 ||
          options.any((value) => value == null || value.toString().trim().isEmpty)) {
        continue;
      }
      candidates.add(questionDoc);
    }

    candidates.sort((a, b) => a.id.compareTo(b.id));
    final finalPositions = <String, int>{
      'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0,
    };
    var corrected = 0;
    var skipped = 0;

    for (var start = 0; start < candidates.length; start += _questionsPerBatch) {
      final end = (start + _questionsPerBatch < candidates.length)
          ? start + _questionsPerBatch
          : candidates.length;
      final group = candidates.sublist(start, end);
      final batch = _firestore.batch();

      for (final questionDoc in group) {
        final originalQuestion = questionDoc.data();
        final originalKey = answerDocs[questionDoc.id];
        final originalOptions = List<String>.from(
          (originalQuestion['options'] as List).map((value) => value.toString()),
        );

        // Select the least-used valid destination. This keeps the answer
        // positions balanced across B-E (or B-D for four-option questions).
        final lastIndex = originalOptions.length - 1;
        final possibleTargets = List<int>.generate(lastIndex, (index) => index + 1);
        possibleTargets.sort((a, b) {
          final count = finalPositions[String.fromCharCode(65 + a)] ?? 0;
          final other = finalPositions[String.fromCharCode(65 + b)] ?? 0;
          return count.compareTo(other);
        });
        final targetIndex = possibleTargets.first;
        final correctText = originalOptions.removeAt(0);
        originalOptions.insert(targetIndex, correctText);
        final newLetter = String.fromCharCode(65 + targetIndex);
        final backupId = '$_backupVersion${questionDoc.id}';
        final backupRef = _firestore.collection(_backups).doc(backupId);
        final questionRef = _firestore.collection(_questions).doc(questionDoc.id);
        final answerRef = _firestore.collection(_answerKeys).doc(questionDoc.id);
        final explanation = (originalKey?['explanation'] ??
            originalQuestion['explanation'] ?? '').toString();

        batch.set(backupRef, {
          'questionId': questionDoc.id,
          'correctionVersion': 1,
          'originalQuestion': originalQuestion,
          'originalAnswerKey': originalKey,
          'correctedAt': FieldValue.serverTimestamp(),
          'originalCorrectAnswer': 'A',
          'newCorrectAnswer': newLetter,
        });

        batch.update(questionRef, {
          'options': originalOptions,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        batch.set(answerRef, {
          'correctAnswer': newLetter,
          'explanation': explanation,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        finalPositions[newLetter] = (finalPositions[newLetter] ?? 0) + 1;
      }

      try {
        await batch.commit();
        corrected += group.length;
      } catch (error) {
        skipped += group.length;
        rethrow;
      }
      onProgress?.call(end, candidates.length);
    }

    return McqAnswerPositionCorrectionResult(
      corrected: corrected,
      skipped: skipped,
      finalPositions: finalPositions,
    );
  }
}
