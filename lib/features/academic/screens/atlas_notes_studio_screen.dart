import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/atlas_academy_app.dart';
import '../../admin/services/admin_access_service.dart';
import '../services/learning_resource_version_service.dart';

class AtlasNotesStudioScreen extends StatefulWidget {
  final String? resourceId;
  const AtlasNotesStudioScreen({super.key, this.resourceId});

  @override
  State<AtlasNotesStudioScreen> createState() => _AtlasNotesStudioScreenState();
}

class _AtlasNotesStudioScreenState extends State<AtlasNotesStudioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _system = TextEditingController();
  final _topic = TextEditingController();
  final _picker = ImagePicker();
  final List<_NoteBlock> _blocks = [];
  String? _subjectId;
  String? _subjectName;
  String? _selectedSystem;
  bool _free = false;
  bool _saving = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _editingId = widget.resourceId;
    if (_editingId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('learning_resources').doc(_editingId).get();
      if (!doc.exists || !mounted) return;
      final data = doc.data() ?? {};
      _title.text = (data['title'] ?? '').toString();
      _description.text = (data['description'] ?? '').toString();
      _subjectId = (data['subjectId'] ?? '').toString();
      _subjectName = (data['subjectName'] ?? '').toString();
      _selectedSystem = (data['systemName'] ?? '').toString();
      _system.text = _selectedSystem ?? '';
      _topic.text = (data['topicName'] ?? '').toString();
      _free = data['isFree'] == true;
      final savedBlocks = data['contentBlocks'];
      if (savedBlocks is List && savedBlocks.isNotEmpty) {
        for (final raw in savedBlocks.whereType<Map>()) {
          final block = _NoteBlock(type: (raw['type'] ?? 'paragraph').toString());
          block.text.text = (raw['text'] ?? '').toString();
          block.caption.text = (raw['caption'] ?? '').toString();
          block.imageUrl = (raw['imageUrl'] ?? '').toString();
          _blocks.add(block);
        }
      } else if ((data['textContent'] ?? '').toString().trim().isNotEmpty) {
        final legacyBlock = _NoteBlock(type: 'paragraph');
        legacyBlock.text.text = (data['textContent'] ?? '').toString();
        _blocks.add(legacyBlock);
      }
      setState(() {});
    } catch (e) {
      _message('Could not load this chapter for editing: $e');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _system.dispose();
    _topic.dispose();
    for (final block in _blocks) {
      block.dispose();
    }
    super.dispose();
  }

  void _addBlock(String type) {
    setState(() => _blocks.add(_NoteBlock(type: type)));
  }

  Future<void> _chooseImage(_NoteBlock block) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 2200,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 12 * 1024 * 1024) {
        _message('Please choose an image smaller than 12 MB.');
        return;
      }
      setState(() {
        block.pendingImage = bytes;
        block.pendingName = file.name;
      });
    } catch (e) {
      _message('Could not select image: $e');
    }
  }

  Future<String> _uploadImage(_NoteBlock block, int index) async {
    if (block.pendingImage == null) return block.imageUrl;
    final ref = FirebaseStorage.instance.ref().child(
      'atlas_notes/${DateTime.now().millisecondsSinceEpoch}_${index}_${block.pendingName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}',
    );
    final task = ref.putData(
      block.pendingImage!,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    await task;
    block.imageUrl = await ref.getDownloadURL();
    block.pendingImage = null;
    return block.imageUrl;
  }

  Future<void> _save({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_blocks.isEmpty) {
      _message('Add at least one content block before saving.');
      return;
    }
    final allowed = await AdminAccessService.isAdmin(refreshToken: true);
    if (!allowed) {
      _message('Administrator access is required.');
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final blocks = <Map<String, dynamic>>[];
      for (var i = 0; i < _blocks.length; i++) {
        final block = _blocks[i];
        if (block.type == 'image') await _uploadImage(block, i);
        blocks.add(block.toMap(order: i));
      }
      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'type': 'text',
        'resourceUrl': '',
        'textContent': '',
        'contentFormat': 'atlas_blocks_v1',
        'contentBlocks': blocks,
        'subjectId': _subjectId ?? '',
        'subjectName': _subjectName ?? '',
        'systemName': _system.text.trim(),
        'topicName': _topic.text.trim(),
        'yearId': '',
        'topicId': '',
        'isFree': _free,
        'isPublished': publish,
        'readingMinutes': _estimateMinutes(),
        'displayOrder': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final isNew = _editingId == null;
      final resourceId = _editingId ?? FirebaseFirestore.instance.collection('learning_resources').doc().id;
      await LearningResourceVersionService.save(resourceId: resourceId, content: data,
        publish: publish, isNew: isNew);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(publish ? 'Chapter published successfully.' : 'Draft saved successfully.'),
      ));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _message('Could not save chapter: $e');
      }
    }
  }

  int _estimateMinutes() {
    final words = _blocks.fold<int>(0, (total, block) =>
      total + block.text.text.trim().split(RegExp(r'\s+')).where((v) => v.isNotEmpty).length);
    return (words / 180).ceil().clamp(1, 999);
  }

  void _preview() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _AtlasNotePreview(
        title: _title.text.trim().isEmpty ? 'Untitled chapter' : _title.text.trim(),
        subject: _subjectName ?? 'Medical Notes',
        system: _system.text.trim(),
        blocks: _blocks.map((b) => b.toMap(order: 0, includePending: true)).toList(),
      ),
    ));
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F6FA),
    appBar: AppBar(
      title: const Text('Atlas Notes Studio'),
      backgroundColor: const Color(0xFFF3F6FA),
      foregroundColor: AtlasColors.navy,
      actions: [
        TextButton.icon(
          onPressed: _saving ? null : _preview,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Preview'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102B49), Color(0xFF24679B)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ATLAS ACADEMY • PUBLISHING WORKSPACE',
                style: TextStyle(color: Color(0xFFBBDCF4), fontSize: 10,
                  fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              SizedBox(height: 8),
              Text('Create a textbook chapter',
                style: TextStyle(color: Colors.white, fontSize: 21,
                  fontWeight: FontWeight.w900)),
              SizedBox(height: 5),
              Text('Build your chapter with structured blocks, illustrations and clinical learning points.',
                style: TextStyle(color: Colors.white70, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 18),
          _sectionCard('CHAPTER DETAILS', Icons.menu_book_rounded, [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Chapter title *',
                hintText: 'e.g. Anatomy of the Heart',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Chapter title is required.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Short introduction',
                hintText: 'A brief description shown in the student library.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('academic_subjects').snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  value: docs.any((d) => d.id == _subjectId) ? _subjectId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    border: OutlineInputBorder(),
                  ),
                  items: docs.map((doc) => DropdownMenuItem(
                    value: doc.id,
                    child: Text((doc.data()['name'] ?? 'Unnamed subject').toString(),
                      overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: _saving ? null : (value) {
                    final selected = docs.where((d) => d.id == value);
                    setState(() {
                      _subjectId = value;
                      _subjectName = selected.isEmpty ? null :
                        (selected.first.data()['name'] ?? '').toString();
                    });
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Select a subject.' : null,
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSystem,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Organ system *',
                helperText: 'Choose the system used to organize this chapter and its medical artwork.',
                border: OutlineInputBorder(),
              ),
              items: const [
                'Cardiovascular System',
                'Respiratory System',
                'Nervous System',
                'Gastrointestinal System',
                'Renal and Urinary System',
                'Musculoskeletal System',
                'Endocrine System',
                'Reproductive System',
                'Hematology',
                'Integumentary System',
                'Immune and Lymphatic System',
                'General Medicine',
                'General Anatomy',
                'Other / Multisystem',
              ].map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
              onChanged: _saving ? null : (value) => setState(() {
                _selectedSystem = value;
                _system.text = value ?? '';
              }),
              validator: (value) => value == null || value.isEmpty
                ? 'Select an organ system.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _topic,
              decoration: const InputDecoration(
                labelText: 'Topic / subtopic (optional)',
                hintText: 'e.g. Heart chambers',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Free chapter'),
              value: _free,
              onChanged: _saving ? null : (v) => setState(() => _free = v),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Text('CHAPTER CONTENT',
              style: TextStyle(color: AtlasColors.navy, fontSize: 13,
                fontWeight: FontWeight.w900, letterSpacing: .8))),
            Text('${_blocks.length} blocks', style: const TextStyle(
              color: AtlasColors.secondaryText, fontSize: 11,
              fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          if (_blocks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE6F0))),
              child: const Column(children: [
                Icon(Icons.post_add_rounded, size: 38, color: AtlasColors.royalBlue),
                SizedBox(height: 8),
                Text('Your chapter starts here',
                  style: TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Add headings, paragraphs, illustrations and clinical learning boxes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AtlasColors.secondaryText, height: 1.4)),
              ]),
            ),
          for (var i = 0; i < _blocks.length; i++)
            _blockCard(i),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _showAddBlockSheet,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Add content block'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AtlasColors.royalBlue,
              side: const BorderSide(color: AtlasColors.royalBlue),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: const BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2EAF2)))),
        child: Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: _saving ? null : () => _save(publish: false),
            child: const Text('Save Draft'),
          )),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: FilledButton.icon(
            onPressed: _saving ? null : () => _save(publish: true),
            icon: _saving ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.publish_rounded),
            label: Text(_saving ? 'Saving...' : 'Publish Chapter'),
          )),
        ]),
      ),
    ),
  );

  Widget _sectionCard(String title, IconData icon, List<Widget> children) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E9F2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AtlasColors.royalBlue, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AtlasColors.navy,
            fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: .6)),
        ]),
        const SizedBox(height: 14),
        ...children,
      ]),
    );

  Widget _blockCard(int index) {
    final block = _blocks[index];
    final label = _NoteBlock.labels[block.type] ?? block.type;
    return Container(
      key: ValueKey(block.id),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDCE6F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 30, height: 30,
            decoration: BoxDecoration(color: const Color(0xFFEAF3FC),
              borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text('${index + 1}', style: const TextStyle(
              color: AtlasColors.royalBlue, fontWeight: FontWeight.w900)))),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: const TextStyle(
            color: AtlasColors.navy, fontWeight: FontWeight.w900))),
          IconButton(
            tooltip: 'Move up',
            visualDensity: VisualDensity.compact,
            onPressed: index == 0 || _saving ? null : () => setState(() {
              final item = _blocks.removeAt(index);
              _blocks.insert(index - 1, item);
            }),
            icon: const Icon(Icons.keyboard_arrow_up_rounded)),
          IconButton(
            tooltip: 'Move down',
            visualDensity: VisualDensity.compact,
            onPressed: index == _blocks.length - 1 || _saving ? null : () => setState(() {
              final item = _blocks.removeAt(index);
              _blocks.insert(index + 1, item);
            }),
            icon: const Icon(Icons.keyboard_arrow_down_rounded)),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'duplicate') {
                setState(() => _blocks.insert(index + 1, block.copy()));
              } else if (value == 'delete') {
                setState(() => _blocks.removeAt(index).dispose());
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'duplicate', child: Text('Duplicate block')),
              PopupMenuItem(value: 'delete', child: Text('Delete block')),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        if (block.type == 'image') ...[
          if (block.pendingImage != null)
            ClipRRect(borderRadius: BorderRadius.circular(12),
              child: Image.memory(block.pendingImage!, height: 170,
                width: double.infinity, fit: BoxFit.contain))
          else if (block.imageUrl.isNotEmpty)
            ClipRRect(borderRadius: BorderRadius.circular(12),
              child: Image.network(block.imageUrl, height: 170,
                width: double.infinity, fit: BoxFit.contain)),
          OutlinedButton.icon(
            onPressed: _saving ? null : () => _chooseImage(block),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(block.imageUrl.isEmpty && block.pendingImage == null
              ? 'Choose medical image' : 'Replace image'),
          ),
          TextField(
            controller: block.caption,
            decoration: const InputDecoration(
              labelText: 'Figure caption (optional)',
              hintText: 'Figure 1. Structure of the human heart.',
            ),
          ),
        ] else
          TextField(
            controller: block.text,
            minLines: block.type == 'paragraph' ? 3 : 2,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: _NoteBlock.hints[block.type] ?? 'Content',
              hintText: _NoteBlock.placeholders[block.type] ?? 'Enter content...',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
      ]),
    );
  }

  void _showAddBlockSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add a content block', style: TextStyle(
              color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: _NoteBlock.labels.entries.map((entry) =>
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _addBlock(entry.key);
                  },
                  icon: Icon(_NoteBlock.icons[entry.key], size: 18),
                  label: Text(entry.value, maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                )).toList(),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NoteBlock {
  final String id;
  final String type;
  final TextEditingController text;
  final TextEditingController caption;
  String imageUrl;
  Uint8List? pendingImage;
  String pendingName;

  _NoteBlock({required this.type})
    : id = DateTime.now().microsecondsSinceEpoch.toString(),
      text = TextEditingController(),
      caption = TextEditingController(),
      imageUrl = '',
      pendingName = 'medical_image.jpg';

  _NoteBlock copy() {
    final result = _NoteBlock(type: type);
    result.text.text = text.text;
    result.caption.text = caption.text;
    result.imageUrl = imageUrl;
    result.pendingImage = pendingImage;
    result.pendingName = pendingName;
    return result;
  }

  Map<String, dynamic> toMap({required int order, bool includePending = false}) => {
    'id': id,
    'type': type,
    'text': text.text.trim(),
    'imageUrl': imageUrl,
    'caption': caption.text.trim(),
    'order': order,
    if (includePending && pendingImage != null) 'pendingImage': pendingImage,
  };

  void dispose() {
    text.dispose();
    caption.dispose();
  }

  static const labels = <String, String>{
    'heading1': 'Heading 1',
    'heading2': 'Heading 2',
    'heading3': 'Heading 3',
    'paragraph': 'Paragraph',
    'bullet': 'Bullet list',
    'numbered': 'Numbered list',
    'image': 'Medical image',
    'highlight': 'Highlight box',
    'clinical': 'Clinical correlation',
    'pearl': 'Examination pearl',
    'definition': 'Definition',
    'warning': 'Warning box',
    'divider': 'Section divider',
    'table': 'Comparison table',
  };

  static const hints = <String, String>{
    'heading1': 'Main chapter heading',
    'heading2': 'Section heading',
    'heading3': 'Subsection heading',
    'paragraph': 'Paragraph text',
    'bullet': 'One point per line',
    'numbered': 'One step per line',
    'highlight': 'Important concept',
    'clinical': 'Clinical application',
    'pearl': 'High-yield examination point',
    'definition': 'Medical term and definition',
    'warning': 'Caution or common mistake',
    'table': 'Table rows (separate columns with |)',
  };

  static const placeholders = <String, String>{
    'heading1': 'Cardiovascular System',
    'heading2': 'Anatomy of the Heart',
    'heading3': 'Chambers of the Heart',
    'paragraph': 'Write your teaching explanation here...',
    'bullet': 'Four chambers\nFour major valves\nMyocardium',
    'numbered': 'Step one\nStep two\nStep three',
    'highlight': 'Important concept to remember...',
    'clinical': 'Explain the clinical relevance...',
    'pearl': 'High-yield fact for examinations...',
    'definition': 'Term — definition...',
    'warning': 'Common mistake or important caution...',
    'table': 'Structure | Feature\nMitral valve | Two cusps\nTricuspid valve | Three cusps',
  };

  static const icons = <String, IconData>{
    'heading1': Icons.title_rounded,
    'heading2': Icons.format_size_rounded,
    'heading3': Icons.short_text_rounded,
    'paragraph': Icons.notes_rounded,
    'bullet': Icons.format_list_bulleted_rounded,
    'numbered': Icons.format_list_numbered_rounded,
    'image': Icons.image_outlined,
    'highlight': Icons.lightbulb_outline_rounded,
    'clinical': Icons.medical_information_outlined,
    'pearl': Icons.school_outlined,
    'definition': Icons.bookmark_outline_rounded,
    'warning': Icons.warning_amber_rounded,
    'divider': Icons.horizontal_rule_rounded,
    'table': Icons.table_chart_outlined,
  };
}

