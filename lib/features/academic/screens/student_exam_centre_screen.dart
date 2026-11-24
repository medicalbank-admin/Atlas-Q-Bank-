import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFFF2F7FF), foregroundColor: AtlasColors.navy, elevation: 0, scrolledUnderElevation: 0),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            return (section == 'mocks' ? category.endsWith('_mock') : category == section) &&
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

          if (user == null) {
            return const Center(child: Text('Please sign in to view your exam progress.'));
          }

          // One student-scoped stream supplies attempt history to every exam card.
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('mcq_attempts')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, attemptsSnapshot) {
              if (attemptsSnapshot.hasError) {
                return Center(child: Text('Unable to load exam progress: ${attemptsSnapshot.error}'));
              }
              if (!attemptsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final attempts = attemptsSnapshot.data!.docs;
              if (section == 'mocks') {
                const mockLabels = {
                  'subject_mock': 'Subject Mocks',
                  'system_mock': 'System Mocks',
                  'grand_mock': 'Grand Mocks',
                };
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 17, 18, 28),
                  children: mockLabels.entries.map((entry) {
                    final group = docs.where((doc) =>
                        doc.data()['examCategory'] == entry.key).toList();
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE0EAF5))),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Icon(Icons.fact_check_rounded, color: AtlasColors.royalBlue),
                        title: Text(entry.value, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
                        subtitle: Text('${group.length} mock(s)'),
                        children: _tiles(context, group, attempts),
                      ),
                    );
                  }).toList(),
                );
              }
              if (section.endsWith('_mock')) return _examList(context, docs, attempts);

              final groups = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
              for (final doc in docs) {
                final data = doc.data();
                final categoryName = (data['categoryName'] ??
                    data['subjectName'] ?? 'Uncategorised').toString();
                groups.putIfAbsent(categoryName, () => []).add(doc);
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                children: groups.entries.map((entry) => Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AtlasColors.border)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: Icon(section == 'subject_exam' ? Icons.menu_book_rounded : Icons.account_tree_rounded, color: AtlasColors.royalBlue),
                    title: Text(entry.key, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
                    subtitle: Text('${entry.value.length} exam(s)'),
                    children: _tiles(context, entry.value, attempts),
                  ),
                )).toList(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _examList(BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> attempts) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      children: _tiles(context, docs, attempts),
    );
  }

  List<Widget> _tiles(BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> attempts) {
    return docs.map((doc) {
      final data = doc.data();
      final examAttempts = attempts.where((attempt) =>
          attempt.data()['examSetId'] == doc.id).toList();
      final hasAttempt = examAttempts.isNotEmpty;
      final bestScore = hasAttempt
          ? examAttempts.map((attempt) =>
              (attempt.data()['percentage'] as num?)?.toDouble() ?? 0.0)
              .reduce((a, b) => a > b ? a : b)
          : 0.0;
      final progressColor = !hasAttempt
          ? AtlasColors.border
          : bestScore < 30
              ? const Color(0xFFE05252)
              : bestScore < 60
                  ? const Color(0xFFE5B83F)
                  : const Color(0xFF2EAA70);
      final configuredCount = (data['questionCount'] as num?)?.toInt();
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 3, 12, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCFF),
          borderRadius: BorderRadius.circular(17),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => StudentMcqPracticeScreen(examSetId: doc.id),
          )),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F1FF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: AtlasColors.royalBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((data['name'] ?? 'Exam').toString(),
                        style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${data['durationMinutes'] ?? 60} minutes',
                        style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 12)),
                    ],
                  )),
                  const Icon(Icons.play_circle_fill_rounded, color: AtlasColors.royalBlue, size: 27),
                ]),
                const SizedBox(height: 13),
                Row(children: [
                  const Icon(Icons.quiz_outlined, size: 16, color: AtlasColors.royalBlue),
                  const SizedBox(width: 6),
                  const Text('Total MCQs', style: TextStyle(color: AtlasColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (configuredCount != null)
                    Text('$configuredCount questions', style: const TextStyle(color: AtlasColors.navy, fontSize: 12, fontWeight: FontWeight.w800))
                  else
                    FutureBuilder<AggregateQuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('mcqs')
                          .where('examSetId', isEqualTo: doc.id)
                          .where('isPublished', isEqualTo: true)
                          .count().get(),
                      builder: (context, countSnapshot) {
                        if (countSnapshot.hasError) {
                          return const Text('Count unavailable', style: TextStyle(color: AtlasColors.secondaryText, fontSize: 11));
                        }
                        if (!countSnapshot.hasData) {
                          return const SizedBox(width: 48, height: 3, child: LinearProgressIndicator(minHeight: 3));
                        }
                        return Text('${countSnapshot.data!.count ?? 0} questions',
                          style: const TextStyle(color: AtlasColors.navy, fontSize: 12, fontWeight: FontWeight.w800));
                      },
                    ),
                ]),
                const SizedBox(height: 11),
                Row(children: [
                  Text(hasAttempt ? 'Best attempt' : 'Not attempted',
                    style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${bestScore.round()}%',
                    style: TextStyle(color: hasAttempt ? progressColor : AtlasColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: hasAttempt ? (bestScore.clamp(0, 100) / 100).clamp(0.035, 1.0).toDouble() : 0,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE9EEF5),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
