import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../mcqs/screens/student_mcq_practice_screen.dart';

class StudentExamCentreScreen extends StatelessWidget {
  final String section;
  const StudentExamCentreScreen({super.key, required this.section});

  static const _titles = {
    'subject_exam': 'Subject-Wise Exams',
    'system_exam': 'System-Wise Exams',
    'subject_mock': 'Subject Mocks',
    'system_mock': 'System Mocks',
    'grand_mock': 'Grand Mocks',
    'mocks': 'Mock Exams',
  };

  @override
  Widget build(BuildContext context) {
    final title = _titles[section] ?? 'Examinations';
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(title: Text(title), backgroundColor: Colors.white, foregroundColor: AtlasColors.navy, elevation: 0),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Restrict the stream to the new structured exam model.
        stream: FirebaseFirestore.instance
            .collection('mcq_exam_sets')
            .where('trackType', isEqualTo: 'structured')
            .where('isPublished', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to load $title: ${snapshot.error}',
                  textAlign: TextAlign.center),
            ));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final category = (data['examCategory'] ?? '').toString();
            final isAcademyExam = data['trackType'] == 'structured';
            return isAcademyExam && (section == 'mocks' ? category.endsWith('_mock') : category == section) &&
                data['isActive'] != false;
          }).toList()
            ..sort((a, b) => (a.data()['name'] ?? '')
                .toString().compareTo((b.data()['name'] ?? '').toString()));

          if (docs.isEmpty) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text('No published ${title.toLowerCase()} yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AtlasColors.secondaryText)),
            ));
          }

          if (section == 'mocks') {
            const mockLabels = {
              'subject_mock': 'Subject Mocks',
              'system_mock': 'System Mocks',
              'grand_mock': 'Grand Mocks',
            };
            return ListView(
              padding: const EdgeInsets.all(16),
              children: mockLabels.entries.map((entry) {
                final group = docs.where((doc) =>
                    doc.data()['examCategory'] == entry.key).toList();
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AtlasColors.border)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.fact_check_rounded,
                        color: AtlasColors.royalBlue),
                    title: Text(entry.value, style: const TextStyle(
                        color: AtlasColors.navy, fontWeight: FontWeight.w900)),
                    subtitle: Text('${group.length} mock(s)'),
                    children: _tiles(context, group),
                  ),
                );
              }).toList(),
            );
          }
          if (section.endsWith('_mock')) return _examList(context, docs);

          final groups = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
          for (final doc in docs) {
            final data = doc.data();
            final categoryName = (data['categoryName'] ??
                data['subjectName'] ?? 'Uncategorised').toString();
            groups.putIfAbsent(categoryName, () => []).add(doc);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: groups.entries.map((entry) => Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AtlasColors.border)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: Icon(section == 'subject_exam'
                    ? Icons.menu_book_rounded : Icons.account_tree_rounded,
                    color: AtlasColors.royalBlue),
                title: Text(entry.key, style: const TextStyle(
                    color: AtlasColors.navy, fontWeight: FontWeight.w900)),
                subtitle: Text('${entry.value.length} exam(s)'),
                children: _tiles(context, entry.value),
              ),
            )).toList(),
          );
        },
      ),
    );
  }

  Widget _examList(BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return ListView(padding: const EdgeInsets.all(16), children: _tiles(context, docs));
  }

  List<Widget> _tiles(BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      return ListTile(
        leading: const CircleAvatar(
          backgroundColor: AtlasColors.paleBlue,
          child: Icon(Icons.assignment_turned_in_rounded,
              color: AtlasColors.royalBlue),
        ),
        title: Text((data['name'] ?? 'Exam').toString(),
            style: const TextStyle(color: AtlasColors.navy,
                fontWeight: FontWeight.w800)),
        subtitle: Text('${data['durationMinutes'] ?? 60} minutes',
            style: const TextStyle(color: AtlasColors.secondaryText)),
        trailing: const Icon(Icons.play_circle_fill_rounded,
            color: AtlasColors.royalBlue),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => StudentMcqPracticeScreen(examSetId: doc.id),
        )),
      );
    }).toList();
  }
}
