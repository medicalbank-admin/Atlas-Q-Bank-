import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/mcq_model.dart';

class StudentMcqPracticeScreen extends StatefulWidget {
  const StudentMcqPracticeScreen({super.key});

  @override
  State<StudentMcqPracticeScreen> createState() =>
      _StudentMcqPracticeScreenState();
}

class _StudentMcqPracticeScreenState
    extends State<StudentMcqPracticeScreen> {
  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color ivory = Color(0xFFF7F8F5);

  List<McqModel> _questions = [];

  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;

  bool _answered = false;
  bool _loading = true;
  bool _finished = false;

  String? _error;

  @override
  void initState() {
    super.initState();
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
          .where((question) =>
              question.options.length >= 4 &&
              question.options.length <= 5 &&
              question.hasValidAnswer)
          .toList();

      questions.shuffle();

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _selectAnswer(int index) {
    if (_answered || _finished) return;

    setState(() {
      _selectedOption = index;
      _answered = true;

      final selectedLetter = String.fromCharCode(65 + index);

      if (selectedLetter == _currentQuestion.correctAnswer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _questions.length) {
      setState(() {
        _finished = true;
      });
      return;
    }

    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _answered = false;
    });
  }

  void _restartPractice() {
    setState(() {
      _questions.shuffle();
      _currentIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _finished = false;
    });
  }

  McqModel get _currentQuestion => _questions[_currentIndex];

  Color _optionColor(int index) {
    if (!_answered) {
      return _selectedOption == index
          ? teal.withValues(alpha: 0.12)
          : Colors.white;
    }

    final letter = String.fromCharCode(65 + index);

    if (letter == _currentQuestion.correctAnswer) {
      return Colors.green.withValues(alpha: 0.12);
    }

    if (_selectedOption == index) {
      return Colors.red.withValues(alpha: 0.10);
    }

    return Colors.white;
  }

  Color _optionBorderColor(int index) {
    if (!_answered) {
      return _selectedOption == index ? teal : Colors.grey.shade300;
    }

    final letter = String.fromCharCode(65 + index);

    if (letter == _currentQuestion.correctAnswer) {
      return Colors.green;
    }

    if (_selectedOption == index) {
      return Colors.red;
    }

    return Colors.grey.shade300;
  }

  Widget _buildOption(int index) {
    final letter = String.fromCharCode(65 + index);
    final isCorrect = letter == _currentQuestion.correctAnswer;
    final isSelected = _selectedOption == index;

    IconData? trailingIcon;

    if (_answered && isCorrect) {
      trailingIcon = Icons.check_circle;
    } else if (_answered && isSelected && !isCorrect) {
      trailingIcon = Icons.cancel;
    }

    return InkWell(
      onTap: () => _selectAnswer(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _optionColor(index),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _optionBorderColor(index),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _answered && isCorrect
                    ? Colors.green
                    : _answered && isSelected
                        ? Colors.red
                        : isSelected
                            ? teal
                            : ivory,
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (_answered && (isCorrect || isSelected)) ||
                          (!_answered && isSelected)
                      ? Colors.white
                      : navy,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                _currentQuestion.options[index],
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(
                trailingIcon,
                color: isCorrect ? Colors.green : Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final progress = (_currentIndex + 1) / _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: navy,
              ),
            ),
            Text(
              'Score: $_score',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: teal,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanation() {
    final correct = String.fromCharCode(
      65 + _currentQuestion.options.indexWhere(
        (option) =>
            option ==
            _currentQuestion.options[
                _currentQuestion.correctAnswer.codeUnitAt(0) - 65],
      ),
    );

    final isCorrect = _selectedOption != null &&
        String.fromCharCode(65 + _selectedOption!) ==
            _currentQuestion.correctAnswer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.info_outline,
                color: isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect ? 'Correct answer!' : 'Incorrect answer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Correct option: ${_currentQuestion.correctAnswer}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explanation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _currentQuestion.explanation.isEmpty
                ? 'No explanation is available for this question.'
                : _currentQuestion.explanation,
            style: const TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedScreen() {
    final percentage = _questions.isEmpty
        ? 0
        : ((_score / _questions.length) * 100).round();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                size: 54,
                color: gold,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Practice Completed!',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Great effort. Here is your practice summary.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: navy.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: teal,
                    ),
                  ),
                  const Text('Your score'),
                  const Divider(height: 28),
                  _summaryRow('Total questions', '${_questions.length}'),
                  _summaryRow('Correct answers', '$_score'),
                  _summaryRow(
                    'Incorrect answers',
                    '${_questions.length - _score}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restartPractice,
                icon: const Icon(Icons.refresh),
                label: const Text('Practice Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgress(),
          const SizedBox(height: 22),
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_currentQuestion.subject} • ${_currentQuestion.topic}',
                  style: const TextStyle(
                    color: teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentQuestion.difficulty,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: navy.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              _currentQuestion.question,
              style: const TextStyle(
                fontSize: 17,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: navy,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Choose the correct answer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            _currentQuestion.options.length,
            _buildOption,
          ),
          if (_answered) ...[
            const SizedBox(height: 10),
            _buildExplanation(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _nextQuestion,
                icon: Icon(
                  _currentIndex + 1 == _questions.length
                      ? Icons.flag_outlined
                      : Icons.arrow_forward,
                ),
                label: Text(
                  _currentIndex + 1 == _questions.length
                      ? 'Finish Practice'
                      : 'Next Question',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text('MCQ Practice'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 45,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to load questions.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
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
                )
              : _questions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No published MCQs are available yet. '
                          'Please check again later.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _finished
                      ? _buildFinishedScreen()
                      : _buildQuestionScreen(),
    );
  }
}
