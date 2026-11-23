import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_logo.dart';
import '../../profile/screens/profile_screen.dart';
import '../../auth/screens/student_account_status_screen.dart';
import '../../auth/services/student_auth_service.dart';
import '../../mcqs/screens/student_mcq_hub_screen.dart';
import '../../mcqs/screens/student_mcq_result_screen.dart';
import '../../academic/screens/student_study_library_screen.dart';
import '../../academic/screens/student_exam_centre_screen.dart';
import '../../academic/screens/student_past_papers_screen.dart';
import '../../anatomy/screens/student_anatomy_lab_screen.dart';
import '../../subscriptions/screens/subscription_plans_screen.dart';
import '../../advanced_learning/screens/advanced_student_tools_screen.dart';
import '../../advanced_learning/screens/atlas_clinical_learning_screen.dart';
import '../../advanced_learning/screens/atlas_premium_learning_screen.dart';
import '../../advanced_learning/services/push_notification_service.dart';
import 'student_notifications_screen.dart';
import '../../inbox/screens/inbox_screens.dart';
import '../../../shared/widgets/dashboard_announcement_welcome.dart';

class StudentDashboardScreen extends StatefulWidget {
 const StudentDashboardScreen({super.key});
 @override State<StudentDashboardScreen> createState()=>_StudentDashboardScreenState();
}
class _StudentDashboardScreenState extends State<StudentDashboardScreen>{
 int selected=0;
 bool _notificationsOpened=false;
 final PushNotificationService pushService=PushNotificationService();
 @override void initState(){super.initState();pushService.registerDevice(context,onNotificationTap:_handleNotificationTap);}
 Future<void> _handleNotificationTap(RemoteMessage message) async {
  final destination=(message.data['destination']??'').toString();
  if(destination.startsWith('forum_thread:')){await openFeature('discussionForum');return;}
  const destinations={'study_library':'studyLibrary','mcq_practice':'mcqPractice','past_papers':'pastPapers','exams_history':'examsHistory','clinical_cases':'clinicalCases','spotter_challenges':'spotterChallenges','clinical_correlations':'clinicalCorrelations','advanced_quizzes':'advancedQuizzes','mistakes_notebook':'mistakesNotebook','mock_predictions':'mockPredictions','discussion_forum':'discussionForum','ask_teacher':'askTeacher','membership':'membership'};
  final key=destinations[destination];
  if(key!=null&&mounted)await openFeature(key);
 }
 Widget _notificationBell(BuildContext context, int count) {
  return Stack(clipBehavior: Clip.none, children: [
    IconButton(
      tooltip: 'Notifications',
      onPressed: () async {
        if (mounted) setState(() => _notificationsOpened = true);
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const StudentNotificationsScreen(),
        ));
      },
      icon: const Icon(Icons.notifications_none_rounded,
          size: 32, color: Color(0xFF123B68)),
    ),
    if (count > 0 && !_notificationsOpened)
      Positioned(right: 1, top: 0, child: Container(
        constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFE34C55), shape: BoxShape.circle,
        ),
        child: Text(count > 9 ? '9+' : '$count',
          style: const TextStyle(color: Colors.white,
            fontSize: 10, fontWeight: FontWeight.w900)),
      )),
  ]);
 }
 Future<void> signOut()async{try{await pushService.unregisterCurrentDevice();await StudentAuthService().signOut();if(mounted)Navigator.of(context).popUntil((r)=>r.isFirst);}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Unable to sign out.')));}}
 Future<void> openFeature(String key)async{
  final u=FirebaseAuth.instance.currentUser;if(u==null)return;
  if(key=='profile'){await Navigator.push(context,MaterialPageRoute(builder:(_)=>const ProfileScreen()));return;}
  if(key=='account'){await Navigator.push(context,MaterialPageRoute(builder:(_)=>const StudentAccountStatusScreen()));return;}
  if(key=='membership'){await Navigator.push(context,MaterialPageRoute(builder:(_)=>const SubscriptionPlansScreen()));return;}
  try{
   final snap=await FirebaseFirestore.instance.collection('users').doc(u.uid).get();final d=snap.data()??{};
   final p=Map<String,dynamic>.from(d['subscriptionAccessPermissions']??const{});final e=d['subscriptionExpiryAt'];
   final valid=e is Timestamp&&e.toDate().isAfter(DateTime.now());
   final permissionKey=['clinicalCases','clinicalCorrelations'].contains(key)?'clinicalCases':key=='spotterChallenges'?'mcqPractice':key=='advancedQuizzes'?'mcqPractice':(['subjectExams','systemExams','mockExams'].contains(key)?'examinations':key);
   final allowed=key=='pastPapers'?(p['pastPapers']==true||p['examinations']==true):key=='examsHistory'?(p['examinations']==true||p['mcqPractice']==true||p['pastPapers']==true):p[permissionKey]==true;
   if(!mounted)return;
   if(d['subscriptionStatus']!='active'||d['accessEnabled']!=true||!valid||!allowed){await Navigator.push(context,MaterialPageRoute(builder:(_)=>const SubscriptionPlansScreen()));return;}
   Widget? page;
   if(key=='studyLibrary')page=const StudentStudyLibraryScreen();
   if(key=='mcqPractice')page=const StudentMcqHubScreen();
   if(key=='pastPapers')page=const StudentPastPapersScreen();
   if(key=='examsHistory')page=const StudentExamsHistoryScreen();
   if(key=='subjectExams'||key=='systemExams'||key=='mockExams') {
    final section = key=='subjectExams' ? 'subject_exam' :
        key=='systemExams' ? 'system_exam' : 'mocks';
    page=StudentExamCentreScreen(section:section);
   }
   if(key=='clinicalCases')page=const ClinicalCaseLearningScreen();
    if(key=='spotterChallenges')page=const AtlasClinicalLearningScreen(initialMode:'spotter');
    if(key=='clinicalCorrelations')page=const AtlasClinicalLearningScreen(initialMode:'cases');
    if(key=='advancedQuizzes')page=const AtlasClinicalLearningScreen(initialMode:'quiz');
   if(key=='mistakesNotebook')page=const MistakesNotebookScreen();
   if(key=='mockPredictions')page=const MockExamPredictionScreen();
   if(key=='discussionForum')page=const StudentDiscussionForumScreen();
   if(key=='askTeacher')page=const AskTeacherScreen();
   if(key=='anatomyLab')page=const StudentAnatomyLabScreen();
   if(page!=null)await Navigator.push(context,MaterialPageRoute(builder:(_)=>page!));
  }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Unable to check membership.')));}
 }
 Future<void> select(int i)async{setState(()=>selected=i);if(MediaQuery.sizeOf(context).width<850)Navigator.of(context).maybePop();if(i>0){const keys=['','studyLibrary','mcqPractice','pastPapers','anatomyLab','subjectExams','systemExams','mockExams','examsHistory','clinicalCases','spotterChallenges','clinicalCorrelations','advancedQuizzes','mistakesNotebook','mockPredictions','discussionForum','askTeacher','membership','account'];await openFeature(keys[i]);if(mounted)setState(()=>selected=0);}}
 @override Widget build(BuildContext context){
  final wide=MediaQuery.sizeOf(context).width>=850;final u=FirebaseAuth.instance.currentUser;final name=u?.displayName?.trim().isNotEmpty==true?u!.displayName!.trim():'Student';
  final pages=<Widget>[_Home(name:name,onSubjectExams:()=>openFeature('subjectExams'),onSystemExams:()=>openFeature('systemExams'),onMockExams:()=>openFeature('mockExams'),onPastPapers:()=>openFeature('pastPapers'),onAnatomyLab:()=>openFeature('anatomyLab'),onSpotter:()=>openFeature('spotterChallenges'),onClinicalCorrelations:()=>openFeature('clinicalCorrelations'),onAdvancedQuizzes:()=>openFeature('advancedQuizzes'),onMembership:()=>openFeature('membership')),_FeaturePage('Study Library',Icons.menu_book_rounded,()=>openFeature('studyLibrary')),_FeaturePage('MCQ Practice',Icons.quiz_rounded,()=>openFeature('mcqPractice')),_FeaturePage('Past Papers',Icons.history_edu_rounded,()=>openFeature('pastPapers')),_FeaturePage('3D Anatomy Lab',Icons.view_in_ar_rounded,()=>openFeature('anatomyLab')),_FeaturePage('Subject-Wise Exams',Icons.menu_book_rounded,()=>openFeature('subjectExams')),_FeaturePage('System-Wise Exams',Icons.account_tree_rounded,()=>openFeature('systemExams')),_FeaturePage('Mock Exams',Icons.fact_check_rounded,()=>openFeature('mockExams')),_FeaturePage('Exams History',Icons.history_rounded,()=>openFeature('examsHistory')),_FeaturePage('Clinical Cases',Icons.medical_services_rounded,()=>openFeature('clinicalCases')),_FeaturePage('Spotter Challenges',Icons.view_in_ar_rounded,()=>openFeature('spotterChallenges')),_FeaturePage('Clinical Correlations',Icons.medical_information_rounded,()=>openFeature('clinicalCorrelations')),_FeaturePage('Advanced Quizzes',Icons.quiz_rounded,()=>openFeature('advancedQuizzes')),_FeaturePage('Mistakes Notebook',Icons.bookmark_added_rounded,()=>openFeature('mistakesNotebook')),_FeaturePage('Mock Exam Readiness',Icons.insights_rounded,()=>openFeature('mockPredictions')),_FeaturePage('Discussion Forum',Icons.forum_rounded,()=>openFeature('discussionForum')),_FeaturePage('Ask a Teacher',Icons.support_agent_rounded,()=>openFeature('askTeacher')),_FeaturePage('Membership',Icons.workspace_premium_rounded,()=>openFeature('membership')),_FeaturePage('Account Status',Icons.verified_user_rounded,()=>openFeature('account'))];
  return Scaffold(backgroundColor:const Color(0xFFF3F7FF),drawer:wide?null:Drawer(backgroundColor:AtlasColors.navy,child:_SideNav(selected:selected,onSelect:select,onSignOut:signOut,onProfile:()=>openFeature('profile'))),body:SafeArea(child:Row(children:[
   if(wide)SizedBox(width:265,child:_SideNav(selected:selected,onSelect:select,onSignOut:signOut,onProfile:()=>openFeature('profile'))),
   Expanded(child:Column(children:[
    Container(
      color: const Color(0xFFF2F8FF),
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      child: Row(children: [
        if (!wide)
          Builder(builder: (headerContext) => IconButton(
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(headerContext).openDrawer(),
            icon: const Icon(Icons.menu_rounded, size: 29, color: Color(0xFF123B68)),
          )),
        const SizedBox(width: 3),
        const Expanded(child: Align(
          alignment: Alignment.centerLeft,
          child: AtlasLogo(size: 70),
        )),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('inbox_conversations')
              .doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
          builder: (context, inboxSnapshot) {
            final unread = (inboxSnapshot.data?.data()?['unreadForStudent'] as num?)?.toInt() ?? 0;
            return Stack(clipBehavior: Clip.none, children: [
              IconButton(
                tooltip: 'Inbox',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const StudentInboxScreen(),
                )),
                icon: const Icon(Icons.headset_mic_rounded,
                    size: 29, color: Color(0xFF1768C8)),
              ),
              if (unread > 0)
                Positioned(right: 0, top: -1, child: Container(
                  constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Color(0xFFE34C55), shape: BoxShape.circle),
                  child: Text(unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                )),
            ]);
          },
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('notifications')
              .where('audience', isEqualTo: 'all')
              .where('isActive', isEqualTo: true).limit(50).snapshots(),
          builder: (context, globalSnapshot) {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null) return _notificationBell(context, globalSnapshot.data?.docs.length ?? 0);
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('notifications')
                  .where('userId', isEqualTo: uid).limit(50).snapshots(),
              builder: (context, personalSnapshot) {
                final count = (globalSnapshot.data?.docs.length ?? 0) +
                    (personalSnapshot.data?.docs.length ?? 0);
                return _notificationBell(context, count);
              },
            );
          },
        ),
      ]),
    ),
    Expanded(child:IndexedStack(index:selected,children:pages)),
   ])),
  ])),
  bottomNavigationBar: wide ? null : _AtlasBottomNavigationBar(
    onHome: () { setState(() => selected = 0); },
    onExams: () => showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Examination Centre', style: TextStyle(color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
            ListTile(leading: const Icon(Icons.menu_book_rounded), title: const Text('Subject-Wise Exams'), onTap: () { Navigator.pop(sheetContext); openFeature('subjectExams'); }),
            ListTile(leading: const Icon(Icons.hub_rounded), title: const Text('System-Wise Exams'), onTap: () { Navigator.pop(sheetContext); openFeature('systemExams'); }),
            ListTile(leading: const Icon(Icons.assignment_rounded), title: const Text('Mock Exams'), onTap: () { Navigator.pop(sheetContext); openFeature('mockExams'); }),
            ListTile(leading: const Icon(Icons.description_rounded), title: const Text('Past Papers'), onTap: () { Navigator.pop(sheetContext); openFeature('pastPapers'); }),
          ],
        ),
      )),
    ),
    onResources: () => openFeature('studyLibrary'),
    onProfile: () => openFeature('profile'),
  ),
 );
 }
}
class _AtlasBottomNavigationBar extends StatelessWidget {
  final VoidCallback onHome, onExams, onResources, onProfile;
  const _AtlasBottomNavigationBar({required this.onHome, required this.onExams,
    required this.onResources, required this.onProfile});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white, boxShadow: [
      BoxShadow(color: Color(0x160E315A), blurRadius: 12, offset: Offset(0, -3)),
    ]),
    child: SafeArea(top: false, child: SizedBox(height: 72, child: Row(children: [
      _NavItem(icon: Icons.home_rounded, label: 'Home', active: true, onTap: onHome),
      _NavItem(icon: Icons.edit_note_rounded, label: 'Exams', onTap: onExams),
      _NavItem(icon: Icons.menu_book_rounded, label: 'Resources', onTap: onResources),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Profile', onTap: onProfile),
    ]))),
  );
}
class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.onTap, this.active = false});
  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(
    onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: active ? const Color(0xFF1768D1) : const Color(0xFF263B59), size: 24),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(color: active ? const Color(0xFF1768D1) : const Color(0xFF263B59),
        fontSize: 11, fontWeight: active ? FontWeight.w900 : FontWeight.w600)),
    ]),
  ));
}

