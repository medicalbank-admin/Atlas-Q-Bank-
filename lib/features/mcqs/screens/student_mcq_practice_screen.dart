import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../models/student_mcq_model.dart';
import '../services/mcq_session_service.dart';
import 'student_mcq_result_screen.dart';
class StudentMcqPracticeScreen extends StatefulWidget {
  final String? examSetId;
  const StudentMcqPracticeScreen({super.key, this.examSetId});
  @override
  State<StudentMcqPracticeScreen> createState() =>
      _StudentMcqPracticeScreenState();
}
class _StudentMcqPracticeScreenState
    extends State<StudentMcqPracticeScreen> {
  final McqSessionService _sessionService = McqSessionService();
  List<StudentMcqModel> _questions = [];
  List<int?> _selectedAnswers = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  DateTime? _deadlineAt;
  Timer? _countdownTimer;
  int? _remainingSeconds;
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }
  String? _sessionId;
  Future<void> _loadQuestions() async {
    try {
      final session = await _sessionService.startSession(
        examSetId: widget.examSetId,
      );
      final ids = List<String>.from(session['questionIds'] as List);
      final snapshots = await Future.wait(
        ids.map((id) => FirebaseFirestore.instance.collection('mcqs').doc(id).get()),
      );
      if (snapshots.any((doc) => !doc.exists || doc.data()?['isPublished'] != true)) {
        throw Exception('A question in this session is no longer published. Please start again.');
      }
      final questions = snapshots
          .map((doc) => StudentMcqModel.fromFirestore(doc))
          .toList();
      if (questions.isEmpty) {
        throw Exception('No published questions are available in this session.');
      }
      if (!mounted) return;
      setState(() {
        _sessionId = session['sessionId'] as String;
        _questions = questions;
        _selectedAnswers = List<int?>.filled(questions.length, null);
        _currentIndex = 0;
        _deadlineAt = DateTime.tryParse(session['expiresAt']?.toString() ?? '');
        _remainingSeconds = _deadlineAt == null
            ? (session['durationMinutes'] as int) * 60
            : _deadlineAt!.difference(DateTime.now()).inSeconds.clamp(0, 240 * 60).toInt();
        _isLoading = false;
      });
      _startCountdown();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isSubmitting) {
        timer.cancel();
        return;
      }
      final remaining = _deadlineAt == null
          ? (_remainingSeconds ?? 0) - 1
          : _deadlineAt!.difference(DateTime.now()).inSeconds;
      setState(() => _remainingSeconds = remaining < 0 ? 0 : remaining);
      if (remaining <= 0) {
        timer.cancel();
        _finishPractice(force: true);
      }
    });
  }
  String _formatRemainingTime() {
    final seconds = _remainingSeconds ?? 0;
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
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
  Future<void> _finishPractice({bool force = false}) async {
    if (_isSubmitting || _questions.isEmpty) return;
    final unanswered = _selectedAnswers
        .where((answer) => answer == null)
        .length;
    final shouldFinish = force ? true : await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          unanswered > 0
              ? 'Unanswered Questions'
              : 'Finish Practice',
          style: const TextStyle(
            color: AtlasColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unanswered questions. '
                  'Do you still want to submit your practice?'
              : 'Are you sure you want to submit your answers?',
          style: const TextStyle(
            color: AtlasColors.secondaryText,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue Practice'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AtlasColors.navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (shouldFinish != true || !mounted) return;
    _countdownTimer?.cancel();
    setState(() {
      _isSubmitting = true;
    });
    try {
      final selectedAnswers = <String, int?>{};
      for (var i = 0; i < _questions.length; i++) {
        selectedAnswers[_questions[i].id] = _selectedAnswers[i];
      }
      final attemptId = await _sessionService.saveCompletedSession(
        sessionId: _sessionId ?? '',
        selectedAnswers: selectedAnswers,
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
    } catch (_) {
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
        backgroundColor:
            isError ? AtlasColors.error : AtlasColors.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  void _showQuestionNavigator() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF3F7FF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(21, 13, 21, 25),
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
                const SizedBox(height: 21),
                const Text(
                  'Question Navigator',
                  style: TextStyle(
                    color: AtlasColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Select a question to jump directly to it.',
                  style: TextStyle(
                    color: AtlasColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(
                        _questions.length,
                        (index) {
                          final answered =
                              _selectedAnswers[index] != null;
                          final current = index == _currentIndex;
                          final background = current
                              ? AtlasColors.navy
                              : answered
                                  ? AtlasColors.paleBlue
                                  : Colors.white;
                          final border = current
                              ? AtlasColors.champagne
                              : answered
                                  ? AtlasColors.royalBlue
                                  : AtlasColors.border;
                          return InkWell(
                            borderRadius: BorderRadius.circular(13),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                            child: Container(
                              width: 45,
                              height: 45,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: background,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: border,
                                  width: current ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: current
                                      ? Colors.white
                                      : AtlasColors.navy,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                const Wrap(
                  spacing: 17,
                  runSpacing: 10,
                  children: [
                    _NavigatorLegend(
                      color: AtlasColors.paleBlue,
                      borderColor: AtlasColors.royalBlue,
                      label: 'Answered',
                    ),
                    _NavigatorLegend(
                      color: Colors.white,
                      borderColor: AtlasColors.border,
                      label: 'Unanswered',
                    ),
                    _NavigatorLegend(
                      color: AtlasColors.navy,
                      borderColor: AtlasColors.champagne,
                      label: 'Current',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MCQ Practice',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'THE ATLAS ACADEMY',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 1.3,
                color: AtlasColors.champagne,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLoading && _questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Center(
                child: Text(
                  _formatRemainingTime(),
                  style: TextStyle(
                    color: (_remainingSeconds ?? 0) <= 60
                        ? AtlasColors.error
                        : AtlasColors.champagne,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          if (!_isLoading && _questions.isNotEmpty)
            IconButton(
              tooltip: 'Question Navigator',
              onPressed: _showQuestionNavigator,
              icon: const Icon(Icons.grid_view_rounded),
            ),
          const SizedBox(width: 5),
        ],
      ),
      body: _buildBody(),
    );
  }
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AtlasColors.royalBlue,
        ),
      );
    }
    if (_questions.isEmpty) {
      return _buildEmptyState();
    }
    final question = _questions[_currentIndex];
    return Column(
      children: [
        _buildProgressHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(19, 20, 19, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionMetadata(question),
                const SizedBox(height: 17),
                _buildQuestionCard(question),
                const SizedBox(height: 22),
                _buildOptions(question),
              ],
            ),
          ),
        ),
        _buildBottomNavigation(),
      ],
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 85,
              width: 85,
              decoration: BoxDecoration(
                color: AtlasColors.paleBlue,
                borderRadius: BorderRadius.circular(27),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 42,
                color: AtlasColors.royalBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Questions Available',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: AtlasColors.navy,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'There are currently no published questions. '
              'Please check again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AtlasColors.secondaryText,
                height: 1.6,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadQuestions();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: AtlasColors.navy,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildProgressHeader() {
    final progress = (_currentIndex + 1) / _questions.length;
    final answered = _selectedAnswers
        .where((answer) => answer != null)
        .length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 21),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AtlasColors.navy,
            AtlasColors.royalBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(23),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUESTION ${_currentIndex + 1} / ${_questions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$answered answered',
                  style: const TextStyle(
                    color: AtlasColors.champagne,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AtlasColors.champagne,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).round()}% completed',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
              ),
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
        _metadataChip(
          Icons.book_outlined,
          question.subject,
        ),
        if (question.topic.isNotEmpty)
          _metadataChip(
            Icons.category_outlined,
            question.topic,
          ),
        if (question.difficulty.isNotEmpty)
          _metadataChip(
            Icons.signal_cellular_alt_rounded,
            question.difficulty,
          ),
      ],
    );
  }
  Widget _metadataChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AtlasColors.paleBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AtlasColors.royalBlue,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AtlasColors.navy,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildQuestionCard(StudentMcqModel question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AtlasColors.border),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: AtlasColors.paleBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: AtlasColors.royalBlue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'QUESTION',
                style: TextStyle(
                  color: AtlasColors.royalBlue,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            question.question,
            style: const TextStyle(
              color: AtlasColors.charcoal,
              fontSize: 17,
              height: 1.65,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (question.reference.isNotEmpty) ...[
            const SizedBox(height: 15),
            const Divider(color: AtlasColors.border),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 15,
                  color: AtlasColors.secondaryText,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Reference: ${question.reference}',
                    style: const TextStyle(
                      color: AtlasColors.secondaryText,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildOptions(StudentMcqModel question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12, left: 2),
          child: Text(
            'SELECT YOUR ANSWER',
            style: TextStyle(
              color: AtlasColors.navy,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ...List.generate(
          question.options.length,
          (index) {
            final selected = _selectedAnswers[_currentIndex] == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: () => _selectAnswer(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AtlasColors.paleBlue
                          : Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: selected
                            ? AtlasColors.royalBlue
                            : AtlasColors.border,
                        width: selected ? 1.8 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AtlasColors.royalBlue.withValues(
                                  alpha: 0.07,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 34,
                          width: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AtlasColors.navy
                                : AtlasColors.ivory,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AtlasColors.navy
                                  : AtlasColors.border,
                            ),
                          ),
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AtlasColors.navy,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: TextStyle(
                              color: AtlasColors.charcoal,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AtlasColors.royalBlue,
                            size: 21,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  Widget _buildBottomNavigation() {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 19),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AtlasColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 49,
            width: 49,
            child: OutlinedButton(
              onPressed: isFirst || _isSubmitting
                  ? null
                  : _previousQuestion,
              style: OutlinedButton.styleFrom(
                foregroundColor: AtlasColors.navy,
                side: const BorderSide(color: AtlasColors.border),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 49,
              child: FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : isLast
                        ? _finishPractice
                        : _nextQuestion,
                style: FilledButton.styleFrom(
                  backgroundColor: isLast
                      ? AtlasColors.gold
                      : AtlasColors.navy,
                  foregroundColor: isLast
                      ? AtlasColors.navy
                      : Colors.white,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'Submit Practice' : 'Next Question',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 17,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 49,
            width: 49,
            child: OutlinedButton(
              onPressed: isLast || _isSubmitting
                  ? null
                  : _nextQuestion,
              style: OutlinedButton.styleFrom(
                foregroundColor: AtlasColors.navy,
                side: const BorderSide(color: AtlasColors.border),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
class _NavigatorLegend extends StatelessWidget {
  const _NavigatorLegend({
    required this.color,
    required this.borderColor,
    required this.label,
  });
  final Color color;
  final Color borderColor;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AtlasColors.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
