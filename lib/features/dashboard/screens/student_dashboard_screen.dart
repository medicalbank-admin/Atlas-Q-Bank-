import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../../subscriptions/screens/subscription_plans_screen.dart';
import '../../advanced_learning/screens/advanced_student_tools_screen.dart';
import '../../advanced_learning/services/push_notification_service.dart';

class StudentDashboardScreen extends StatefulWidget {
 const StudentDashboardScreen({super.key});
 @override State<StudentDashboardScreen> createState()=>_StudentDashboardScreenState();
}
class _StudentDashboardScreenState extends State<StudentDashboardScreen>{
 int selected=0;
 final PushNotificationService pushService=PushNotificationService();
 @override void initState(){super.initState();pushService.registerDevice(context,onNotificationTap:_handleNotificationTap);}
 Future<void> _handleNotificationTap(RemoteMessage message) async {
  final destination=(message.data['destination']??'').toString();
  if(destination.startsWith('forum_thread:')){await openFeature('discussionForum');return;}
  const destinations={'study_library':'studyLibrary','mcq_practice':'mcqPractice','past_papers':'pastPapers','exams_history':'examsHistory','clinical_cases':'clinicalCases','mistakes_notebook':'mistakesNotebook','mock_predictions':'mockPredictions','discussion_forum':'discussionForum','ask_teacher':'askTeacher','membership':'membership'};
  final key=destinations[destination];
  if(key!=null&&mounted)await openFeature(key);
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
   final permissionKey=key=='clinicalCases'?'clinicalCases':(['subjectExams','systemExams','mockExams'].contains(key)?'examinations':key);
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
   if(key=='mistakesNotebook')page=const MistakesNotebookScreen();
   if(key=='mockPredictions')page=const MockExamPredictionScreen();
   if(key=='discussionForum')page=const StudentDiscussionForumScreen();
   if(key=='askTeacher')page=const AskTeacherScreen();
   if(page!=null)await Navigator.push(context,MaterialPageRoute(builder:(_)=>page!));
  }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Unable to check membership.')));}
 }
 Future<void> select(int i)async{setState(()=>selected=i);if(MediaQuery.sizeOf(context).width<850)Navigator.of(context).maybePop();if(i>0){const keys=['','studyLibrary','mcqPractice','pastPapers','subjectExams','systemExams','mockExams','examsHistory','clinicalCases','mistakesNotebook','mockPredictions','discussionForum','askTeacher','membership','account'];await openFeature(keys[i]);if(mounted)setState(()=>selected=0);}}
 @override Widget build(BuildContext context){
  final wide=MediaQuery.sizeOf(context).width>=850;final u=FirebaseAuth.instance.currentUser;final name=u?.displayName?.trim().isNotEmpty==true?u!.displayName!.trim():'Student';
  final pages=<Widget>[_Home(name:name,onMembership:()=>openFeature('membership'),onSubjectExams:()=>openFeature('subjectExams'),onSystemExams:()=>openFeature('systemExams'),onMockExams:()=>openFeature('mockExams')),_FeaturePage('Study Library',Icons.menu_book_rounded,()=>openFeature('studyLibrary')),_FeaturePage('MCQ Practice',Icons.quiz_rounded,()=>openFeature('mcqPractice')),_FeaturePage('Past Papers',Icons.history_edu_rounded,()=>openFeature('pastPapers')),_FeaturePage('Subject-Wise Exams',Icons.menu_book_rounded,()=>openFeature('subjectExams')),_FeaturePage('System-Wise Exams',Icons.account_tree_rounded,()=>openFeature('systemExams')),_FeaturePage('Mock Exams',Icons.fact_check_rounded,()=>openFeature('mockExams')),_FeaturePage('Exams History',Icons.history_rounded,()=>openFeature('examsHistory')),_FeaturePage('Clinical Cases',Icons.medical_services_rounded,()=>openFeature('clinicalCases')),_FeaturePage('Mistakes Notebook',Icons.bookmark_added_rounded,()=>openFeature('mistakesNotebook')),_FeaturePage('Mock Exam Readiness',Icons.insights_rounded,()=>openFeature('mockPredictions')),_FeaturePage('Discussion Forum',Icons.forum_rounded,()=>openFeature('discussionForum')),_FeaturePage('Ask a Teacher',Icons.support_agent_rounded,()=>openFeature('askTeacher')),_FeaturePage('Membership',Icons.workspace_premium_rounded,()=>openFeature('membership')),_FeaturePage('Account Status',Icons.verified_user_rounded,()=>openFeature('account'))];
  return Scaffold(backgroundColor:AtlasColors.ivory,drawer:wide?null:Drawer(backgroundColor:AtlasColors.navy,child:_SideNav(selected:selected,onSelect:select,onSignOut:signOut,onProfile:()=>openFeature('profile'))),body:SafeArea(child:Row(children:[
   if(wide)SizedBox(width:265,child:_SideNav(selected:selected,onSelect:select,onSignOut:signOut,onProfile:()=>openFeature('profile'))),
   Expanded(child:Column(children:[
    Container(
      color: const Color(0xFFF2F8FF),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 9),
      child: Row(children: [
        if (!wide)
          Builder(builder: (c) => IconButton(
            onPressed: () => Scaffold.of(c).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: AtlasColors.navy),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 42),
          )),
        const AtlasLogo(size: 58),
        const SizedBox(width: 9),
        const Expanded(child: Text(
          'The Atlas\\nAcademy',
          style: TextStyle(
            color: Color(0xFF123B68), fontFamily: 'Georgia',
            fontSize: 21, height: 1.02, fontWeight: FontWeight.w700,
          ),
        )),
        Stack(clipBehavior: Clip.none, children: [
          IconButton(
            onPressed: () => openFeature('account'),
            icon: const Icon(Icons.notifications_none_rounded, size: 28, color: AtlasColors.navy),
          ),
          Positioned(right: 8, top: 7, child: Container(
            width: 9, height: 9,
            decoration: const BoxDecoration(color: Color(0xFFE34C55), shape: BoxShape.circle),
          )),
        ]),
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
    child: SafeArea(top: false, child: SizedBox(height: 64, child: Row(children: [
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
        fontSize: 10, fontWeight: active ? FontWeight.w900 : FontWeight.w600)),
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
    (Icons.menu_book_rounded, 'Subject-Wise Exams'),
    (Icons.account_tree_rounded, 'System-Wise Exams'),
    (Icons.fact_check_rounded, 'Mock Exams'),
    (Icons.history_rounded, 'Exams History'),
    (Icons.medical_services_rounded, 'Clinical Cases'),
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
                  const SizedBox(height: 14),
                  const Text(
                    'THE ATLAS ACADEMY',
                    style: TextStyle(
                      color: AtlasColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
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
  final VoidCallback onMembership, onSubjectExams, onSystemExams, onMockExams;
  const _Home({
    required this.name,
    required this.onMembership,
    required this.onSubjectExams,
    required this.onSystemExams,
    required this.onMockExams,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final firstName = name.trim().split(' ').first;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 178,
          padding: const EdgeInsets.fromLTRB(18, 17, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFE5F1FF), Color(0xFFD4E8FF), Color(0xFFF1F7FF)],
            ),
          ),
          child: Stack(children: [
            Positioned(right: -12, top: 0, bottom: -15, child: Icon(
              Icons.medical_services_rounded, size: 145,
              color: AtlasColors.royalBlue.withValues(alpha: .22),
            )),
            Positioned(right: 28, top: 12, child: Icon(
              Icons.health_and_safety_outlined, size: 75,
              color: AtlasColors.royalBlue.withValues(alpha: .15),
            )),
            Align(alignment: Alignment.centerLeft, child: SizedBox(
              width: MediaQuery.sizeOf(context).width * .68,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Hello, $firstName!', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF123B68), fontSize: 26,
                    fontWeight: FontWeight.w900, letterSpacing: -.7)),
                const SizedBox(height: 7),
                const Text('Your journey to excellence continues',
                  style: TextStyle(color: Color(0xFF173B65), fontSize: 13, height: 1.4)),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 13),
        if (uid != null) _ProgressOverview(uid: uid),
        const SizedBox(height: 17),
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11,
          childAspectRatio: 1.12, shrinkWrap: true,
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
              action: 'Explore', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StudentPastPapersScreen()))),
          ],
        ),
        const SizedBox(height: 18),
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
          height: 105, width: double.infinity,
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
            Icon(Icons.school_rounded, size: 78,
              color: AtlasColors.royalBlue.withValues(alpha: .8)),
          ]),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  final String uid;
  const _ProgressOverview({required this.uid});
  @override
  Widget build(BuildContext context) =>
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('mcq_attempts')
        .where('userId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        var correct = 0, total = 0;
        for (final doc in docs) {
          final data = doc.data();
          correct += (data['correctAnswers'] as num?)?.toInt() ?? 0;
          total += (data['totalQuestions'] as num?)?.toInt() ?? 0;
        }
        final percent = total > 0 ? (correct * 100 / total).round().clamp(0, 100) : 0;
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2EBF7)),
            boxShadow: [BoxShadow(color: AtlasColors.navy.withValues(alpha: .07),
              blurRadius: 16, offset: const Offset(0, 5))],
          ),
          child: Column(children: [
            Row(children: [
              const Expanded(child: Text('Overall Progress', style: TextStyle(
                color: Color(0xFF152C50), fontSize: 16, fontWeight: FontWeight.w900))),
              Text('$percent%', style: const TextStyle(color: Color(0xFF123B68),
                fontSize: 25, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(value: percent / 100, minHeight: 11,
                backgroundColor: const Color(0xFFE4ECFA),
                color: const Color(0xFF2379E8))),
            const SizedBox(height: 10),
            Row(children: [
              Text(total.toString(), style: const TextStyle(color: Color(0xFF1768D1),
                fontWeight: FontWeight.w900, fontSize: 13)),
              const Text(' MCQs Attempted', style: TextStyle(
                color: Color(0xFF152C50), fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.bar_chart_rounded, color: Color(0xFF2379E8), size: 26),
            ]),
          ]),
        );
      },
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
            const Icon(Icons.trending_up_rounded, color: Color(0xFF159A85), size: 27),
          ]),
        );
      },
    );
}

