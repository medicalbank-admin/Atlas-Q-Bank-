import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/atlas_academy_app.dart';
import '../models/learning_resource_model.dart';

class StudentStudyLibraryScreen extends StatefulWidget {
  const StudentStudyLibraryScreen({super.key});
  @override
  State<StudentStudyLibraryScreen> createState() => _StudentStudyLibraryScreenState();
}

class _StudentStudyLibraryScreenState extends State<StudentStudyLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F7FF),
    appBar: AppBar(
      title: const Text('Learning Library'),
      backgroundColor: const Color(0xFFF2F7FF),
      foregroundColor: AtlasColors.navy,
      elevation: 0,
      bottom: TabBar(controller: _tabs,
        labelColor: AtlasColors.royalBlue,
        unselectedLabelColor: AtlasColors.secondaryText,
        indicatorColor: AtlasColors.royalBlue,
        tabs: const [
          Tab(icon: Icon(Icons.notes_rounded), text: 'Notes'),
          Tab(icon: Icon(Icons.picture_as_pdf_rounded), text: 'PDFs'),
          Tab(icon: Icon(Icons.play_circle_rounded), text: 'Videos'),
        ]),
    ),
    body: Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE4F0FF), Color(0xFFD5E8FF)]),
          borderRadius: BorderRadius.circular(20)),
        child: const Row(children: [
          Icon(Icons.local_library_rounded, color: AtlasColors.royalBlue, size: 30),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Learning Library', style: TextStyle(color: AtlasColors.navy,
              fontSize: 18, fontWeight: FontWeight.w900)),
            SizedBox(height: 4),
            Text('New content published by your academy appears here.',
              style: TextStyle(color: Color(0xFF526B87), height: 1.4)),
          ])),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _ResourceShelf(type: LearningResourceType.text, onOpen: _open),
        _ResourceShelf(type: LearningResourceType.pdf, onOpen: _open),
        _ResourceShelf(type: LearningResourceType.video, onOpen: _open),
      ])),
    ]),
  );

  Future<void> _open(LearningResourceModel resource) async {
    if (resource.type == LearningResourceType.text) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _NoteReader(resource: resource)));
      return;
    }
    final uri = Uri.tryParse(resource.resourceUrl);
    if (uri == null || !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      _message('This content link is invalid.'); return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('No compatible app could open this content.');
      if (!mounted) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('student_resource_progress')
          .doc('${uid}_${resource.id}').set({
            'userId': uid, 'resourceId': resource.id, 'completed': true,
            'completedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      }
    } catch (e) { _message('Unable to open content: $e'); }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _ResourceShelf extends StatelessWidget {
  final LearningResourceType type;
  final ValueChanged<LearningResourceModel> onOpen;
  const _ResourceShelf({required this.type, required this.onOpen});

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('learning_resources')
      .where('isPublished', isEqualTo: true).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text(
        'Unable to load content. Check your connection or subscription access.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final items = snapshot.data!.docs.map(LearningResourceModel.fromFirestore)
        .where((item) => item.type == type).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (items.isEmpty) {
        final label = switch (type) {
          LearningResourceType.text => 'notes',
          LearningResourceType.pdf => 'PDFs',
          _ => 'videos',
        };
        return Center(child: Padding(padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(switch (type) {
              LearningResourceType.text => Icons.notes_rounded,
              LearningResourceType.pdf => Icons.picture_as_pdf_rounded,
              _ => Icons.play_circle_outline_rounded,
            }, size: 46, color: AtlasColors.royalBlue),
            const SizedBox(height: 12),
            Text('No $label published yet', style: const TextStyle(
              color: AtlasColors.navy, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            const Text('Please check back later.',
              style: TextStyle(color: AtlasColors.secondaryText)),
          ])));
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final icon = switch (type) {
            LearningResourceType.text => Icons.article_rounded,
            LearningResourceType.pdf => Icons.picture_as_pdf_rounded,
            _ => Icons.play_circle_fill_rounded,
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 11),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0EAF5))),
            child: ListTile(
              onTap: () => onOpen(item),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              leading: Container(width: 46, height: 46,
                decoration: BoxDecoration(color: const Color(0xFFE5F1FF),
                  borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: AtlasColors.royalBlue)),
              title: Text(item.title, style: const TextStyle(
                color: AtlasColors.navy, fontWeight: FontWeight.w900)),
              subtitle: Text(item.description.isEmpty
                ? (type == LearningResourceType.text ? 'Study note' :
                    type == LearningResourceType.pdf ? 'PDF document' : 'Video lesson')
                : item.description,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AtlasColors.secondaryText)),
              trailing: const Icon(Icons.arrow_forward_rounded, color: AtlasColors.royalBlue),
            ));
        });
    });
}

class _NoteReader extends StatelessWidget {
  final LearningResourceModel resource;
  const _NoteReader({required this.resource});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F7FF),
    appBar: AppBar(title: Text(resource.title),
      backgroundColor: const Color(0xFFF2F7FF), foregroundColor: AtlasColors.navy),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      if (resource.description.isNotEmpty) ...[
        Text(resource.description, style: const TextStyle(
          color: AtlasColors.secondaryText, fontSize: 14, height: 1.5)),
        const SizedBox(height: 18),
      ],
      Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
        child: SelectableText(resource.textContent, style: const TextStyle(
          color: AtlasColors.navy, height: 1.75, fontSize: 15))),
    ]),
  );
}
