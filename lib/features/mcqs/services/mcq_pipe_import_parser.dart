import '../models/mcq_model.dart';

class McqImportError {
  final int lineNumber;
  final String message;
  final String originalLine;

  const McqImportError({
    required this.lineNumber,
    required this.message,
    required this.originalLine,
  });
}

class McqImportResult {
  final List<McqModel> questions;
  final List<McqImportError> errors;
  final int totalRows;

  const McqImportResult({
    required this.questions,
    required this.errors,
    required this.totalRows,
  });

  int get successfulRows => questions.length;

  int get failedRows => errors.length;

  bool get hasErrors => errors.isNotEmpty;

  bool get isEmpty => questions.isEmpty;
}

class McqPipeImportParser {
  static const List<String> _difficultyLevels = [
    'Easy',
    'Medium',
    'Hard',
  ];

  static McqImportResult parse({
    required String input,
    required String yearId,
    required String adminUid,
  }) {
    final questions = <McqModel>[];
    final errors = <McqImportError>[];

    final lines = input.split('\n');

    int totalRows = 0;

    for (int i = 0; i < lines.length; i++) {
      final originalLine = lines[i].replaceAll('\r', '');

      if (originalLine.trim().isEmpty) {
        continue;
      }

      // Allow an optional header row.
      if (i == 0 &&
          originalLine.trimLeft().toLowerCase().startsWith('question|')) {
        continue;
      }

      totalRows++;

      try {
        final fields = _splitEscapedPipes(originalLine);

        if (fields.length != 10 && fields.length != 11) {
          throw FormatException(
            'Expected 10 fields for four options or '
            '11 fields for five options, but found ${fields.length}.',
          );
        }

        final bool hasFiveOptions = fields.length == 11;

        final String question = fields[0].trim();

        final List<String> options = hasFiveOptions
            ? [
                fields[1].trim(),
                fields[2].trim(),
                fields[3].trim(),
                fields[4].trim(),
                fields[5].trim(),
              ]
            : [
                fields[1].trim(),
                fields[2].trim(),
                fields[3].trim(),
                fields[4].trim(),
              ];

        final int answerIndex = hasFiveOptions ? 6 : 5;
        final int explanationIndex = hasFiveOptions ? 7 : 6;
        final int subjectIndex = hasFiveOptions ? 8 : 7;
        final int topicIndex = hasFiveOptions ? 9 : 8;
        final int difficultyIndex = hasFiveOptions ? 10 : 9;

        final String correctAnswer =
            fields[answerIndex].trim().toUpperCase();

        final String explanation =
            fields[explanationIndex].trim();

        final String subject = fields[subjectIndex].trim();

        final String topic = fields[topicIndex].trim();

        final String difficulty =
            _normalizeDifficulty(fields[difficultyIndex].trim());

        if (question.isEmpty) {
          throw const FormatException('Question cannot be empty.');
        }

        for (int optionIndex = 0;
            optionIndex < options.length;
            optionIndex++) {
          if (options[optionIndex].isEmpty) {
            throw FormatException(
              'Option ${String.fromCharCode(65 + optionIndex)} '
              'cannot be empty.',
            );
          }
        }

        if (!['A', 'B', 'C', 'D', 'E'].contains(correctAnswer)) {
          throw const FormatException(
            'Correct answer must be A, B, C, D or E.',
          );
        }

        final int correctIndex =
            'ABCDE'.indexOf(correctAnswer);

        if (correctIndex >= options.length) {
          throw const FormatException(
            'Correct answer refers to an option that does not exist.',
          );
        }

        if (subject.isEmpty) {
          throw const FormatException('Subject cannot be empty.');
        }

        if (topic.isEmpty) {
          throw const FormatException('Topic cannot be empty.');
        }

        if (difficulty.isEmpty) {
          throw const FormatException(
            'Difficulty must be Easy, Medium or Hard.',
          );
        }

        questions.add(
          McqModel(
            id: '',
            question: question,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanation,
            yearId: yearId,
            subject: subject,
            topic: topic,
            difficulty: difficulty,
            createdBy: adminUid,
            isPublished: false,
          ),
        );
      } catch (error) {
        errors.add(
          McqImportError(
            lineNumber: i + 1,
            message: error is FormatException
                ? error.message
                : 'Unable to process this row.',
            originalLine: originalLine,
          ),
        );
      }
    }

    return McqImportResult(
      questions: questions,
      errors: errors,
      totalRows: totalRows,
    );
  }

  static List<String> _splitEscapedPipes(String line) {
    final fields = <String>[];
    final current = StringBuffer();

    bool escaped = false;

    for (int i = 0; i < line.length; i++) {
      final character = line[i];

      if (escaped) {
        if (character == '|' || character == r'\') {
          current.write(character);
        } else {
          current.write(r'\');
          current.write(character);
        }

        escaped = false;
        continue;
      }

      if (character == r'\') {
        escaped = true;
        continue;
      }

      if (character == '|') {
        fields.add(current.toString());
        current.clear();
        continue;
      }

      current.write(character);
    }

    if (escaped) {
      current.write(r'\');
    }

    fields.add(current.toString());

    return fields;
  }

  static String _normalizeDifficulty(String value) {
    for (final level in _difficultyLevels) {
      if (level.toLowerCase() == value.toLowerCase()) {
        return level;
      }
    }

    return '';
  }
}