class _SectionHeading extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: AtlasColors.paleBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AtlasColors.royalBlue, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AtlasColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AtlasColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _DashboardMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  const _DashboardMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtlasColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AtlasColors.secondaryText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AtlasColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ExamSectionCard extends StatelessWidget {
  final String title, subtitle, detail;
  final IconData icon;
  final VoidCallback onTap;

  const _ExamSectionCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: AtlasColors.border),
              boxShadow: [
                BoxShadow(
                  color: AtlasColors.navy.withValues(alpha: .035),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AtlasColors.paleBlue,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: AtlasColors.royalBlue, size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AtlasColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AtlasColors.secondaryText,
                          fontSize: 10,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AtlasColors.royalBlue,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AtlasColors.royalBlue,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      );
}
class _Membership extends StatelessWidget{
 final Map<String,dynamic> data;final VoidCallback onTap;const _Membership({required this.data,required this.onTap});
 @override Widget build(BuildContext context){
  DateTime? dt(dynamic v)=>v is Timestamp?v.toDate():null;
  final start=dt(data['subscriptionStartedAt']);final expiry=dt(data['subscriptionExpiryAt']);final days=(data['subscriptionDurationDays'] as num?)?.toInt()??(start!=null&&expiry!=null?expiry.difference(start).inDays:0);
  final left=expiry==null?0:expiry.difference(DateTime.now()).inDays.clamp(0,days>0?days:3650);final used=days>0?(days-left).clamp(0,days):0;final ratio=days>0?(used/days).clamp(0.0,1.0):0.0;
  final active=data['subscriptionStatus']=='active'&&data['accessEnabled']==true&&expiry!=null&&expiry.isAfter(DateTime.now());
  return Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AtlasColors.navy,AtlasColors.royalBlue]),borderRadius:BorderRadius.circular(23),boxShadow:[BoxShadow(color:AtlasColors.navy.withValues(alpha:.13),blurRadius:18,offset:const Offset(0,7))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[const Icon(Icons.workspace_premium,color:AtlasColors.champagne),const SizedBox(width:9),const Expanded(child:Text('Membership overview',style:TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w900))),Text(active?'ACTIVE':(data['subscriptionStatus']=='active'?'EXPIRED':'INACTIVE'),style:const TextStyle(color:AtlasColors.champagne,fontSize:10,fontWeight:FontWeight.w900))]),
   const SizedBox(height:14),Text((data['subscriptionPlanName']??'No active plan').toString(),style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:17),
   Row(children:[
    SizedBox(width:120,height:120,child:Stack(alignment:Alignment.center,children:[SizedBox.expand(child:CircularProgressIndicator(value:ratio,strokeWidth:9,backgroundColor:Colors.white24,valueColor:const AlwaysStoppedAnimation(AtlasColors.champagne),strokeCap:StrokeCap.round)),Column(mainAxisSize:MainAxisSize.min,children:[Text('$left',style:const TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.w900)),const Text('DAYS LEFT',style:TextStyle(color:Colors.white70,fontSize:9,letterSpacing:1))])])),
    const SizedBox(width:20),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_Metric('Days used',days>0?'$used':'—'),const SizedBox(height:12),_Metric('Membership duration',days>0?'$days days':'Not available'),const SizedBox(height:12),_Metric('Expiry date',expiry!=null?expiry.day.toString()+'/'+expiry.month.toString()+'/'+expiry.year.toString():'Not activated')]))
   ]),
   const SizedBox(height:16),ClipRRect(borderRadius:BorderRadius.circular(9),child:LinearProgressIndicator(value:ratio,minHeight:7,backgroundColor:Colors.white24,color:AtlasColors.champagne)),
   const SizedBox(height:17),Row(children:[Expanded(child:OutlinedButton(onPressed:onTap,style:OutlinedButton.styleFrom(foregroundColor:Colors.white,side:const BorderSide(color:Colors.white54),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),child:Text(active?'Upgrade plan':'Choose a plan'))),const SizedBox(width:10),Expanded(child:FilledButton(onPressed:onTap,style:FilledButton.styleFrom(backgroundColor:AtlasColors.champagne,foregroundColor:AtlasColors.navy,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),child:Text(active?'Renew membership':'Activate membership')))])
  ]));
 }
}
class _Metric extends StatelessWidget{final String label,value;const _Metric(this.label,this.value);@override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:Colors.white60,fontSize:10)),const SizedBox(height:3),Text(value,style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w800))]);}
class _Stats extends StatelessWidget{
 final String uid;const _Stats({required this.uid});
 @override Widget build(BuildContext context)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('mcq_attempts').where('userId',isEqualTo:uid).snapshots(),builder:(c,s){if(s.hasError)return const Text('Statistics are temporarily unavailable.');final docs=s.data?.docs??[];final past=docs.where((d)=>d.data()['trackType']=='past_paper').length;final exams=docs.where((d)=>d.data()['trackType']!='past_paper'&&d.data()['examSetId']!=null).length;return Row(children:[Expanded(child:_Stat('Past papers attempted','$past',Icons.history_edu_rounded,AtlasColors.gold)),const SizedBox(width:12),Expanded(child:_Stat('Exams attempted','$exams',Icons.assignment_turned_in_rounded,AtlasColors.royalBlue))]);});
}
class _Stat extends StatelessWidget{final String title,value;final IconData icon;final Color color;const _Stat(this.title,this.value,this.icon,this.color);@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:AtlasColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:color,size:24),const SizedBox(height:10),Text(value,style:const TextStyle(color:AtlasColors.navy,fontSize:25,fontWeight:FontWeight.w900)),Text(title,style:const TextStyle(color:AtlasColors.secondaryText,fontSize:10,fontWeight:FontWeight.w700))]));}
class _FeaturePage extends StatelessWidget{final String title;final IconData icon;final VoidCallback onOpen;const _FeaturePage(this.title,this.icon,this.onOpen);@override Widget build(BuildContext context)=>Center(child:Container(constraints:const BoxConstraints(maxWidth:450),padding:const EdgeInsets.all(25),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:AtlasColors.border)),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,color:AtlasColors.royalBlue,size:48),const SizedBox(height:14),Text(title,style:const TextStyle(color:AtlasColors.navy,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:20),FilledButton.icon(onPressed:onOpen,icon:const Icon(Icons.arrow_forward),label:const Text('Open feature'))])));}
class _QuoteCarousel extends StatefulWidget{const _QuoteCarousel();@override State<_QuoteCarousel> createState()=>_QuoteCarouselState();}
class _QuoteCarouselState extends State<_QuoteCarousel>{
 final controller=PageController(viewportFraction:.92);Timer? timer;int index=0;
 static const cards=[
 ('QURAN','Indeed, with hardship comes ease.','Qur’an 94:6'),('QURAN','My Lord, increase me in knowledge.','Qur’an 20:114'),('QURAN','Allah does not burden a soul beyond what it can bear.','Qur’an 2:286'),('QURAN','Whoever relies upon Allah, He is sufficient for him.','Qur’an 65:3'),('QURAN','So remember Me; I will remember you.','Qur’an 2:152'),('QURAN','Whoever saves one life, it is as if he saved all mankind.','Qur’an 5:32'),('QURAN','And say: My Lord, increase me in knowledge.','Qur’an 20:114'),
 ('HADITH','Whoever follows a path seeking knowledge, Allah makes easy for him a path to Paradise.','Sahih Muslim 2699'),('HADITH','The best of you are those who learn the Qur’an and teach it.','Sahih al-Bukhari 5027'),('HADITH','Allah is gentle and loves gentleness in all matters.','Sahih al-Bukhari 6927'),('HADITH','Make things easy and do not make them difficult.','Sahih al-Bukhari 69'),('HADITH','The strong believer is better and more beloved to Allah.','Sahih Muslim 2664'),('HADITH','Whoever does not show mercy will not be shown mercy.','Sahih al-Bukhari 6013'),('HADITH','The most beloved deeds are those done regularly, even if small.','Sahih al-Bukhari 6464'),
 ('INSPIRATION','Small, consistent efforts become extraordinary achievements.','A reminder for your journey'),('INSPIRATION','Let curiosity guide you, discipline carry you, and compassion define you.','For future clinicians'),('INSPIRATION','Every concept mastered today is confidence for tomorrow.','A reminder for your journey'),('INSPIRATION','Progress is built one focused study session at a time.','A reminder for your journey'),('INSPIRATION','Your knowledge matters most when used to serve others.','For future clinicians'),('INSPIRATION','Be patient with the process. Excellence is a practice, not a moment.','A reminder for your journey'),('INSPIRATION','Study with purpose. Practice with honesty. Treat every patient with kindness.','The Atlas Academy')
 ];
 @override void initState(){super.initState();timer=Timer.periodic(const Duration(seconds:6),(_){if(!mounted)return;index=(index+1)%cards.length;controller.animateToPage(index,duration:const Duration(milliseconds:600),curve:Curves.easeInOut);});}
 @override void dispose(){timer?.cancel();controller.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Column(children:[SizedBox(height:204,child:PageView.builder(controller:controller,itemCount:cards.length,onPageChanged:(i)=>setState(()=>index=i),itemBuilder:(c,i){final v=cards[i];final colors=v.$1=='QURAN'?[const Color(0xFF0B3151),const Color(0xFF176B73)]:v.$1=='HADITH'?[AtlasColors.navy,AtlasColors.royalBlue]:[const Color(0xFF263D65),const Color(0xFF5476A8)];return Padding(padding:const EdgeInsets.only(right:9,bottom:4),child:Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:LinearGradient(colors:colors),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(v.$1=='QURAN'?Icons.menu_book_rounded:v.$1=='HADITH'?Icons.auto_stories_rounded:Icons.lightbulb_outline,color:AtlasColors.champagne),const SizedBox(width:8),Expanded(child:Text(v.$1,style:const TextStyle(color:AtlasColors.champagne,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1.3))),Text((i+1).toString()+'/'+cards.length.toString(),style:const TextStyle(color:Colors.white60,fontSize:10))]),const Spacer(),Text(v.$2,style:const TextStyle(color:Colors.white,fontSize:16,height:1.5,fontWeight:FontWeight.w700),maxLines:4,overflow:TextOverflow.ellipsis),const SizedBox(height:10),Text(v.$3,style:const TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w700))]))); })),const SizedBox(height:4),Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(cards.length,(i)=>AnimatedContainer(duration:const Duration(milliseconds:200),margin:const EdgeInsets.symmetric(horizontal:2),width:index==i?16:5,height:5,decoration:BoxDecoration(color:index==i?AtlasColors.royalBlue:AtlasColors.border,borderRadius:BorderRadius.circular(8)))))]);}
