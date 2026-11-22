import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import 'student_mcq_result_screen.dart';
class StudentMcqHistoryScreen extends StatelessWidget {
  const StudentMcqHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        title: const Text('Practice History'),
        backgroundColor: Colors.white,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: user == null
          ? const _HistoryMessage(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in required',
              message: 'Please sign in to view your practice history.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('mcq_attempts')
                  .where('userId', isEqualTo: user.uid)
                  .limit(200)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AtlasColors.royalBlue,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const _HistoryMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Unable to load history',
                    message:
                        'Please check your connection and try again later.',
                  );
                }
                final documents = [...(snapshot.data?.docs ?? [])]
                  ..sort((a, b) {
                    final aValue = a.data()['completedAt'] ?? a.data()['createdAt'];
                    final bValue = b.data()['completedAt'] ?? b.data()['createdAt'];
                    final aTime = aValue is Timestamp ? aValue : Timestamp(0, 0);
                    final bTime = bValue is Timestamp ? bValue : Timestamp(0, 0);
                    return bTime.compareTo(aTime);
                  });
                final recentDocuments = documents.take(50).toList();
                if (documents.isEmpty) {
                  return const _HistoryMessage(
                    icon: Icons.auto_stories_rounded,
                    title: 'Your journey starts here',
                    message:
                        'Complete your first MCQ practice session. '
                        'Your results will appear here.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  children: [
                    _HistoryHeader(count: documents.length),
                    const SizedBox(height: 25),
                    const Text(
                      'Previous Sessions',
                      style: TextStyle(
                        color: AtlasColors.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 13),
                    ...recentDocuments.map(
                      (document) => _SessionCard(
                        attemptId: document.id,
                        data: document.data(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Showing your 50 most recent sessions',
                        style: TextStyle(
                          color: AtlasColors.secondaryText,
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
}
class _HistoryHeader extends StatelessWidget {
  final int count;
  const _HistoryHeader({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AtlasColors.navy,
            AtlasColors.royalBlue,
            AtlasColors.brightBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AtlasColors.champagne,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Learning Journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
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
          const Icon(
            Icons.auto_awesome_rounded,
            color: AtlasColors.champagne,
            size: 23,
          ),
        ],
      ),
    );
  }
}
class _SessionCard extends StatelessWidget {
  final String attemptId;
  final Map<String, dynamic> data;
  const _SessionCard({
    required this.attemptId,
    required this.data,
  });
  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
  double _decimal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
  @override
  Widget build(BuildContext context) {
    final total = _number(data['totalQuestions']);
    final correct = _number(data['correctAnswers']);
    final unanswered = _number(data['unansweredQuestions']);
    final incorrect = data['incorrectAnswers'] == null
        ? (total - correct - unanswered).clamp(0, total)
        : _number(data['incorrectAnswers']);
    final percentage = _decimal(data['percentage']).clamp(0.0, 100.0);
    final subject = data['subject']?.toString().trim().isNotEmpty == true
        ? data['subject'].toString()
        : 'Mixed subjects';
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
    final scoreColor = percentage >= 70
        ? AtlasColors.success
        : percentage >= 40
            ? AtlasColors.gold
            : AtlasColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AtlasColors.border),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.045),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
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
                    Container(
                      height: 43,
                      width: 43,
                      decoration: BoxDecoration(
                        color: AtlasColors.paleBlue,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AtlasColors.royalBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AtlasColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              color: AtlasColors.secondaryText,
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
                        color: scoreColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    _Metric(
                      label: 'Questions',
                      value: total,
                      color: AtlasColors.navy,
                    ),
                    _Metric(
                      label: 'Correct',
                      value: correct,
                      color: AtlasColors.success,
                    ),
                    _Metric(
                      label: 'Incorrect',
                      value: incorrect,
                      color: AtlasColors.error,
                    ),
                    _Metric(
                      label: 'Skipped',
                      value: unanswered,
                      color: AtlasColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 7,
                    backgroundColor: AtlasColors.paleBlue,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                const SizedBox(height: 13),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Review Answers',
                      style: TextStyle(
                        color: AtlasColors.royalBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AtlasColors.royalBlue,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _Metric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
class _HistoryMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: AtlasColors.paleBlue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: AtlasColors.royalBlue,
                size: 35,
              ),
            ),
            const SizedBox(height: 19),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AtlasColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AtlasColors.secondaryText,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