class _SideNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut, onProfile;

  const _SideNav({
    required this.selected,
    required this.onSelect,
    required this.onSignOut,
    required this.onProfile,
  });

  static const items = [
    (Icons.home_rounded, 'Home'),
    (Icons.menu_book_rounded, 'Study Library'),
    (Icons.quiz_rounded, 'MCQ Practice'),
    (Icons.history_edu_rounded, 'Past Papers'),
    (Icons.view_in_ar_rounded, '3D Anatomy Lab'),
    (Icons.menu_book_rounded, 'Subject-Wise Exams'),
    (Icons.account_tree_rounded, 'System-Wise Exams'),
    (Icons.fact_check_rounded, 'Mock Exams'),
    (Icons.history_rounded, 'Exams History'),
    (Icons.medical_services_rounded, 'Clinical Cases'),
    (Icons.view_in_ar_rounded, 'Spotter Challenges'),
    (Icons.medical_information_rounded, 'Clinical Correlations'),
    (Icons.quiz_rounded, 'Advanced Quizzes'),
    (Icons.bookmark_added_rounded, 'Mistakes Notebook'),
    (Icons.insights_rounded, 'Mock Exam Readiness'),
    (Icons.forum_rounded, 'Discussion Forum'),
    (Icons.support_agent_rounded, 'Ask a Teacher'),
    (Icons.workspace_premium_rounded, 'Membership'),
    (Icons.verified_user_rounded, 'Account Status'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 25, 19, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AtlasLogo(size: 58),
                  const SizedBox(height: 10),
                  const Text(
                    'YOUR MEDICAL LEARNING SPACE',
                    style: TextStyle(
                      color: AtlasColors.secondaryText,
                      fontSize: 8,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: AtlasColors.border),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (var i = 0; i < items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Material(
                        color: selected == i
                            ? AtlasColors.paleBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          onTap: () => onSelect(i),
                          borderRadius: BorderRadius.circular(13),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 13,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  items[i].$1,
                                  color: selected == i
                                      ? AtlasColors.royalBlue
                                      : AtlasColors.secondaryText,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    items[i].$2,
                                    style: TextStyle(
                                      color: selected == i
                                          ? AtlasColors.navy
                                          : AtlasColors.charcoal,
                                      fontSize: 12,
                                      fontWeight: selected == i
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (selected == i)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AtlasColors.royalBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 15),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.person_outline,
                      color: AtlasColors.royalBlue,
                    ),
                    title: const Text(
                      'My Profile',
                      style: TextStyle(
                        color: AtlasColors.charcoal,
                        fontSize: 12,
                      ),
                    ),
                    onTap: onProfile,
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.logout,
                      color: AtlasColors.secondaryText,
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AtlasColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    onTap: onSignOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
class _Home extends StatelessWidget {
  final String name;
  final VoidCallback onSubjectExams, onSystemExams, onMockExams, onPastPapers, onAnatomyLab, onSpotter, onClinicalCorrelations, onAdvancedQuizzes, onMembership;
  const _Home({
    required this.name,
    required this.onSubjectExams,
    required this.onSystemExams,
    required this.onMockExams,
    required this.onPastPapers,
    required this.onAnatomyLab,
    required this.onSpotter,
    required this.onClinicalCorrelations,
    required this.onAdvancedQuizzes,
    required this.onMembership,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firstName = name.trim().split(' ').first;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DashboardAnnouncementWelcome(displayName: firstName),
        const SizedBox(height: 16),
        const AtlasDashboardCoreFeatures(),
        const SizedBox(height: 19),
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 1.50, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ClinicalExamTile(title: 'Subject-Wise\nExams', icon: Icons.menu_book_rounded,
              tint: const Color(0xFFEAF1FF), iconColor: const Color(0xFF1768D1),
              action: 'Explore', onTap: onSubjectExams),
            _ClinicalExamTile(title: 'System-Wise\nExams', icon: Icons.hub_rounded,
              tint: const Color(0xFFE7F8F8), iconColor: const Color(0xFF1599A5),
              action: 'Explore', onTap: onSystemExams),
            _ClinicalExamTile(title: 'Mock Exams', icon: Icons.assignment_rounded,
              tint: const Color(0xFFF2EBFF), iconColor: const Color(0xFF8651D6),
              action: 'Explore', onTap: onMockExams),
            _ClinicalExamTile(title: 'Past Papers', icon: Icons.description_rounded,
              tint: const Color(0xFFE7F7F1), iconColor: const Color(0xFF168B69),
              action: 'Explore', onTap: onPastPapers),
            _ClinicalExamTile(title: '3D Anatomy\nLab', icon: Icons.view_in_ar_rounded,
              tint: const Color(0xFFE9F1FF), iconColor: const Color(0xFF315FA8),
              action: 'Explore', onTap: onAnatomyLab),
            _ClinicalExamTile(title: '3D Spotter\nChallenges', icon: Icons.view_in_ar_rounded,
              tint: const Color(0xFFEAF4FC), iconColor: const Color(0xFF2563A6),
              action: 'Start', onTap: onSpotter),
            _ClinicalExamTile(title: 'Clinical\nCorrelations', icon: Icons.medical_information_rounded,
              tint: const Color(0xFFFFF1E8), iconColor: const Color(0xFFB65B32),
              action: 'Explore', onTap: onClinicalCorrelations),
            _ClinicalExamTile(title: 'Advanced\nQuizzes', icon: Icons.quiz_rounded,
              tint: const Color(0xFFF0ECFF), iconColor: const Color(0xFF7754C8),
              action: 'Practice', onTap: onAdvancedQuizzes),
          ],
        ),
        const SizedBox(height: 15),
        const AtlasDashboardDailyChallenge(),
        const SizedBox(height: 15),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Your Activity', style: TextStyle(
            color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
          TextButton(onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StudentExamsHistoryScreen())),
            child: const Text('View History  →', style: TextStyle(fontSize: 12))),
        ]),
        if (uid != null) _ActivitySummary(uid: uid),
        const SizedBox(height: 13),
        Container(
          height: 112, width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 15, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFB9D9FF), Color(0xFFE2F0FF)],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
          ),
          child: Row(children: [
            const Expanded(child: Text('Study Smart.\nScore High.',
              style: TextStyle(color: Color(0xFF123B68), fontSize: 21,
                height: 1.15, fontWeight: FontWeight.w900))),
            SizedBox(
              width: 160, height: 96,
              child: SvgPicture.asset(
                'assets/images/study_smart_banner.svg',
                fit: BoxFit.contain,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        if (uid != null) _MembershipDetails(uid: uid, onManage: onMembership),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _MembershipDetails extends StatelessWidget {
  final String uid;
  final VoidCallback onManage;
  const _MembershipDetails({required this.uid, required this.onManage});

  String _expiryLabel(dynamic value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;
    if (value is String) date = DateTime.tryParse(value);
    if (date == null) return 'Not specified';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final status = (data['subscriptionStatus'] ?? 'Not active').toString();
          final plan = (data['subscriptionPlanName'] ?? 'No membership selected').toString();
          final enabled = data['accessEnabled'] == true;
          final active = status.toLowerCase() == 'active' && enabled;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(17, 16, 15, 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: const Color(0xFFDCE8F5)),
              boxShadow: [BoxShadow(
                color: AtlasColors.navy.withValues(alpha: .055),
                blurRadius: 15, offset: const Offset(0, 5),
              )],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFF2563A6), size: 22),
                const SizedBox(width: 9),
                const Expanded(child: Text('Membership Details',
                    style: TextStyle(color: AtlasColors.navy,
                        fontSize: 16, fontWeight: FontWeight.w900))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFE5F7EF) : const Color(0xFFFFF2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(active ? 'ACTIVE' : status.toUpperCase(),
                    style: TextStyle(
                      color: active ? const Color(0xFF16845D) : const Color(0xFF9A681D),
                      fontSize: 9, fontWeight: FontWeight.w900,
                    )),
                ),
              ]),
              const SizedBox(height: 13),
              _membershipLine('Current Plan', plan),
              _membershipLine('Valid Until', _expiryLabel(data['subscriptionExpiryAt'])),
              _membershipLine('Account Access', enabled ? 'Enabled' : 'Awaiting activation'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Manage Membership'),
                ),
              ),
            ]),
          );
        },
      );

  Widget _membershipLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 112, child: Text(label,
        style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 11))),
      Expanded(child: Text(value,
        style: const TextStyle(color: AtlasColors.charcoal,
          fontSize: 12, fontWeight: FontWeight.w700))),
    ]),
  );
}

