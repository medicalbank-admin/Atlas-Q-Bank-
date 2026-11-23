import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:interactive_3d/interactive_3d.dart';
import '../../../app/atlas_academy_app.dart';
import '../data/anatomy_catalog.dart';
import '../data/detailed_skeleton_catalog.dart';

const _maleModelUrl = 'https://cdn.jsdelivr.net/npm/open-anatomy-3d@0.1.0/models/anatomy-male.glb';
const _femaleModelUrl = 'https://cdn.jsdelivr.net/npm/open-anatomy-3d@0.1.0/models/anatomy-female.glb';
const _skeletonModelUrl = 'https://raw.githubusercontent.com/organui/skeleton-3d/main/public/models/skeleton.glb';
const _systems = <String, String>{
  'skeleton': 'Skeletal', 'organs': 'Organs', 'muscles': 'Muscles',
  'vessels': 'Vessels', 'nerves': 'Nerves', 'skin': 'Skin', 'joints': 'Joints',
};

class StudentAnatomyLabScreen extends StatefulWidget {
  const StudentAnatomyLabScreen({super.key});
  @override
  State<StudentAnatomyLabScreen> createState() => _StudentAnatomyLabScreenState();
}

class _StudentAnatomyLabScreenState extends State<StudentAnatomyLabScreen> {
  final Interactive3dController _controller = Interactive3dController();
  final Set<String> _visibleSystems = {'skeleton'};
  String _sex = 'male';
  String _activeSystem = 'skeleton';
  String? _selectedKey;
  bool _modelReady = false;
  int _loadAttempt = 0;
  Map<String, String>? _quizTarget;
  int _quizCorrect = 0;
  int _quizStep = 0;
  static const int _quizLength = 5;

  Map<String, String>? _find(String key) {
    for (final item in detailedSkeletonCatalog) {
      if (item['key'] == key) return item;
    }
    for (final item in anatomyCatalog) {
      if (item['key'] == key) return item;
    }
    return null;
  }

  List<String> _names(String system) => (system == 'skeleton'
      ? detailedSkeletonCatalog
      : anatomyCatalog.where((item) => item['system'] == system))
      .map((item) => item['key']!)
      .toList(growable: false);

  Future<void> _applyLayers() async {
    if (!_modelReady || _activeSystem == 'skeleton') return;
    for (final system in _systems.keys) {
      final names = _names(system);
      if (names.isEmpty) continue;
      await _controller.updatePartGroupConfig(
        isVisible: _visibleSystems.contains(system),
        group: ModelPartGroup(title: _systems[system]!, names: names),
      );
    }
  }

  Future<void> _toggleSystem(String system) async {
    setState(() {
      if (_visibleSystems.contains(system)) {
        if (_visibleSystems.length > 1) _visibleSystems.remove(system);
      } else {
        _visibleSystems.add(system);
      }
      _activeSystem = system;
      _selectedKey = null;
      _quizTarget = null;
    });
    await _applyLayers();
  }

  void _onSelectionChanged(List<EntityData> parts) {
    if (!mounted) return;
    if (parts.isEmpty) {
      setState(() => _selectedKey = null);
      return;
    }
    final key = parts.last.name;
    setState(() => _selectedKey = key);
    _recordView(key);
    if (_quizTarget != null) {
      if (_quizTarget!['key'] == key) {
        setState(() {
          _quizCorrect++;
          _quizStep++;
          _quizTarget = _quizStep >= _quizLength ? null : _nextTarget();
        });
        if (_quizStep >= _quizLength) {
          _saveQuiz();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Spotter complete: $_quizCorrect/$_quizLength correct.'),
            backgroundColor: AtlasColors.success,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Correct identification. Next structure!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not quite. Keep exploring the model.')),
        );
      }
    }
  }

