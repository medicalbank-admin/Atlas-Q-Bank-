import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../auth/screens/student_account_status_screen.dart';
import '../../auth/services/student_auth_service.dart';
import '../../mcqs/screens/student_mcq_hub_screen.dart';
import '../../subscriptions/screens/subscription_plans_screen.dart';
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
  Future<void> _openMcqCentre(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final data = profile.data() ?? {};
      final hasMembership = data['subscriptionStatus'] == 'active' &&
          data['accessEnabled'] == true;
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => hasMembership
            ? const StudentMcqHubScreen()
            : const SubscriptionPlansScreen(),
      ));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to check your membership. Please try again.')),
      );
    }
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
              padding: const EdgeInsets.fromLTRB(19, 13, 19, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(context),
                  const SizedBox(height: 25),
                  _buildWelcomeCard(displayName),
                  const SizedBox(height: 29),
                  _sectionHeading(
                    'Your Learning Space',
                    'Everything you need for your medical preparation',
                  ),
                  const SizedBox(height: 15),
                  _buildLearningGrid(context),
                  const SizedBox(height: 29),
                  _sectionHeading(
                    'Your Academic Journey',
                    'Keep track of your learning activities',
                  ),
                  const SizedBox(height: 15),
                  _buildProgressCard(),
                  const SizedBox(height: 23),
                  _buildAccountCard(context),
                  const SizedBox(height: 25),
                  _buildMotivationCard(),
                  const SizedBox(height: 28),
                  _buildFooter(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 49,
          width: 49,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AtlasColors.navy, AtlasColors.royalBlue],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AtlasColors.navy.withValues(alpha: 0.15),
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
              SizedBox(height: 4),
              Text(
                'STUDENT PORTAL',
                style: TextStyle(
                  color: AtlasColors.secondaryText,
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _HeaderButton(
          icon: Icons.person_outline_rounded,
          tooltip: 'Account',
          onTap: () => _openAccountStatus(context),
        ),
        const SizedBox(width: 8),
        _HeaderButton(
          icon: Icons.logout_rounded,
          tooltip: 'Sign out',
          onTap: () => _signOut(context),
        ),
      ],
    );
  }
  Widget _buildWelcomeCard(String displayName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 24, 23, 23),
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
            color: AtlasColors.navy.withValues(alpha: 0.19),
            blurRadius: 23,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
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
                    color: Colors.white.withValues(alpha: 0.15),
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
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
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
                'Your next achievement begins with what you learn today. '
                'Stay focused and keep moving forward.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.83),
                  fontSize: 12,
                  height: 1.65,
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
    );
  }
  Widget _sectionHeading(String title, String subtitle) {
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
            height: 1.5,
          ),
        ),
      ],
    );
  }
  Widget _buildLearningGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 13,
      crossAxisSpacing: 13,
      childAspectRatio: 1.04,
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
          subtitle: 'Assess your knowledge',
          accent: AtlasColors.brightBlue,
        ),
        const _LearningTile(
          icon: Icons.route_rounded,
          title: 'Exam Pathways',
          subtitle: 'Explore your pathway',
          accent: AtlasColors.gold,
        ),
      ],
    );
  }
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AtlasColors.border),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.navy.withValues(alpha: 0.035),
            blurRadius: 15,
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
    );
  }
  Widget _buildAccountCard(BuildContext context) {
    return Material(
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
                        fontWeight: FontWeight.w900,
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
    );
  }
  Widget _buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AtlasColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AtlasColors.paleBlue,
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: AtlasColors.gold,
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A Reminder for Today',
                  style: TextStyle(
                    color: AtlasColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Consistency is the foundation of excellence. '
                  'A little focused study every day can make a '
                  'remarkable difference.',
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
  Widget _buildFooter() {
    return const Center(
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
    );
  }
}
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
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
class _LearningTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;
  const _LearningTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });
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
                  fontWeight: FontWeight.w900,
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
  final IconData icon;
  final String title;
  const _ProgressRow({
    required this.icon,
    required this.title,
  });
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
