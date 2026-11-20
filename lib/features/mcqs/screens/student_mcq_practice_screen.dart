import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/mcq_model.dart';
import '../services/mcq_session_service.dart';
import 'student_mcq_result_screen.dart';

class StudentMcqPracticeScreen extends StatefulWidget {
  const StudentMcqPracticeScreen({super.key});

  @override
  State<StudentMcqPracticeScreen> createState() =>
      _StudentMcqPracticeScreenState();
}

class _StudentMcqPracticeScreenState
    extends State<StudentMcqPracticeScreen> {
  final McqSessionService _sessionService = McqSessionService();

  List<McqModel> _questions = [];
  List<int?> _selectedAnswers = [];

  bool _loading = true;
  bool _saving = false;
  String? _error;

  int _currentIndex = 0;
  late DateTime _startedAt;

  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color ivory = Color(0xFFF7F8F5);

  int get _answeredCount =>
      _selectedAnswers.where((answer) => answer != null).length;

  int get _unansweredCount =>
      _questions.length - _answeredCount;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mcqs')
          .where('isPublished', isEqualTo: true)
          .get();

      final questions = snapshot.docs
          .map((doc) => McqModel.fromFirestore(doc))
          .toList();

      questions.shuffle(Random());

      if (!mounted) return;

      if (questions.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No published MCQs are available yet.';
        });
        return;
      }

      setState(() {
        _questions = questions;
        _selectedAnswers =
            List<int?>.filled(questions.length, null);
        _loading = false;
        _startedAt = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load questions. Please try again.';
      });
    }
  }

  void _selectAnswer(int index) {
    if (_saving) return;

    setState(() {
      _selectedAnswers[_currentIndex] = index;
    });
  }

  void _goToQuestion(int index) {
    if (_saving || index < 0 || index >= _questions.length) return;

    setState(() {
      _currentIndex = index;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _goToQuestion(_currentIndex + 1);
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      _goToQuestion(_currentIndex - 1);
    }
  }

  Future<void> _showQuestionNavigator() async {
    if (_saving) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, refreshSheet) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: ivory,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Question Navigator',
                    style: TextStyle(
                      color: navy,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_answeredCount answered • $_unansweredCount remaining',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 11,
                    runSpacing: 11,
                    children: List.generate(_questions.length, (index) {
                      final answered =
                          _selectedAnswers[index] != null;
                      final current = index == _currentIndex;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _goToQuestion(index);
                        },
                        child: Container(
                          width: 43,
                          height: 43,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: current
                                ? navy
                                : answered
                                    ? teal.withValues(alpha: 0.13)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: current
                                  ? navy
                                  : answered
                                      ? teal
                                      : Colors.black12,
                              width: current ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: current
                                  ? Colors.white
                                  : answered
                                      ? teal
                                      : navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _legend(teal, 'Answered'),
                      const SizedBox(width: 18),
                      _legend(Colors.white, 'Unanswered'),
                      const SizedBox(width: 18),
                      _legend(navy, 'Current'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Continue Practice'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _finishPractice() async {
    if (_saving || _questions.isEmpty) return;

    if (_unansweredCount > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Finish Practice?'),
          content: Text(
            'You have answered $_answeredCount out of '
            '${_questions.length} questions.\n\n'
            '$_unansweredCount questions are still unanswered. '
            'Unanswered questions will not receive marks.\n\n'
            'Would you like to finish?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Continue Practice'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: navy,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Finish'),
            ),
          ],
        ),
      );

      if (!mounted || confirm != true) return;
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Submit Your Practice?'),
          content: const Text(
            'You have answered every question. '
            'Are you ready to submit your practice session?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Review Answers'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: navy,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (!mounted || confirm != true) return;
    }

    setState(() => _saving = true);

    try {
      final selectedAnswers = <String, int?>{
        for (int i = 0; i < _questions.length; i++)
          _questions[i].id: _selectedAnswers[i],
      };

      final sessionId = await _sessionService.saveCompletedSession(
        questions: _questions,
        selectedAnswers: selectedAnswers,
        startedAt: _startedAt,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentMcqResultScreen(
            sessionId: sessionId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save result: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );

      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'MCQ Practice',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_loading && _error == null && _questions.isNotEmpty)
            IconButton(
              tooltip: 'Question Navigator',
              onPressed: _saving ? null : _showQuestionNavigator,
              icon: const Icon(Icons.grid_view_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: teal),
            )
          : _error != null
              ? _buildError()
              : _buildPractice(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.quiz_outlined,
              size: 55,
              color: teal,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadQuestions();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPractice() {
    final question = _questions[_currentIndex];
    final selectedAnswer = _selectedAnswers[_currentIndex];

    final progress = (_currentIndex + 1) / _questions.length;

    return Column(
      children: [
        Container(
          color: navy,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of ${_questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(gold),
                ),
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _headerStat(
                    Icons.check_circle_outline,
                    '$_answeredCount Answered',
                  ),
                  _headerStat(
                    Icons.pending_outlined,
                    '$_unansweredCount Remaining',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tag(question.subject, teal),
                    _tag(question.topic, navy),
                    _tag(question.difficulty, gold),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'QUESTION',
                  style: TextStyle(
                    color: teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 25),
                ...List.generate(
                  question.options.length,
                  (index) => _buildOption(
                    index,
                    question.options[index],
                    selectedAnswer == index,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigation(),
      ],
    );
  }

  Widget _headerStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: gold, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _tag(String value, Color color) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color == gold ? navy : color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOption(
    int index,
    String option,
    bool selected,
  ) {
    final letter = String.fromCharCode(65 + index);

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? teal.withValues(alpha: 0.09)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? teal : Colors.black12,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? teal : ivory,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: selected ? Colors.white : navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option,
                style: const TextStyle(
                  color: navy,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: teal),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _currentIndex == 0 || _saving
                          ? null
                          : _previousQuestion,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed:
                      _currentIndex == _questions.length - 1 || _saving
                          ? null
                          : _nextQuestion,
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _showQuestionNavigator,
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('View All Questions'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _finishPractice,
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Finish Practice'),
            ),
          ),
        ],
      ),
    );
  }
}
