import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../data/anatomy_catalog.dart';

class AdminAnatomyManagementScreen extends StatefulWidget {
  const AdminAnatomyManagementScreen({super.key});
  @override
  State<AdminAnatomyManagementScreen> createState() => _AdminAnatomyManagementScreenState();
}

class _AdminAnatomyManagementScreenState extends State<AdminAnatomyManagementScreen> {
  String query = '';
  String system = 'all';

  @override
  Widget build(BuildContext context) {
    final items = anatomyCatalog.where((item) {
      final matches = query.isEmpty || item['label']!.toLowerCase().contains(query.toLowerCase());
      return matches && (system == 'all' || item['system'] == system);
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(title: const Text('Anatomy Content Management')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D2748), Color(0xFF1D568A)]),
              borderRadius: BorderRadius.circular(18)),
            child: const Row(children: [
              Icon(Icons.view_in_ar_rounded, color: Color(0xFFB8D9F5), size: 30),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('3D Anatomy Atlas', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 16)),
                SizedBox(height: 4),
                Text('Publish structure explanations, Latin names and clinical correlations for students.',
                  style: TextStyle(color: Color(0xFFD8E9F8), fontSize: 11, height: 1.45)),
              ])),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Find a structure to edit')),
        ),
        SizedBox(height: 42, child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            _filter('all', 'All'),
            ...const [
              ('skeleton', 'Skeletal'), ('organs', 'Organs'), ('muscles', 'Muscles'),
              ('vessels', 'Vessels'), ('nerves', 'Nerves'), ('joints', 'Joints'), ('skin', 'Skin'),
            ].map((e) => _filter(e.$1, e.$2)),
          ],
        )),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 7),
          itemBuilder: (context, index) {
            final item = items[index];
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('anatomy_content').doc(item['key']).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? const <String, dynamic>{};
                final published = data['isPublished'] == true;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AtlasColors.border)),
                    leading: const CircleAvatar(backgroundColor: AtlasColors.paleBlue,
                      child: Icon(Icons.biotech_rounded, color: AtlasColors.royalBlue, size: 19)),
                    title: Text(item['label']!, style: const TextStyle(color: AtlasColors.navy,
                      fontSize: 12, fontWeight: FontWeight.w900)),
                    subtitle: Text(published ? 'Published to students' : 'Draft • not visible to students',
                      style: TextStyle(fontSize: 10,
                        color: published ? AtlasColors.success : AtlasColors.secondaryText)),
                    trailing: const Icon(Icons.edit_outlined, color: AtlasColors.royalBlue),
                    onTap: () => _editStructure(item, data),
                  ),
                );
              },
            );
          },
        )),
      ]),
    );
  }

  Widget _filter(String value, String label) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(label: Text(label, style: const TextStyle(fontSize: 10)),
      selected: system == value, onSelected: (_) => setState(() => system = value)),
  );

  Future<void> _editStructure(Map<String, String> item, Map<String, dynamic> existing) async {
    final latin = TextEditingController(text: existing['latinName'] ?? '');
    final description = TextEditingController(text: existing['description'] ?? '');
    final function = TextEditingController(text: existing['function'] ?? '');
    final clinical = TextEditingController(text: existing['clinicalRelevance'] ?? '');
    final blood = TextEditingController(text: existing['bloodSupply'] ?? '');
    final nerves = TextEditingController(text: existing['innervation'] ?? '');
    bool published = existing['isPublished'] == true;
    final formKey = GlobalKey<FormState>();
    final save = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
            child: SizedBox(height: MediaQuery.sizeOf(context).height * .84,
              child: Form(key: formKey, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['label']!, style: const TextStyle(color: AtlasColors.navy,
                    fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('Structure ID: ${item['key']}', style: const TextStyle(
                    color: AtlasColors.secondaryText, fontSize: 10)),
                  const SizedBox(height: 12),
                  Expanded(child: ListView(children: [
                    _field(latin, 'Latin / anatomical name'),
                    _field(description, 'Anatomical overview', lines: 3),
                    _field(function, 'Function', lines: 3),
                    _field(clinical, 'Clinical relevance', lines: 3),
                    _field(blood, 'Blood supply', lines: 2),
                    _field(nerves, 'Innervation', lines: 2),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Publish to active students',
                        style: TextStyle(fontWeight: FontWeight.w800,
                          color: AtlasColors.navy, fontSize: 13)),
                      value: published,
                      onChanged: (value) => setSheetState(() => published = value)),
                  ])),
                  SizedBox(width: double.infinity, child: FilledButton.icon(
                    onPressed: () {
                      if (formKey.currentState!.validate()) Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save anatomy content'))),
                ],
              )),
            ),
          ),
        ),
      ),
    );
    if (save == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('anatomy_content').doc(item['key']).set({
        'structureKey': item['key'], 'label': item['label'], 'system': item['system'],
        'latinName': latin.text.trim(), 'description': description.text.trim(),
        'function': function.text.trim(), 'clinicalRelevance': clinical.text.trim(),
        'bloodSupply': blood.text.trim(), 'innervation': nerves.text.trim(),
        'isPublished': published, 'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anatomy content saved.')));
    }
  }

  Widget _field(TextEditingController controller, String label, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: TextFormField(controller: controller, minLines: lines, maxLines: lines,
      decoration: InputDecoration(labelText: label)),
  );
}
