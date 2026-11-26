import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../services/learning_resource_service.dart';
import '../models/learning_resource_model.dart';

class LearningResourceUploadDialog extends StatefulWidget {
  final String yearId;
  final String subjectId;
  final String topicId;
  const LearningResourceUploadDialog({
    super.key, this.yearId = '', this.subjectId = '', this.topicId = '',
  });

  @override
  State<LearningResourceUploadDialog> createState() => _LearningResourceUploadDialogState();
}

class _LearningResourceUploadDialogState extends State<LearningResourceUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _text = TextEditingController();
  LearningResourceType _type = LearningResourceType.pdf;
  PlatformFile? _file;
  bool _free = false;
  bool _saving = false;
  double _progress = 0;

  @override
  void dispose() {
    _title.dispose(); _description.dispose(); _text.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    final extensions = _type == LearningResourceType.pdf ? ['pdf']
      : _type == LearningResourceType.video ? ['mp4', 'mov', 'm4v', 'webm']
      : ['txt'];
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: extensions, withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null || file.bytes!.isEmpty) {
      _message('Could not read the selected file. Please select it again.');
      return;
    }
    if (file.size > 200 * 1024 * 1024) {
      _message('The selected file is larger than 200 MB.');
      return;
    }
    setState(() => _file = file);
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type != LearningResourceType.text && _file == null) {
      _message('Choose a file before saving.');
      return;
    }
    if (_type == LearningResourceType.text && utf8.encode(_text.text.trim()).length > 700000) {
      _message('Text notes must be shorter than 700,000 characters.');
      return;
    }
    if (_type == LearningResourceType.text && _text.text.trim().isEmpty) {
      _message('Write the note content first.');
      return;
    }
    setState(() { _saving = true; _progress = 0; });
    try {
      var downloadUrl = '';
      var textContent = _text.text.trim();
      if (_type != LearningResourceType.text) {
        final file = _file!;
        final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        final storageRef = FirebaseStorage.instance.ref().child(
          'learning_resources/general/general/general/${DateTime.now().millisecondsSinceEpoch}_$safeName',
        );
        final extension = file.extension?.toLowerCase();
        final contentType = _type == LearningResourceType.pdf ? 'application/pdf'
          : extension == 'mov' ? 'video/quicktime'
          : extension == 'webm' ? 'video/webm' : 'video/mp4';
        final task = storageRef.putData(
          file.bytes!,
          SettableMetadata(contentType: contentType, customMetadata: {'originalName': file.name}),
        );
        task.snapshotEvents.listen((snapshot) {
          if (mounted && snapshot.totalBytes > 0) {
            setState(() => _progress = snapshot.bytesTransferred / snapshot.totalBytes);
          }
        });
        await task;
        downloadUrl = await storageRef.getDownloadURL();
      }
      await LearningResourceService.createResource(
        yearId: widget.yearId,
        subjectId: widget.subjectId,
        topicId: widget.topicId,
        title: _title.text.trim(),
        description: _description.text.trim(),
        type: _type,
        resourceUrl: downloadUrl,
        textContent: textContent,
        isFree: _free,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      _message('Upload failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Publish Learning Content'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LearningResourceType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Material type'),
              items: const [
                DropdownMenuItem(value: LearningResourceType.pdf, child: Text('PDF notes')),
                DropdownMenuItem(value: LearningResourceType.video, child: Text('Video lesson')),
              ],
              onChanged: _saving ? null : (v) => setState(() { _type = v!; _file = null; }),
            ),
            const SizedBox(height: 12),
            if (_type == LearningResourceType.text)
              TextFormField(
                controller: _text,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'Note content',
                  hintText: 'Write or paste the lesson notes here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _saving ? null : _chooseFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(_file == null ? (_type == LearningResourceType.pdf ? 'Choose PDF file' : 'Choose video file') : _file!.name),
              ),
            if (_saving && _type != LearningResourceType.text) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 4),
              Text('${(_progress * 100).round()}% uploaded'),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Free resource'),
              value: _free,
              onChanged: _saving ? null : (v) => setState(() => _free = v),
            ),
          ]),
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
      FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Publishing...' : 'Publish')),
    ],
  );
}
