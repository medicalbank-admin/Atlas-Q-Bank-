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
    appBar: AppBar(title: const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('My Downloads', style: TextStyle(fontWeight: FontWeight.w900)),
      Text('OFFLINE PDF LIBRARY', style: TextStyle(fontSize: 9, letterSpacing: 1,
        color: AtlasColors.secondaryText, fontWeight: FontWeight.w800)),
    ]),
      backgroundColor: Colors.white, foregroundColor: AtlasColors.navy,
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _items.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 76, height: 76, decoration: BoxDecoration(
            color: const Color(0xFFE8F1FC), borderRadius: BorderRadius.circular(23)),
            child: const Icon(Icons.download_for_offline_rounded,
              size: 38, color: AtlasColors.royalBlue)),
          const SizedBox(height: 14),
          const Text('Your offline library is empty', style: TextStyle(
            color: AtlasColors.navy, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Download a PDF from the reader to access it without an internet connection.',
            textAlign: TextAlign.center, style: TextStyle(
              color: AtlasColors.secondaryText, height: 1.45)),
        ])))
      : ListView.builder(padding: const EdgeInsets.fromLTRB(15, 12, 15, 24), itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index]; final id = (item['id'] ?? '').toString();
          return Card(elevation: 0, color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17),
              side: const BorderSide(color: Color(0xFFE1EAF3))),
            child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE5F1FF),
              child: Icon(Icons.picture_as_pdf_rounded, color: AtlasColors.royalBlue)),
            title: Text((item['title'] ?? 'PDF document').toString(),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AtlasColors.navy)),
            subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text([
              if ((item['subjectName'] ?? '').toString().isNotEmpty) item['subjectName'].toString(),
              if ((item['systemName'] ?? '').toString().isNotEmpty) item['systemName'].toString(),
              _size(item['sizeBytes']), 'Available offline',
            ].join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis)),
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
