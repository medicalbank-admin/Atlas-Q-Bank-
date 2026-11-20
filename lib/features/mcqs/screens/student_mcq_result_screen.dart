import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/mcq_attempt_service.dart';

class StudentMcqResultScreen extends StatefulWidget {
  final String attemptId;

  const StudentMcqResultScreen({
    super.key,
    required this.attemptId,
  });

  @override
  State<StudentMcqResultScreen> createState() =>
      _StudentMcqResultScreenState();
}

class _StudentMcqResultScreenState
    extends State<StudentMcqResultScreen> {
  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color ivory = Color(0xFFF7F8F5);

  final McqAttemptService _service = McqAttemptService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    try {
      final document =
          await _service.getMyAttempt(widget.attemptId);

      if (!mounted) return;

      setState(() {
        _result = document.data();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 9),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final data = _result!;

    final total =
        (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final correct =
        (data['correctAnswers'] as num?)?.toInt() ?? 0;
    final incorrect =
        (data['incorrectAnswers'] as num?)?.toInt() ??
            total - correct;
    final percentage =
        (data['percentage'] as num?)?.toInt() ?? 0;

    final completedAt = data['completedAt'];
    DateTime? date;

    if (completedAt is Timestamp) {
      date = completedAt.toDate();
    }

    final color = percentage >= 80
        ? Colors.green
        : percentage >= 50
            ? Colors.orange
            : Colors.red;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [navy, teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 45,
                color: Color(0xFFD8B66B),
              ),
              const SizedBox(height: 12),
              const Text(
                'Practice Result',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$correct correct out of $total questions',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              if (date != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}/'
                  '${date.year}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _summaryCard(
              label: 'Correct',
              value: '$correct',
              color: Colors.green,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(width: 10),
            _summaryCard(
              label: 'Incorrect',
              value: '$incorrect',
              color: Colors.red,
              icon: Icons.cancel_outlined,
            ),
            const SizedBox(width: 10),
            _summaryCard(
              label: 'Total',
              value: '$total',
              color: teal,
              icon: Icons.quiz_outlined,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Session Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 12),
        _infoRow('Subject', data['subject']?.toString() ?? 'General'),
        _infoRow('Topic', data['topic']?.toString() ?? 'All topics'),
        _infoRow('Session type', data['type']?.toString() ?? 'Practice'),
        _infoRow('Accuracy', '$percentage%'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.insights_outlined, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  percentage >= 80
                      ? 'Excellent work! Keep maintaining your performance.'
                      : percentage >= 50
                          ? 'Good effort. Review the topics you found difficult.'
                          : 'Keep practising and review your explanations carefully.',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Question Review',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Detailed answers will appear here once the practice '
          'screen saves each selected answer and explanation.',
          style: TextStyle(
            color: Colors.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Practice History'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text('Result Details'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load this result.\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _result == null
                  ? const Center(
                      child: Text('Result not found.'),
                    )
                  : _buildResult(),
    );
  }
}