class _ClinicalExamTile extends StatelessWidget {
  final String title, action;
  final IconData icon;
  final Color tint, iconColor;
  final VoidCallback onTap;
  const _ClinicalExamTile({required this.title, required this.icon,
    required this.tint, required this.iconColor, required this.action,
    required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: tint, borderRadius: BorderRadius.circular(19),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white.withValues(alpha: .9)),
          boxShadow: [BoxShadow(color: AtlasColors.navy.withValues(alpha: .06),
            blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: iconColor, size: 42),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF122A4B), fontSize: 15,
              height: 1.15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          Text('$action  →', style: TextStyle(color: iconColor,
            fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ),
    ),
  );
}

class _ActivitySummary extends StatelessWidget {
  final String uid;
  const _ActivitySummary({required this.uid});
  @override
  Widget build(BuildContext context) =>
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('mcq_attempts')
        .where('userId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        var attempted = 0;
        for (final doc in docs) {
          attempted += (doc.data()['totalQuestions'] as num?)?.toInt() ?? 0;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2EBF7)),
            boxShadow: [BoxShadow(color: AtlasColors.navy.withValues(alpha: .045),
              blurRadius: 12, offset: const Offset(0, 3))]),
          child: Row(children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFF2B62D), size: 38),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Keep up the great work!', style: TextStyle(
                  color: Color(0xFF483C27), fontSize: 14, fontWeight: FontWeight.w900)),
                Text('$attempted MCQs attempted so far',
                  style: const TextStyle(color: Color(0xFF52647C), fontSize: 11)),
              ])),
            const Icon(Icons.bar_chart_rounded, color: Color(0xFF159A85), size: 29),
          ]),
        );
      },
    );
}

