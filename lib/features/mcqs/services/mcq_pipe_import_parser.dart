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
    String trackType = 'structured',
    String subjectId = '',
    String examSetId = '',
    String examSetName = '',
  }) {
    final questions = <McqModel>[];
    final errors = <McqImportError>[];

    final cleanYearId = yearId.trim();
    final cleanAdminUid = adminUid.trim();

    if (!['structured', 'past_paper'].contains(trackType) || (trackType == 'structured' && cleanYearId != 'exam_centre') || cleanAdminUid.isEmpty || examSetId.trim().isEmpty || subjectId.trim().isEmpty) {
      return const McqImportResult(
        questions: [],
        errors: [
          McqImportError(
            lineNumber: 1,
            message:
                'Select a valid destination and administrator account before importing.',
            originalLine: '',
          ),
        ],
        totalRows: 0,
      );
    }

    final lines = input.split('\n');

    int totalRows = 0;
    bool headerChecked = false;

    for (int i = 0; i < lines.length; i++) {
      String originalLine = lines[i].replaceAll('\r', '');

      // Remove a possible UTF-8 BOM.
      if (i == 0 && originalLine.startsWith('\uFEFF')) {
        originalLine = originalLine.substring(1);
      }

      if (originalLine.trim().isEmpty) {
        continue;
      }

      // Allow a header after any number of blank lines.
      if (!headerChecked) {
        headerChecked = true;

        final firstField = _splitEscapedPipes(
          originalLine,
        ).first.trim().toLowerCase();

        if (firstField == 'question') {
          continue;
        }
      }

      totalRows++;

      try {
        final fields = _splitEscapedPipes(originalLine);

        if (fields.length != 10 && fields.length != 11) {
          throw FormatException(
            'Expected 10 fields for four options or '
            '11 fields for five options, but found '
            '${fields.length}.',
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

        final String subject =
            fields[subjectIndex].trim();

        final String topic =
            fields[topicIndex].trim();

        final String difficulty = _normalizeDifficulty(
          fields[difficultyIndex].trim(),
        );

        if (question.isEmpty) {
          throw const FormatException(
            'Question cannot be empty.',
          );
        }

        if (question.length > 5000) {
          throw const FormatException(
            'Question cannot exceed 5000 characters.',
          );
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

          if (options[optionIndex].length > 2000) {
            throw FormatException(
              'Option ${String.fromCharCode(65 + optionIndex)} '
              'cannot exceed 2000 characters.',
            );
          }
        }

        if (options.toSet().length != options.length) {
          throw const FormatException(
            'Duplicate options are not allowed.',
          );
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
          throw const FormatException(
            'Subject cannot be empty.',
          );
        }

        if (subject.length > 150) {
          throw const FormatException(
            'Subject cannot exceed 150 characters.',
          );
        }

        if (topic.isEmpty) {
          throw const FormatException(
            'Topic cannot be empty.',
          );
        }

        if (topic.length > 150) {
          throw const FormatException(
            'Topic cannot exceed 150 characters.',
          );
        }

        if (explanation.length > 10000) {
          throw const FormatException(
            'Explanation cannot exceed 10000 characters.',
          );
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
            yearId: cleanYearId,
            trackType: trackType,
            subjectId: subjectId,
            examSetId: examSetId,
            examSetName: examSetName,
            subject: subject,
            topic: topic,
            difficulty: difficulty,
            createdBy: cleanAdminUid,
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
