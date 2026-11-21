import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_academy/features/mcqs/services/mcq_pipe_import_parser.dart';

void main() {
  group('McqPipeImportParser', () {
    test('parses a valid four-option row and normalizes difficulty', () {
      final result = McqPipeImportParser.parse(
        input: 'Which chamber pumps blood to the lungs?|Right atrium|Right ventricle|Left atrium|Left ventricle|B|It pumps blood to the lungs.|Anatomy|Heart|easy',
        yearId: ' year-1 ',
        adminUid: ' admin-1 ',
      );

      expect(result.totalRows, 1);
      expect(result.successfulRows, 1);
      expect(result.failedRows, 0);
      expect(result.questions.single.correctAnswer, 'B');
      expect(result.questions.single.difficulty, 'Easy');
      expect(result.questions.single.yearId, 'year-1');
      expect(result.questions.single.createdBy, 'admin-1');
      expect(result.questions.single.isPublished, isFalse);
    });

    test('accepts five options and escaped pipe characters', () {
      final result = McqPipeImportParser.parse(
        input: r'Which symbol is literal\|? |A|B|C|D|E|E|Use A\|B as notation|Physics|Waves|HARD',
        yearId: 'year-1',
        adminUid: 'admin-1',
      );

      expect(result.successfulRows, 1);
      expect(result.questions.single.options, ['A', 'B', 'C', 'D', 'E']);
      expect(result.questions.single.question, contains('|'));
      expect(result.questions.single.difficulty, 'Hard');
    });

    test('reports malformed rows without discarding valid rows', () {
      final result = McqPipeImportParser.parse(
        input: 'Valid question|A|B|C|D|A|Reason|Biology|Cells|Medium\nBad row|A|B',
        yearId: 'year-1',
        adminUid: 'admin-1',
      );

      expect(result.totalRows, 2);
      expect(result.successfulRows, 1);
      expect(result.failedRows, 1);
      expect(result.errors.single.lineNumber, 2);
    });

    test('rejects missing administrator or academic year', () {
      final result = McqPipeImportParser.parse(
        input: 'Question|A|B|C|D|A|Reason|Biology|Cells|Easy',
        yearId: '',
        adminUid: 'admin-1',
      );

      expect(result.questions, isEmpty);
      expect(result.hasErrors, isTrue);
      expect(result.errors.single.message,
          contains('Academic year and administrator'));
    });
  });
}
