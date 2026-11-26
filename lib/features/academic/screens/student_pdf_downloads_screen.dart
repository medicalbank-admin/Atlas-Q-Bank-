import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../models/learning_resource_model.dart';
import 'student_pdf_reader_screen.dart';
import '../services/pdf_offline_store.dart';

class StudentPdfDownloadsScreen extends StatefulWidget {
  const StudentPdfDownloadsScreen({super.key});
  @override
  State<StudentPdfDownloadsScreen> createState() => _StudentPdfDownloadsScreenState();
}
class _StudentPdfDownloadsScreenState extends State<StudentPdfDownloadsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final items = await listOfflinePdfs(); if (mounted) setState(() { _items = items; _loading = false; }); }
    catch (_) { if (mounted) setState(() => _loading = false); }
  }
  String _size(dynamic value) {
    final bytes = (value as num?)?.toInt() ?? 0;
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    appBar: AppBar(title: const Text('My PDF Downloads'),
      backgroundColor: Colors.white, foregroundColor: AtlasColors.navy,
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _items.isEmpty ? const Center(child: Text('No PDFs downloaded yet.'))
      : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index]; final id = (item['id'] ?? '').toString();
          return Card(color: Colors.white, child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE5F1FF),
              child: Icon(Icons.picture_as_pdf_rounded, color: AtlasColors.royalBlue)),
            title: Text((item['title'] ?? 'PDF document').toString(),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AtlasColors.navy)),
            subtitle: Text('${_size(item['sizeBytes'])} • Offline available'),
            onTap: () {
              final resource = LearningResourceModel(
                id: id, yearId: '', subjectId: '', topicId: '',
                subjectName: (item['subjectName'] ?? '').toString(),
                topicName: (item['topicName'] ?? '').toString(),
                title: (item['title'] ?? 'PDF document').toString(),
                description: '', type: LearningResourceType.pdf,
                resourceUrl: (item['resourceUrl'] ?? '').toString(),
                systemName: (item['systemName'] ?? '').toString(),
                versionNumber: (item['versionNumber'] as num?)?.toInt() ?? 0,
                isPublished: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
              );
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StudentPdfReaderScreen(resource: resource)));
            },
            trailing: IconButton(tooltip: 'Remove download',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                await removeOfflinePdf(id);
                if (mounted) { setState(() => _items.removeAt(index)); }
              }),
          ));
        }),
  );
}
