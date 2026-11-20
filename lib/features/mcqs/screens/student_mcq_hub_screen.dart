import 'package:flutter/material.dart';

import 'student_mcq_practice_screen.dart';
import 'student_mcq_history_screen.dart';

class StudentMcqHubScreen extends StatelessWidget {
  const StudentMcqHubScreen({super.key});

  static const Color navy = Color(0xFF123F46);
  static const Color teal = Color(0xFF28777B);
  static const Color gold = Color(0xFFD8B66B);
  static const Color ivory = Color(0xFFF7F8F5);

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _featureCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required String buttonText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor, size: 27),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: teal,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonText),
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
        title: const Text('MCQ Learning Centre'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [navy, teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    color: gold,
                    size: 35,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Master Your Medical MCQs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Practise important medical questions, '
                    'understand explanations and track your progress.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Your Learning Tools',
              style: TextStyle(
                color: navy,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _featureCard(
              context: context,
              title: 'MCQ Practice',
              description:
                  'Attempt published questions, choose answers, '
                  'check explanations and improve your knowledge.',
              icon: Icons.quiz_outlined,
              iconColor: teal,
              buttonText: 'Start Practising',
              onTap: () => _openScreen(
                context,
                const StudentMcqPracticeScreen(),
              ),
            ),
            _featureCard(
              context: context,
              title: 'Practice History',
              description:
                  'Review your previous practice sessions, '
                  'scores, accuracy and learning progress.',
              icon: Icons.history,
              iconColor: gold,
              buttonText: 'View History',
              onTap: () => _openScreen(
                context,
                const StudentMcqHistoryScreen(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: teal),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Study tip: Focus on understanding why an '
                      'answer is correct, not just memorising it.',
                      style: TextStyle(
                        color: navy,
                        height: 1.5,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
