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
          final dailyTotals = <String, int>{};
          for (final row in rows) {
            final daily = row['dailyReadingSeconds'];
            if (daily is Map) {
              for (final entry in daily.entries) {
                final seconds = (entry.value as num?)?.toInt() ?? 0;
                dailyTotals[entry.key.toString()] = (dailyTotals[entry.key.toString()] ?? 0) + seconds;
              }
            }
          }
          String dayKey(DateTime date) =>
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final today = DateTime(now.year, now.month, now.day);
          var streak = 0;
          var streakDate = dailyTotals[dayKey(today)] != null && dailyTotals[dayKey(today)]! > 0
            ? today : today.subtract(const Duration(days: 1));
          while ((dailyTotals[dayKey(streakDate)] ?? 0) > 0 && streak < 366) {
            streak++;
            streakDate = streakDate.subtract(const Duration(days: 1));
          }
          final totalSeconds = dailyTotals.values.fold<int>(0, (sum, value) => sum + value);

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
              const SizedBox(height: 14),
              _studyActivityCard(dailyTotals, streak, totalSeconds),
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


  Widget _studyActivityCard(Map<String, int> daily, int streak, int totalSeconds) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final lastSeven = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final maxDaily = lastSeven.map((d) => daily[key(d)] ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
    final last28 = List.generate(28, (i) => today.subtract(Duration(days: 27 - i)));
    final minutes = totalSeconds ~/ 60;
    final duration = minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Study consistency', style: TextStyle(
              color: AtlasColors.navy, fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text('$duration reading time recorded', style: const TextStyle(
              color: AtlasColors.secondaryText, fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFF3DF), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFE58B26), size: 19),
              const SizedBox(width: 4),
              Text('$streak day streak', style: const TextStyle(
                color: AtlasColors.navy, fontSize: 11, fontWeight: FontWeight.w900)),
            ])),
        ]),
        const SizedBox(height: 18),
        const Text('Last 7 days', style: TextStyle(
          color: AtlasColors.navy, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SizedBox(height: 94, child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: lastSeven.map((date) {
            final seconds = daily[key(date)] ?? 0;
            final fraction = maxDaily == 0 ? 0.0 : seconds / maxDaily;
            final height = seconds == 0 ? 4.0 : 8.0 + fraction * 48;
            const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
            return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(seconds == 0 ? '' : '${(seconds / 60).ceil()}m',
                style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 9)),
              const SizedBox(height: 4),
              Container(height: height, width: 15,
                decoration: BoxDecoration(
                  color: seconds == 0 ? const Color(0xFFE8EEF5) : AtlasColors.royalBlue,
                  borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 5),
              Text(labels[date.weekday - 1], style: const TextStyle(
                color: AtlasColors.secondaryText, fontSize: 10, fontWeight: FontWeight.w700)),
            ]));
          }).toList(),
        )),
        const SizedBox(height: 17),
        const Text('28-day activity calendar', style: TextStyle(
          color: AtlasColors.navy, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: last28.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
          itemBuilder: (context, index) {
            final date = last28[index];
            final seconds = daily[key(date)] ?? 0;
            final shade = seconds == 0 ? const Color(0xFFEFF3F7) :
              seconds < 300 ? const Color(0xFFC9DDF4) :
              seconds < 1200 ? const Color(0xFF7EACDC) : const Color(0xFF245F98);
            return Tooltip(message: '${date.month}/${date.day}: ${(seconds / 60).floor()} min',
              child: Container(decoration: BoxDecoration(
                color: shade, borderRadius: BorderRadius.circular(5))));
          },
        ),
        const SizedBox(height: 9),
        const Row(children: [
          Text('Less', style: TextStyle(color: AtlasColors.secondaryText, fontSize: 10)),
          SizedBox(width: 6),
          _ActivityLegendDot(color: Color(0xFFEFF3F7)),
          SizedBox(width: 4),
          _ActivityLegendDot(color: Color(0xFFC9DDF4)),
          SizedBox(width: 4),
          _ActivityLegendDot(color: Color(0xFF7EACDC)),
          SizedBox(width: 4),
          _ActivityLegendDot(color: Color(0xFF245F98)),
          SizedBox(width: 6),
          Text('More', style: TextStyle(color: AtlasColors.secondaryText, fontSize: 10)),
        ]),
      ]),
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
        final resourceId = (r['resourceId'] ?? '').toString();
        final subject = (r['subjectName'] ?? r['systemName'] ?? '').toString();
        final isComplete = r['completed'] == true || percent >= 99.5;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8F1FC),
            child: Icon(isComplete ? Icons.task_alt_rounded : Icons.history_rounded,
              color: isComplete ? const Color(0xFF25845D) : AtlasColors.royalBlue,
              size: 19),
          ),
          title: Text((r['resourceTitle'] ?? resourceId.isNotEmpty ? r['resourceTitle'] ?? resourceId : 'Chapter').toString(),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (subject.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 5),
              child: Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 10))),
            LinearProgressIndicator(value: percent / 100, minHeight: 5),
          ]),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${percent.toStringAsFixed(0)}%',
              style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800)),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AtlasColors.secondaryText),
          ]),
          onTap: resourceId.isEmpty ? null : () async {
            try {
              final doc = await FirebaseFirestore.instance
                  .collection('learning_resources').doc(resourceId).get();
              if (!doc.exists || doc.data()?['isPublished'] != true) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This chapter is no longer published.')));
                return;
              }
              final resource = LearningResourceModel.fromFirestore(doc);
              if (resource.type != LearningResourceType.text) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This item is not a textbook chapter.')));
                return;
              }
              widget.onOpen(resource);
            } catch (_) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unable to reopen this chapter. Please try again.')));
            }
          },
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

class _ActivityLegendDot extends StatelessWidget {
  final Color color;
  const _ActivityLegendDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 11, height: 11,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)));
}
