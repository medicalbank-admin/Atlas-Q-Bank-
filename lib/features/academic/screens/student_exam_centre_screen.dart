import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../mcqs/screens/student_mcq_practice_screen.dart';
import '../../../shared/widgets/medical_category_artwork.dart';

class StudentExamCentreScreen extends StatelessWidget {
  final String section;
  const StudentExamCentreScreen({super.key, required this.section});

  static const _titles = {
    'subject_exam': 'Subject-Wise Exams',
    'system_exam': 'System-Wise Exams',
    'subject_mock': 'Subject Mocks',
    'system_mock': 'System Mocks',
    'grand_mock': 'Grand Mocks',
    'mocks': 'Mock Exams',
  };

  @override
  Widget build(BuildContext context) {
    final title = _titles[section] ?? 'Examinations';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AtlasColors.ivory,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('mcq_exam_sets')
            .where('trackType', isEqualTo: 'structured')
            .where('isPublished', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message('Unable to load $title. Please try again.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final category = (data['examCategory'] ?? '').toString();
            return (section == 'mocks'
                        ? category.endsWith('_mock')
                        : category == section) &&
                    data['isActive'] != false;
          }).toList()
            ..sort((a, b) => (a.data()['name'] ?? '')
                .toString()
                .compareTo((b.data()['name'] ?? '').toString()));

          if (user == null) {
            return _message('Please sign in to view your exam progress.');
          }
          if (docs.isEmpty) {
            return _message('No published ${title.toLowerCase()} yet.');
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('mcq_attempts')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, attemptsSnapshot) {
              if (attemptsSnapshot.hasError) {
                return _message('Unable to load exam progress.');
              }
              if (!attemptsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final attempts = attemptsSnapshot.data!.docs;
              final groups = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

              if (section == 'mocks') {
                const labels = {
                  'subject_mock': 'Subject Mocks',
                  'system_mock': 'System Mocks',
                  'grand_mock': 'Grand Mocks',
                };
                for (final entry in labels.entries) {
                  final matching = docs
                      .where((doc) => doc.data()['examCategory'] == entry.key)
                      .toList();
                  if (matching.isNotEmpty) groups[entry.value] = matching;
                }
              } else {
                for (final doc in docs) {
                  final data = doc.data();
                  final name = (data['categoryName'] ??
                          data['subjectName'] ??
                          'Other')
                      .toString()
                      .trim();
                  groups.putIfAbsent(name.isEmpty ? 'Other' : name, () => []).add(doc);
                }
              }

              final entries = groups.entries.toList();
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: _intro(title, section),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = entries[index];
                          return _FolderCard(
                            title: entry.key,
                            count: entry.value.length,
                            category: entry.key,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _ExamFolderScreen(
                                  title: entry.key,
                                  docs: entry.value,
                                  attempts: attempts,
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: entries.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _message(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AtlasColors.secondaryText)),
        ),
      );

  Widget _intro(String title, String section) {
    final subtitle = section == 'subject_exam'
        ? 'Choose a subject to explore its examinations.'
        : section == 'system_exam'
            ? 'Choose a body system to explore its examinations.'
            : 'Choose a mock category to view available tests.';
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF174B7A), Color(0xFF2879B8)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x24123B68), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          const _GlossyMedicalIcon(
            icon: Icons.school_rounded,
            size: 54,
            light: Color(0xFF8EC8F4),
            dark: Color(0xFF2469A4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFFDCEEFF), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _folderIcon(String name, String section) {
    final value = name.toLowerCase();
    if (section == 'mocks') {
      if (value.contains('grand')) return Icons.workspace_premium_rounded;
      if (value.contains('system')) return Icons.account_tree_rounded;
      return Icons.assignment_rounded;
    }
    if (value.contains('cardio') || value.contains('heart')) return Icons.favorite_rounded;
    if (value.contains('respir')) return Icons.air_rounded;
    if (value.contains('neuro') || value.contains('brain')) return Icons.psychology_rounded;
    if (value.contains('anatom')) return Icons.accessibility_new_rounded;
    if (value.contains('surg')) return Icons.medical_services_rounded;
    if (value.contains('path')) return Icons.biotech_rounded;
    if (value.contains('physio')) return Icons.monitor_heart_rounded;
    if (value.contains('medicine')) return Icons.health_and_safety_rounded;
    if (value.contains('renal') || value.contains('urinary')) return Icons.water_drop_rounded;
    if (value.contains('gastro') || value.contains('digest')) return Icons.restaurant_rounded;
    if (value.contains('endocr')) return Icons.bubble_chart_rounded;
    return section == 'system_exam'
        ? Icons.account_tree_rounded
        : Icons.menu_book_rounded;
  }
}

class _ExamFolderScreen extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> attempts;

  const _ExamFolderScreen({
    required this.title,
    required this.docs,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AtlasColors.ivory,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Row(
                children: [
                  MedicalCategoryArtwork(category: title, size: 58),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: AtlasColors.navy,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        Text('${docs.length} available exam(s)',
                            style: const TextStyle(
                                color: AtlasColors.secondaryText, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.91,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ExamCard(
                  doc: docs[index],
                  attempts: attempts,
                ),
                childCount: docs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String title;
  final int count;
  final String category;
  final VoidCallback onTap;

  const _FolderCard({
    required this.title,
    required this.count,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFDCE8F2)),
            boxShadow: const [
              BoxShadow(color: Color(0x0B123B68), blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MedicalCategoryArtwork(category: category, size: 66),
              const SizedBox(height: 10),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AtlasColors.navy,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('$count exam(s)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AtlasColors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AtlasColors.royalBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> attempts;

  const _ExamCard({required this.doc, required this.attempts});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final examAttempts = attempts
        .where((attempt) => attempt.data()['examSetId'] == doc.id)
        .toList();
    final hasAttempt = examAttempts.isNotEmpty;
    final bestScore = hasAttempt
        ? examAttempts
            .map((attempt) =>
                (attempt.data()['percentage'] as num?)?.toDouble() ?? 0.0)
            .reduce((a, b) => a > b ? a : b)
        : 0.0;
    final configuredCount = (data['questionCount'] as num?)?.toInt();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentMcqPracticeScreen(examSetId: doc.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFDCE8F2)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A123B68), blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MedicalCategoryArtwork(
                    category: (data['categoryName'] ?? data['subjectName'] ?? data['name'] ?? '').toString(),
                    size: 46,
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded,
                      color: AtlasColors.royalBlue, size: 18),
                ],
              ),
              const SizedBox(height: 11),
              Text((data['name'] ?? 'Exam').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AtlasColors.navy,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('${data['durationMinutes'] ?? 60} min',
                  style: const TextStyle(
                      color: AtlasColors.secondaryText, fontSize: 11)),
              const SizedBox(height: 5),
              Text(
                configuredCount == null
                    ? 'MCQs included'
                    : '$configuredCount MCQs',
                style: const TextStyle(
                    color: AtlasColors.royalBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AtlasColors.paleBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hasAttempt ? 'Best: ${bestScore.round()}%' : 'Start exam',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AtlasColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glossy, dimensional medical icon treatment built with native Flutter
/// gradients, highlights and shadows so it remains crisp on every screen.
class _GlossyMedicalIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color light;
  final Color dark;

  const _GlossyMedicalIcon({
    required this.icon,
    required this.size,
    required this.light,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, dark],
        ),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Color(0x66FFFFFF),
            blurRadius: 3,
            offset: Offset(-2, -2),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.12,
            left: size * 0.18,
            child: Container(
              width: size * 0.34,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Icon(icon, size: size * 0.49, color: Colors.white,
              shadows: const [Shadow(color: Color(0x55304F70), blurRadius: 5, offset: Offset(0, 2))]),
        ],
      ),
    );
  }
}
