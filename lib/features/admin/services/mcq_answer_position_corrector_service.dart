import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_access_service.dart';

class McqAnswerPositionAudit {
  final int totalQuestions;
  final Map<String, int> distribution;
  final int correctAtA;
  final int eligible;
  final int alreadyBackedUp;
  final int missingAnswerKey;
  final int invalidAnswerKey;
  final int unsupportedOptions;

  const McqAnswerPositionAudit({
    required this.totalQuestions,
    required this.distribution,
    required this.correctAtA,
    required this.eligible,
    required this.alreadyBackedUp,
    required this.missingAnswerKey,
    required this.invalidAnswerKey,
    required this.unsupportedOptions,
  });
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
    final backupDocs = {
      for (final doc in backupSnapshot.docs) doc.id: doc.data(),
    };
    final distribution = <String, int>{
      'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0,
    };
    var correctAtA = 0;
    var eligible = 0;
    var alreadyBackedUp = 0;
    var missingAnswerKey = 0;
    var invalidAnswerKey = 0;
    var unsupportedOptions = 0;

    for (final questionDoc in questionSnapshot.docs) {
      final data = questionDoc.data();
      final backup = backupDocs['$_backupVersion${questionDoc.id}'];
      final originalQuestion = backup?['originalQuestion'];
      final originalKey = backup?['originalAnswerKey'];
      final currentKey = answerDocs[questionDoc.id];
      final rawAnswer = backup?['originalCorrectAnswer'] ??
          (originalKey is Map ? originalKey['correctAnswer'] : null) ??
          (originalQuestion is Map ? originalQuestion['correctAnswer'] : null) ??
          currentKey?['correctAnswer'] ??
          data['correctAnswer'];
      if (rawAnswer == null || rawAnswer.toString().trim().isEmpty) {
        missingAnswerKey++;
        continue;
      }
      final answer = rawAnswer.toString().trim().toUpperCase();
      final sourceOptions = originalQuestion is Map
          ? originalQuestion['options']
          : data['options'];
      if (!['A', 'B', 'C', 'D', 'E'].contains(answer) ||
          sourceOptions is! List ||
          'ABCDE'.indexOf(answer) >= sourceOptions.length) {
        invalidAnswerKey++;
        continue;
      }
      distribution[answer] = (distribution[answer] ?? 0) + 1;
      if (answer == 'A') correctAtA++;
      final supported = sourceOptions.length >= 4 &&
          sourceOptions.length <= 5 &&
          !sourceOptions.any(
            (value) => value == null || value.toString().trim().isEmpty,
          );
      if (!supported) {
        unsupportedOptions++;
        continue;
      }
      eligible++;
      if (backup != null) alreadyBackedUp++;
    }

