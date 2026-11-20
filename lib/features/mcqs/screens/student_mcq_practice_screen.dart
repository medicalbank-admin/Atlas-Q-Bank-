
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
    } catch (e) {
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

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _finishPractice() async {
    if (_saving) return;

    final unanswered =
        _selectedAnswers.where((answer) => answer == null).length;

    if (unanswered > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Unanswered Questions'),
          content: Text(
            'You still have $unanswered unanswered questions. '
            'Would you like to finish anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Continue Practice'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Finish'),
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
                      _currentIndex == 0 ? null : _previousQuestion,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _currentIndex == _questions.length - 1
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