  Future<void> _recordView(String key) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('anatomy_progress').doc('${uid}_$key').set({
        'userId': uid, 'structureKey': key,
        'lastViewedAt': FieldValue.serverTimestamp(),
        'views': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _markReviewed(String key) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('anatomy_progress')
          .doc('${uid}_$key').set({
        'userId': uid,
        'structureKey': key,
        'reviewed': true,
        'reviewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Structure marked as reviewed.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save review progress.')),
        );
      }
    }
  }

  Map<String, String>? _nextTarget() {
    final source = _activeSystem == 'skeleton'
        ? detailedSkeletonCatalog
        : anatomyCatalog;
    final list = source.where((item) =>
      item['system'] == _activeSystem && item['system'] != 'joints' &&
      item['key'] != _selectedKey).toList();
    final pool = list.isEmpty
      ? detailedSkeletonCatalog
      : list;
    return pool[Random().nextInt(pool.length)];
  }

  void _startSpotter() {
    setState(() {
      _quizCorrect = 0;
      _quizStep = 0;
      _quizTarget = _nextTarget();
    });
  }

  Future<void> _saveQuiz() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('anatomy_progress')
        .doc('${uid}_spotter_${DateTime.now().millisecondsSinceEpoch}').set({
          'userId': uid, 'structureKey': 'spotter_quiz',
          'score': _quizCorrect, 'total': _quizLength,
          'completedAt': FieldValue.serverTimestamp(),
        });
    } catch (_) {}
  }

  Future<void> _openSearch() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AnatomySearchSheet(),
    );
    if (result == null) return;
    setState(() {
      _selectedKey = result['key'];
      _activeSystem = result['system'] ?? 'skeleton';
      _visibleSystems.add(_activeSystem);
    });
    await _applyLayers();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedKey == null ? null : _find(_selectedKey!);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(title: const Text('3D Anatomy Lab'), actions: [
        IconButton(onPressed: _openSearch, tooltip: 'Search structures',
          icon: const Icon(Icons.search_rounded)),
        IconButton(onPressed: _startSpotter, tooltip: 'Spotter challenge',
          icon: const Icon(Icons.quiz_outlined)),
        const SizedBox(width: 5),
      ]),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        _introCard(),
        const SizedBox(height: 14),
        _bodySelector(),
        const SizedBox(height: 12),
        _systemSelector(),
        if (_quizTarget != null) ...[
          const SizedBox(height: 12),
          _spotterCard(),
        ],
        const SizedBox(height: 12),
        _viewerCard(),
        const SizedBox(height: 14),
        if (selected != null) _structureDetails(selected),
        if (selected == null) _emptySelectionCard(),
        const SizedBox(height: 14),
        _learningTools(),
        const SizedBox(height: 12),
        const Text(
          'Whole-body models: Open Anatomy 3D (CC BY 4.0). Detailed skeleton: BodyParts3D via OrganUI Skeleton (CC BY-SA 2.1 Japan). BodyParts3D © The Database Center for Life Science. Educational use only; not for diagnosis.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AtlasColors.secondaryText, fontSize: 9, height: 1.45)),
      ]),
    );
  }

  Widget _introCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0D2748), Color(0xFF1D568A)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(22)),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.view_in_ar_rounded, color: Color(0xFF9CC9ED), size: 24),
        SizedBox(width: 9),
        Text('ATLAS ANATOMY EXPERIENCE', style: TextStyle(
          color: Color(0xFFB8D9F5), fontSize: 10, letterSpacing: 1.3,
          fontWeight: FontWeight.w900)),
      ]),
      SizedBox(height: 12),
      Text('Explore the human body in 3D', style: TextStyle(
        color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, height: 1.15)),
      SizedBox(height: 7),
      Text('Rotate, zoom, select structures and study each system layer by layer.',
        style: TextStyle(color: Color(0xFFD8E9F8), fontSize: 12, height: 1.5)),
    ]),
  );

  Widget _bodySelector() => Row(children: [
    Text(_activeSystem == 'skeleton' ? 'Detailed skeletal atlas' : 'Whole-body model', style: const TextStyle(
      color: AtlasColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
    const Spacer(),
    if (_activeSystem != 'skeleton') SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'male', label: Text('Male')),
        ButtonSegment(value: 'female', label: Text('Female')),
      ],
      selected: {_sex},
      onSelectionChanged: (value) => setState(() {
        _sex = value.first;
        _modelReady = false;
        _loadAttempt++;
      }),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
    ),
  ]);

  Widget _systemSelector() => SizedBox(height: 42, child: ListView(
    scrollDirection: Axis.horizontal,
    children: _systems.entries.map((entry) {
      final active = _activeSystem == entry.key;
      final visible = _visibleSystems.contains(entry.key);
      return Padding(
        padding: const EdgeInsets.only(right: 7),
        child: FilterChip(
          selected: active,
          avatar: Icon(visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 14, color: active ? Colors.white : AtlasColors.royalBlue),
          label: Text(entry.value),
          onSelected: (_) => _toggleSystem(entry.key),
          selectedColor: AtlasColors.navy,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(color: active ? Colors.white : AtlasColors.navy,
            fontWeight: FontWeight.w800, fontSize: 11),
          side: BorderSide(color: active ? AtlasColors.navy : AtlasColors.border)),
      );
    }).toList(),
  ));

  Widget _spotterCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFEAF4FF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFBFD8F2))),
    child: Row(children: [
      const Icon(Icons.center_focus_strong_rounded, color: AtlasColors.royalBlue, size: 25),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SPOTTER ${_quizStep + 1} OF $_quizLength', style: const TextStyle(
          color: AtlasColors.royalBlue, fontSize: 9, fontWeight: FontWeight.w900,
          letterSpacing: 1)),
        const SizedBox(height: 3),
        Text('Find: ${_quizTarget?['label'] ?? ''}', style: const TextStyle(
          color: AtlasColors.navy, fontSize: 14, fontWeight: FontWeight.w900)),
      ])),
      Text('$_quizCorrect/$_quizLength', style: const TextStyle(
        color: AtlasColors.navy, fontWeight: FontWeight.w900)),
      IconButton(onPressed: () => setState(() => _quizTarget = null),
        icon: const Icon(Icons.close_rounded, size: 19)),
    ]),
  );

  Widget _viewerCard() => Container(
    height: 390,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: const Color(0xFF07182C),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFF183A5C)),
      boxShadow: const [BoxShadow(color: Color(0x180B2745),
        blurRadius: 18, offset: Offset(0, 7))]),
    child: Stack(children: [
      Positioned.fill(child: Interactive3d(
        key: ValueKey('$_activeSystem-$_sex-$_loadAttempt'),
        controller: _controller,
        modelUrl: _activeSystem == 'skeleton'
            ? _skeletonModelUrl
            : (_sex == 'male' ? _maleModelUrl : _femaleModelUrl),
        defaultZoom: 1.35,
        backgroundColor: const Color(0xFF07182C),
        selectionColor: const [0.20, 0.66, 1.0, 1.0],
        preselectedEntities: _selectedKey == null ? const [] : [_selectedKey!],
        onSelectionChanged: _onSelectionChanged,
        onModelLoaded: () {
          if (!mounted) return;
          setState(() => _modelReady = true);
          _applyLayers();
        },
        loadingWidget: const Center(child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF8FC7F4)),
            SizedBox(height: 12),
            Text('Preparing anatomical model…',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        errorBuilder: (context, error) => Center(child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFF9CC9ED), size: 34),
            const SizedBox(height: 10),
            const Text('3D model could not be loaded', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: () => setState(() {
              _modelReady = false;
              _loadAttempt++;
            }), child: const Text('Retry')),
          ]),
        )),
      )),
      Positioned(top: 12, left: 12, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .42),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.touch_app_rounded, color: Color(0xFF9CC9ED), size: 14),
          SizedBox(width: 6),
          Text('DRAG TO ROTATE  •  PINCH TO ZOOM', style: TextStyle(
            color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900,
            letterSpacing: .5)),
        ]),
      )),
      Positioned(right: 10, bottom: 10, child: Column(children: [
        _viewerControl(Icons.add_rounded, () => _controller.zoomBy(.2)),
        const SizedBox(height: 6),
        _viewerControl(Icons.remove_rounded, () => _controller.zoomBy(-.2)),
        const SizedBox(height: 6),
        _viewerControl(Icons.center_focus_strong_rounded, () => _controller.resetCamera()),
      ])),
    ]),
  );

  Widget _viewerControl(IconData icon, VoidCallback action) => Material(
    color: Colors.white.withValues(alpha: .13), shape: const CircleBorder(),
    child: InkWell(customBorder: const CircleBorder(), onTap: action,
      child: SizedBox(width: 38, height: 38,
        child: Icon(icon, color: Colors.white, size: 19))),
  );

  Widget _structureDetails(Map<String, String> item) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('anatomy_content')
        .doc(item['key']).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final published = data['isPublished'] == true;
        final description = (data['description'] ?? '').toString();
        return Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AtlasColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item['label'] ?? 'Selected structure',
                style: const TextStyle(color: AtlasColors.navy,
                  fontSize: 18, fontWeight: FontWeight.w900))),
              IconButton(onPressed: () => setState(() => _selectedKey = null),
                icon: const Icon(Icons.close_rounded)),
            ]),
            Text('${_systems[item['system']] ?? item['system']}  •  ${item['category']}',
              style: const TextStyle(color: AtlasColors.royalBlue,
                fontSize: 10, fontWeight: FontWeight.w800)),
            if (published && (data['latinName'] ?? '').toString().isNotEmpty)
              _detail('LATIN NAME', data['latinName'].toString()),
            const SizedBox(height: 12),
            _detail('ANATOMICAL OVERVIEW', published && description.isNotEmpty
              ? description
              : 'This structure is part of the ${item['category']} group. Select it in the 3D model to explore its position and relationships. Detailed academy notes appear here when published by the teaching team.'),
            if (published && (data['function'] ?? '').toString().isNotEmpty)
              _detail('FUNCTION', data['function'].toString()),
            if (published && (data['clinicalRelevance'] ?? '').toString().isNotEmpty)
              _detail('CLINICAL CORRELATION', data['clinicalRelevance'].toString()),
            if (published && (data['bloodSupply'] ?? '').toString().isNotEmpty)
              _detail('BLOOD SUPPLY', data['bloodSupply'].toString()),
            if (published && (data['innervation'] ?? '').toString().isNotEmpty)
              _detail('INNERVATION', data['innervation'].toString()),
            Align(alignment: Alignment.centerRight, child: TextButton.icon(
              onPressed: () => _markReviewed(item['key']!),
              icon: const Icon(Icons.bookmark_added_outlined, size: 17),
              label: const Text('Mark reviewed'))),
          ]),
        );
      },
    );
  }

  Widget _detail(String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AtlasColors.royalBlue,
        fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text(body, style: const TextStyle(color: AtlasColors.charcoal,
        fontSize: 12, height: 1.55)),
    ]),
  );

  Widget _emptySelectionCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AtlasColors.border)),
    child: const Row(children: [
      Icon(Icons.ads_click_rounded, color: AtlasColors.royalBlue, size: 26),
      SizedBox(width: 12),
      Expanded(child: Text('Tap any named structure in the 3D model to open its anatomy notes.',
        style: TextStyle(color: AtlasColors.secondaryText, fontSize: 12, height: 1.5))),
    ]),
  );

  Widget _learningTools() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('LEARNING TOOLS', style: TextStyle(color: AtlasColors.navy,
      fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w900)),
    const SizedBox(height: 9),
    Row(children: [
      Expanded(child: _tool(Icons.search_rounded, 'Structure index',
        'Browse 242 bones and 147 body structures', _openSearch)),
      const SizedBox(width: 10),
      Expanded(child: _tool(Icons.quiz_rounded, 'Spotter practice',
        'Identify five structures', _startSpotter)),
    ]),
  ]);

  Widget _tool(IconData icon, String title, String subtitle, VoidCallback action) =>
    InkWell(onTap: action, borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtlasColors.border)),
        child: Row(children: [
          Icon(icon, color: AtlasColors.royalBlue, size: 24),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AtlasColors.navy,
              fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(
              color: AtlasColors.secondaryText, fontSize: 9)),
          ])),
        ]),
      ),
    );
}