    return McqAnswerPositionAudit(
      totalQuestions: questionSnapshot.size,
      distribution: distribution,
      correctAtA: correctAtA,
      eligible: eligible,
      alreadyBackedUp: alreadyBackedUp,
      missingAnswerKey: missingAnswerKey,
      invalidAnswerKey: invalidAnswerKey,
      unsupportedOptions: unsupportedOptions,
    );
  }

  /// Rebalances every supported MCQ across A-D. Existing v1 backups are used
  /// as the source of truth so questions corrected by the earlier A-to-B/C/D
  /// version can safely be redistributed without losing their original text.
  Future<McqAnswerPositionCorrectionResult> rebalanceAll({
    void Function(int completed, int total)? onProgress,
  }) async {
    await _verifyAdmin();

    final questionSnapshot = await _firestore.collection(_questions).get();
    final answerSnapshot = await _firestore.collection(_answerKeys).get();
    final backupSnapshot = await _firestore.collection(_backups).get();

    final answerDocs = {
      for (final doc in answerSnapshot.docs) doc.id: doc.data(),
    };
    final backupDocs = {
      for (final doc in backupSnapshot.docs) doc.id: doc.data(),
    };

    final candidates = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final questionDoc in questionSnapshot.docs) {
      final backup = backupDocs['$_backupVersion${questionDoc.id}'];
      final originalQuestion = backup?['originalQuestion'];
      final originalKey = backup?['originalAnswerKey'];
      final currentKey = answerDocs[questionDoc.id];
      final rawAnswer = backup?['originalCorrectAnswer'] ??
          (originalKey is Map ? originalKey['correctAnswer'] : null) ??
          (originalQuestion is Map ? originalQuestion['correctAnswer'] : null) ??
          currentKey?['correctAnswer'] ??
          questionDoc.data()['correctAnswer'];
      final sourceOptions = originalQuestion is Map
          ? originalQuestion['options']
          : questionDoc.data()['options'];
      final answer = (rawAnswer ?? '').toString().trim().toUpperCase();
      if (!['A', 'B', 'C', 'D', 'E'].contains(answer) ||
          sourceOptions is! List ||
          'ABCDE'.indexOf(answer) >= sourceOptions.length ||
          sourceOptions.length < 4 ||
          sourceOptions.length > 5 ||
          sourceOptions.any(
            (value) => value == null || value.toString().trim().isEmpty,
          )) {
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
        final currentQuestion = questionDoc.data();
        final backupId = '$_backupVersion${questionDoc.id}';
        final existingBackup = backupDocs[backupId];
        final originalQuestion = existingBackup?['originalQuestion'];
        final originalKey = existingBackup?['originalAnswerKey'];
        final originalData = originalQuestion is Map
            ? Map<String, dynamic>.from(originalQuestion)
            : currentQuestion;
        final currentKey = answerDocs[questionDoc.id];
        final rawAnswer = existingBackup?['originalCorrectAnswer'] ??
            (originalKey is Map ? originalKey['correctAnswer'] : null) ??
            originalData['correctAnswer'] ??
            currentKey?['correctAnswer'] ??
            currentQuestion['correctAnswer'];
        final originalAnswer = rawAnswer.toString().trim().toUpperCase();
        final sourceOptions = List<String>.from(
          (originalData['options'] as List).map((value) => value.toString()),
        );
        final correctText = sourceOptions.removeAt(
          'ABCDE'.indexOf(originalAnswer),
        );

        // Select the least-used position among A, B, C and D only.
        var targetIndex = 0;
        for (var index = 1; index < 4; index++) {
          final letter = String.fromCharCode(65 + index);
          final selectedLetter = String.fromCharCode(65 + targetIndex);
          if ((finalPositions[letter] ?? 0) <
              (finalPositions[selectedLetter] ?? 0)) {
            targetIndex = index;
          }
        }
        sourceOptions.insert(targetIndex, correctText);
        final newLetter = String.fromCharCode(65 + targetIndex);

        final questionRef = _firestore.collection(_questions).doc(questionDoc.id);
        final answerRef = _firestore.collection(_answerKeys).doc(questionDoc.id);
        final backupRef = _firestore.collection(_backups).doc(backupId);
        final explanation = (originalKey is Map
                ? originalKey['explanation']
                : null) ??
            originalData['explanation'] ??
            currentKey?['explanation'] ??
            '';

        if (existingBackup == null) {
          batch.set(backupRef, {
            'questionId': questionDoc.id,
            'correctionVersion': 1,
            'originalQuestion': currentQuestion,
            'originalAnswerKey': currentKey,
            'correctedAt': FieldValue.serverTimestamp(),
            'originalCorrectAnswer': originalAnswer,
            'newCorrectAnswer': newLetter,
          });
        }

        batch.update(questionRef, {
          'options': sourceOptions,
          'updatedAt': FieldValue.serverTimestamp(),
          if (currentQuestion.containsKey('correctAnswer'))
            'correctAnswer': FieldValue.delete(),
          if (currentQuestion.containsKey('explanation'))
            'explanation': FieldValue.delete(),
        });
        batch.set(answerRef, {
          'correctAnswer': newLetter,
          'explanation': explanation.toString(),
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
