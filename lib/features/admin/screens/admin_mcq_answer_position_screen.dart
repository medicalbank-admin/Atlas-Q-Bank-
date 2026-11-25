import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../services/mcq_answer_position_corrector_service.dart';

class AdminMcqAnswerPositionScreen extends StatefulWidget {
  const AdminMcqAnswerPositionScreen({super.key});

  @override
  State<AdminMcqAnswerPositionScreen> createState() =>
      _AdminMcqAnswerPositionScreenState();
}

class _AdminMcqAnswerPositionScreenState
    extends State<AdminMcqAnswerPositionScreen> {
  final _service = McqAnswerPositionCorrectorService();
  McqAnswerPositionAudit? _audit;
  McqAnswerPositionCorrectionResult? _result;
  bool _scanning = false;
  bool _correcting = false;
  int _completed = 0;
  int _total = 0;
  String? _error;

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
      _result = null;
    });
    try {
      final report = await _service.audit();
      if (!mounted) return;
      setState(() => _audit = report);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _correct() async {
    final audit = _audit;
    if (audit == null || audit.eligible <= 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Correct answer positions?'),
        content: Text(
          'This will rearrange the options for up to ${audit.eligible} '
          'questions whose private answer key is A. The correct answer text '
          'will be moved, the private answer key will be updated, and an '
          'administrator-only backup will be created for every changed MCQ. '
          'Question wording, distractors and explanations will be preserved. '
          'This operation changes answer positions only; it does not medically '
          're-verify the original answers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create backups & correct'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _correcting = true;
      _completed = 0;
      _total = audit.eligible;
      _error = null;
      _result = null;
    });
    try {
      final result = await _service.correctAllA(
        onProgress: (completed, total) {
          if (!mounted) return;
          setState(() {
            _completed = completed;
            _total = total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _audit = null;
      });
      await _scan();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _correcting = false);
    }
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AtlasColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(
              color: color ?? AtlasColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            )),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  Widget _distribution(McqAnswerPositionAudit audit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current correct-answer distribution',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(
              children: ['A', 'B', 'C', 'D', 'E'].map((letter) {
                final count = audit.distribution[letter] ?? 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Text('$count', style: const TextStyle(
                          color: AtlasColors.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        )),
                        const SizedBox(height: 6),
                        Container(
                          height: 7,
                          decoration: BoxDecoration(
                            color: letter == 'A'
                                ? AtlasColors.error
                                : AtlasColors.royalBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(letter, style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audit = _audit;
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(title: const Text('MCQ Answer Position Corrector')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE7F1FF), Color(0xFFF7FAFF)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AtlasColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shuffle_rounded,
                      color: AtlasColors.royalBlue, size: 30),
                  SizedBox(height: 10),
                  Text('Remove answer-position bias',
                      style: TextStyle(
                        color: AtlasColors.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      )),
                  SizedBox(height: 7),
                  Text(
                    'Scan the complete MCQ bank, then move answers currently '
                    'keyed as A to balanced alternative positions. Original '
                    'question and answer-key data are backed up before changes.',
                    style: TextStyle(
                      color: AtlasColors.secondaryText,
                      height: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_scanning || _correcting) ? null : _scan,
                    icon: _scanning
                        ? const SizedBox(
                            width: 17, height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.analytics_outlined),
                    label: Text(_scanning ? 'Scanning...' : 'Scan question bank'),
                  ),
                ),
              ],
            ),
            if (audit != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _stat('Total MCQs', '${audit.totalQuestions}'),
                  const SizedBox(width: 9),
                  _stat('Correct at A', '${audit.correctAtA}',
                      color: AtlasColors.error),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  _stat('Ready to correct', '${audit.eligible}',
                      color: AtlasColors.success),
                  const SizedBox(width: 9),
                  _stat('Already backed up', '${audit.alreadyBackedUp}'),
                ],
              ),
              const SizedBox(height: 14),
              _distribution(audit),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data quality checks',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      _checkLine('Missing answer keys', audit.missingAnswerKey),
                      _checkLine('Invalid answer keys', audit.invalidAnswerKey),
                      _checkLine('Unsupported option sets', audit.unsupportedOptions),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: (_correcting || audit.eligible <= 0) ? null : _correct,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: Text('Back up & correct ${audit.eligible} MCQs'),
              ),
            ],
            if (_correcting) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _total == 0 ? null : _completed / _total,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Text('Processing $_completed of $_total questions...',
                  textAlign: TextAlign.center),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.check_circle, color: AtlasColors.success),
                        SizedBox(width: 8),
                        Text('Correction completed',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                      ]),
                      const SizedBox(height: 10),
                      Text('${_result!.corrected} MCQs corrected successfully.'),
                      Text('${_result!.skipped} MCQs skipped.'),
                      const SizedBox(height: 10),
                      Text('New correct-answer positions: ${_result!.finalPositions.entries.where((e) => e.key != 'A' && e.value > 0).map((e) => '${e.key}: ${e.value}').join('  •  ')}'),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: AtlasColors.error)),
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'Important: this tool trusts the existing private answer key. '
              'It preserves that answer and only changes its position. It '
              'cannot determine whether the original medical answer itself '
              'is correct. Every changed MCQ receives a private backup.',
              style: TextStyle(
                color: AtlasColors.secondaryText,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkLine(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 12))),
          Text('$count', style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AtlasColors.navy,
          )),
        ],
      ),
    );
  }
}