class _NoticeLine extends StatelessWidget{
 const _NoticeLine();
 Future<void> open(BuildContext context,String value)async{final uri=Uri.tryParse(value);if(uri==null||!['https','http'].contains(uri.scheme)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('This announcement link is invalid.')));return;}if(!await launchUrl(uri,mode:LaunchMode.externalApplication)&&context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Unable to open this link.')));}
 @override Widget build(BuildContext context)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('notifications').where('audience',isEqualTo:'all').where('isActive',isEqualTo:true).snapshots(),builder:(c,s){final docs=[...(s.data?.docs??[])]..sort((a,b){final x=a.data()['createdAt'];final y=b.data()['createdAt'];return (y is Timestamp?y.toDate():DateTime(1970)).compareTo(x is Timestamp?x.toDate():DateTime(1970));});if(docs.isEmpty)return const SizedBox.shrink();final d=docs.first.data();final link=(d['linkUrl']??d['url']??'').toString().trim();return Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:11),decoration:BoxDecoration(color:const Color(0xFFFFF5DF),borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFFEAD6A7))),child:Row(children:[const Icon(Icons.campaign_rounded,color:AtlasColors.gold),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((d['title']??'Academy announcement').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AtlasColors.navy,fontSize:11,fontWeight:FontWeight.w900)),Text((d['body']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AtlasColors.charcoal,fontSize:10,height:1.4))])),if(link.isNotEmpty)IconButton(tooltip:'Open link',onPressed:()=>open(context,link),style:IconButton.styleFrom(backgroundColor:AtlasColors.navy,foregroundColor:Colors.white),icon:const Icon(Icons.open_in_new_rounded,size:17))]));});
}


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
