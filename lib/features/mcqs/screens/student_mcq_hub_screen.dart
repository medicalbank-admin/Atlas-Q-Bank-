import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import 'student_mcq_practice_screen.dart';
import 'student_mcq_history_screen.dart';
class StudentMcqHubScreen extends StatelessWidget {
  const StudentMcqHubScreen({super.key});
  void _openPractice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentMcqPracticeScreen(),
      ),
    );
  }
  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentMcqHistoryScreen(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: const Text('MCQ Learning Centre'),
        backgroundColor: AtlasColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroCard(context),
            const SizedBox(height: 29),
            const _SectionHeading(
              title: 'Your Learning Tools',
              subtitle: 'Choose how you want to prepare today',
            ),
            const SizedBox(height: 16),
            _FeatureCard(
              icon: Icons.play_circle_fill_rounded,
              title: 'Start MCQ Practice',
              description:
                  'Challenge yourself with medical questions and '
                  'strengthen your subject knowledge.',
              buttonText: 'Start Practicing',
              accent: AtlasColors.royalBlue,
              onTap: () => _openPractice(context),
            ),
            const SizedBox(height: 14),
            _FeatureCard(
              icon: Icons.history_rounded,
              title: 'Practice History',
              description:
                  'Revisit your previous attempts and review '
                  'your performance and answers.',
              buttonText: 'View History',
              accent: AtlasColors.gold,
              onTap: () => _openHistory(context),
            ),
            const SizedBox(height: 23),
            _tipCard(),
            const SizedBox(height: 27),
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.school_rounded,
                    color: AtlasColors.champagne,
                    size: 25,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'THE ATLAS ACADEMY',
                    style: TextStyle(
                      color: AtlasColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'EXCELLENCE IN MEDICAL EDUCATION',
                    style: TextStyle(
                      color: AtlasColors.secondaryText,
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
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
  Widget _heroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
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
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: 5,
            child: Icon(
              Icons.psychology_rounded,
              size: 125,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AtlasColors.champagne,
                  size: 29,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Learn. Practice. Excel.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Strengthen your medical knowledge through '
                'focused MCQ practice and detailed review.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 23),
              SizedBox(
                width: double.infinity,
                height: 51,
                child: FilledButton(
                  onPressed: () => _openPractice(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AtlasColors.champagne,
                    foregroundColor: AtlasColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 22),
                      SizedBox(width: 7),
                      Text(
                        'Begin Practice',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _tipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AtlasColors.paleBlue,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AtlasColors.royalBlue.withValues(alpha: 0.10),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: AtlasColors.gold,
              size: 22,
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A Study Tip',
                  style: TextStyle(
                    color: AtlasColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Read the explanation after every practice '
                  'session. Understanding why an answer is correct '
                  'is just as important as remembering it.',
                  style: TextStyle(
                    color: AtlasColors.secondaryText,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AtlasColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AtlasColors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final Color accent;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: AtlasColors.border),
            boxShadow: [
              BoxShadow(
                color: AtlasColors.navy.withValues(alpha: 0.035),
                blurRadius: 13,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AtlasColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AtlasColors.secondaryText,
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Text(
                          buttonText,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: accent,
                          size: 15,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
