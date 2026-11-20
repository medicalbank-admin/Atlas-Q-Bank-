import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'student_mcq_result_screen.dart';

class StudentMcqHistoryScreen extends StatelessWidget {
  const StudentMcqHistoryScreen({super.key});

  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color ivory = Color(0xFFF7F8F5);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Practice History',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: user == null
          ? _message('Please sign in to view your practice history.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('mcq_attempts')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('completedAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: teal),
                  );
                }

                if (snapshot.hasError) {
                  return _message(
                    'Unable to load your practice history. '
                    'Please try again later.',
                  );
                }

                final documents = snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return _emptyHistory(context);
                }

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _summaryBanner(documents.length),
                    const SizedBox(height: 20),
                    const Text(
                      'Previous Sessions',
                      style: TextStyle(
                        color: navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 13),
                    ...documents.map(
                      (document) => _historyCard(
                        context,
                        document.id,
                        document.data(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Showing your 50 most recent sessions.',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _summaryBanner(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navy, teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: gold,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Learning Journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count recent practice sessions',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(
    BuildContext context,
    String attemptId,
    Map<String, dynamic> data,
  ) {
    final total = _number(data['totalQuestions']);
    final correct = _number(data['correctAnswers']);

    final unanswered = data['unansweredQuestions'] == null
        ? 0
        : _number(data['unansweredQuestions']);

    final incorrect = data['incorrectAnswers'] == null
        ? (total - correct - unanswered).clamp(0, total)
        : _number(data['incorrectAnswers']);

    final percentage = _decimal(data['percentage']);

    final subject = data['subject']?.toString().trim().isNotEmpty == true
        ? data['subject'].toString()
        : 'Mixed subjects';

    final color = percentage >= 70
        ? const Color(0xFF23865B)
        : percentage >= 40
            ? const Color(0xFFB18425)
            : const Color(0xFFC44B4B);

    final completedAt = data['completedAt'];

    DateTime? date;

    if (completedAt is Timestamp) {
      date = completedAt.toDate();
    } else if (completedAt is DateTime) {
      date = completedAt;
    }

    final dateLabel = date == null
        ? 'Date unavailable'
        : '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentMcqResultScreen(
                attemptId: attemptId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  _metric('Questions', total.toString(), navy),
                  _metric(
                    'Correct',
                    correct.toString(),
                    const Color(0xFF23865B),
                  ),
                  _metric(
                    'Incorrect',
                    incorrect.toString(),
                    const Color(0xFFC44B4B),
                  ),
                  _metric(
                    'Unanswered',
                    unanswered.toString(),
                    const Color(0xFFB18425),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: percentage.clamp(0, 100) / 100,
                  minHeight: 6,
                  backgroundColor: ivory,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Review Answers',
                    style: TextStyle(
                      color: teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: teal,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 62,
              color: teal,
            ),
            const SizedBox(height: 17),
            const Text(
              'No Practice History Yet',
              style: TextStyle(
                color: navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your first MCQ practice session '
              'and your results will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: teal,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: navy,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _decimal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
