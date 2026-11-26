import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/medical_category_artwork.dart';
import '../models/learning_resource_model.dart';
import '../services/learning_resource_offline_service.dart';
import 'student_learning_progress_screen.dart';
import 'student_pdf_reader_screen.dart';
import 'student_pdf_highlights_screen.dart';
import 'student_pdf_downloads_screen.dart';

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
      backgroundColor: Colors.white,
      foregroundColor: AtlasColors.navy,
      elevation: 0,
      titleSpacing: 16,
      title: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FC),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.health_and_safety_rounded,
            color: AtlasColors.royalBlue, size: 22),
        ),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('The Atlas Academy', style: TextStyle(
            color: AtlasColors.navy, fontSize: 15, fontWeight: FontWeight.w900)),
          Text('LEARNING RESOURCES', style: TextStyle(
            color: AtlasColors.secondaryText, fontSize: 9,
            letterSpacing: 1.15, fontWeight: FontWeight.w800)),
        ]),
      ]),
      actions: [
        IconButton(tooltip: 'My learning progress',
          icon: const Icon(Icons.insights_rounded),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => StudentLearningProgressScreen(onOpen: _open)))),
        IconButton(tooltip: 'Notifications', icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => _message('Your learning notifications are available in the notification centre.')),
      ],
    ),
    body: Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(15, 13, 15, 12),
        padding: const EdgeInsets.fromLTRB(18, 17, 14, 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF09264A), Color(0xFF15558B), Color(0xFF2877A7)],
          ),
          borderRadius: BorderRadius.circular(23),
          boxShadow: const [BoxShadow(
            color: Color(0x24102B49), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('YOUR MEDICAL LEARNING COMPANION',
                style: TextStyle(color: Color(0xFFB9DDF7), fontSize: 9,
                  letterSpacing: 1.15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              const Text('Study smarter.\nExcel further.',
                style: TextStyle(color: Colors.white, fontSize: 22,
                  height: 1.12, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              const Text('Explore structured notes, trusted PDFs and video lessons.',
                style: TextStyle(color: Color(0xFFE0EFFA), fontSize: 11, height: 1.4)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFFD45A),
                  borderRadius: BorderRadius.circular(22)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Start learning', style: TextStyle(
                    color: Color(0xFF09264A), fontSize: 11, fontWeight: FontWeight.w900)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF09264A)),
                ]),
              ),
            ],
          )),
          const SizedBox(width: 5),
          Container(
            width: 92, height: 112,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .15)),
            ),
            child: const Icon(Icons.monitor_heart_rounded,
              color: Color(0xFFFFD1C5), size: 66),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
        child: Row(children: [
          const Expanded(child: Text('Quick access', style: TextStyle(
            color: AtlasColors.navy, fontSize: 16, fontWeight: FontWeight.w900))),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StudentPdfHighlightsScreen(onOpen: _openHighlighted))),
            child: const Text('View all', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
      SizedBox(
        height: 76,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          scrollDirection: Axis.horizontal,
          children: [
            _quickAccess('My Highlights', Icons.star_rounded, const Color(0xFFFFF1D7),
              const Color(0xFFE99A24), () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StudentPdfHighlightsScreen(onOpen: _openHighlighted)))),
            _quickAccess('Quick Revision', Icons.bolt_rounded, const Color(0xFFF1EAFE),
              const Color(0xFF8252D5), () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StudentPdfHighlightsScreen(onOpen: _openHighlighted))),
              badge: 'REVISE'),
            _quickAccess('My Downloads', Icons.download_rounded, const Color(0xFFE5F5EF),
              const Color(0xFF21956A), () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const StudentPdfDownloadsScreen()))),
            _quickAccess('Bookmarks', Icons.bookmark_rounded, const Color(0xFFE7F0FF),
              AtlasColors.royalBlue, () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _StudentSavedChaptersScreen(
                  offlineOnly: false, onOpen: _open)))),
            _quickAccess('Offline Notes', Icons.offline_pin_rounded, const Color(0xFFEAF4F4),
              const Color(0xFF278A87), () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _StudentSavedChaptersScreen(
                  offlineOnly: true, onOpen: _open)))),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE1EAF3))),
        child: TabBar(
          controller: _tabs,
          labelColor: AtlasColors.royalBlue,
          unselectedLabelColor: AtlasColors.secondaryText,
          indicatorColor: AtlasColors.royalBlue,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded, size: 19), text: 'Notes'),
            Tab(icon: Icon(Icons.picture_as_pdf_rounded, size: 19), text: 'PDF Library'),
            Tab(icon: Icon(Icons.play_circle_rounded, size: 19), text: 'Videos'),
          ],
        ),
      ),
      const SizedBox(height: 4),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _NotesLibraryShelf(onOpen: _open),
        _ResourceShelf(type: LearningResourceType.pdf, onOpen: _open),
        _ResourceShelf(type: LearningResourceType.video, onOpen: _open),
      ])),
    ]),
  );

  Widget _quickAccess(String title, IconData icon, Color background,
      Color foreground, VoidCallback onTap, {String? badge}) => Container(
    width: 91,
    margin: const EdgeInsets.only(right: 9),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3EAF2))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 31, height: 31,
              decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: foreground, size: 19)),
            const SizedBox(height: 5),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AtlasColors.navy,
                fontSize: 9, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    ),
  );

  Future<void> _open(LearningResourceModel resource) async {
    if (resource.type == LearningResourceType.text) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _NoteReader(resource: resource)));
      return;
    }
    if (resource.type == LearningResourceType.pdf) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StudentPdfReaderScreen(resource: resource)));
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

  Future<void> _openHighlighted(Map<String, dynamic> data) async {
    final resource = LearningResourceModel(
      id: (data['resourceId'] ?? '').toString(),
      yearId: '',
      subjectId: (data['subjectId'] ?? '').toString(),
      topicId: (data['topicId'] ?? '').toString(),
      subjectName: (data['subjectName'] ?? '').toString(),
      topicName: (data['topicName'] ?? '').toString(),
      title: (data['resourceTitle'] ?? 'PDF document').toString(),
      description: '',
      type: LearningResourceType.pdf,
      resourceUrl: (data['resourceUrl'] ?? '').toString(),
      systemName: (data['systemName'] ?? '').toString(),
      versionNumber: (data['resourceVersion'] as num?)?.toInt() ?? 0,
      isPublished: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (resource.id.isEmpty || resource.resourceUrl.isEmpty) {
      _message('This PDF link is no longer available.');
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StudentPdfReaderScreen(
        resource: resource,
        initialPage: (data['pageNumber'] as num?)?.toInt() ?? 1,
      )));
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _StudentSavedChaptersScreen extends StatelessWidget {
  final bool offlineOnly;
  final ValueChanged<LearningResourceModel> onOpen;
  const _StudentSavedChaptersScreen({
    required this.offlineOnly, required this.onOpen,
  });

  LearningResourceModel _offlineModel(Map<String, dynamic> data) {
    final revision = DateTime.tryParse((data['updatedAt'] ?? data['savedAt'] ?? '').toString())
        ?? DateTime.now();
    final blocks = (data['contentBlocks'] as List?)
        ?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
    return LearningResourceModel(
      id: (data['id'] ?? '').toString(),
      yearId: '',
      subjectId: '',
      topicId: '',
      title: (data['title'] ?? 'Saved chapter').toString(),
      description: (data['description'] ?? '').toString(),
      type: LearningResourceType.text,
      resourceUrl: '',
      textContent: (data['textContent'] ?? '').toString(),
      contentBlocks: blocks,
      systemName: (data['systemName'] ?? '').toString(),
      readingMinutes: (data['readingMinutes'] as num?)?.toInt() ?? 0,
      isPublished: true,
      createdAt: revision,
      updatedAt: revision,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = offlineOnly ? 'Offline Chapters' : 'Bookmarked Chapters';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(title: Text(title), backgroundColor: Colors.white,
        foregroundColor: AtlasColors.navy),
      body: offlineOnly
        ? FutureBuilder<List<Map<String, dynamic>>>(
            future: LearningResourceOfflineService.listSaved(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(
                child: Text('Unable to read saved chapters on this device.'));
              if (!snapshot.hasData) return const Center(
                child: CircularProgressIndicator());
              final items = snapshot.data!;
              if (items.isEmpty) return _empty(context,
                'No offline chapters yet. Open a chapter and tap the download icon.');
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = _offlineModel(items[index]);
                  return _tile(context, item, 'Saved on this device');
                },
              );
            },
          )
        : uid == null
          ? _empty(context, 'Sign in to view your bookmarks.')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('student_resource_progress')
                  .where('userId', isEqualTo: uid).snapshots(),
              builder: (context, progressSnapshot) {
                if (progressSnapshot.hasError) return _empty(context,
                  'Unable to load bookmarks. Please check your connection and access.');
                if (!progressSnapshot.hasData) return const Center(
                  child: CircularProgressIndicator());
                final ids = progressSnapshot.data!.docs
                    .where((doc) => doc.data()['isBookmarked'] == true)
                    .map((doc) => (doc.data()['resourceId'] ?? '').toString())
                    .where((id) => id.isNotEmpty).toSet();
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('learning_resources')
                      .where('isPublished', isEqualTo: true).snapshots(),
                  builder: (context, resourceSnapshot) {
                    if (resourceSnapshot.hasError) return _empty(context,
                      'Unable to load bookmarked chapters.');
                    if (!resourceSnapshot.hasData) return const Center(
                      child: CircularProgressIndicator());
                    final items = resourceSnapshot.data!.docs
                        .where((doc) => ids.contains(doc.id))
                        .map(LearningResourceModel.fromFirestore).toList();
                    if (items.isEmpty) return _empty(context,
                      'You have not bookmarked any chapters yet.');
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _tile(context, items[index], 'Bookmarked chapter'),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _tile(BuildContext context, LearningResourceModel item, String subtitle) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E9F2))),
        child: ListTile(
          onTap: () => onOpen(item),
          leading: const CircleAvatar(backgroundColor: Color(0xFFE8F1FB),
            child: Icon(Icons.menu_book_rounded, color: AtlasColors.royalBlue)),
          title: Text(item.title, style: const TextStyle(
            color: AtlasColors.navy, fontWeight: FontWeight.w900)),
          subtitle: Text(item.systemName.isEmpty ? subtitle : item.systemName),
          trailing: const Icon(Icons.chevron_right_rounded,
            color: AtlasColors.royalBlue),
        ),
      );

  Widget _empty(BuildContext context, String message) => Center(
    child: Padding(padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(offlineOnly ? Icons.offline_pin_rounded : Icons.bookmarks_outlined,
          size: 42, color: AtlasColors.royalBlue),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: AtlasColors.secondaryText, height: 1.5)),
      ]),
    ),
  );
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
  String _accessFilter = 'All';
  String _sortMode = 'Newest';
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
          final searchableNotes = allNotes.where((note) {
            final raw = rawById[note.id] ?? {};
            final subjectName = (subjectData[note.subjectId]?['name'] ?? '').toString();
            final systemName = _systemName(raw);
            final topicName = (raw['topicName'] ?? raw['topic'] ?? '').toString();
            final blocks = note.contentBlocks.map((block) =>
              (block['text'] ?? block['caption'] ?? '').toString()).join(' ');
            final matchesQuery = query.isEmpty || [
              note.title, note.description, subjectName, systemName, topicName, blocks,
            ].any((value) => value.toLowerCase().contains(query));
            final matchesAccess = _accessFilter == 'All' ||
              (_accessFilter == 'Free' && note.isFree) ||
              (_accessFilter == 'Premium' && !note.isFree);
            return matchesQuery && matchesAccess;
          }).toList();
          searchableNotes.sort((a, b) {
            switch (_sortMode) {
              case 'Title A–Z':
                return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              case 'Oldest':
                return a.createdAt.compareTo(b.createdAt);
              case 'Recently updated':
                return b.updatedAt.compareTo(a.updatedAt);
              default:
                return b.createdAt.compareTo(a.createdAt);
            }
          });

          for (final note in searchableNotes) {
            final raw = rawById[note.id] ?? {};
            final category = _browseMode == 'Subjects'
              ? ((subjectData[note.subjectId]?['name'] ?? 'General Notes').toString().trim())
              : _systemName(raw);
            if (category.isEmpty) continue;
            categories.putIfAbsent(category, () => []).add(note);
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
                Text('${searchableNotes.length} of ${allNotes.length} chapters', style: const TextStyle(
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
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final filter in ['All', 'Free', 'Premium'])
                  ChoiceChip(
                    label: Text(filter == 'All' ? 'All chapters' : filter),
                    selected: _accessFilter == filter,
                    onSelected: (_) => setState(() {
                      _accessFilter = filter;
                      _selectedCategory = null;
                    }),
                    selectedColor: const Color(0xFFDCEBFA),
                    labelStyle: TextStyle(
                      color: _accessFilter == filter
                        ? AtlasColors.royalBlue : AtlasColors.secondaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(width: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortMode,
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'Recently updated', child: Text('Recently updated')),
                      DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                      DropdownMenuItem(value: 'Title A–Z', child: Text('Title A–Z')),
                    ],
                    onChanged: (value) => setState(() {
                      if (value != null) _sortMode = value;
                    }),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _ContinueReadingShelf(notes: searchableNotes, onOpen: widget.onOpen),
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
                _sectionLabel(_sortMode == 'Newest' ? 'Recently published' : 'Matching chapters'),
                const SizedBox(height: 8),
                ...searchableNotes.take(5).map((note) => _NoteListTile(
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

class _ContinueReadingShelf extends StatelessWidget {
  final List<LearningResourceModel> notes;
  final ValueChanged<LearningResourceModel> onOpen;
  const _ContinueReadingShelf({required this.notes, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('student_resource_progress')
          .where('userId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) return const SizedBox.shrink();
        final noteById = {for (final note in notes) note.id: note};
        final recent = snapshot.data!.docs
            .where((doc) {
              final data = doc.data();
              final percent = (data['progressPercent'] as num?)?.toDouble() ?? 0;
              final id = (data['resourceId'] ?? '').toString();
              return percent > 0 && percent < 100 && noteById.containsKey(id);
            }).toList()
          ..sort((a, b) {
            final ad = a.data()['lastReadAt'];
            final bd = b.data()['lastReadAt'];
            final at = ad is Timestamp ? ad.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            final bt = bd is Timestamp ? bd.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });
        if (recent.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(bottom: 9),
            child: Text('Continue reading', style: TextStyle(
              color: AtlasColors.navy, fontSize: 15, fontWeight: FontWeight.w900))),
          SizedBox(height: 112, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length > 6 ? 6 : recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final data = recent[index].data();
              final id = (data['resourceId'] ?? '').toString();
              final note = noteById[id]!;
              final progress = ((data['progressPercent'] as num?)?.toDouble() ?? 0)
                  .clamp(0, 100).toDouble();
              return SizedBox(width: 230, child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  onTap: () => onOpen(note),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFDCE7F1))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(note.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AtlasColors.navy,
                            fontWeight: FontWeight.w900, fontSize: 12)),
                        Row(children: [
                          Expanded(child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(value: progress / 100,
                              minHeight: 5, backgroundColor: const Color(0xFFE8EEF5),
                              color: AtlasColors.royalBlue))),
                          const SizedBox(width: 8),
                          Text('${progress.round()}%',
                            style: const TextStyle(color: AtlasColors.royalBlue,
                              fontSize: 10, fontWeight: FontWeight.w900)),
                        ]),
                      ]),
                  ),
                ),
              ));
            },
          )),
          const SizedBox(height: 13),
        ]);
      },
    );
  }
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

