import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import 'learning_resource_management_screen.dart';

/// Resource-first navigation: choose existing curriculum nodes without
/// entering the academic-year creation workflow.
class AdminLearningResourcesScreen extends StatefulWidget {
  const AdminLearningResourcesScreen({super.key});

  @override
  State<AdminLearningResourcesScreen> createState() =>
      _AdminLearningResourcesScreenState();
}

class _AdminLearningResourcesScreenState
    extends State<AdminLearningResourcesScreen> {
  String? _yearId;
  String? _subjectId;

  Query<Map<String, dynamic>> _years() =>
      FirebaseFirestore.instance.collection('academic_years');

  Query<Map<String, dynamic>> _subjects() =>
      FirebaseFirestore.instance.collection('academic_subjects')
          .where('yearId', isEqualTo: _yearId);

  Query<Map<String, dynamic>> _topics() =>
      FirebaseFirestore.instance.collection('academic_topics')
          .where('yearId', isEqualTo: _yearId)
          .where('subjectId', isEqualTo: _subjectId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: const Text('Learning Resources'),
        backgroundColor: AtlasColors.navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AtlasColors.navy, AtlasColors.royalBlue],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.video_library_rounded,
                    color: AtlasColors.champagne, size: 32),
                SizedBox(height: 12),
                Text('Resource Centre',
                    style: TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Choose an existing academic year, subject and topic '
                    'to add, publish or manage learning materials.',
                    style: TextStyle(color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _heading('1. Select academic year'),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _years().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _error(snapshot.error);
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) => ((a.data()['order'] as num?) ?? 0)
                    .compareTo((b.data()['order'] as num?) ?? 0));
              if (docs.isEmpty) {
                return _empty('No academic years exist yet. Create them '
                    'under Academic Management first.');
              }
              return Column(
                children: docs.map((doc) {
                  final selected = _yearId == doc.id;
                  return _choice(
                    title: (doc.data()['name'] ?? 'Academic year').toString(),
                    subtitle: doc.data()['isActive'] == false
                        ? 'Inactive' : 'Academic year',
                    selected: selected,
                    onTap: () => setState(() {
                      _yearId = doc.id;
                      _subjectId = null;
                    }),
                  );
                }).toList(),
              );
            },
          ),
          if (_yearId != null) ...[
            const SizedBox(height: 22),
            _heading('2. Select subject'),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _subjects().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _error(snapshot.error);
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return _empty('No subjects are linked to this year yet.');
                return Column(children: docs.map((doc) {
                  final selected = _subjectId == doc.id;
                  return _choice(
                    title: (doc.data()['name'] ?? 'Subject').toString(),
                    subtitle: 'Subject',
                    selected: selected,
                    onTap: () => setState(() {
                      _subjectId = doc.id;
                    }),
                  );
                }).toList());
              },
            ),
          ],
          if (_yearId != null && _subjectId != null) ...[
            const SizedBox(height: 22),
            _heading('3. Select topic'),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _topics().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _error(snapshot.error);
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return _empty('No topics are linked to this subject yet.');
                return Column(children: docs.map((doc) {
                  final title = (doc.data()['title'] ?? 'Topic').toString();
                  return _choice(
                    title: title,
                    subtitle: 'Manage resources for this topic',
                    selected: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) =>
                        LearningResourceManagementScreen(
                          yearId: _yearId!,
                          subjectId: _subjectId!,
                          topicId: doc.id,
                          topicTitle: title,
                        )),
                    ),
                  );
                }).toList());
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _heading(String text) => Text(text,
      style: const TextStyle(color: AtlasColors.navy,
          fontSize: 17, fontWeight: FontWeight.w900));

  Widget _choice({required String title, required String subtitle,
      required bool selected, required VoidCallback onTap}) =>
    Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(selected ? Icons.check_circle : Icons.folder_outlined,
            color: AtlasColors.royalBlue),
        title: Text(title, style: const TextStyle(
            color: AtlasColors.navy, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(
            color: AtlasColors.secondaryText)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AtlasColors.royalBlue),
      ),
    );

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(text, style: const TextStyle(
        color: AtlasColors.secondaryText, height: 1.5)),
  );

  Widget _error(Object? error) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text('Unable to load curriculum: $error',
        style: const TextStyle(color: AtlasColors.error)),
  );
}
