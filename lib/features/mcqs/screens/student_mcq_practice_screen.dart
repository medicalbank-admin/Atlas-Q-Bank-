import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/student_mcq_model.dart';
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
  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color ivory = Color(0xFFF7F8F5);
  static const Color charcoal = Color(0xFF202A30);
  static const Color softTeal = Color(0xFFE5F1EF);
  final McqSessionService _sessionService = McqSessionService();
  List<StudentMcqModel> _questions = [];
  List<int?> _selectedAnswers = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  late DateTime _startedAt;
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
          .map((doc) => StudentMcqModel.fromFirestore(doc))
          .toList();
      questions.shuffle(Random());
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _selectedAnswers =
            List<int?>.filled(questions.length, null);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showMessage(
        'Unable to load questions. Please try again.',
        isError: true,
      );
    }
  }
  void _selectAnswer(int index) {
    if (_isSubmitting) return;
    setState(() {
      _selectedAnswers[_currentIndex] = index;
    });
  }
  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }
  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }
  Future<void> _finishPractice() async {
    if (_isSubmitting || _questions.isEmpty) return;
    final unanswered = _selectedAnswers
        .where((answer) => answer == null)
        .length;
    if (unanswered > 0) {
      final shouldFinish = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unanswered Questions'),
          content: Text(
            'You have $unanswered unanswered questions. '
            'Do you still want to submit your practice?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Continue Practice'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (shouldFinish != true) return;
    } else {
      final shouldFinish = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finish Practice'),
          content: const Text(
            'Are you sure you want to submit your answers?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (shouldFinish != true) return;
    }
    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      final selectedAnswers = <String, int?>{};
      for (var i = 0; i < _questions.length; i++) {
        selectedAnswers[_questions[i].id] =
            _selectedAnswers[i];
      }
      final attemptId =
          await _sessionService.saveCompletedSession(
        questionIds:
            _questions.map((question) => question.id).toList(),
        selectedAnswers: selectedAnswers,
        startedAt: _startedAt,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentMcqResultScreen(
            attemptId: attemptId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      _showMessage(
        'Unable to submit your practice. Please try again.',
        isError: true,
      );
    }
  }
  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  void _showQuestionNavigator() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ivory,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Question Navigator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(
                    _questions.length,
                    (index) {
                      final answered =
                          _selectedAnswers[index] != null;
                      final current = index == _currentIndex;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: current
                                ? navy
                                : answered
                                    ? softTeal
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: current
                                  ? gold
                                  : answered
                                      ? teal
                                      : Colors.grey.shade300,
                              width: current ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: current
                                  ? Colors.white
                                  : navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _legendDot(softTeal, teal),
                    const SizedBox(width: 6),
                    const Text('Answered'),
                    const SizedBox(width: 18),
                    _legendDot(Colors.white, Colors.grey),
                    const SizedBox(width: 6),
                    const Text('Unanswered'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _legendDot(Color color, Color border) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MCQ Practice',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading && _questions.isNotEmpty)
            IconButton(
              tooltip: 'Question Navigator',
              onPressed: _showQuestionNavigator,
              icon: const Icon(Icons.grid_view_rounded),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: teal),
      );
    }
    if (_questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 58,
                color: teal,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Questions Available',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'There are currently no published questions. '
                'Please check again later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: charcoal),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
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
    final question = _questions[_currentIndex];
    return Column(
      children: [
        _buildProgressHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionMetadata(question),
                const SizedBox(height: 20),
                _buildQuestionCard(question),
                const SizedBox(height: 22),
                _buildOptions(question),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
        _buildBottomNavigation(),
      ],
    );
  }
  Widget _buildProgressHeader() {
    final progress =
        (_currentIndex + 1) / _questions.length;
    final answered = _selectedAnswers
        .where((answer) => answer != null)
        .length;
    return Container(
      color: navy,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
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
                '$answered answered',
                style: const TextStyle(
                  color: Color(0xFFD8E8E6),
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
    );
  }
  Widget _buildQuestionMetadata(StudentMcqModel question) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metadataChip(question.subject),
        if (question.topic.isNotEmpty)
          _metadataChip(question.topic),
        if (question.difficulty.isNotEmpty)
          _metadataChip(question.difficulty),
      ],
    );
  }
  Widget _metadataChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: softTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: navy,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  Widget _buildQuestionCard(StudentMcqModel question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E9E7)),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUESTION ${_currentIndex + 1}',
            style: const TextStyle(
              color: teal,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            question.question,
            style: const TextStyle(
              color: charcoal,
              fontSize: 18,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (question.reference.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Reference: ${question.reference}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildOptions(StudentMcqModel question) {
    return Column(
      children: List.generate(
        question.options.length,
        (index) {
          final selected =
              _selectedAnswers[_currentIndex] == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _selectAnswer(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  color: selected ? softTeal : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? teal : Colors.grey.shade300,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? navy : ivory,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          color: selected ? Colors.white : navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        question.options[index],
                        style: const TextStyle(
                          color: charcoal,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: teal,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildBottomNavigation() {
    final isLast =
        _currentIndex == _questions.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed:
                _currentIndex == 0 ? null : _previousQuestion,
            style: OutlinedButton.styleFrom(
              foregroundColor: navy,
              side: const BorderSide(color: teal),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            child: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _isSubmitting
                  ? null
                  : isLast
                      ? _finishPractice
                      : _nextQuestion,
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLast ? 'Submit Practice' : 'Next Question',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed:
                isLast ? null : _nextQuestion,
            style: OutlinedButton.styleFrom(
              foregroundColor: navy,
              side: const BorderSide(color: teal),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            child: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}