class _AtlasNotePreview extends StatelessWidget {
  final String title;
  final String subject;
  final String system;
  final List<Map<String, dynamic>> blocks;
  const _AtlasNotePreview({required this.title, required this.subject,
    required this.system, required this.blocks});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    appBar: AppBar(title: const Text('Student Preview'),
      backgroundColor: Colors.white, foregroundColor: AtlasColors.navy),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('THE ATLAS ACADEMY • LEARNING RESOURCES',
              style: TextStyle(color: AtlasColors.royalBlue, fontSize: 10,
                letterSpacing: 1.1, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: AtlasColors.navy,
              fontSize: 25, fontWeight: FontWeight.w900, height: 1.2)),
            const SizedBox(height: 8),
            Text('$subject  •  ${system.isEmpty ? 'Medical Notes' : system}',
              style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 12),
        for (final block in blocks) _PreviewBlock(block: block),
      ],
    ),
  );
}

class _PreviewBlock extends StatelessWidget {
  final Map<String, dynamic> block;
  const _PreviewBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final type = (block['type'] ?? 'paragraph').toString();
    final text = (block['text'] ?? '').toString();
    final caption = (block['caption'] ?? '').toString();
    final imageUrl = (block['imageUrl'] ?? '').toString();
    if (type == 'divider') return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Color(0xFFDCE5EF), thickness: 1.2));
    if (type.startsWith('heading')) {
      final size = type == 'heading1' ? 25.0 : type == 'heading2' ? 20.0 : 17.0;
      return Padding(padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text, style: TextStyle(color: AtlasColors.navy,
          fontSize: size, fontWeight: FontWeight.w900)));
    }
    if (type == 'image') return Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block['pendingImage'] is Uint8List)
          ClipRRect(borderRadius: BorderRadius.circular(14),
            child: Image.memory(block['pendingImage'] as Uint8List))
        else if (imageUrl.isNotEmpty)
          ClipRRect(borderRadius: BorderRadius.circular(14),
            child: Image.network(imageUrl)),
        if (caption.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 7, bottom: 10),
          child: Text(caption, style: const TextStyle(
            color: AtlasColors.secondaryText, fontSize: 12, fontStyle: FontStyle.italic))),
      ]);
    if (['highlight', 'clinical', 'pearl', 'definition', 'warning'].contains(type)) {
      final title = _NoteBlock.labels[type] ?? 'Important';
      final color = type == 'warning' ? const Color(0xFFFFF0EA)
        : type == 'clinical' ? const Color(0xFFEAF5F4)
        : type == 'pearl' ? const Color(0xFFFFF7E5)
        : const Color(0xFFEAF2FC);
      final icon = _NoteBlock.icons[type] ?? Icons.info_outline;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AtlasColors.royalBlue),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AtlasColors.navy,
              fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(text, style: const TextStyle(color: AtlasColors.navy, height: 1.55)),
          ])),
        ]),
      );
    }
    if (type == 'bullet' || type == 'numbered') {
      final lines = text.split('\n').where((v) => v.trim().isNotEmpty).toList();
      return Padding(padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(lines.length, (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 24, child: Text(type == 'bullet' ? '•' : '${i + 1}.',
                style: const TextStyle(color: AtlasColors.royalBlue,
                  fontWeight: FontWeight.w900))),
              Expanded(child: Text(lines[i], style: const TextStyle(
                color: AtlasColors.navy, height: 1.55))),
            ]),
          ))));
    }
    if (type == 'table') {
      final rows = text.split('\n').where((v) => v.trim().isNotEmpty)
        .map((row) => row.split('|').map((v) => v.trim()).toList()).toList();
      if (rows.isEmpty) return const SizedBox.shrink();
      return SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFEAF2FC)),
          columns: rows.first.map((v) => DataColumn(label: Text(v,
            style: const TextStyle(fontWeight: FontWeight.w900)))).toList(),
          rows: rows.skip(1).map((row) => DataRow(cells: List.generate(
            rows.first.length, (i) => DataCell(Text(i < row.length ? row[i] : ''))))).toList(),
        ));
    }
    if (type == 'definition') return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(color: AtlasColors.navy,
        fontSize: 15, height: 1.65)));
    return Padding(padding: const EdgeInsets.symmetric(vertical: 7),
      child: Text(text, style: const TextStyle(
        color: AtlasColors.navy, fontSize: 15, height: 1.75)));
  }
}
