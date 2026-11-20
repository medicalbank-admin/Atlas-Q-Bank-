import 'package:flutter/material.dart';

import '../services/mcq_session_service.dart';

class StudentMcqResultScreen extends StatefulWidget {
  final String sessionId;

  const StudentMcqResultScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<StudentMcqResultScreen> createState() =>
      _StudentMcqResultScreenState();
}

class _StudentMcqResultScreenState
    extends State<StudentMcqResultScreen> {
  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color background = Color(0xFFF7F8F5);

  final McqSessionService _service = McqSessionService();

  late Future<Map<String, dynamic>?> _resultFuture;

  @override
  void initState() {
    super.initState();
    _resultFuture = _service.getMySession(widget.sessionId);
  }

  Color _resultColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF16845B);
    if (percentage >= 50) return const Color(0xFFE09B32);
    return const Color(0xFFD9534F);
  }

  String _grade(double percentage) {
    if (percentage >= 90) return 'Outstanding';
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 70) return 'Very Good';
    if (percentage >= 60) return 'Good';
    if (percentage >= 50) return 'Needs Improvement';
    return 'Keep Practising';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Practice Result',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _resultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: teal),
            );
          }

          if (snapshot.hasError) {
            return _message(
              'Unable to load your result.',
              'Please check your connection and try again.',
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return _message(
              'Result not found',
              'This practice result is unavailable or does not belong to your account.',
            );
          }

          return _buildResult(data);
        },
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> data) {
    final total = (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final correct = (data['correctAnswers'] as num?)?.toInt() ?? 0;
    final incorrect = (data['incorrectAnswers'] as num?)?.toInt() ?? 0;
    final unanswered =
        (data['unansweredQuestions'] as num?)?.toInt() ??
        (total - correct - incorrect).clamp(0, total);

    final percentage =
        (data['percentage'] as num?)?.toDouble() ?? 0;

    final answers = (data['answers'] as List<dynamic>?) ?? [];

    final resultColor = _resultColor(percentage);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
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
              const Icon(
                Icons.emoji_events_rounded,
                color: gold,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Performance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _grade(percentage),
                style: const TextStyle(
                  color: gold,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : correct / total,
                  minHeight: 9,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(gold),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$correct correct out of $total questions',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          'Result Breakdown',
          style: TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _statCard(
                'Correct',
                correct,
                const Color(0xFF16845B),
                Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _statCard(
                'Incorrect',
                incorrect,
                const Color(0xFFD9534F),
                Icons.cancel_rounded,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _statCard(
                'Unanswered',
                unanswered,
                const Color(0xFFE09B32),
                Icons.remove_circle_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'Question Review',
          style: TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Review your selected answers and explanations.',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 14),

        if (answers.isEmpty)
          const Text('No detailed question review is available.')
        else
          ...List.generate(
            answers.length,
            (index) {
              final raw = answers[index];

              if (raw is! Map) {
                return const SizedBox.shrink();
              }

              return _questionCard(
                Map<String, dynamic>.from(raw),
                index,
              );
            },
          ),

        const SizedBox(height: 24),

        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.popUntil(
                context,
                (route) => route.isFirst,
              );
            },
            icon: const Icon(Icons.dashboard_rounded),
            label: const Text(
              'Back to Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _statCard(
    String label,
    int value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 9),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(
    Map<String, dynamic> answer,
    int index,
  ) {
    final question =
        answer['question']?.toString() ?? '';

    final options =
        (answer['options'] as List<dynamic>?) ?? [];

    final selected =
        answer['selectedAnswer']?.toString();

    final correct =
        answer['correctAnswer']?.toString() ?? '';

    final explanation =
        answer['explanation']?.toString() ?? '';

    final isAnswered =
        answer['isAnswered'] == true || selected != null;

    final isCorrect = answer['isCorrect'] == true;

    final Color statusColor = !isAnswered
        ? const Color(0xFFE09B32)
        : isCorrect
            ? const Color(0xFF16845B)
            : const Color(0xFFD9534F);

    final String status = !isAnswered
        ? 'Unanswered'
        : isCorrect
            ? 'Correct'
            : 'Incorrect';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            question,
            style: const TextStyle(
              color: Color(0xFF202A30),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 13),

          ...List.generate(options.length, (optionIndex) {
            final letter =
                String.fromCharCode(65 + optionIndex);

            final option = options[optionIndex].toString();

            final isCorrectOption = letter == correct;
            final isSelectedOption = letter == selected;

            Color optionColor = Colors.black54;
            Color optionBackground = const Color(0xFFF7F8F5);
            IconData? optionIcon;

            if (isCorrectOption) {
              optionColor = const Color(0xFF16845B);
              optionBackground = const Color(0xFFE7F5EE);
              optionIcon = Icons.check_circle_rounded;
            } else if (isSelectedOption) {
              optionColor = const Color(0xFFD9534F);
              optionBackground = const Color(0xFFFFEEEE);
              optionIcon = Icons.cancel_rounded;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: optionBackground,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  Text(
                    '$letter.',
                    style: TextStyle(
                      color: optionColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: optionColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (optionIcon != null)
                    Icon(
                      optionIcon,
                      color: optionColor,
                      size: 18,
                    ),
                ],
              ),
            );
          }),

          if (!isAnswered) ...[
            const SizedBox(height: 8),
            const Text(
              'You did not select an answer.',
              style: TextStyle(
                color: Color(0xFFE09B32),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],

          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explanation',
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    explanation,
                    style: const TextStyle(
                      color: Color(0xFF40565A),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if ((answer['subject'] ?? '').toString().isNotEmpty ||
              (answer['topic'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              [
                if ((answer['subject'] ?? '').toString().isNotEmpty)
                  answer['subject'].toString(),
                if ((answer['topic'] ?? '').toString().isNotEmpty)
                  answer['topic'].toString(),
              ].join(' • '),
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

  Widget _message(String title, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: teal,
              size: 45,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
