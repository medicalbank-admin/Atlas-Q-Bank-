import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../auth/screens/student_account_status_screen.dart';
import '../../auth/services/student_auth_service.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await StudentAuthService().signOut();

      if (!context.mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to sign out. Please try again.'),
        ),
      );
    }
  }

  void _openAccountStatus(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StudentAccountStatusScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Student';

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AtlasColors.deepTeal,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: AtlasColors.champagne,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THE ATLAS ACADEMY',
                              style: TextStyle(
                                color: AtlasColors.deepTeal,
                                fontSize: 12,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Student Portal',
                              style: TextStyle(
                                color: AtlasColors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Account status',
                        onPressed: () => _openAccountStatus(context),
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          color: AtlasColors.deepTeal,
                          size: 27,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sign out',
                        onPressed: () => _signOut(context),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AtlasColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(23),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AtlasColors.deepTeal,
                          AtlasColors.oceanTeal,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AtlasColors.deepTeal.withValues(
                            alpha: 0.16,
                          ),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR MEDICAL JOURNEY',
                          style: TextStyle(
                            color: AtlasColors.champagne,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          'Welcome back,\\n$displayName',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Every study session brings you one step '
                          'closer to your goals.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: AtlasColors.champagne,
                                size: 17,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Learn. Practice. Excel.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 27),
                  const _SectionHeading(
                    title: 'Your Learning Space',
                    subtitle: 'Everything you need to keep progressing',
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 13,
                    crossAxisSpacing: 13,
                    childAspectRatio: 1.12,
                    children: const [
                      _LearningTile(
                        icon: Icons.menu_book_rounded,
                        title: 'Study Library',
                        subtitle: 'Notes and resources',
                      ),
                      _LearningTile(
                        icon: Icons.quiz_rounded,
                        title: 'MCQ Practice',
                        subtitle: 'Test your knowledge',
                      ),
                      _LearningTile(
                        icon: Icons.assignment_rounded,
                        title: 'Examinations',
                        subtitle: 'Attempt assessments',
                      ),
                      _LearningTile(
                        icon: Icons.route_rounded,
                        title: 'Exam Pathways',
                        subtitle: 'Explore your pathway',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeading(
                    title: 'Your Progress',
                    subtitle: 'Your learning statistics will appear here',
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AtlasColors.softTeal,
                      ),
                    ),
                    child: const Column(
                      children: [
                        _ProgressRow(
                          icon: Icons.menu_book_rounded,
                          title: 'Study materials completed',
                          value: 'Coming soon',
                        ),
                        Divider(height: 25),
                        _ProgressRow(
                          icon: Icons.quiz_outlined,
                          title: 'MCQs attempted',
                          value: 'Coming soon',
                        ),
                        Divider(height: 25),
                        _ProgressRow(
                          icon: Icons.emoji_events_outlined,
                          title: 'Examination results',
                          value: 'Coming soon',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  OutlinedButton.icon(
                    onPressed: () => _openAccountStatus(context),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('View Account and Membership Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AtlasColors.deepTeal,
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(
                        color: AtlasColors.oceanTeal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'THE ATLAS ACADEMY  •  EXCELLENCE IN MEDICAL EDUCATION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AtlasColors.secondaryText,
                        fontSize: 9,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
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
            color: AtlasColors.deepTeal,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AtlasColors.secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _LearningTile extends StatelessWidget {
  const _LearningTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AtlasColors.softTeal,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AtlasColors.softTeal,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: AtlasColors.deepTeal,
              size: 22,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AtlasColors.charcoal,
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
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AtlasColors.oceanTeal,
          size: 21,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AtlasColors.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
