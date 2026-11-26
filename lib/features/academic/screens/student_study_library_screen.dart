import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/medical_category_artwork.dart';
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
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    appBar: AppBar(
      title: const Text('Learning Resources'),
      backgroundColor: const Color(0xFFF4F7FB),
      foregroundColor: AtlasColors.navy,
      elevation: 0,
      bottom: TabBar(
        controller: _tabs,
        labelColor: AtlasColors.royalBlue,
        unselectedLabelColor: AtlasColors.secondaryText,
        indicatorColor: AtlasColors.royalBlue,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.menu_book_rounded), text: 'Notes'),
          Tab(icon: Icon(Icons.picture_as_pdf_rounded), text: 'PDF Library'),
          Tab(icon: Icon(Icons.play_circle_rounded), text: 'Video Lessons'),
        ],
      ),
    ),
    body: Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF102B49), Color(0xFF1C5B8D)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x24102B49), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .2)),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ATLAS MEDICAL LIBRARY', style: TextStyle(
                color: Color(0xFFB9DDF7), fontSize: 10, letterSpacing: 1.5,
                fontWeight: FontWeight.w900)),
              SizedBox(height: 5),
              Text('Learn. Understand. Excel.', style: TextStyle(
                color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('Your organized medical study collection.',
                style: TextStyle(color: Color(0xFFD8E8F5), fontSize: 12, height: 1.35)),
            ],
          )),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _NotesLibraryShelf(onOpen: _open),
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
      _message('This content link is invalid.');
      return;
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
    } catch (e) {
      _message('Unable to open content: $e');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _NotesLibraryShelf extends StatefulWidget {
  final ValueChanged<LearningResourceModel> onOpen;
  const _NotesLibraryShelf({required this.onOpen});

  @override
  State<_NotesLibraryShelf> createState() => _NotesLibraryShelfState();
}

class _NotesLibraryShelfState extends State<_NotesLibraryShelf> {
  final TextEditingController _search = TextEditingController();
  String _browseMode = 'Subjects';
  String? _selectedCategory;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _systemName(Map<String, dynamic> data) {
    final value = data['systemName'] ?? data['organSystem'] ?? data['system'];
    if (value is Map) return (value['name'] ?? '').toString().trim();
    return (value ?? '').toString().trim();
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('learning_resources')
      .where('isPublished', isEqualTo: true).snapshots(),
    builder: (context, resourcesSnapshot) {
      if (resourcesSnapshot.hasError) return _stateMessage(
        'Unable to load notes. Please check your connection and access.');
      if (!resourcesSnapshot.hasData) return const Center(
        child: CircularProgressIndicator());
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('academic_subjects').snapshots(),
        builder: (context, subjectsSnapshot) {
          if (subjectsSnapshot.hasError) return _stateMessage(
            'Unable to load subject categories.');
          if (!subjectsSnapshot.hasData) return const Center(
            child: CircularProgressIndicator());

          final subjectData = <String, Map<String, dynamic>>{
            for (final doc in subjectsSnapshot.data!.docs) doc.id: doc.data(),
          };
          final allNotes = resourcesSnapshot.data!.docs
            .map(LearningResourceModel.fromFirestore)
            .where((item) => item.type == LearningResourceType.text)
            .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final rawById = {
            for (final doc in resourcesSnapshot.data!.docs) doc.id: doc.data(),
          };
          final query = _search.text.trim().toLowerCase();
          final categories = <String, List<LearningResourceModel>>{};
          final categoryArt = <String, String>{};

          for (final note in allNotes) {
            final raw = rawById[note.id] ?? {};
            final category = _browseMode == 'Subjects'
              ? ((subjectData[note.subjectId]?['name'] ?? 'General Notes').toString().trim())
              : _systemName(raw);
            if (category.isEmpty) continue;
            final matches = query.isEmpty ||
              note.title.toLowerCase().contains(query) ||
              note.description.toLowerCase().contains(query) ||
              category.toLowerCase().contains(query);
            if (!matches) continue;
            categories.putIfAbsent(category, () => []).add(note);
            categoryArt[category] = category;
          }

          if (_selectedCategory != null &&
              !categories.containsKey(_selectedCategory)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedCategory = null);
            });
          }

          final selected = _selectedCategory;
          if (selected != null && categories.containsKey(selected)) {
            return _categoryNotes(selected, categories[selected]!);
          }

          final sorted = categories.keys.toList()..sort();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() => _selectedCategory = null),
                decoration: InputDecoration(
                  hintText: 'Search notes, subjects or systems...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty ? null : IconButton(
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFE0E9F2))),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFE0E9F2))),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(child: Text('Browse your library', style: TextStyle(
                  color: AtlasColors.navy, fontSize: 17, fontWeight: FontWeight.w900))),
                Text('${allNotes.length} notes', style: const TextStyle(
                  color: AtlasColors.secondaryText, fontSize: 11,
                  fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 11),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Subjects', label: Text('By Subject'),
                    icon: Icon(Icons.school_outlined)),
                  ButtonSegment(value: 'Systems', label: Text('By System'),
                    icon: Icon(Icons.account_tree_outlined)),
                ],
                selected: {_browseMode},
                onSelectionChanged: (value) => setState(() {
                  _browseMode = value.first;
                  _selectedCategory = null;
                }),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 15),
              if (sorted.isEmpty)
                _emptyCategoryState()
              else ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sorted.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12,
                    mainAxisSpacing: 12, childAspectRatio: 1.12),
                  itemBuilder: (context, index) {
                    final name = sorted[index];
                    final count = categories[name]!.length;
                    final matchingSubjects = subjectData.values.where(
                      (value) => (value['name'] ?? '').toString() == name).toList();
                    final subject = matchingSubjects.isEmpty ? null : matchingSubjects.first;
                    return _MedicalCategoryCard(
                      title: name,
                      count: count,
                      imageUrl: subject?['imageUrl']?.toString(),
                      onTap: () => setState(() => _selectedCategory = name),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _sectionLabel('Recently published'),
                const SizedBox(height: 8),
                ...allNotes.take(5).map((note) => _NoteListTile(
                  note: note,
                  category: _browseMode == 'Subjects'
                    ? (subjectData[note.subjectId]?['name'] ?? 'General Notes').toString()
                    : _systemName(rawById[note.id] ?? {}),
                  onTap: () => widget.onOpen(note),
                )),
              ],
            ],
          );
        },
      );
    },
  );

  Widget _categoryNotes(String category, List<LearningResourceModel> notes) =>
      ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    children: [
      Row(children: [
        IconButton(
          onPressed: () => setState(() => _selectedCategory = null),
          icon: const Icon(Icons.arrow_back_rounded, color: AtlasColors.navy)),
        MedicalCategoryArtwork(category: category, size: 54),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category, style: const TextStyle(color: AtlasColors.navy,
            fontSize: 19, fontWeight: FontWeight.w900)),
          Text('${notes.length} published chapter(s)', style: const TextStyle(
            color: AtlasColors.secondaryText, fontSize: 12)),
        ])),
      ]),
      const SizedBox(height: 18),
      ...notes.map((note) => _NoteListTile(
        note: note, category: category, onTap: () => widget.onOpen(note))),
    ],
  );

  Widget _emptyCategoryState() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1EAF2))),
    child: Column(children: [
      const Icon(Icons.menu_book_rounded, size: 38, color: AtlasColors.royalBlue),
      const SizedBox(height: 10),
      Text(_browseMode == 'Systems'
        ? 'No system-tagged notes yet'
        : 'No published notes yet',
        style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text(_browseMode == 'Systems'
        ? 'System categories will appear automatically when chapters are assigned an organ system.'
        : 'Your academy will publish medical chapters here.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AtlasColors.secondaryText, height: 1.4)),
    ]),
  );

  Widget _stateMessage(String message) => Center(
    child: Padding(padding: const EdgeInsets.all(28),
      child: Text(message, textAlign: TextAlign.center,
        style: const TextStyle(color: AtlasColors.secondaryText))));

  Widget _sectionLabel(String label) => Text(label, style: const TextStyle(
    color: AtlasColors.navy, fontSize: 15, fontWeight: FontWeight.w900));
}

