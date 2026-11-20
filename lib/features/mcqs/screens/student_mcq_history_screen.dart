import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/mcq_attempt_service.dart';

class StudentMcqHistoryScreen extends StatelessWidget {
  const StudentMcqHistoryScreen({super.key});

  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color ivory = Color(0xFFF7F8F5);

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: teal, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
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

  Widget _attemptCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final total = (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final correct = (data['correctAnswers'] as num?)?.toInt() ?? 0;
    final incorrect = (data['incorrectAnswers'] as num?)?.toInt() ??
        (total - correct);
    final percentage = (data['percentage'] as num?)?.toInt() ?? 0;

    final subject = data['subject']?.toString() ?? '';
    final topic = data['topic']?.toString() ?? '';

    final completedAt = data['completedAt'];
    DateTime? date;

    if (completedAt is Timestamp) {
      date = completedAt.toDate();
    }

    final scoreColor = percentage >= 80
        ? Colors.green
        : percentage >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.isEmpty ? 'General Practice' : subject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (topic.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              topic,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : correct / total,
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _resultValue('Total', '$total'),
              _resultValue('Correct', '$correct'),
              _resultValue('Incorrect', '$incorrect'),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: teal,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  date == null
                      ? 'Completion date unavailable'
                      : DateFormat('dd MMM yyyy, hh:mm a').format(date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Icon(
                Icons.check_circle_outline,
                size: 17,
                color: teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultValue(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = McqAttemptService();

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text('Practice History'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.watchMyAttempts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load your practice history.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history,
                        size: 45,
                        color: teal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Practice History Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your completed MCQ practice sessions '
                      'will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: teal,
                      ),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalAttempts = documents.length;

          final totalQuestions = documents.fold<int>(
            0,
            (sum, doc) =>
                sum + ((doc.data()['totalQuestions'] as num?)?.toInt() ?? 0),
          );

          final totalCorrect = documents.fold<int>(
            0,
            (sum, doc) =>
                sum + ((doc.data()['correctAnswers'] as num?)?.toInt() ?? 0),
          );

          final overallPercentage = totalQuestions == 0
              ? 0
              : (totalCorrect / totalQuestions * 100).round();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [navy, teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Learning Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Keep practising to strengthen your medical knowledge.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _statCard(
                          title: 'Sessions',
                          value: '$totalAttempts',
                          icon: Icons.assignment_outlined,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          title: 'Questions',
                          value: '$totalQuestions',
                          icon: Icons.quiz_outlined,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          title: 'Accuracy',
                          value: '$overallPercentage%',
                          icon: Icons.trending_up,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 23),
              const Text(
                'Previous Practice Sessions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 14),
              ...documents.map(
                (document) => _attemptCard(context, document),
              ),
            ],
          );
        },
      ),
    );
  }
}
