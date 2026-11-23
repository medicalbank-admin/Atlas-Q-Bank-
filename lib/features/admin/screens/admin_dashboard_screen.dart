import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_logo.dart';
import '../../profile/screens/profile_screen.dart';
import 'admin_academic_screen.dart';
import '../../academic/screens/admin_learning_resources_screen.dart';
import 'admin_mcq_bank_screen.dart';
import 'admin_past_papers_screen.dart';
import 'admin_exam_management_screen.dart';
import 'admin_students_screen.dart';
import 'admin_subscription_plans_screen.dart';
import 'admin_subscription_requests_screen.dart';
import 'admin_payment_settings_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_advanced_learning_screens.dart';
import '../../inbox/screens/inbox_screens.dart';
import '../../anatomy/screens/admin_anatomy_management_screen.dart';
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  Future<bool> _isAuthorizedAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult(true);
      return token.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthorizedAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AtlasColors.ivory,
            body: Center(
              child: CircularProgressIndicator(
                color: AtlasColors.royalBlue,
              ),
            ),
          );
        }
        if (snapshot.data != true) {
          return _buildAccessDenied(context);
        }
        return _buildDashboard(context);
      },
    );
  }
  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  color: AtlasColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(27),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AtlasColors.error,
                  size: 39,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Administrator Access Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AtlasColors.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This account does not have administrator permission.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AtlasColors.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDashboard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(context),
                  const SizedBox(height: 15),
                  _buildWelcomeBanner(user?.email ?? 'Administrator'),
                  const SizedBox(height: 13),
                  _buildAdminStats(),
                  const SizedBox(height: 22),
                  _buildSectionHeading(
                    'Management Centre',
                    'Your academy operations, organised in one place.',
                  ),
                  const SizedBox(height: 17),
                  _buildManagementGrid(context),
                  const SizedBox(height: 22),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Row(
          children: [
            AtlasLogo(size: compact ? 36 : 56),
            const Spacer(),
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ProfileScreen(isAdmin: true),
              )),
              borderRadius: BorderRadius.circular(30),
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final photo = (snapshot.data?.data()?['profileImageUrl'] ??
                      FirebaseAuth.instance.currentUser?.photoURL ?? '').toString();
                  final name = (snapshot.data?.data()?['fullName'] ??
                      FirebaseAuth.instance.currentUser?.displayName ?? '').toString();
                  return CircleAvatar(
                    radius: compact ? 18 : 22,
                    backgroundColor: AtlasColors.paleBlue,
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'A',
                            style: const TextStyle(
                                color: AtlasColors.navy, fontWeight: FontWeight.w900))
                        : null,
                  );
                },
              ),
            ),
            SizedBox(width: compact ? 2 : 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('inbox_conversations')
                  .where('unreadForAdmin', isGreaterThan: 0).snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.fold<int>(0, (total, doc) =>
                    total + ((doc.data()['unreadForAdmin'] as num?)?.toInt() ?? 0)) ?? 0;
                return Stack(clipBehavior: Clip.none, children: [
                  IconButton(
                    constraints: compact
                        ? const BoxConstraints.tightFor(width: 38, height: 42)
                        : null,
                    padding: compact ? EdgeInsets.zero : null,
                    tooltip: 'Student Inbox',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AdminInboxScreen(),
                    )),
                    icon: const Icon(Icons.forum_rounded,
                        color: AtlasColors.royalBlue, size: 24),
                  ),
                  if (count > 0)
                    Positioned(right: 0, top: 0, child: Container(
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: AtlasColors.error, shape: BoxShape.circle),
                      child: Text(count > 99 ? '99+' : '$count',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 9, fontWeight: FontWeight.w900)),
                    )),
                ]);
              },
            ),
            PopupMenuButton<String>(
              padding: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
              constraints: compact
                  ? const BoxConstraints.tightFor(width: 38, height: 42)
                  : null,
              tooltip: 'Notifications and account',
              icon: const Icon(Icons.notifications_none_rounded, size: 24),
              color: Colors.white,
              onSelected: (value) {
                if (value == 'notifications') {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AdminNotificationsScreen(),
                  ));
                } else if (value == 'signout') {
                  _confirmSignOut(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'notifications', child: ListTile(
                  dense: true, leading: Icon(Icons.notifications_none_rounded),
                  title: Text('Notifications'),
                )),
                PopupMenuItem(value: 'signout', child: ListTile(
                  dense: true, leading: Icon(Icons.logout_rounded),
                  title: Text('Sign Out'),
                )),
              ],
            ),
          ],
        );
      },
    );
  }
  Widget _buildWelcomeBanner(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 19, 18, 19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE4F0FF), Color(0xFFD5E8FF), Color(0xFFF1F7FF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -22,
            child: SizedBox(
              width: 150, height: 155,
              child: SvgPicture.asset(
                'assets/images/clinical_stethoscope.svg',
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0x6682B5E8), BlendMode.srcIn,
                ),
              ),
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
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFD7E7F8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: AtlasColors.royalBlue,
                      size: 14,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'SECURE ADMIN WORKSPACE',
                      style: TextStyle(
                        color: AtlasColors.royalBlue,
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Welcome, Administrator',
                style: TextStyle(
                  color: AtlasColors.navy,
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Manage students, subscriptions, academic content '
                'and your medical question bank.',
                style: TextStyle(
                  color: const Color(0xFF355474),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 19),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E9FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dashboard_rounded,
                      color: AtlasColors.navy,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Academy Control Centre',
                      style: TextStyle(
                        color: AtlasColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF637B95),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildAdminStats() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'student').snapshots(),
      builder: (context, studentsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('subscription_requests')
              .where('status', isEqualTo: 'pending').snapshots(),
          builder: (context, requestsSnapshot) {
            final students = studentsSnapshot.data?.size ?? 0;
            final pending = requestsSnapshot.data?.size ?? 0;
            return Row(children: [
              Expanded(child: _AdminStatTile(title: 'Registered Students',
                value: '$students', icon: Icons.people_alt_rounded,
                color: const Color(0xFF1768D1))),
              const SizedBox(width: 10),
              Expanded(child: _AdminStatTile(title: 'Pending Requests',
                value: '$pending', icon: Icons.pending_actions_rounded,
                color: const Color(0xFF1599A5))),
            ]);
          },
        );
      },
    );
  }
  Widget _buildSectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AtlasColors.navy,
            fontSize: 20,
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
  Widget _buildManagementGrid(BuildContext context) {
    final items = [
      _AdminItem(
        icon: Icons.mark_chat_unread_rounded,
        title: 'Student Inbox',
        subtitle: 'Private chats, image messages and read receipts',
        color: AtlasColors.royalBlue,
        page: const AdminInboxScreen(),
      ),
      _AdminItem(
        icon: Icons.people_alt_rounded,
        title: 'Student Management',
        subtitle: 'View and manage registered students',
        color: AtlasColors.royalBlue,
        page: const AdminStudentsScreen(),
      ),
      _AdminItem(
        icon: Icons.payments_rounded,
        title: 'Subscription Requests',
        subtitle: 'Review payments and access requests',
        color: AtlasColors.gold,
        page: const AdminSubscriptionRequestsScreen(),
      ),
      _AdminItem(
        icon: Icons.account_balance_rounded,
        title: 'Payment Settings',
        subtitle: 'Configure bank details and academy WhatsApp',
        color: AtlasColors.success,
        page: const AdminPaymentSettingsScreen(),
      ),
      _AdminItem(
        icon: Icons.workspace_premium_rounded,
        title: 'Subscription Plans',
        subtitle: 'Create plans and manage membership',
        color: AtlasColors.success,
        page: const AdminSubscriptionPlansScreen(),
      ),
      _AdminItem(
        icon: Icons.school_rounded,
        title: 'Academic Management',
        subtitle: 'Manage academic years, subjects and topics',
        color: AtlasColors.brightBlue,
        page: const AdminAcademicScreen(),
      ),
      _AdminItem(
        icon: Icons.video_library_rounded,
        title: 'Learning Resources',
        subtitle: 'Manage notes, PDFs and learning videos',
        color: AtlasColors.gold,
        page: const AdminLearningResourcesScreen(),
      ),
      _AdminItem(
        icon: Icons.campaign_rounded,
        title: 'Push Notification Center',
        subtitle: 'Target, schedule, send and track student alerts',
        color: AtlasColors.brightBlue,
        page: const AdminNotificationsScreen(),
      ),
      _AdminItem(
        icon: Icons.insights_rounded,
        title: 'Analytics & Reports',
        subtitle: 'Live student, payment and content metrics',
        color: AtlasColors.gold,
        page: const AdminAnalyticsScreen(),
      ),
      _AdminItem(
        icon: Icons.menu_book_rounded,
        title: 'Subject-Wise Exams',
        subtitle: 'Create and manage subject categories and exams',
        color: AtlasColors.royalBlue,
        page: const AdminExamManagementScreen(sectionType: 'subject_exam'),
      ),
      _AdminItem(
        icon: Icons.account_tree_rounded,
        title: 'System-Wise Exams',
        subtitle: 'Create and manage system categories and exams',
        color: AtlasColors.gold,
        page: const AdminExamManagementScreen(sectionType: 'system_exam'),
      ),
      _AdminItem(
        icon: Icons.fact_check_rounded,
        title: 'Mock Exams',
        subtitle: 'Manage subject mocks, system mocks and grand mocks',
        color: AtlasColors.brightBlue,
        page: const AdminExamManagementScreen(sectionType: 'mocks'),
      ),
      _AdminItem(
        icon: Icons.history_edu_rounded,
        title: 'Past Papers',
        subtitle: 'Create, import, publish and manage past papers',
        color: AtlasColors.brightBlue,
        page: const AdminPastPapersScreen(),
      ),
      _AdminItem(
        icon: Icons.medical_services_rounded,
        title: 'Clinical Case Management',
        subtitle: 'Author patient scenarios, investigations and decision questions',
        color: AtlasColors.royalBlue,
        page: const AdminClinicalCasesScreen(),
      ),
      _AdminItem(
        icon: Icons.forum_rounded,
        title: 'Student Community & Support',
        subtitle: 'Answer teacher questions and moderate discussions',
        color: AtlasColors.gold,
        page: const AdminStudentSupportScreen(),
      ),
      _AdminItem(
        icon: Icons.view_in_ar_rounded,
        title: '3D Anatomy Lab Management',
        subtitle: 'Manage structure notes, Latin names and clinical details',
        color: AtlasColors.royalBlue,
        page: const AdminAnatomyManagementScreen(),
      ),
      _AdminItem(
        icon: Icons.quiz_rounded,
        title: 'MCQ Question Bank',
        subtitle: 'Create, edit, publish and bulk import MCQs',
        color: AtlasColors.royalBlue,
        page: const AdminMcqBankScreen(),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 3 ? 1.24 : 1.12,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _AdminManagementCard(
              item: item,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => item.page),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildFooter() {
    return const Center(
      child: Column(
        children: [
          Icon(
            Icons.school_rounded,
            color: AtlasColors.champagne,
            size: 27,
          ),
          SizedBox(height: 9),
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to leave the administrator workspace?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }
}
class _AdminStatTile extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _AdminStatTile({required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0EAF5)),
      boxShadow: [BoxShadow(color: AtlasColors.navy.withValues(alpha: .045), blurRadius: 12, offset: const Offset(0, 3))]),
    child: Row(children: [
      Container(width: 39, height: 39, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: color, size: 21)),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: AtlasColors.navy, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(title, maxLines: 2, style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );
}
class _AdminItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget page;
  const _AdminItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.page,
  });
}
class _AdminManagementCard extends StatelessWidget {
  final _AdminItem item;
  final VoidCallback onTap;
  const _AdminManagementCard({
    required this.item,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color.withValues(alpha: 0.075),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1EBF5)),
            boxShadow: [
              BoxShadow(
                color: AtlasColors.navy.withValues(alpha: 0.035),
                blurRadius: 13,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 47,
                width: 47,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AtlasColors.navy,
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                maxLines: 3,
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
