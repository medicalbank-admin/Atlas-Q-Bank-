import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../advanced_learning/services/push_notification_service.dart';

class AdminClinicalCasesScreen extends StatefulWidget {
  const AdminClinicalCasesScreen({super.key});
  @override
  State<AdminClinicalCasesScreen> createState() => _AdminClinicalCasesScreenState();
}

class _AdminClinicalCasesScreenState extends State<AdminClinicalCasesScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  bool authorized = false;
  bool checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final user = FirebaseAuth.instance.currentUser;
    var allowed = false;
    if (user != null) {
      try {
        allowed = (await user.getIdTokenResult(true)).claims?['admin'] == true;
      } catch (_) {}
    }
    if (mounted) setState(() { authorized = allowed; checking = false; });
  }

  Future<void> _form({String? id, Map<String, dynamic>? data}) async {
    final existing = data ?? <String, dynamic>{};
    final title = TextEditingController(text: (existing['title'] ?? '').toString());
    final specialty = TextEditingController(text: (existing['specialty'] ?? '').toString());
    final difficulty = TextEditingController(text: (existing['difficulty'] ?? 'Intermediate').toString());
    final summary = TextEditingController(text: (existing['summary'] ?? '').toString());
    final scenario = TextEditingController(text: (existing['scenario'] ?? '').toString());
    final history = TextEditingController(text: (existing['history'] ?? '').toString());
    final vitals = TextEditingController(text: (existing['vitals'] ?? '').toString());
    final investigations = TextEditingController(text: (existing['investigations'] ?? '').toString());
    final findings = TextEditingController(text: (existing['findings'] ?? '').toString());
    final management = TextEditingController(text: (existing['management'] ?? '').toString());
    final questionText = TextEditingController();
    final rawQuestions = existing['questions'];
    if (rawQuestions is List) {
      questionText.text = rawQuestions.whereType<Map>().map((q) {
        final options = q['options'] is List ? (q['options'] as List).join('~') : '';
        return '${q['question']}|$options|${q['correctAnswer']}|${q['explanation']}';
      }).join('\n');
    }
    var published = existing['isPublished'] == true;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(id == null ? 'Create clinical case' : 'Edit clinical case'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(title, 'Case title', required: true),
                    _field(specialty, 'Specialty / subject', required: true),
                    _field(difficulty, 'Difficulty'),
                    _field(summary, 'Short case summary', lines: 2),
                    _field(scenario, 'Patient presentation / scenario', lines: 4),
                    _field(history, 'History and examination', lines: 4),
                    _field(vitals, 'Vitals', lines: 3),
                    _field(investigations, 'Investigations / laboratory results', lines: 4),
                    _field(findings, 'Clinical findings', lines: 4),
                    _field(management, 'Management, learning points and debrief', lines: 5),
                    _field(questionText, 'Decision questions: question|optionA~optionB~optionC~optionD|correct letter|explanation (one per line)', lines: 5),
                    SwitchListTile(
                      value: published,
                      onChanged: (value) => setDialogState(() => published = value),
                      title: const Text('Publish to eligible students'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final questions = <Map<String, dynamic>>[];
                for (final line in questionText.text.split('\n')) {
                  if (line.trim().isEmpty) continue;
                  final parts = line.split('|');
                  if (parts.length < 4) continue;
                  final options = parts[1].split('~').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
                  final correct = parts[2].trim().toUpperCase();
                  if (options.length == 4 && ['A', 'B', 'C', 'D'].contains(correct)) {
                    questions.add({
                      'question': parts[0].trim(),
                      'options': options,
                      'correctAnswer': correct,
                      'explanation': parts.sublist(3).join('|').trim(),
                    });
                  }
                }
                final payload = <String, dynamic>{
                  'title': title.text.trim(),
                  'specialty': specialty.text.trim(),
                  'difficulty': difficulty.text.trim(),
                  'summary': summary.text.trim(),
                  'scenario': scenario.text.trim(),
                  'history': history.text.trim(),
                  'vitals': vitals.text.trim(),
                  'investigations': investigations.text.trim(),
                  'findings': findings.text.trim(),
                  'management': management.text.trim(),
                  'questions': questions,
                  'isPublished': published,
                  'updatedAt': FieldValue.serverTimestamp(),
                  'updatedBy': FirebaseAuth.instance.currentUser?.uid,
                };
                try {
                  if (id == null) {
                    payload['createdAt'] = FieldValue.serverTimestamp();
                    payload['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
                    await db.collection('clinical_cases').add(payload);
                  } else {
                    await db.collection('clinical_cases').doc(id).update(payload);
                  }
                  if (published && existing['isPublished'] != true) {
                    try { await PushNotificationService().sendCampaign(notificationId: 'clinical_case_' + (id ?? 'new'), title: 'New clinical case available', body: title.text.trim() + ' is now available in Clinical Case-Based Learning.', destination: 'clinical_cases', audience: 'all'); } catch (_) {}
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clinical case saved.')),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Save failed: $error')),
                    );
                  }
                }
              },
              child: const Text('Save case'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    specialty.dispose();
    difficulty.dispose();
    summary.dispose();
    scenario.dispose();
    history.dispose();
    vitals.dispose();
    investigations.dispose();
    findings.dispose();
    management.dispose();
    questionText.dispose();
  }

  Widget _field(TextEditingController controller, String label, {int lines = 1, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        minLines: lines,
        maxLines: lines,
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
      ),
    );
  }

  Future<void> _delete(String id) async {
    await db.collection('clinical_cases').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!authorized) return const Scaffold(body: Center(child: Text('Administrator access required.')));
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(title: const Text('Clinical Case Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('Create case'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('clinical_cases').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No clinical cases created yet.'));
          return ListView(
            padding: const EdgeInsets.all(15),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AtlasColors.navy, AtlasColors.royalBlue]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Build structured clinical scenarios with history, examination, investigations, decision questions, explanations and a management debrief. Drafts stay private until published.',
                  style: TextStyle(color: Colors.white, height: 1.5),
                ),
              ),
              const SizedBox(height: 13),
              ...docs.map((doc) {
                final item = doc.data();
                final isPublished = item['isPublished'] == true;
                return Card(
                  child: ListTile(
                    title: Text((item['title'] ?? 'Untitled case').toString(), style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
                    subtitle: Text('${item['specialty'] ?? 'General'} • ${isPublished ? 'Published' : 'Draft'}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _form(id: doc.id, data: item);
                        if (value == 'delete') _delete(doc.id);
                        if (value == 'publish') {
                          db.collection('clinical_cases').doc(doc.id).update({
                            'isPublished': !isPublished,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'publish', child: Text(isPublished ? 'Unpublish' : 'Publish')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class AdminStudentSupportScreen extends StatefulWidget {
  const AdminStudentSupportScreen({super.key});
  @override
  State<AdminStudentSupportScreen> createState() => _AdminStudentSupportScreenState();
}

class _AdminStudentSupportScreenState extends State<AdminStudentSupportScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  bool authorized = false;
  bool checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final user = FirebaseAuth.instance.currentUser;
    var allowed = false;
    if (user != null) {
      try {
        allowed = (await user.getIdTokenResult(true)).claims?['admin'] == true;
      } catch (_) {}
    }
    if (mounted) setState(() { authorized = allowed; checking = false; });
  }

  Future<void> _reply(String id, Map<String, dynamic> data) async {
    final controller = TextEditingController(text: (data['reply'] ?? '').toString());
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Teacher response'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 7,
          decoration: const InputDecoration(hintText: 'Write an educational response…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Send reply')),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      await db.collection('teacher_questions').doc(id).update({
        'reply': value,
        'status': 'answered',
        'repliedBy': FirebaseAuth.instance.currentUser?.uid,
        'repliedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final studentUid = (data['userId'] ?? '').toString();
      if (studentUid.isNotEmpty) {
        try { await PushNotificationService().sendCampaign(notificationId: 'teacher_reply_' + id, title: 'Your teacher has replied', body: 'Open Ask a Teacher to read the response to your question.', destination: 'ask_teacher', audience: 'selected', userIds: [studentUid]); } catch (_) {}
      }
    }
  }

  Future<void> _moderate(String id, String status) async {
    await db.collection('forum_posts').doc(id).update({
      'status': status,
      'moderatedBy': FirebaseAuth.instance.currentUser?.uid,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!authorized) return const Scaffold(body: Center(child: Text('Administrator access required.')));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AtlasColors.ivory,
        appBar: AppBar(
          title: const Text('Student Community & Support'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Teacher questions'),
            Tab(text: 'Discussion moderation'),
          ]),
        ),
        body: TabBarView(children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('teacher_questions').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = [...snapshot.data!.docs]..sort((a, b) {
                final av = a.data()['createdAt'];
                final bv = b.data()['createdAt'];
                return (bv is Timestamp ? bv : Timestamp(0, 0))
                    .compareTo(av is Timestamp ? av : Timestamp(0, 0));
              });
              return ListView(
                padding: const EdgeInsets.all(14),
                children: docs.map((doc) {
                  final item = doc.data();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['subject'] ?? 'Question'} • ${item['studentName'] ?? 'Student'}', style: const TextStyle(color: AtlasColors.royalBlue, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 7),
                          Text((item['question'] ?? '').toString(), style: const TextStyle(color: AtlasColors.charcoal, height: 1.5)),
                          if ((item['reply'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Current reply: ${item['reply']}', style: const TextStyle(color: AtlasColors.success)),
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: () => _reply(doc.id, item),
                              icon: const Icon(Icons.reply),
                              label: Text(item['status'] == 'answered' ? 'Update reply' : 'Reply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('forum_posts').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = [...snapshot.data!.docs]..sort((a, b) {
                final av = a.data()['createdAt'];
                final bv = b.data()['createdAt'];
                return (bv is Timestamp ? bv : Timestamp(0, 0))
                    .compareTo(av is Timestamp ? av : Timestamp(0, 0));
              });
              return ListView(
                padding: const EdgeInsets.all(14),
                children: docs.map((doc) {
                  final item = doc.data();
                  return Card(
                    child: ListTile(
                      title: Text((item['title'] ?? '').toString(), style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
                      subtitle: Text('${item['authorName'] ?? 'Student'} • ${item['status'] ?? 'published'}\n${item['body'] ?? ''}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => _moderate(doc.id, value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'published', child: Text('Approve / publish')),
                          PopupMenuItem(value: 'hidden', child: Text('Hide')),
                          PopupMenuItem(value: 'removed', child: Text('Remove')),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }
}
