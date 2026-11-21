import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../auth/screens/student_account_status_screen.dart';
import '../../auth/services/student_auth_service.dart';
import '../../mcqs/screens/student_mcq_hub_screen.dart';
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
  void _openMcqCentre(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StudentMcqHubScreen(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Student';
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Container(
                        height: 49,
                        width: 49,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AtlasColors.navy,
                              AtlasColors.royalBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AtlasColors.navy.withValues(alpha: 0.16),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
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
                                color: AtlasColors.navy,
                                fontSize: 12,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'STUDENT PORTAL',
                              style: TextStyle(
                                color: AtlasColors.secondaryText,
                                fontSize: 10,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _HeaderAction(
                        icon: Icons.person_outline_rounded,
                        tooltip: 'Account status',
                        onTap: () => _openAccountStatus(context),
                      ),
                      const SizedBox(width: 8),
                      _HeaderAction(
                        icon: Icons.logout_rounded,
                        tooltip: 'Sign out',
                        onTap: () => _signOut(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 27),
                  // Welcome banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(23, 25, 23, 23),
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
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: AtlasColors.navy.withValues(alpha: 0.20),
                          blurRadius: 24,
                          offset: const Offset(0, 11),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -25,
                          child: Icon(
                            Icons.school_rounded,
                            size: 155,
                            color: Colors.white.withValues(alpha: 0.055),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AtlasColors.champagne,
                                    size: 14,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'YOUR MEDICAL JOURNEY',
                                    style: TextStyle(
                                      color: AtlasColors.champagne,
                                      fontSize: 9,
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your next achievement starts with what '
                              'you learn today. Keep moving forward.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 21),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AtlasColors.champagne,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 16,
                                    color: AtlasColors.navy,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Learn. Practice. Excel.',
                                    style: TextStyle(
                                      color: AtlasColors.navy,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _SectionHeading(
                    title: 'Your Learning Space',
                    subtitle: 'Explore your academic resources',
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 13,
                    crossAxisSpacing: 13,
                    childAspectRatio: 1.05,
                    children: [
                      const _LearningTile(
                        icon: Icons.menu_book_rounded,
                        title: 'Study Library',
                        subtitle: 'Notes and resources',
                        accent: AtlasColors.royalBlue,
                      ),
                      _LearningTile(
                        icon: Icons.quiz_rounded,
                        title: 'MCQ Practice',
                        subtitle: 'Practice and review',
                        accent: AtlasColors.gold,
                        onTap: () => _openMcqCentre(context),
                      ),
                      const _LearningTile(
                        icon: Icons.assignment_rounded,
                        title: 'Examinations',
                        subtitle: 'Attempt assessments',
                        accent: AtlasColors.brightBlue,
                      ),
                      const _LearningTile(
                        icon: Icons.route_rounded,
                        title: 'Exam Pathways',
                        subtitle: 'Explore your pathway',
                        accent: AtlasColors.gold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const _SectionHeading(
                    title: 'Your Progress',
                    subtitle: 'Your academic journey at a glance',
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AtlasColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AtlasColors.navy.withValues(alpha: 0.035),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        _ProgressRow(
                          icon: Icons.menu_book_rounded,
                          title: 'Study materials completed',
                        ),
                        Divider(height: 25, color: AtlasColors.border),
                        _ProgressRow(
                          icon: Icons.quiz_outlined,
                          title: 'MCQs attempted',
                        ),
                        Divider(height: 25, color: AtlasColors.border),
                        _ProgressRow(
                          icon: Icons.emoji_events_outlined,
                          title: 'Examination results',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Account status card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openAccountStatus(context),
                      borderRadius: BorderRadius.circular(19),
                      child: Ink(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AtlasColors.paleBlue,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: AtlasColors.royalBlue.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 23,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.verified_user_outlined,
                                color: AtlasColors.royalBlue,
                              ),
                            ),
                            SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account & Membership',
                                    style: TextStyle(
                                      color: AtlasColors.navy,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'View your account status and details',
                                    style: TextStyle(
                                      color: AtlasColors.secondaryText,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: AtlasColors.royalBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 29),
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'THE ATLAS ACADEMY',
                          style: TextStyle(
                            color: AtlasColors.navy,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'EXCELLENCE IN MEDICAL EDUCATION',
                          style: TextStyle(
                            color: AtlasColors.secondaryText,
                            fontSize: 8,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AtlasColors.navy,
        fixedSize: const Size(42, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AtlasColors.border),
        ),
      ),
      icon: Icon(icon, size: 20),
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
class _LearningTile extends StatelessWidget {
  const _LearningTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: AtlasColors.border),
            boxShadow: [
              BoxShadow(
                color: AtlasColors.navy.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AtlasColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AtlasColors.secondaryText,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.icon,
    required this.title,
  });
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            color: AtlasColors.paleBlue,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: AtlasColors.royalBlue,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AtlasColors.charcoal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Text(
          'Coming soon',
          style: TextStyle(
            color: AtlasColors.secondaryText,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