class _ResourceShelf extends StatefulWidget {
  final LearningResourceType type;
  final ValueChanged<LearningResourceModel> onOpen;
  const _ResourceShelf({required this.type, required this.onOpen});

  @override
  State<_ResourceShelf> createState() => _ResourceShelfState();
}

class _ResourceShelfState extends State<_ResourceShelf> {
  final TextEditingController _search = TextEditingController();
  String _subject = 'All subjects';
  String _system = 'All systems';
  String _sort = 'Newest';

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('learning_resources')
        .where('isPublished', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text(
          'Unable to load content. Please check your connection or access.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final all = snapshot.data!.docs.map(LearningResourceModel.fromFirestore)
          .where((item) => item.type == widget.type).toList();
        final subjects = <String>{'All subjects'};
        final systems = <String>{'All systems'};
        for (final item in all) {
          if (item.subjectName.trim().isNotEmpty) subjects.add(item.subjectName.trim());
          if (item.systemName.trim().isNotEmpty) systems.add(item.systemName.trim());
        }
        if (!subjects.contains(_subject)) _subject = 'All subjects';
        if (!systems.contains(_system)) _system = 'All systems';

        final query = _search.text.trim().toLowerCase();
        final items = all.where((item) {
          final subjectMatch = _subject == 'All subjects' || item.subjectName.trim() == _subject;
          final systemMatch = _system == 'All systems' || item.systemName.trim() == _system;
          final searchMatch = query.isEmpty || [
            item.title, item.description, item.subjectName, item.systemName, item.topicName,
          ].any((value) => value.toLowerCase().contains(query));
          return subjectMatch && systemMatch && searchMatch;
        }).toList()..sort((a,b) {
          switch (_sort) {
            case 'Title A–Z': return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            case 'Oldest': return a.createdAt.compareTo(b.createdAt);
            case 'Recently updated': return b.updatedAt.compareTo(a.updatedAt);
            default: return b.createdAt.compareTo(a.createdAt);
          }
        });

        final isPdf = widget.type == LearningResourceType.pdf;
        final label = isPdf ? 'PDF documents' : 'video lessons';
        return Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Column(children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isPdf ? 'Search PDFs, subjects, systems or topics...' :
                  'Search videos, subjects, systems or topics...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty ? null : IconButton(
                  onPressed: () { _search.clear(); setState(() {}); },
                  icon: const Icon(Icons.close_rounded)),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0EAF5))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0EAF5))),
              ),
            ),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: _filterDropdown('Subject', _subject, subjects.toList(),
                (value) => setState(() => _subject = value))),
              const SizedBox(width: 8),
              Expanded(child: _filterDropdown('System', _system, systems.toList(),
                (value) => setState(() => _system = value))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Sort by', style: TextStyle(color: AtlasColors.secondaryText,
                fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Expanded(child: Align(alignment: Alignment.centerRight,
                child: DropdownButton<String>(
                  value: _sort, isDense: true,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'Recently updated', child: Text('Recently updated')),
                    DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
                    DropdownMenuItem(value: 'Title A–Z', child: Text('Title A–Z')),
                  ],
                  onChanged: (value) { if (value != null) setState(() => _sort = value); },
                ))),
            ]),
            if (_subject != 'All subjects' || _system != 'All systems' || query.isNotEmpty)
              Align(alignment: Alignment.centerRight, child: TextButton.icon(
                onPressed: () => setState(() {
                  _search.clear(); _subject = 'All subjects'; _system = 'All systems';
                }),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Clear filters'))),
          ])),
          Expanded(child: items.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.play_circle_outline_rounded,
                    size: 46, color: AtlasColors.royalBlue),
                  const SizedBox(height: 12),
                  Text(all.isEmpty ? 'No $label published yet' : 'No matching content found',
                    style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(all.isEmpty ? 'Please check back later.' :
                    'Try another search or clear your filters.',
                    style: const TextStyle(color: AtlasColors.secondaryText)),
                ])))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 11),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE0EAF5))),
                    child: ListTile(
                      onTap: () => widget.onOpen(item),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(width: 52, height: 52,
                          child: (item.thumbnailUrl ?? '').isNotEmpty
                            ? Image.network(item.thumbnailUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _resourceFallback(isPdf))
                            : _resourceFallback(isPdf))),
                      title: Text(item.title, style: const TextStyle(
                        color: AtlasColors.navy, fontWeight: FontWeight.w900)),
                      subtitle: Text([
                        if (item.subjectName.isNotEmpty) item.subjectName,
                        if (item.systemName.isNotEmpty) item.systemName,
                        if (item.topicName.isNotEmpty) item.topicName,
                        if (item.description.isNotEmpty) item.description,
                        if (item.subjectName.isEmpty && item.systemName.isEmpty &&
                            item.topicName.isEmpty && item.description.isEmpty)
                          (isPdf ? 'PDF document' : 'Video lesson'),
                      ].join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AtlasColors.secondaryText)),
                      trailing: const Icon(Icons.arrow_forward_rounded,
                        color: AtlasColors.royalBlue),
                    ),
                  );
                })),
        ]);
      },
    );

  Widget _filterDropdown(String label, String value, List<String> values,
      ValueChanged<String> onChanged) => DropdownButtonFormField<String>(
    value: value, isExpanded: true, isDense: true,
    decoration: InputDecoration(
      labelText: label, filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0EAF5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0EAF5))),
    ),
    items: (values.toSet().toList()..sort((a,b) {
      if (a.startsWith('All ')) return -1;
      if (b.startsWith('All ')) return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    })).map((entry) => DropdownMenuItem<String>(
      value: entry, child: Text(entry, overflow: TextOverflow.ellipsis))).toList(),
    onChanged: (next) { if (next != null) onChanged(next); },
  );

  Widget _resourceFallback(bool isPdf) => Container(
    color: const Color(0xFFE5F1FF),
    child: Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.play_circle_fill_rounded,
      color: AtlasColors.royalBlue));
}

