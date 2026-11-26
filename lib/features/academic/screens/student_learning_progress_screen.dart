import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/atlas_academy_app.dart';
import '../models/learning_resource_model.dart';

class StudentLearningProgressScreen extends StatefulWidget {
  final ValueChanged<LearningResourceModel> onOpen;
  const StudentLearningProgressScreen({super.key, required this.onOpen});
  @override
  State<StudentLearningProgressScreen> createState() => _StudentLearningProgressScreenState();
}

class _StudentLearningProgressScreenState extends State<StudentLearningProgressScreen> {
  int _weeklyGoal = 5;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _weeklyGoal = prefs.getInt('atlas_weekly_chapter_goal') ?? 5);
  }

  Future<void> _setGoal(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('atlas_weekly_chapter_goal', value);
    if (mounted) setState(() => _weeklyGoal = value);
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Please sign in to view your progress.')));
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('My Learning Progress'),
        backgroundColor: const Color(0xFFF4F7FB),
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Set weekly goal',
            onSelected: _setGoal,
            icon: const Icon(Icons.flag_outlined),
            itemBuilder: (_) => [3, 5, 7, 10, 14].map((v) =>
              PopupMenuItem(value: v, child: Text('$v chapters per week'))).toList(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('student_resource_progress')
          .where('userId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Learning analytics are temporarily unavailable. Check your connection and account permissions.', textAlign: TextAlign.center)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!.docs.map((d) => d.data()).toList();
          final started = rows.where((d) => ((d['progressPercent'] as num?)?.toDouble() ?? 0) > 0).toList();
          final completed = rows.where((d) => d['completed'] == true ||
            ((d['progressPercent'] as num?)?.toDouble() ?? 0) >= 99.5).toList();
          final bookmarked = rows.where((d) => d['isBookmarked'] == true).length;
          final now = DateTime.now();
          final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
          final weekly = completed.where((d) {
            final date = _date(d['completedAt']) ?? _date(d['lastReadAt']);
            return date != null && !date.isBefore(weekStart);
          }).length;
          final average = started.isEmpty ? 0.0 : started.fold<double>(0,
            (sum, d) => sum + ((d['progressPercent'] as num?)?.toDouble() ?? 0)) / started.length;
          final recent = List<Map<String, dynamic>>.from(rows)..sort((a, b) {
            final da = _date(a['lastReadAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final db = _date(b['lastReadAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });
          final subjectCounts = <String, int>{};
          for (final row in recent.take(8)) {
            final subject = (row['subjectId'] ?? '').toString();
            if (subject.isNotEmpty) subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
          }
          final sortedSubjects = subjectCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final preferredSubject = sortedSubjects.isEmpty ? null : sortedSubjects.first.key;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _weeklyGoalCard(weekly),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _metric('Chapters started', '${started.length}', Icons.menu_book_rounded),
                  _metric('Completed', '${completed.length}', Icons.task_alt_rounded),
                  _metric('Bookmarks', '$bookmarked', Icons.bookmark_rounded),
                  _metric('Average progress', '${average.toStringAsFixed(0)}%', Icons.insights_rounded),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Continue your momentum', style: TextStyle(
                color: AtlasColors.navy, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              _activityCard(recent),
              const SizedBox(height: 22),
              const Text('Recommended next chapters', style: TextStyle(
                color: AtlasColors.navy, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('learning_resources')
                  .where('isPublished', isEqualTo: true).snapshots(),
                builder: (context, resources) {
                  if (resources.hasError) return const Text('Recommendations are unavailable right now.');
                  if (!resources.hasData) return const LinearProgressIndicator();
                  final seen = rows.map((d) => (d['resourceId'] ?? '').toString()).toSet();
                  final candidates = resources.data!.docs.map(LearningResourceModel.fromFirestore)
                    .where((r) => r.type == LearningResourceType.text && !seen.contains(r.id)).toList();
                  candidates.sort((a, b) {
                    final am = preferredSubject != null && a.subjectId == preferredSubject ? 0 : 1;
                    final bm = preferredSubject != null && b.subjectId == preferredSubject ? 0 : 1;
                    if (am != bm) return am.compareTo(bm);
                    return b.updatedAt.compareTo(a.updatedAt);
                  });
                  if (candidates.isEmpty) return _empty('You have started all currently published chapters. Great work!');
                  return Column(children: candidates.take(5).map((r) => Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2EAF3))),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFE8F1FC),
                        child: Icon(Icons.auto_stories_rounded, color: AtlasColors.royalBlue)),
                      title: Text(r.title, style: const TextStyle(
                        color: AtlasColors.navy, fontWeight: FontWeight.w800)),
                      subtitle: Text([r.systemName, r.description].where((v) => v.trim().isNotEmpty).join(' • '),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                      onTap: () => widget.onOpen(r),
                    ),
                  )).toList());
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _weeklyGoalCard(int completed) {
    final ratio = (completed / _weeklyGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF102B49), Color(0xFF1C5B8D)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('THIS WEEK’S STUDY GOAL', style: TextStyle(
            color: Color(0xFFB9DDF7), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900))),
          Text('$completed / $_weeklyGoal chapters', style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ]),
        const SizedBox(height: 13),
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: ratio, minHeight: 9,
            backgroundColor: Colors.white24, color: const Color(0xFF8BD3B5))),
        const SizedBox(height: 10),
        Text(completed >= _weeklyGoal ? 'Weekly goal achieved. Excellent work!' :
          '${_weeklyGoal - completed} more chapter(s) to reach your weekly goal.',
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }

  Widget _metric(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2EAF3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AtlasColors.royalBlue, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: AtlasColors.navy, fontSize: 21, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
  );

  Widget _activityCard(List<Map<String, dynamic>> rows) {
    final active = rows.where((r) =>
      ((r['progressPercent'] as num?)?.toDouble() ?? 0) > 0).take(4).toList();
    if (active.isEmpty) return _empty('Open a chapter to begin building your study history.');
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE2EAF3))),
      child: Column(children: active.map((r) {
        final percent = ((r['progressPercent'] as num?)?.toDouble() ?? 0).clamp(0, 100);
        return ListTile(
          dense: true,
          leading: const Icon(Icons.history_rounded, color: AtlasColors.royalBlue),
          title: Text((r['resourceTitle'] ?? r['resourceId'] ?? 'Chapter').toString(),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800)),
          subtitle: Padding(padding: const EdgeInsets.only(top: 5),
            child: LinearProgressIndicator(value: percent / 100, minHeight: 5)),
          trailing: Text('${percent.toStringAsFixed(0)}%'),
        );
      }).toList()),
    );
  }

  Widget _empty(String text) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2EAF3))),
    child: Text(text, style: const TextStyle(color: AtlasColors.secondaryText)),
  );
}
