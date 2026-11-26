import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../models/learning_resource_model.dart';
import 'learning_resource_upload_dialog.dart';
import 'atlas_notes_studio_screen.dart';

class AdminLearningResourcesScreen extends StatelessWidget {
  const AdminLearningResourcesScreen({super.key});

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
          final docs = snapshot.data!.docs.toList()..sort((a, b) {
            final av = a.data()['createdAt']; final bv = b.data()['createdAt'];
            final ad = av is Timestamp ? av.toDate() : DateTime(2000);
            final bd = bv is Timestamp ? bv.toDate() : DateTime(2000);
            return bd.compareTo(ad);
          });
          if (docs.isEmpty) return const Padding(
            padding: EdgeInsets.all(20), child: Text('No content yet. Tap Publish Content.'));
          return Column(children: docs.map((doc) {
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
                    if (v == 'delete') _delete(context, doc.id);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'publish',
                      child: Text(item.isPublished ? 'Unpublish' : 'Publish')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ]),
              ));
          }).toList());
        },
      ),
    ]),
  );
}
