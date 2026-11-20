import 'package:flutter/material.dart';

import '../services/mcq_session_service.dart';

class StudentMcqResultScreen extends StatefulWidget {
  const StudentMcqResultScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<StudentMcqResultScreen> createState() =>
      _StudentMcqResultScreenState();
}

class _StudentMcqResultScreenState
    extends State<StudentMcqResultScreen> {
  final McqSessionService _service = McqSessionService();

  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color ivory = Color(0xFFF7F8F5);

  late Future<Map<String, dynamic>> _resultFuture;

  @override
  void initState() {
    super.initState();
    _resultFuture = _service.getMySession(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Practice Result',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                _resultFuture =
                    _service.getMySession(widget.sessionId);
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _resultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: teal),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _errorView();
          }

          return _buildResult(snapshot.data!);
        },
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 50,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load this result.',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> data) {
    final total = (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final correct = (data['correctAnswers'] as num?)?.toInt() ?? 0;
    final incorrect =
        (data['incorrectAnswers'] as num?)?.toInt() ?? 0;
    final percentage =
        (data['percentage'] as num?)?.toInt() ?? 0;

    final answers = (data['answers'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final subject = data['subject']?.toString() ?? 'Mixed subjects';
    final topic = data['topic']?.toString() ?? 'Mixed topics';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scoreCard(
            percentage: percentage,
            correct: correct,
            total: total,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Correct',
                  correct.toString(),
                  const Color(0xFF23865B),
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  'Incorrect',
                  incorrect.toString(),
                  const Color(0xFFC44B4B),
                  Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  'Total',
                  total.toString(),
                  navy,
                  Icons.quiz_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _informationCard(subject, topic),
          const SizedBox(height: 26),
          const Text(
            'Detailed Answer Review',
            style: TextStyle(
              color: navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (answers.isEmpty)
            _emptyReview()
          else
            ...List.generate(
              answers.length,
              (index) => _answerCard(answers[index], index),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Dashboard'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _scoreCard({
    required int percentage,
    required int correct,
    required int total,
  }) {
    final Color scoreColor = percentage >= 70
        ? const Color(0xFF23865B)
        : percentage >= 40
            ? gold
            : const Color(0xFFC44B4B);

    final message = percentage >= 80
        ? 'Excellent performance!'
        : percentage >= 60
            ? 'Good work. Keep improving!'
            : percentage >= 40
                ? 'You are making progress!'
                : 'Keep practicing. You can improve!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'YOUR FINAL SCORE',
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 142,
            height: 142,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 142,
                  height: 142,
                  child: CircularProgressIndicator(
                    value: (percentage.clamp(0, 100)) / 100,
                    strokeWidth: 11,
                    backgroundColor: Colors.white24,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$correct correct answers out of $total questions',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _informationCard(String subject, String topic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.menu_book_outlined, 'Subject', subject),
          const Divider(height: 22),
          _infoRow(Icons.topic_outlined, 'Topic', topic),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: teal, size: 20),
        const SizedBox(width: 11),
        Text(
          '$title: ',
          style: const TextStyle(
            color: navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _answerCard(Map<String, dynamic> answer, int index) {
    final question = answer['question']?.toString() ?? '';
    final options =
        (answer['options'] as List<dynamic>? ?? [])
            .map((option) => option.toString())
            .toList();

    final selected = answer['selectedAnswer']?.toString() ?? '';
    final correct = answer['correctAnswer']?.toString() ?? '';
    final isCorrect = answer['isCorrect'] == true;
    final explanation = answer['explanation']?.toString() ?? '';

    final subject = answer['subject']?.toString() ?? '';
    final topic = answer['topic']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF23865B).withValues(alpha: 0.25)
              : const Color(0xFFC44B4B).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'QUESTION ${index + 1}',
                  style: const TextStyle(
                    color: teal,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFFE5F3EA)
                      : const Color(0xFFFCE9E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCorrect ? 'Correct' : 'Incorrect',
                  style: TextStyle(
                    color: isCorrect
                        ? const Color(0xFF23865B)
                        : const Color(0xFFC44B4B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: const TextStyle(
              color: navy,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          ...List.generate(options.length, (optionIndex) {
            final letter = String.fromCharCode(65 + optionIndex);
            final isSelected = letter == selected;
            final isCorrectOption = letter == correct;

            Color background = ivory;
            Color border = Colors.transparent;
            Color textColor = navy;
            IconData? icon;

            if (isCorrectOption) {
              background = const Color(0xFFE5F3EA);
              border = const Color(0xFF23865B);
              textColor = const Color(0xFF176B47);
              icon = Icons.check_circle;
            } else if (isSelected) {
              background = const Color(0xFFFCE9E9);
              border = const Color(0xFFC44B4B);
              textColor = const Color(0xFFAD3434);
              icon = Icons.cancel;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Text(
                    '$letter.',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      options[optionIndex],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, color: textColor, size: 18),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Your answer: ${selected.isEmpty ? 'Not answered' : selected}',
            style: const TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Correct answer: $correct',
            style: const TextStyle(
              color: Color(0xFF23865B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPLANATION',
                    style: TextStyle(
                      color: teal,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    explanation,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (subject.isNotEmpty || topic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              [subject, topic]
                  .where((value) => value.isNotEmpty)
                  .join(' • '),
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyReview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Detailed answers are not available for this older practice session.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}
