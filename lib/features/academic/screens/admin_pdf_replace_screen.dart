import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../admin/services/admin_access_service.dart';

class AdminPdfReplaceScreen extends StatefulWidget {
  final String resourceId;
  final String title;
  const AdminPdfReplaceScreen({super.key, required this.resourceId, required this.title});
  @override
  State<AdminPdfReplaceScreen> createState() => _AdminPdfReplaceScreenState();
}

class _AdminPdfReplaceScreenState extends State<AdminPdfReplaceScreen> {
  PlatformFile? _file;
  bool _saving = false;
  double _progress = 0;

  Future<void> _choosePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null || file.bytes!.isEmpty || file.size > 200 * 1024 * 1024) {
      _message('Choose a readable PDF smaller than 200 MB.'); return;
    }
    if (String.fromCharCodes(file.bytes!.take(5)) != '%PDF-') {
      _message('The selected file is not a valid PDF.'); return;
    }
    setState(() => _file = file);
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _replace() async {
    if (_file == null || _saving) return;
    final allowed = await AdminAccessService.isAdmin(refreshToken: true);
    if (!allowed) { _message('Administrator access is required.'); return; }
    setState(() { _saving = true; _progress = 0; });
    try {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('learning_resources').doc(widget.resourceId);
      final snap = await ref.get();
      if (!snap.exists) throw StateError('This PDF resource no longer exists.');
      final current = snap.data() ?? <String, dynamic>{};
      if ((current['type'] ?? '').toString() != 'pdf') {
        throw StateError('This item is not a PDF resource.');
      }
      final oldVersion = (current['versionNumber'] as num?)?.toInt() ?? 0;
      final nextVersion = oldVersion + 1;
      final archiveVersion = oldVersion > 0 ? oldVersion : 1;
      final archived = Map<String, dynamic>.from(current)
        ..remove('createdAt')..remove('updatedAt');
      await ref.collection('versions').doc('v$archiveVersion').set({
        ...archived,
        'versionNumber': archiveVersion,
        'savedAt': FieldValue.serverTimestamp(),
        'changeNote': oldVersion > 0 ? 'Archived before PDF replacement' : 'Original PDF archived',
      });

      final selected = _file!;
      final safeName = selected.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final storageRef = FirebaseStorage.instance.ref().child(
        'learning_resources/pdf_revisions/${widget.resourceId}/v${nextVersion}_${DateTime.now().millisecondsSinceEpoch}_$safeName');
      final task = storageRef.putData(selected.bytes!,
        SettableMetadata(contentType: 'application/pdf',
          customMetadata: {'originalName': selected.name, 'resourceId': widget.resourceId,
            'versionNumber': '$nextVersion'}));
      task.snapshotEvents.listen((snapshot) {
        if (mounted && snapshot.totalBytes > 0) {
          setState(() => _progress = snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
      await task;
      final url = await storageRef.getDownloadURL();
      await ref.update({
        'resourceUrl': url,
        'versionNumber': nextVersion,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastRevisionNote': 'PDF file replaced',
      });
      if (!mounted) return;
      _message('PDF replaced successfully. Version $nextVersion is now published.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      _message('Could not replace PDF: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    appBar: AppBar(title: const Text('Replace PDF'),
      backgroundColor: Colors.white, foregroundColor: const Color(0xFF102B49)),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.picture_as_pdf_rounded, size: 34, color: Color(0xFF2467A3)),
          const SizedBox(height: 12),
          Text(widget.title, style: const TextStyle(fontSize: 19,
            fontWeight: FontWeight.w900, color: Color(0xFF102B49))),
          const SizedBox(height: 8),
          const Text('Replace the file while keeping the same resource identity. The previous published PDF is archived in Version History.',
            style: TextStyle(height: 1.5, color: Color(0xFF5E7185))),
        ])),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: _saving ? null : _choosePdf,
        icon: const Icon(Icons.upload_file_rounded),
        label: Text(_file?.name ?? 'Choose revised PDF')),
      if (_saving) ...[
        const SizedBox(height: 14),
        LinearProgressIndicator(value: _progress > 0 ? _progress : null),
        const SizedBox(height: 6),
        Text('Uploading PDF • ${(_progress * 100).round()}%'),
      ],
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: _saving || _file == null ? null : _replace,
        icon: _saving ? const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.published_with_changes_rounded),
        label: Text(_saving ? 'Replacing...' : 'Publish revised PDF')),
    ]),
  );
}
