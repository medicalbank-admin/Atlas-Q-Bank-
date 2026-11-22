import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/dashboard_announcement_welcome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_logo.dart';
import '../../profile/screens/profile_screen.dart';
import '../../auth/screens/student_account_status_screen.dart';
import '../../auth/services/student_auth_service.dart';
import '../../mcqs/screens/student_mcq_hub_screen.dart';
import '../../academic/screens/student_study_library_screen.dart';
import '../../academic/screens/student_exam_centre_screen.dart';
import '../../academic/screens/student_past_papers_screen.dart';
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
  Future<void> _openProtectedFeature(BuildContext context, String feature) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final data = profile.data() ?? {};
      final permissions = Map<String, dynamic>.from(
        data['subscriptionAccessPermissions'] ?? const {},
      );
      final expiry = data['subscriptionExpiryAt'];
      final notExpired = expiry is Timestamp && expiry.toDate().isAfter(DateTime.now());
      final hasFeaturePermission = feature == 'pastPapers'
          ? (permissions['pastPapers'] == true || permissions['examinations'] == true)
          : permissions[feature] == true;
      final hasAccess = data['subscriptionStatus'] == 'active' &&
          data['accessEnabled'] == true && notExpired && hasFeaturePermission;
      if (!context.mounted) return;
      if (!hasAccess) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()));
        return;
      }
      if (feature == 'mcqPractice') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentMcqHubScreen()));
      } else if (feature == 'studyLibrary') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentStudyLibraryScreen()));
      } else if (feature == 'pastPapers') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentPastPapersScreen()));
      } else if (feature == 'examinations' || feature == 'examPathways') {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentExamCentreScreen(pathwaysOnly: feature == 'examPathways')));
      }
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
                  DashboardAnnouncementWelcome(displayName: displayName),
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
        const AtlasLogo(size: 52),
        /*
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
        */
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
        InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          borderRadius: BorderRadius.circular(30),
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              final photo = (snapshot.data?.data()?['profileImageUrl'] ?? FirebaseAuth.instance.currentUser?.photoURL ?? '').toString();
              final name = (snapshot.data?.data()?['fullName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? '').toString();
              return CircleAvatar(
                radius: 22,
                backgroundColor: AtlasColors.paleBlue,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'A', style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)) : null,
              );
            },
          ),
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
        _LearningTile(
          icon: Icons.menu_book_rounded,
          title: 'Study Library',
          subtitle: 'Notes and resources',
          accent: AtlasColors.royalBlue,
          onTap: () => _openProtectedFeature(context, 'studyLibrary'),
        ),
        _LearningTile(
          icon: Icons.quiz_rounded,
          title: 'MCQ Practice',
          subtitle: 'Practice and review',
          accent: AtlasColors.gold,
          onTap: () => _openProtectedFeature(context, 'mcqPractice'),
        ),
        _LearningTile(
          icon: Icons.history_edu_rounded,
          title: 'Past Papers',
          subtitle: 'Solve previous exam papers',
          accent: AtlasColors.gold,
          onTap: () => _openProtectedFeature(context, 'pastPapers'),
        ),
        _LearningTile(
          icon: Icons.assignment_rounded,
          title: 'Examinations',
          subtitle: 'Assess your knowledge',
          accent: AtlasColors.brightBlue,
          onTap: () => _openProtectedFeature(context, 'examinations'),
        ),
        _LearningTile(
          icon: Icons.route_rounded,
          title: 'Exam Pathways',
          subtitle: 'Explore your pathway',
          accent: AtlasColors.gold,
          onTap: () => _openProtectedFeature(context, 'examPathways'),
        ),
      ],
    );
  }
  Widget _buildProgressCard() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final attempts = FirebaseFirestore.instance.collection('mcq_attempts').where('userId', isEqualTo: uid).snapshots();
    final progress = FirebaseFirestore.instance.collection('student_resource_progress').where('userId', isEqualTo: uid).snapshots();
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AtlasColors.border)),
      child: Column(children: [
        StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: progress, builder: (c,s) => _ProgressRow(icon: Icons.menu_book_rounded, title: 'Study materials completed', value: s.hasData ? '${s.data!.docs.where((d)=>d.data()['completed']==true).length}' : '—')),
        const Divider(height: 25, color: AtlasColors.border),
        StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: attempts, builder: (c,s) => _ProgressRow(icon: Icons.quiz_outlined, title: 'MCQ practice sessions', value: s.hasData ? '${s.data!.docs.where((d) => d.data()['examSetId'] == null).length}' : '—')),
        const Divider(height: 25, color: AtlasColors.border),
        StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: attempts, builder: (c,s) => _ProgressRow(icon: Icons.emoji_events_outlined, title: 'Timed examinations completed', value: s.hasData ? '${s.data!.docs.where((d) => d.data()['examSetId'] != null).length}' : '—')),
      ]),
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
  final String value;
  const _ProgressRow({required this.icon, required this.title, required this.value});
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
        Text(value, style: const TextStyle(color: AtlasColors.royalBlue, fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
