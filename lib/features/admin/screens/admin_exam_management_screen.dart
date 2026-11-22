import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../mcqs/screens/student_mcq_practice_screen.dart';
import 'admin_mcq_import_screen.dart';

class AdminExamManagementScreen extends StatefulWidget {
  final String? sectionType;
  const AdminExamManagementScreen({super.key, this.sectionType});
  @override
  State<AdminExamManagementScreen> createState() => _AdminExamManagementScreenState();
}

class _AdminExamManagementScreenState extends State<AdminExamManagementScreen> {
  final db = FirebaseFirestore.instance;
  static const types = <String, String>{
    'subject_exam': 'Subject-Wise Exam',
    'system_exam': 'System-Wise Exam',
    'subject_mock': 'Subject Mock',
    'system_mock': 'System Mock',
    'grand_mock': 'Grand Mock',
  };

  Future<void> _addCategory(String type) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text('Add ${type == 'subject' ? 'subject' : 'system'}'),
      content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: type == 'subject' ? 'Subject name' : 'System name')),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))],
    ));
    final name = controller.text.trim();
    controller.dispose();
    if (ok != true || name.isEmpty) return;
    await db.collection('exam_categories').add({'name': name, 'categoryType': type, 'isActive': true, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _createExam() async {
    String type = widget.sectionType == 'mocks' ? 'subject_mock' : (widget.sectionType ?? 'subject_exam');
    String categoryId = '';
    String categoryName = '';
    final title = TextEditingController();
    final duration = TextEditingController(text: '60');
    final description = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('Create examination'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (widget.sectionType == null || widget.sectionType == 'mocks')
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Examination type'), items: types.entries.where((e) => widget.sectionType != 'mocks' || e.key.endsWith('_mock')).map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) { if (v != null) setDialogState(() { type = v; categoryId = ''; categoryName = ''; }); })
        else
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Align(alignment: Alignment.centerLeft, child: Text(types[type] ?? 'Examination', style: const TextStyle(fontWeight: FontWeight.w800)))),
        if (type != 'grand_mock') StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: db.collection('exam_categories').where('categoryType', isEqualTo: type.startsWith('subject') ? 'subject' : 'system').snapshots(), builder: (c, s) {
          if (!s.hasData) return const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator());
          final docs = s.data!.docs.where((d) => d.data()['isActive'] != false).toList();
          return DropdownButtonFormField<String>(value: docs.any((d) => d.id == categoryId) ? categoryId : null, decoration: const InputDecoration(labelText: 'Subject / system'), items: docs.map((d) => DropdownMenuItem(value: d.id, child: Text((d.data()['name'] ?? '').toString()))).toList(), onChanged: (v) { final matches = docs.where((x) => x.id == v); final d = matches.isEmpty ? null : matches.first; setDialogState(() { categoryId = v ?? ''; categoryName = (d?.data()['name'] ?? '').toString(); }); });
        }),
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Exam name (e.g. Exam 1)')),
        TextField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration in minutes')),
        TextField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: 'Instructions (optional)')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Create'))],
    )));
    if (ok != true) { title.dispose(); duration.dispose(); description.dispose(); return; }
    if (title.text.trim().isEmpty || (type != 'grand_mock' && categoryId.isEmpty)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an exam name and select its subject or system.')));
      title.dispose(); duration.dispose(); description.dispose(); return;
    }
    final minutes = int.tryParse(duration.text.trim()) ?? 60;
    final ref = db.collection('mcq_exam_sets').doc();
    final subjectId = categoryId.isEmpty ? 'grand_mock' : categoryId;
    final subjectName = categoryName.isEmpty ? 'Grand Mock' : categoryName;
    await ref.set({
      'name': title.text.trim(), 'description': description.text.trim(),
      'trackType': 'structured',
      'subjectId': subjectId, 'subjectName': subjectName,
      'examSetId': ref.id, 'examSetName': title.text.trim(),
      'examCategory': type, 'categoryId': categoryId, 'categoryName': categoryName,
      'durationMinutes': minutes.clamp(1, 300), 'isActive': true, 'isPublished': false,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    });
    title.dispose(); duration.dispose(); description.dispose();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam created. Import its MCQs, then publish it.')));
  }

  Future<void> _editExam(String id, Map<String, dynamic> data) async {
    final title = TextEditingController(text: (data['name'] ?? '').toString());
    final duration = TextEditingController(text: (data['durationMinutes'] ?? 60).toString());
    final description = TextEditingController(text: (data['description'] ?? '').toString());
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Edit examination'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Exam name')),
        TextField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration in minutes')),
        TextField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: 'Instructions')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))],
    ));
    if (ok == true && title.text.trim().isNotEmpty) {
      await db.collection('mcq_exam_sets').doc(id).update({'name': title.text.trim(), 'examSetName': title.text.trim(), 'durationMinutes': (int.tryParse(duration.text.trim()) ?? 60).clamp(1, 300), 'description': description.text.trim(), 'updatedAt': FieldValue.serverTimestamp()});
    }
    title.dispose(); duration.dispose(); description.dispose();
  }

  Future<void> _togglePublished(String id, bool published) async {
    final questions = await db.collection('mcqs').where('examSetId', isEqualTo: id).get();
    if (!published && questions.docs.isEmpty) throw Exception('Import questions into this exam before publishing it.');
    for (var start = 0; start < questions.docs.length; start += 450) {
      final batch = db.batch();
      final end = (start + 450 < questions.docs.length) ? start + 450 : questions.docs.length;
      for (var i = start; i < end; i++) {
        batch.update(questions.docs[i].reference, {'isPublished': !published, 'updatedAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }
    await db.collection('mcq_exam_sets').doc(id).update({'isPublished': !published, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Widget _categoryPanel(String type, String title, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE0EAF5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: AtlasColors.royalBlue), const SizedBox(width: 9), Expanded(child: Text(title, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900))), TextButton.icon(onPressed: () => _addCategory(type), icon: const Icon(Icons.add), label: const Text('Add'))]),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: db.collection('exam_categories').where('categoryType', isEqualTo: type).snapshots(), builder: (c, s) {
        if (s.hasError) return const Text('Unable to load categories. Check Firestore rules.');
        if (!s.hasData) return const LinearProgressIndicator();
        if (s.data!.docs.isEmpty) return Text('No ${type}s added yet.', style: const TextStyle(color: AtlasColors.secondaryText));
        return Wrap(spacing: 8, runSpacing: 8, children: s.data!.docs.map((d) => Chip(label: Text((d.data()['name'] ?? '').toString()), deleteIcon: Icon(d.data()['isActive'] == false ? Icons.visibility_off : Icons.check_circle_outline), onDeleted: () => d.reference.update({'isActive': d.data()['isActive'] != false ? false : true, 'updatedAt': FieldValue.serverTimestamp()}))).toList());
      }),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F7FF),
    appBar: AppBar(title: Text(widget.sectionType == null ? 'Examination Management' : widget.sectionType == 'mocks' ? 'Mock Exams Management' : (types[widget.sectionType] ?? 'Exam Management'))),
    floatingActionButton: FloatingActionButton.extended(onPressed: _createExam, icon: const Icon(Icons.add), label: const Text('Create exam')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(19), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AtlasColors.navy, AtlasColors.royalBlue]), borderRadius: BorderRadius.circular(20)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.account_tree_rounded, color: AtlasColors.royalBlue, size: 30), SizedBox(height: 10),
        Text('Examination Control Centre', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        SizedBox(height: 6), Text('Manage subjects, systems, subject and system mocks, and grand mocks in one organized workspace.', style: TextStyle(color: Colors.white70, height: 1.5)),
      ])),
      const SizedBox(height: 14),
      if (widget.sectionType == null || widget.sectionType == 'subject_exam' || widget.sectionType == 'subject_mock' || widget.sectionType == 'mocks')
        _categoryPanel('subject', 'Subject categories', Icons.menu_book_rounded),
      if (widget.sectionType == null || widget.sectionType == 'system_exam' || widget.sectionType == 'system_mock' || widget.sectionType == 'mocks')
        _categoryPanel('system', 'System categories', Icons.account_tree_rounded),
      FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMcqImportScreen())), icon: const Icon(Icons.upload_file_rounded), label: const Text('Import MCQs')),
      const SizedBox(height: 14),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: db.collection('mcq_exam_sets').snapshots(), builder: (c, s) {
        if (s.hasError) return Text('Unable to load exams: ${s.error}');
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final visibleDocs = s.data!.docs.where((d) {
          final data = d.data();
          final structured = data['trackType'] == 'structured';
          return structured && (widget.sectionType == null || (widget.sectionType == 'mocks' ? (data['examCategory'] ?? '').toString().endsWith('_mock') : data['examCategory'] == widget.sectionType));
        }).toList();
        if (visibleDocs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No exams in this section yet. Create your first exam.')));
        return Column(children: visibleDocs.map((d) {
          final x = d.data(); final published = x['isPublished'] == true;
          return Card(color: Colors.white, child: ListTile(
            title: Text((x['name'] ?? 'Exam').toString(), style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
            subtitle: Text('${types[x['examCategory']] ?? 'Examination'} • ${x['categoryName'] ?? 'Grand Mock'} • ${published ? 'Published' : 'Draft'}', style: const TextStyle(color: AtlasColors.secondaryText)),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(onSelected: (v) async {
              try {
                if (v == 'edit') await _editExam(d.id, x);
                if (v == 'import') await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMcqImportScreen()));
                if (v == 'publish') await _togglePublished(d.id, published);
                if (v == 'preview') await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentMcqPracticeScreen(examSetId: d.id)));
                if (v == 'delete') { await d.reference.update({'isActive': false, 'isPublished': false, 'archivedAt': FieldValue.serverTimestamp()}); }
              } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
            }, itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit exam')),
              const PopupMenuItem(value: 'import', child: Text('Import MCQs')),
              PopupMenuItem(value: 'publish', child: Text(published ? 'Unpublish' : 'Publish')),
              const PopupMenuItem(value: 'preview', child: Text('Preview exam')),
              const PopupMenuItem(value: 'delete', child: Text('Archive (preserve data)')),
            ]),
          ));
        }).toList());
      }),
      const SizedBox(height: 80),
    ]),
  );
}
