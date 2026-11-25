import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../mcqs/services/mcq_bulk_import_service.dart';
import '../../mcqs/services/mcq_pipe_import_parser.dart';
import '../widgets/mcq_destination_selector.dart';

class AdminMcqImportScreen extends StatefulWidget {
  const AdminMcqImportScreen({super.key});

  @override
  State<AdminMcqImportScreen> createState() =>
      _AdminMcqImportScreenState();
}

class _AdminMcqImportScreenState
    extends State<AdminMcqImportScreen> {
  final TextEditingController _inputController =
      TextEditingController();

  final McqBulkImportService _importService =
      McqBulkImportService();

  McqDestination? _destination;

  McqImportResult? _previewResult;

  bool _isImporting = false;
  bool _showAllQuestions = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _preparePreview() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in first.');
      return;
    }

    if (_destination == null) {
      _showMessage('Please select a track, subject and exam set.');
      return;
    }

    if (_inputController.text.trim().isEmpty) {
      _showMessage('Please paste your MCQs first.');
      return;
    }

    final result = McqPipeImportParser.parse(
      input: _inputController.text,
      yearId: _destination!.yearId,
      adminUid: user.uid,
      trackType: _destination!.trackType,
      subjectId: _destination!.subjectId,
      examSetId: _destination!.examSetId,
      examSetName: _destination!.examSetName,
    );

    setState(() {
      _previewResult = result;
      _showAllQuestions = false;
    });

    if (result.totalRows == 0) {
      _showMessage('No questions were found.');
    }
  }

  Future<void> _importQuestions() async {
    final result = _previewResult;

    if (result == null || result.questions.isEmpty) {
      _showMessage('There are no valid questions to import.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm MCQ Import'),
        content: Text(
          'You are about to import '
          '${result.questions.length} valid questions.\n\n'
          'Questions will remain unpublished until an '
          'administrator publishes them.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final saveResult = await _importService.importQuestions(
        questions: result.questions,
      );

      if (!mounted) return;

      setState(() {
        _previewResult = null;
        _inputController.clear();
        _showAllQuestions = false;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import Completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultRow(
                'Total submitted',
                saveResult.totalQuestions,
              ),
              _resultRow(
                'Successfully imported',
                saveResult.importedQuestions,
              ),
              _resultRow(
                'Duplicates skipped',
                saveResult.duplicateQuestions,
              ),
              if (saveResult.duplicateDetails.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Duplicate details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    itemCount: saveResult.duplicateDetails.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${saveResult.duplicateDetails[index]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Import failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Widget _resultRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSummaryCard() {
    final result = _previewResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _summaryItem(
                  'Total',
                  result.totalRows,
                  Colors.blue,
                ),
                _summaryItem(
                  'Valid',
                  result.successfulRows,
                  Colors.green,
                ),
                _summaryItem(
                  'Errors',
                  result.failedRows,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (result.questions.isNotEmpty) ...[
              const Text(
                'Valid questions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...result.questions
                  .take(_showAllQuestions ? result.questions.length : 5)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final question = entry.value;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 15,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    question.question,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${question.subject} • ${question.topic} • '
                    '${question.difficulty}',
                  ),
                );
              }),
              if (result.questions.length > 5)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllQuestions = !_showAllQuestions;
                    });
                  },
                  child: Text(
                    _showAllQuestions
                        ? 'Show fewer'
                        : 'Show all ${result.questions.length} questions',
                  ),
                ),
            ],
            if (result.errors.isNotEmpty) ...[
              const Divider(height: 28),
              const Text(
                'Validation errors',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...result.errors.map(
                (error) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Line ${error.lineNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(error.message),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
    String label,
    int count,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _previewResult;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        title: const Text('Bulk MCQ Import'),
        backgroundColor: const Color(0xFFF2F7FF),
        foregroundColor: const Color(0xFF123B68),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF123B68),
                      Color(0xFF2563A6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.library_add_check,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Import Multiple MCQs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Paste pipe-delimited questions, validate '
                      'them and import them into your question bank.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '1. Select MCQ Destination',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              McqDestinationSelector(
                onChanged: (value) => setState(() { _destination = value; _previewResult = null; }),
              ),
              const SizedBox(height: 24),
              const Text(
                '2. Paste Pipe-Delimited MCQs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Four-option rows contain 10 fields. '
                'Five-option rows contain 11 fields. '
                'Each question must be on a separate line.',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _inputController,
                // Keep the editor compact on mobile while allowing large pastes.
                // iOS Safari zooms focused inputs whose rendered text is below 16px.
                minLines: 8,
                maxLines: 14,
                enabled: !_isImporting,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textAlignVertical: TextAlignVertical.top,
                scrollPadding: const EdgeInsets.only(bottom: 140),
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  height: 1.35,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'Question|Option A|Option B|Option C|'
                      'Option D|Correct Answer|Explanation|'
                      'Subject|Topic|Difficulty\n\n'
                      'Which organelle produces ATP?|Ribosome|'
                      'Mitochondria|Golgi apparatus|Lysosome|'
                      'B|Mitochondria generate ATP.|'
                      'Biochemistry|Cell Biology|Easy',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isImporting
                    ? null
                    : _preparePreview,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Validate & Preview'),
              ),
              if (result != null) ...[
                const SizedBox(height: 22),
                _buildSummaryCard(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isImporting ||
                            result.questions.isEmpty
                        ? null
                        : _importQuestions,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _isImporting
                          ? 'Importing...'
                          : 'Import ${result.questions.length} Valid MCQs',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