class _NoteReader extends StatefulWidget {
  final LearningResourceModel resource;
  const _NoteReader({required this.resource});

  @override
  State<_NoteReader> createState() => _NoteReaderState();
}

class _NoteReaderState extends State<_NoteReader> with WidgetsBindingObserver {
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _headingKeys = {};
  Timer? _progressTimer;
  Timer? _readingCheckpoint;
  final Stopwatch _readingWatch = Stopwatch();
  int _savedReadingSeconds = 0;
  late LearningResourceModel _shown;
  bool _bookmarked = false;
  bool _offlineSaved = false;
  bool _offlineOutdated = false;
  double _downloadProgress = 0;
  bool _busy = false;
  bool _dark = false;
  double _fontScale = 1.0;
  double _progress = 0;
  List<LearningResourceModel> _chapters = [];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String get _progressId => '${_uid}_${widget.resource.id}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readingWatch.start();
    _readingCheckpoint = Timer.periodic(const Duration(seconds: 30), (_) => _flushReadingTime());
    _shown = widget.resource;
    _scroll.addListener(_onScroll);
    _loadReaderPreferences();
    _loadReaderState();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _readingCheckpoint?.cancel();
    _readingWatch.stop();
    _flushReadingTime();
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_readingWatch.isRunning) _readingWatch.start();
    } else {
      _readingWatch.stop();
      _flushReadingTime();
    }
  }

  Future<void> _flushReadingTime() async {
    final uid = _uid;
    if (uid == null) return;
    final elapsed = _readingWatch.elapsed.inSeconds;
    final delta = elapsed - _savedReadingSeconds;
    if (delta <= 0) return;
    _savedReadingSeconds = elapsed;
    final now = DateTime.now();
    final day = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ref = FirebaseFirestore.instance.collection('student_resource_progress').doc(_progressId);
    try {
      await ref.set({
        'userId': uid,
        'resourceId': widget.resource.id,
        'resourceTitle': widget.resource.title,
        'subjectId': widget.resource.subjectId,
        'systemName': widget.resource.systemName,
      }, SetOptions(merge: true));
      await ref.update({
        'dailyReadingSeconds.$day': FieldValue.increment(delta),
        'totalReadingSeconds': FieldValue.increment(delta),
        'lastReadAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      _savedReadingSeconds -= delta;
    }
  }

  Future<void> _loadReaderPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _fontScale = (prefs.getDouble('atlas_reader_font_scale') ?? 1.0)
            .clamp(0.85, 1.45).toDouble();
        _dark = prefs.getBool('atlas_reader_dark_theme') ?? false;
      });
    } catch (_) {}
  }

  Future<void> _loadReaderState() async {
    final offline = await LearningResourceOfflineService.read(widget.resource.id);
    if (offline != null && mounted) {
      final blocks = (offline['contentBlocks'] as List?)
          ?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      final savedRevision = DateTime.tryParse((offline['updatedAt'] ?? '').toString());
      final outdated = savedRevision != null &&
          savedRevision.isBefore(widget.resource.updatedAt);
      setState(() {
        _offlineSaved = true;
        _offlineOutdated = outdated;
        if (!outdated) {
          _shown = widget.resource.copyWith(
            contentBlocks: blocks,
            textContent: offline['textContent']?.toString() ?? widget.resource.textContent,
          );
        }
      });
    }
    final uid = _uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('student_resource_progress').doc(_progressId).get();
        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          setState(() {
            _bookmarked = data['isBookmarked'] == true;
            _progress = ((data['progressPercent'] as num?)?.toDouble() ?? 0)
                .clamp(0, 100).toDouble();
          });
          if (_progress > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _scroll.hasClients && _scroll.position.maxScrollExtent > 0) {
                _scroll.jumpTo(_scroll.position.maxScrollExtent * (_progress / 100));
              }
            });
          }
        }
      } catch (_) {}
    }
    _loadChapterNavigation();
  }

  Future<void> _loadChapterNavigation() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('learning_resources')
          .where('isPublished', isEqualTo: true).get();
      final all = snapshot.docs.map(LearningResourceModel.fromFirestore)
          .where((item) => item.type == LearningResourceType.text).toList();
      var items = all;
      if (widget.resource.subjectId.isNotEmpty) {
        final sameSubject = all.where((item) =>
            item.subjectId == widget.resource.subjectId).toList();
        if (sameSubject.isNotEmpty) items = sameSubject;
      } else if (widget.resource.systemName.isNotEmpty) {
        final sameSystem = all.where((item) =>
            item.systemName == widget.resource.systemName).toList();
        if (sameSystem.isNotEmpty) items = sameSystem;
      }
      items.sort((a, b) {
        final dateOrder = a.createdAt.compareTo(b.createdAt);
        return dateOrder != 0 ? dateOrder : a.title.compareTo(b.title);
      });
      if (mounted) setState(() => _chapters = items);
    } catch (_) {}
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final value = max <= 0 ? 0.0 : (_scroll.offset / max * 100).clamp(0, 100).toDouble();
    if ((value - _progress).abs() >= 1) setState(() => _progress = value);
    _progressTimer?.cancel();
    _progressTimer = Timer(const Duration(seconds: 4), _saveProgress);
  }

  Future<void> _saveProgress() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('student_resource_progress')
          .doc(_progressId).set({
        'userId': uid,
        'resourceId': widget.resource.id,
        'progressPercent': _progress,
        'lastPosition': _scroll.hasClients ? _scroll.offset : 0,
        'isBookmarked': _bookmarked,
        'subjectId': widget.resource.subjectId,
        'systemName': widget.resource.systemName,
        'resourceTitle': widget.resource.title,
        'lastReadAt': FieldValue.serverTimestamp(),
        'completed': _progress >= 99.5,
        if (_progress >= 99.5) 'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    setState(() => _bookmarked = !_bookmarked);
    await _saveProgress();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_bookmarked ? 'Chapter bookmarked.' : 'Bookmark removed.')));
  }

  Future<void> _toggleOffline() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_offlineSaved && !_offlineOutdated) {
        await LearningResourceOfflineService.remove(widget.resource.id);
        if (mounted) setState(() { _offlineSaved = false; _offlineOutdated = false; });
      } else {
        await LearningResourceOfflineService.download(widget.resource,
          onProgress: (done, total) {
            if (mounted) setState(() => _downloadProgress = total == 0
                ? 1 : done / total);
          });
        final saved = await LearningResourceOfflineService.read(widget.resource.id);
        if (saved != null) {
          final blocks = (saved['contentBlocks'] as List?)
              ?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
          if (mounted) setState(() {
            _offlineSaved = true;
            _offlineOutdated = false;
            _shown = widget.resource.copyWith(contentBlocks: blocks);
          });
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_offlineSaved
          ? 'Chapter and its illustrations saved for offline reading.'
          : 'Offline chapter removed.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Offline save failed: $e')));
    } finally {
      if (mounted) setState(() { _busy = false; _downloadProgress = 0; });
    }
  }

  void _showContents() {
    final headings = <MapEntry<int, String>>[];
    for (var i = 0; i < _shown.contentBlocks.length; i++) {
      final block = _shown.contentBlocks[i];
      final type = (block['type'] ?? '').toString();
      if (type.startsWith('heading') && (block['text'] ?? '').toString().trim().isNotEmpty) {
        headings.add(MapEntry(i, block['text'].toString()));
      }
    }
    if (headings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This chapter has no section headings yet.')));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text('Table of contents', style: TextStyle(
              color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900))),
          ...headings.map((entry) => ListTile(
            leading: const Icon(Icons.format_list_bulleted_rounded,
              color: AtlasColors.royalBlue),
            title: Text(entry.value, style: const TextStyle(
              color: AtlasColors.navy, fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(sheetContext);
              final key = _headingKeys[entry.key];
              final target = key?.currentContext;
              if (target != null) Scrollable.ensureVisible(target,
                duration: const Duration(milliseconds: 450), curve: Curves.easeInOut,
                alignment: 0.08);
            },
          )),
        ],
      )),
    );
  }

  void _changeFont(double value) {
    setState(() => _fontScale = value);
    SharedPreferences.getInstance().then((prefs) =>
        prefs.setDouble('atlas_reader_font_scale', value));
  }

  void _toggleReadingTheme() {
    setState(() => _dark = !_dark);
    SharedPreferences.getInstance().then((prefs) =>
        prefs.setBool('atlas_reader_dark_theme', _dark));
  }

  void _moveChapter(int direction) {
    final index = _chapters.indexWhere((item) => item.id == widget.resource.id);
    final next = index + direction;
    if (index < 0 || next < 0 || next >= _chapters.length) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => _NoteReader(resource: _chapters[next])));
  }

  @override
  Widget build(BuildContext context) {
    final background = _dark ? const Color(0xFF101B29) : const Color(0xFFF4F7FB);
    final foreground = _dark ? const Color(0xFFE8F0F8) : AtlasColors.navy;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(widget.resource.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: _dark ? const Color(0xFF17283B) : Colors.white,
        foregroundColor: _dark ? Colors.white : AtlasColors.navy,
        actions: [
          IconButton(tooltip: 'Table of contents', onPressed: _showContents,
            icon: const Icon(Icons.toc_rounded)),
          IconButton(tooltip: 'Text size', onPressed: () => showModalBottomSheet<void>(
            context: context, showDragHandle: true, builder: (c) => StatefulBuilder(
              builder: (c, update) => Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Reading text size', style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900)),
                  Slider(value: _fontScale, min: 0.85, max: 1.45, divisions: 6,
                    label: '${(_fontScale * 100).round()}%',
                    onChanged: (v) { _changeFont(v); update(() {}); }),
                ]),
              ),
            ),
          ), icon: const Icon(Icons.text_fields_rounded)),
          IconButton(tooltip: _dark ? 'Light reading theme' : 'Dark reading theme',
            onPressed: _toggleReadingTheme,
            icon: Icon(_dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded)),
          IconButton(tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark chapter',
            onPressed: _toggleBookmark,
            icon: Icon(_bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _bookmarked ? Colors.amber : null)),
          IconButton(tooltip: _offlineSaved ? 'Remove offline copy' : 'Download for offline',
            onPressed: _toggleOffline,
            icon: _busy ? SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(value: _downloadProgress,
                strokeWidth: 2))
              : Icon(_offlineSaved ? Icons.offline_pin_rounded : Icons.download_for_offline_rounded)),
        ],
      ),
      body: Column(children: [
        LinearProgressIndicator(value: _progress / 100,
          minHeight: 3, backgroundColor: _dark ? Colors.white12 : const Color(0xFFE3EAF2),
          color: AtlasColors.royalBlue),
        Padding(padding: const EdgeInsets.fromLTRB(18, 5, 18, 0),
          child: Align(alignment: Alignment.centerRight,
            child: Text('${_progress.round()}% read', style: TextStyle(
              color: _dark ? Colors.white60 : AtlasColors.secondaryText,
              fontSize: 10, fontWeight: FontWeight.w700)))),
        Expanded(child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_fontScale)),
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF102B49), Color(0xFF1E5B8B)]),
                  borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('THE ATLAS ACADEMY • LEARNING RESOURCES',
                    style: TextStyle(color: Color(0xFFB9DDF7), fontSize: 9,
                      letterSpacing: 1.1, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text(_shown.title, style: const TextStyle(color: Colors.white,
                    fontSize: 24, height: 1.2, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 9),
                  Text(_shown.systemName.isEmpty ? 'STUDY NOTES' : _shown.systemName.toUpperCase(),
                    style: const TextStyle(color: Color(0xFFD5E7F5), fontSize: 11)),
                  if (_shown.versionNumber > 0)
                    Text('PUBLISHED REVISION • VERSION ${_shown.versionNumber}',
                      style: const TextStyle(color: Color(0xFFD5E7F5), fontSize: 10,
                        fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  if (_shown.readingMinutes > 0)
                    Text('${_shown.readingMinutes} min read',
                      style: const TextStyle(color: Color(0xFFD5E7F5), fontSize: 11)),
                  if (_offlineSaved) Padding(padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      Icon(Icons.offline_pin_rounded, color: Color(0xFFB9E8D0), size: 16),
                      SizedBox(width: 5),
                      Text(_offlineOutdated ? 'OFFLINE COPY NEEDS UPDATE' : 'AVAILABLE OFFLINE', style: TextStyle(
                        color: Color(0xFFB9E8D0), fontSize: 10, fontWeight: FontWeight.w900)),
                    ])),
                ]),
              ),
              if (_shown.description.isNotEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(_shown.description, style: TextStyle(
                    color: _dark ? Colors.white70 : AtlasColors.secondaryText,
                    fontSize: 14, height: 1.6))),
              if (_shown.contentBlocks.isNotEmpty)
                ..._shown.contentBlocks.asMap().entries.map((entry) {
                  final type = (entry.value['type'] ?? '').toString();
                  final key = type.startsWith('heading')
                      ? (_headingKeys[entry.key] ??= GlobalKey()) : null;
                  return KeyedSubtree(
                    key: key ?? ValueKey('block_${entry.key}'),
                    child: _StudentNoteBlock(block: entry.value, dark: _dark));
                })
              else
                Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _dark ? const Color(0xFF1B2A3B) : Colors.white,
                    borderRadius: BorderRadius.circular(18)),
                  child: SelectableText(_shown.textContent, style: TextStyle(
                    color: foreground, height: 1.75, fontSize: 15))),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _chapters.isEmpty ? null : () => _moveChapter(-1),
                  icon: const Icon(Icons.chevron_left_rounded), label: const Text('Previous chapter'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.icon(
                  onPressed: _chapters.isEmpty ? null : () => _moveChapter(1),
                  icon: const Icon(Icons.chevron_right_rounded), label: const Text('Next chapter'),
                  iconAlignment: IconAlignment.end)),
              ]),
            ],
          ),
        )),
      ]),
    );
  }
}