class _MedicalCategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final String? imageUrl;
  final VoidCallback onTap;

  const _MedicalCategoryCard({
    required this.title, required this.count, required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFDCE7F1)),
          boxShadow: const [
            BoxShadow(color: Color(0x09102B49), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(child: MedicalCategoryArtwork(
            category: title, imageUrl: imageUrl, size: 82)),
          const SizedBox(height: 7),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center, style: const TextStyle(
              color: AtlasColors.navy, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('$count chapter(s)', style: const TextStyle(
            color: AtlasColors.secondaryText, fontSize: 10,
            fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}

class _NoteListTile extends StatelessWidget {
  final LearningResourceModel note;
  final String category;
  final VoidCallback onTap;

  const _NoteListTile({
    required this.note, required this.category, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E9F2))),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      leading: MedicalCategoryArtwork(category: category, size: 48),
      title: Text(note.title, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
      subtitle: Text(note.description.isEmpty ? category : note.description,
        maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AtlasColors.royalBlue),
    ),
  );
}

class _ResourceShelf extends StatelessWidget {
  final LearningResourceType type;
  final ValueChanged<LearningResourceModel> onOpen;
  const _ResourceShelf({required this.type, required this.onOpen});

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('learning_resources')
      .where('isPublished', isEqualTo: true).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text(
        'Unable to load content. Please check your connection or access.'));
      if (!snapshot.hasData) return const Center(
        child: CircularProgressIndicator());
      final items = snapshot.data!.docs.map(LearningResourceModel.fromFirestore)
        .where((item) => item.type == type).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (items.isEmpty) {
        final label = type == LearningResourceType.pdf ? 'PDF documents' : 'video lessons';
        return Center(child: Padding(padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(type == LearningResourceType.pdf
              ? Icons.picture_as_pdf_rounded : Icons.play_circle_outline_rounded,
              size: 46, color: AtlasColors.royalBlue),
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
                child: Icon(type == LearningResourceType.pdf
                  ? Icons.picture_as_pdf_rounded : Icons.play_circle_fill_rounded,
                  color: AtlasColors.royalBlue)),
              title: Text(item.title, style: const TextStyle(
                color: AtlasColors.navy, fontWeight: FontWeight.w900)),
              subtitle: Text(item.description.isEmpty
                ? (type == LearningResourceType.pdf ? 'PDF document' : 'Video lesson')
                : item.description,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AtlasColors.secondaryText)),
              trailing: const Icon(Icons.arrow_forward_rounded,
                color: AtlasColors.royalBlue),
            ),
          );
        },
      );
    },
  );
}

class _NoteReader extends StatelessWidget {
  final LearningResourceModel resource;
  const _NoteReader({required this.resource});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    appBar: AppBar(title: Text(resource.title),
      backgroundColor: const Color(0xFFF4F7FB), foregroundColor: AtlasColors.navy),
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
