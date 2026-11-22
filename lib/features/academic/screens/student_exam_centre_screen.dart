import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../mcqs/screens/student_mcq_practice_screen.dart';

class StudentExamCentreScreen extends StatelessWidget {
  final bool pathwaysOnly;
  const StudentExamCentreScreen({super.key, this.pathwaysOnly = false});

  @override
  Widget build(BuildContext context) {
    if (pathwaysOnly) return _pathwayScreen(context);
    return DefaultTabController(length: 3, child: Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(title: const Text('Examination Centre'), bottom: const TabBar(isScrollable: true, tabs: [
        Tab(text: 'Subject-Wise'), Tab(text: 'System-Wise'), Tab(text: 'Mock Exams'),
      ])),
      body: Column(children: [
        Container(width: double.infinity, margin: const EdgeInsets.fromLTRB(16, 14, 16, 10), padding: const EdgeInsets.all(17), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AtlasColors.navy, AtlasColors.royalBlue]), borderRadius: BorderRadius.circular(18)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your Examination Centre', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
          SizedBox(height: 5), Text('Choose a subject, system or mock examination. Only exams published by the academy appear here.', style: TextStyle(color: Colors.white70, height: 1.45)),
        ])),
        const Expanded(child: TabBarView(children: [
          _StructuredExamList(types: ['subject_exam'], heading: 'Subject-Wise Exams'),
          _StructuredExamList(types: ['system_exam'], heading: 'System-Wise Exams'),
          _StructuredExamList(types: ['subject_mock', 'system_mock', 'grand_mock'], heading: 'Mock Exams', showMockTypes: true),
        ])),
      ]),
    ));
  }

  Widget _pathwayScreen(BuildContext context) => Scaffold(
    backgroundColor: AtlasColors.ivory,
    appBar: AppBar(title: const Text('Exam Pathways')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('licensing_pathways').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Unable to load pathways.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No licensing pathways are available yet.'));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: snapshot.data!.docs.map((pathway) {
            return Card(
              child: ExpansionTile(
                title: Text((pathway.data()['name'] ?? 'Pathway').toString()),
                subtitle: Text((pathway.data()['description'] ?? '').toString()),
                children: [
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('mcq_exam_sets')
                      .where('pathwayId', isEqualTo: pathway.id)
                      .where('trackType', isEqualTo: 'licensing')
                      .where('isPublished', isEqualTo: true).snapshots(),
                    builder: (context, setsSnapshot) {
                      if (!setsSnapshot.hasData) return const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator());
                      final sets = setsSnapshot.data!.docs;
                      if (sets.isEmpty) return const ListTile(title: Text('No published sets yet.'));
                      return Column(children: sets.map((examSet) {
                        return ListTile(
                          title: Text((examSet.data()['name'] ?? 'Exam').toString()),
                          trailing: const Icon(Icons.play_arrow),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentMcqPracticeScreen(examSetId: examSet.id))),
                        );
                      }).toList());
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    ),
  );
}

class _StructuredExamList extends StatelessWidget {
  final List<String> types;
  final String heading;
  final bool showMockTypes;
  const _StructuredExamList({required this.types, required this.heading, this.showMockTypes = false});

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream: FirebaseFirestore.instance.collection('mcq_exam_sets').where('isPublished', isEqualTo: true).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Unable to load $heading. Please try again.')));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs.where((d) { final x = d.data(); final category = (x['examCategory'] ?? '').toString(); final isNewStructure = x['yearId'] == 'exam_centre' && types.contains(category); final isLegacySubjectSet = types.contains('subject_exam') && x['trackType'] == 'mbbs' && x['yearId'] != 'exam_centre' && category.isEmpty; return (isNewStructure || isLegacySubjectSet) && x['isActive'] != false; }).toList();
      if (docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(28), child: Text('No published exams in this section yet.', style: const TextStyle(color: AtlasColors.secondaryText))));
      if (showMockTypes) {
        const labels = {'subject_mock': 'Subject Mocks', 'system_mock': 'System Mocks', 'grand_mock': 'Grand Mocks'};
        return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: types.map((type) {
          final group = docs.where((d) => d.data()['examCategory'] == type).toList();
          return _section(context, labels[type] ?? 'Mocks', group);
        }).toList());
      }
      final groups = <String, List<QueryDocumentSnapshot<Map<String,dynamic>>>>{};
      for (final doc in docs) {
        final x = doc.data(); final name = (x['categoryName'] ?? x['subjectName'] ?? 'Previously Published Exams').toString();
        groups.putIfAbsent(name, () => []).add(doc);
      }
      return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: groups.entries.map((e) => _section(context, e.key, e.value)).toList());
    },
  );

  Widget _section(BuildContext context, String title, List<QueryDocumentSnapshot<Map<String,dynamic>>> docs) {
    final sorted = [...docs]..sort((a,b) => (a.data()['name'] ?? '').toString().compareTo((b.data()['name'] ?? '').toString()));
    return Card(color: Colors.white, margin: const EdgeInsets.only(bottom: 12), child: ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.folder_open_rounded, color: AtlasColors.royalBlue),
      title: Text(title, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
      subtitle: Text('${docs.length} exam(s)', style: const TextStyle(color: AtlasColors.secondaryText)),
      children: sorted.map((d) {
        final x = d.data();
        return ListTile(
          leading: const CircleAvatar(backgroundColor: AtlasColors.paleBlue, child: Icon(Icons.assignment_turned_in_rounded, color: AtlasColors.royalBlue)),
          title: Text((x['name'] ?? 'Exam').toString(), style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800)),
          subtitle: Text('${x['durationMinutes'] ?? 60} minutes', style: const TextStyle(color: AtlasColors.secondaryText)),
          trailing: const Icon(Icons.play_circle_fill_rounded, color: AtlasColors.royalBlue),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentMcqPracticeScreen(examSetId: d.id))),
        );
      }).toList(),
    ));
  }
}
