import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/learning_resource_service.dart';
import '../services/learning_resource_file_service.dart';
import '../services/learning_resource_image_service.dart';
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
  final _subjectName = TextEditingController();
  final _systemName = TextEditingController();
  final _topicName = TextEditingController();
  LearningResourceType _type = LearningResourceType.pdf;
  PlatformFile? _file;
  PlatformFile? _coverFile;
  bool _free = false;
  bool _saving = false;
  double _progress = 0;

  @override
  void dispose() {
    _title.dispose(); _description.dispose(); _text.dispose();
    _subjectName.dispose(); _systemName.dispose(); _topicName.dispose();
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
    if (file.size > 100 * 1024 * 1024) {
      _message('The selected file is larger than 100 MB. Please compress it before uploading.');
      return;
    }
    setState(() => _file = file);
  }

  Future<void> _chooseCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null || file.bytes!.isEmpty || file.size > 8 * 1024 * 1024) {
      _message('Choose a readable cover image smaller than 8 MB.');
      return;
    }
    setState(() => _coverFile = file);
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
      var thumbnailUrl = '';
      var textContent = _text.text.trim();
      if (_type != LearningResourceType.text) {
        final file = _file!;
        downloadUrl = await LearningResourceFileService.upload(
          bytes: file.bytes!,
          fileName: file.name,
          resourceType: _type == LearningResourceType.pdf ? 'raw' : 'video',
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
        );
      }
      if (_coverFile != null) {
        final cover = _coverFile!;
        thumbnailUrl = await LearningResourceImageService.uploadChapterImage(
          bytes: cover.bytes!,
          fileName: cover.name,
        );
      }
      await LearningResourceService.createResource(
        yearId: widget.yearId,
        subjectId: widget.subjectId,
        topicId: widget.topicId,
        subjectName: _subjectName.text.trim(),
        topicName: _topicName.text.trim(),
        systemName: _systemName.text.trim(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        type: _type,
        resourceUrl: downloadUrl,
        textContent: textContent,
        thumbnailUrl: thumbnailUrl.isEmpty ? null : thumbnailUrl,
        isFree: _free,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      _message('Could not publish this resource: $error');
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
            TextFormField(controller: _subjectName,
              decoration: const InputDecoration(labelText: 'Subject (e.g. Anatomy)'),),
            const SizedBox(height: 10),
            TextFormField(controller: _systemName,
              decoration: const InputDecoration(labelText: 'Organ system (e.g. Cardiovascular)'),),
            const SizedBox(height: 10),
            TextFormField(controller: _topicName,
              decoration: const InputDecoration(labelText: 'Topic (optional)'),),
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
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _chooseCover,
              icon: const Icon(Icons.image_outlined),
              label: Text(_coverFile == null ? 'Add cover / thumbnail (optional)' : _coverFile!.name),
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
