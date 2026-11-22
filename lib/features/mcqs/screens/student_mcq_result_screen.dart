import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../services/mcq_session_service.dart';
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
  final McqSessionService _service = McqSessionService();
  late Future<Map<String, dynamic>?> _resultFuture;
  @override
  void initState() {
    super.initState();
    _resultFuture = _service.getMySession(widget.attemptId);
  }
  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
  double _decimal(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
  Color _scoreColor(double score) {
    if (score >= 80) return AtlasColors.success;
    if (score >= 50) return AtlasColors.gold;
    return AtlasColors.error;
  }
  String _grade(double score) {
    if (score >= 90) return 'Outstanding Performance';
    if (score >= 80) return 'Excellent Work';
    if (score >= 70) return 'Very Good';
    if (score >= 60) return 'Good Progress';
    if (score >= 50) return 'Keep Improving';
    return 'Keep Practising';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        title: const Text('Practice Result'),
        backgroundColor: Colors.white,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _resultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AtlasColors.royalBlue,
              ),
            );
          }
          if (snapshot.hasError) {
            return const _ResultMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load result',
              message: 'Please check your connection and try again.',
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const _ResultMessage(
              icon: Icons.receipt_long_outlined,
              title: 'Result not found',
              message:
                  'This practice result is unavailable or does not belong '
                  'to your account.',
            );
          }
          return _buildResult(data);
        },
      ),
    );
  }
  Widget _buildResult(Map<String, dynamic> data) {
    final total = _number(data['totalQuestions']);
    final correct = _number(data['correctAnswers']);
    final incorrect = _number(data['incorrectAnswers']);
    final unanswered = data['unansweredQuestions'] == null
        ? (total - correct - incorrect).clamp(0, total)
        : _number(data['unansweredQuestions']);
    final percentage = _decimal(data['percentage']).clamp(0.0, 100.0);
    final answers = data['answers'] is List
        ? data['answers'] as List
        : <dynamic>[];
    final scoreColor = _scoreColor(percentage);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        _performanceCard(
          percentage: percentage,
          correct: correct,
          total: total,
          scoreColor: scoreColor,
        ),
        const SizedBox(height: 25),
        const Text(
          'Result Breakdown',
          style: TextStyle(
            color: AtlasColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Correct',
                value: correct,
                icon: Icons.check_circle_rounded,
                color: AtlasColors.success,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _StatCard(
                label: 'Incorrect',
                value: incorrect,
                icon: Icons.cancel_rounded,
                color: AtlasColors.error,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _StatCard(
                label: 'Skipped',
                value: unanswered,
                icon: Icons.remove_circle_rounded,
                color: AtlasColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 27),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Question Review',
                style: TextStyle(
                  color: AtlasColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AtlasColors.paleBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${answers.length} Questions',
                style: const TextStyle(
                  color: AtlasColors.royalBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Review your selected answers and explanations.',
          style: TextStyle(
            color: AtlasColors.secondaryText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 15),
        if (answers.isEmpty)
          const _NoReviewCard()
        else
          ...List.generate(answers.length, (index) {
            final raw = answers[index];
            if (raw is! Map) {
              return const SizedBox.shrink();
            }
            return _QuestionReviewCard(
              answer: Map<String, dynamic>.from(raw),
              index: index,
            );
          }),
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
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
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AtlasColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _performanceCard({
    required double percentage,
    required int correct,
    required int total,
    required Color scoreColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(25),
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
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.17),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 57,
            width: 57,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AtlasColors.champagne.withValues(alpha: 0.6),
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AtlasColors.champagne,
              size: 31,
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'YOUR PERFORMANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 43,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            _grade(percentage),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AtlasColors.champagne,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AtlasColors.champagne,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$correct correct out of $total questions',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.55),
              ),
            ),
            child: Text(
              percentage >= 70
                  ? 'Strong performance'
                  : 'More practice will help you improve',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 9),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
class _QuestionReviewCard extends StatelessWidget {
  final Map<String, dynamic> answer;
  final int index;
  const _QuestionReviewCard({
    required this.answer,
    required this.index,
  });
  @override
  Widget build(BuildContext context) {
    final question = answer['question']?.toString() ?? '';
    final options = answer['options'] is List
        ? answer['options'] as List
        : <dynamic>[];
    final selected = answer['selectedAnswer']?.toString();
    final correct = answer['correctAnswer']?.toString() ?? '';
    final explanation = answer['explanation']?.toString() ?? '';
    final isAnswered =
        answer['isAnswered'] == true || selected != null;
    final isCorrect = answer['isCorrect'] == true;
    final statusColor = !isAnswered
        ? AtlasColors.gold
        : isCorrect
            ? AtlasColors.success
            : AtlasColors.error;
    final status = !isAnswered
        ? 'Unanswered'
        : isCorrect
            ? 'Correct'
            : 'Incorrect';
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.035),
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
                  'QUESTION ${index + 1}',
                  style: const TextStyle(
                    color: AtlasColors.royalBlue,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question,
            style: const TextStyle(
              color: AtlasColors.charcoal,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          ...List.generate(options.length, (optionIndex) {
            final letter = String.fromCharCode(65 + optionIndex);
            final option = options[optionIndex].toString();
            final isCorrectOption = letter == correct;
            final isSelectedOption = letter == selected;
            Color textColor = AtlasColors.secondaryText;
            Color background = AtlasColors.ivory;
            IconData? trailingIcon;
            if (isCorrectOption) {
              textColor = AtlasColors.success;
              background = const Color(0xFFE9F6EF);
              trailingIcon = Icons.check_circle_rounded;
            } else if (isSelectedOption) {
              textColor = AtlasColors.error;
              background = const Color(0xFFFFEEEE);
              trailingIcon = Icons.cancel_rounded;
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '$letter.',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: isCorrectOption || isSelectedOption
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    Icon(
                      trailingIcon,
                      color: textColor,
                      size: 18,
                    ),
                ],
              ),
            );
          }),
          if (!isAnswered) ...[
            const SizedBox(height: 5),
            const Text(
              'You did not select an answer.',
              style: TextStyle(
                color: AtlasColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AtlasColors.paleBlue,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AtlasColors.royalBlue,
                        size: 17,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Explanation',
                        style: TextStyle(
                          color: AtlasColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    explanation,
                    style: const TextStyle(
                      color: AtlasColors.charcoal,
                      fontSize: 12,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if ((answer['subject'] ?? '').toString().isNotEmpty ||
              (answer['topic'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              [
                if ((answer['subject'] ?? '').toString().isNotEmpty)
                  answer['subject'].toString(),
                if ((answer['topic'] ?? '').toString().isNotEmpty)
                  answer['topic'].toString(),
              ].join(' • '),
              style: const TextStyle(
                color: AtlasColors.secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class _NoReviewCard extends StatelessWidget {
  const _NoReviewCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AtlasColors.border),
      ),
      child: const Text(
        'No detailed question review is available for this session.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AtlasColors.secondaryText,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}
class _ResultMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _ResultMessage({
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: AtlasColors.paleBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: AtlasColors.royalBlue,
                size: 35,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AtlasColors.navy,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
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
