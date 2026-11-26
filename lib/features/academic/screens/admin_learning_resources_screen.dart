import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../models/learning_resource_model.dart';
import 'learning_resource_upload_dialog.dart';
import 'atlas_notes_studio_screen.dart';

class AdminLearningResourcesScreen extends StatefulWidget {
  const AdminLearningResourcesScreen({super.key});

  @override
  State<AdminLearningResourcesScreen> createState() => _AdminLearningResourcesScreenState();
}

class _AdminLearningResourcesScreenState extends State<AdminLearningResourcesScreen> {
  final TextEditingController _search = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _publish(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Create learning content', style: TextStyle(
              color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE6F1FC),
                child: Icon(Icons.auto_stories_rounded, color: AtlasColors.royalBlue)),
              title: const Text('Create textbook chapter', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Atlas Notes Studio • Rich content blocks'),
              onTap: () => Navigator.pop(sheetContext, 'chapter'),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE6F1FC),
                child: Icon(Icons.cloud_upload_rounded, color: AtlasColors.royalBlue)),
              title: const Text('Upload PDF or video', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Continue with the existing file publishing workflow'),
              onTap: () => Navigator.pop(sheetContext, 'file'),
            ),
          ]),
        ),
      ),
    );
    if (choice == 'chapter' && context.mounted) {
      final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => const AtlasNotesStudioScreen()));
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atlas chapter saved.')));
      }
    } else if (choice == 'file' && context.mounted) {
      final result = await showDialog<bool>(context: context,
        builder: (_) => const LearningResourceUploadDialog());
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content published for students.')));
      }
    }
  }

  Future<void> _edit(BuildContext context, String id) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AtlasNotesStudioScreen(resourceId: id)));
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapter changes saved.')));
    }
  }

  Future<void> _toggle(BuildContext context, String id, bool current) async {
    try {
      await FirebaseFirestore.instance.collection('learning_resources').doc(id).update({
        'isPublished': !current, 'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update content: $e')));
    }
  }

  Future<void> _delete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Delete content?'),
      content: const Text('This removes the item from the student library.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
      ],
    ));
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance.collection('learning_resources').doc(id).delete();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete content: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F7FF),
    appBar: AppBar(title: const Text('Learning Content'),
      backgroundColor: const Color(0xFFF2F7FF), foregroundColor: AtlasColors.navy),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _publish(context), backgroundColor: AtlasColors.royalBlue,
      foregroundColor: Colors.white, icon: const Icon(Icons.publish_rounded),
      label: const Text('Create Content')),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 100), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AtlasColors.navy, AtlasColors.royalBlue]),
          borderRadius: BorderRadius.circular(22)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.library_books_rounded, color: Colors.white, size: 30),
          SizedBox(height: 12),
          Text('Atlas Notes Studio + Resource Library', style: TextStyle(
            color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text('Create rich textbook chapters with headings, medical illustrations and clinical learning blocks, or continue uploading PDFs and videos.'
            'Students see it in Notes, PDFs or Videos.',
            style: TextStyle(color: Colors.white70, height: 1.5)),
        ]),
      ),
      const SizedBox(height: 20),
      const Text('Your content', style: TextStyle(color: AtlasColors.navy,
        fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('learning_resources').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text(
            'Unable to load content. Check Firestore permissions.');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final allDocs = snapshot.data!.docs;
          final publishedCount = allDocs.where((doc) => doc.data()['isPublished'] == true).length;
          final draftCount = allDocs.length - publishedCount;
          final noteCount = allDocs.where((doc) => doc.data()['type'] == 'text').length;
          final pdfCount = allDocs.where((doc) => doc.data()['type'] == 'pdf').length;
          final videoCount = allDocs.where((doc) => doc.data()['type'] == 'video').length;
          final query = _search.text.trim().toLowerCase();
          final docs = allDocs.where((doc) {
            final data = doc.data();
            final published = data['isPublished'] == true;
            final statusMatches = _statusFilter == 'All' ||
              (_statusFilter == 'Published' && published) ||
              (_statusFilter == 'Drafts' && !published);
            final searchable = [
              data['title'], data['description'], data['subjectName'],
              data['systemName'], data['topicName'],
            ].map((v) => (v ?? '').toString().toLowerCase()).join(' ');
            return statusMatches && (query.isEmpty || searchable.contains(query));
          }).toList()..sort((a, b) {
            final av = a.data()['updatedAt'] ?? a.data()['createdAt'];
            final bv = b.data()['updatedAt'] ?? b.data()['createdAt'];
            final ad = av is Timestamp ? av.toDate() : DateTime(2000);
            final bd = bv is Timestamp ? bv.toDate() : DateTime(2000);
            return bd.compareTo(ad);
          });
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: 9, runSpacing: 9, children: [
              _ContentMetric(label: 'Total content', value: allDocs.length, icon: Icons.library_books_rounded),
              _ContentMetric(label: 'Published', value: publishedCount, icon: Icons.public_rounded),
              _ContentMetric(label: 'Drafts', value: draftCount, icon: Icons.edit_note_rounded),
              _ContentMetric(label: 'Notes', value: noteCount, icon: Icons.menu_book_rounded),
              _ContentMetric(label: 'PDFs', value: pdfCount, icon: Icons.picture_as_pdf_rounded),
              _ContentMetric(label: 'Videos', value: videoCount, icon: Icons.play_circle_rounded),
            ]),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('student_resource_progress').snapshots(),
              builder: (context, progressSnapshot) {
                if (!progressSnapshot.hasData || progressSnapshot.hasError) {
                  return const SizedBox.shrink();
                }
                final records = progressSnapshot.data!.docs;
                final learners = records.map((doc) =>
                  (doc.data()['userId'] ?? '').toString())
                  .where((id) => id.isNotEmpty).toSet().length;
                final completed = records.where((doc) =>
                  ((doc.data()['progressPercent'] as num?)?.toDouble() ?? 0) >= 100).length;
                final reading = records.where((doc) {
                  final percent = (doc.data()['progressPercent'] as num?)?.toDouble() ?? 0;
                  return percent > 0 && percent < 100;
                }).length;
                final bookmarks = records.where((doc) =>
                  doc.data()['isBookmarked'] == true).length;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(bottom: 9),
                    child: Text('Student engagement', style: TextStyle(
                      color: AtlasColors.navy, fontSize: 14, fontWeight: FontWeight.w900))),
                  Wrap(spacing: 9, runSpacing: 9, children: [
                    _ContentMetric(label: 'Learners', value: learners, icon: Icons.people_alt_rounded),
                    _ContentMetric(label: 'Reading', value: reading, icon: Icons.menu_book_rounded),
                    _ContentMetric(label: 'Completed', value: completed, icon: Icons.task_alt_rounded),
                    _ContentMetric(label: 'Bookmarks', value: bookmarks, icon: Icons.bookmark_rounded),
                  ]),
                ]);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search content by title, subject or system...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty ? null : IconButton(
                  onPressed: () { _search.clear(); setState(() {}); },
                  icon: const Icon(Icons.close_rounded)),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'All', label: Text('All')),
                ButtonSegment(value: 'Published', label: Text('Published')),
                ButtonSegment(value: 'Drafts', label: Text('Drafts')),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (values) => setState(() => _statusFilter = values.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty) Padding(
              padding: const EdgeInsets.all(20),
              child: Text(allDocs.isEmpty ? 'No content yet. Tap Create Content.' :
                'No content matches this search or filter.')),
            ...docs.map((doc) {
            final item = LearningResourceModel.fromFirestore(doc);
            final label = switch (item.type) {
              LearningResourceType.text => 'NOTE',
              LearningResourceType.pdf => 'PDF',
              LearningResourceType.video => 'VIDEO',
              _ => item.type.name.toUpperCase(),
            };
            final icon = switch (item.type) {
              LearningResourceType.text => Icons.notes_rounded,
              LearningResourceType.pdf => Icons.picture_as_pdf_rounded,
              LearningResourceType.video => Icons.play_circle_rounded,
              _ => Icons.description_rounded,
            };
            return Card(color: Colors.white, margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFE5F1FF),
                  child: Icon(icon, color: AtlasColors.royalBlue)),
                title: Text(item.title, style: const TextStyle(color: AtlasColors.navy,
                  fontWeight: FontWeight.w800)),
                subtitle: Text('$label • ${item.isPublished ? 'Published' : 'Unpublished'}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'publish') _toggle(context, doc.id, item.isPublished);
                    if (v == 'edit' && item.type == LearningResourceType.text) _edit(context, doc.id);
                    if (v == 'delete') _delete(context, doc.id);
                  },
                  itemBuilder: (_) => [
                    if (item.type == LearningResourceType.text)
                      const PopupMenuItem(value: 'edit', child: Text('Edit chapter')),
                    PopupMenuItem(value: 'publish',
                      child: Text(item.isPublished ? 'Unpublish' : 'Publish')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ]),
              ));
          }),
          ]);
        },
      ),
    ]),
  );
}

class _ContentMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _ContentMetric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: 142, padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFDCE7F1))),
    child: Row(children: [
      Icon(icon, color: AtlasColors.royalBlue, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value', style: const TextStyle(color: AtlasColors.navy,
          fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 10)),
      ])),
    ]),
  );
}