class _FeaturePage extends StatelessWidget{final String title;final IconData icon;final VoidCallback onOpen;const _FeaturePage(this.title,this.icon,this.onOpen);@override Widget build(BuildContext context)=>Center(child:Container(constraints:const BoxConstraints(maxWidth:450),padding:const EdgeInsets.all(25),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:AtlasColors.border)),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,color:AtlasColors.royalBlue,size:48),const SizedBox(height:14),Text(title,style:const TextStyle(color:AtlasColors.navy,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:20),FilledButton.icon(onPressed:onOpen,icon:const Icon(Icons.arrow_forward),label:const Text('Open feature'))])));}

class StudentExamsHistoryScreen extends StatelessWidget {
 const StudentExamsHistoryScreen({super.key});
 @override Widget build(BuildContext context) {
  final uid=FirebaseAuth.instance.currentUser?.uid;
  if(uid==null)return const Scaffold(body:Center(child:Text('Please sign in to view your exam history.')));
  return Scaffold(backgroundColor:AtlasColors.ivory,appBar:AppBar(title:const Text('Exams History')),
   body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('mcq_attempts').where('userId',isEqualTo:uid).snapshots(),builder:(context,s){
    if(s.hasError)return Center(child:Text('Unable to load exam history: ${s.error}'));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final docs=[...s.data!.docs]..sort((x,y){
     DateTime date(Map<String,dynamic> d){final v=d['completedAt']??d['createdAt'];if(v is Timestamp)return v.toDate();if(v is String)return DateTime.tryParse(v)??DateTime(1970);return DateTime(1970);}
     return date(y.data()).compareTo(date(x.data()));
    });
    if(docs.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(28),child:Text('No attempted exams yet. Your completed attempts will appear here.',textAlign:TextAlign.center,style:TextStyle(color:AtlasColors.secondaryText))));
    return ListView(padding:const EdgeInsets.all(15),children:[
     Padding(padding:const EdgeInsets.only(bottom:12),child:Text('${docs.length} completed attempts',style:const TextStyle(color:AtlasColors.secondaryText,fontWeight:FontWeight.w700))),
     ...docs.map((doc){final data=doc.data();final score=(data['percentage'] as num?)?.toDouble()??0;final title=(data['examName']??data['examTitle']??data['title']??data['subject']??(data['examSetId']!=null?'Exam attempt':'MCQ practice')).toString();final when=data['completedAt']??data['createdAt'];final dt=when is Timestamp?when.toDate():when is String?DateTime.tryParse(when):null;final total=(data['totalQuestions'] as num?)?.toInt()??0;final correct=(data['correctAnswers'] as num?)?.toInt()??0;
      return Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:8),leading:CircleAvatar(backgroundColor:AtlasColors.paleBlue,child:Text('${score.round()}%',style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900,fontSize:11))),title:Text(title,style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900)),subtitle:Text('${correct}/${total} correct • ${dt==null?'Date unavailable':'${dt.day}/${dt.month}/${dt.year}'}',style:const TextStyle(color:AtlasColors.secondaryText,fontSize:11)),trailing:const Icon(Icons.chevron_right_rounded,color:AtlasColors.royalBlue),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>StudentMcqResultScreen(attemptId:doc.id)))));
     })
    ]);
   })
  );
 }
}