class _StudentNoteBlock extends StatelessWidget {
  final Map<String, dynamic> block;
  final bool dark;
  const _StudentNoteBlock({required this.block, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final type = (block['type'] ?? 'paragraph').toString();
    final value = (block['text'] ?? '').toString();
    final caption = (block['caption'] ?? '').toString();
    final url = (block['imageUrl'] ?? '').toString();
    final offlineData = (block['offlineImageData'] ?? '').toString();
    if (type == 'divider') return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: dark ? Colors.white24 : const Color(0xFFDCE5EF), thickness: 1.2));
    if (type.startsWith('heading')) {
      final size = type == 'heading1' ? 25.0 : type == 'heading2' ? 20.0 : 17.0;
      return Padding(padding: const EdgeInsets.only(top: 19, bottom: 8),
        child: Text(value, style: TextStyle(color: dark ? const Color(0xFFE8F0F8) : AtlasColors.navy,
          fontSize: size, fontWeight: FontWeight.w900)));
    }
    if (type == 'image') return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (url.isNotEmpty) ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: offlineData.startsWith('data:image/')
              ? Image.memory(base64Decode(offlineData.split(',').last),
                  width: double.infinity, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 130,
                    child: Center(child: Icon(Icons.broken_image_outlined))))
              : Image.network(url, width: double.infinity, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 130,
                    child: Center(child: Icon(Icons.broken_image_outlined)))),
        ),
        if (caption.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(caption, style: TextStyle(
            color: dark ? Colors.white60 : AtlasColors.secondaryText, fontSize: 12,
            fontStyle: FontStyle.italic))),
      ]),
    );
    if (type == 'highlight' || type == 'clinical' || type == 'pearl' ||
        type == 'definition' || type == 'warning') {
      final title = type == 'clinical' ? 'Clinical correlation'
        : type == 'pearl' ? 'Examination pearl'
        : type == 'warning' ? 'Important caution'
        : type == 'definition' ? 'Definition' : 'Important concept';
      final color = dark ? const Color(0xFF26384B)
        : type == 'warning' ? const Color(0xFFFFF0EA)
        : type == 'clinical' ? const Color(0xFFEAF5F4)
        : type == 'pearl' ? const Color(0xFFFFF7E5)
        : const Color(0xFFEAF2FC);
      return Container(margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: color,
          borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: dark ? const Color(0xFFE8F0F8) : AtlasColors.navy,
            fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          SelectableText(value, style: TextStyle(
            color: dark ? const Color(0xFFE8F0F8) : AtlasColors.navy, height: 1.6)),
        ]),
      );
    }
    if (type == 'bullet' || type == 'numbered') {
      final lines = value.split('\\n').where((v) => v.trim().isNotEmpty).toList();
      return Padding(padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 24, child: Text('•',
                style: TextStyle(color: dark ? const Color(0xFF8DBCF4) : AtlasColors.royalBlue,
                  fontWeight: FontWeight.w900))),
              Expanded(child: SelectableText(line, style: TextStyle(
                color: dark ? const Color(0xFFE8F0F8) : AtlasColors.navy, height: 1.6, fontSize: 15))),
            ]),
          )).toList()),
      );
    }
    if (type == 'table') {
      final rows = value.split('\\n').where((v) => v.trim().isNotEmpty)
        .map((row) => row.split('|').map((v) => v.trim()).toList()).toList();
      if (rows.isEmpty) return const SizedBox.shrink();
      return SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(dark ? const Color(0xFF26384B) : const Color(0xFFEAF2FC)),
          columns: rows.first.map((v) => DataColumn(label: Text(v,
            style: TextStyle(color: dark ? Colors.white : AtlasColors.navy,
              fontWeight: FontWeight.w900)))).toList(),
          rows: rows.skip(1).map((row) => DataRow(cells: List.generate(
            rows.first.length, (i) => DataCell(Text(i < row.length ? row[i] : '',
              style: TextStyle(color: dark ? const Color(0xFFE8F0F8) : AtlasColors.navy)))))).toList(),
        ));
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: 7),
      child: SelectableText(value, style: TextStyle(
        color: dark ? const Color(0xFFE8F0F8) : AtlasColors.navy, fontSize: 15, height: 1.75)));
  }
}