class _AnatomySearchSheet extends StatefulWidget {
  const _AnatomySearchSheet();
  @override
  State<_AnatomySearchSheet> createState() => _AnatomySearchSheetState();
}

class _AnatomySearchSheetState extends State<_AnatomySearchSheet> {
  String query = '';
  String system = 'all';

  @override
  Widget build(BuildContext context) {
    final combined = <Map<String, String>>[
      ...detailedSkeletonCatalog,
      ...anatomyCatalog.where((item) => item['system'] != 'skeleton'),
    ];
    final results = combined.where((item) {
      final matches = query.isEmpty ||
        item['label']!.toLowerCase().contains(query.toLowerCase()) ||
        item['key']!.toLowerCase().contains(query.toLowerCase());
      return matches && (system == 'all' || item['system'] == system);
    }).toList();
    return SafeArea(child: Padding(
      padding: EdgeInsets.fromLTRB(18, 15, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
      child: SizedBox(height: MediaQuery.sizeOf(context).height * .78,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 42, height: 4,
            decoration: BoxDecoration(color: Colors.black12,
              borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 17),
          const Text('Anatomical structure index', style: TextStyle(
            color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search bone, organ, muscle or joint')),
          const SizedBox(height: 9),
          SizedBox(height: 38, child: ListView(scrollDirection: Axis.horizontal,
            children: [
              _filter('all', 'All'),
              ..._systems.entries.map((e) => _filter(e.key, e.value)),
            ])),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = results[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: AtlasColors.paleBlue,
                  child: Icon(item['system'] == 'skeleton'
                    ? Icons.accessibility_new_rounded : Icons.biotech_rounded,
                    color: AtlasColors.royalBlue, size: 19)),
                title: Text(item['label']!, style: const TextStyle(
                  color: AtlasColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
                subtitle: Text('${_systems[item['system']] ?? item['system']} • ${item['key']}',
                  style: const TextStyle(fontSize: 10)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, item),
              );
            },
          )),
        ]),
      ),
    ));
  }

  Widget _filter(String value, String label) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(label: Text(label, style: const TextStyle(fontSize: 10)),
      selected: system == value,
      onSelected: (_) => setState(() => system = value)),
  );
}
