import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../mcqs/screens/student_mcq_practice_screen.dart';

class StudentPastPapersScreen extends StatelessWidget {
  const StudentPastPapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: const Text('Past Papers'),
        backgroundColor: AtlasColors.ivory,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('mcq_exam_sets')
            .where('trackType', isEqualTo: 'past_paper')
            .where('isPublished', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Past papers could not be loaded.',
                  style: TextStyle(color: AtlasColors.error)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs
              .where((doc) => doc.data()['isActive'] != false)
              .toList()
            ..sort((a, b) {
              final ay = (a.data()['paperYear'] ?? '').toString();
              final by = (b.data()['paperYear'] ?? '').toString();
              return by.compareTo(ay);
            });

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF174B7A), Color(0xFF2879B8)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x24123B68),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const _PastPaperGlossyIcon(),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Past Examination Papers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                docs.isEmpty
                                    ? 'Practice with previous examination papers.'
                                    : '${docs.length} published paper(s) ready to practise.',
                                style: const TextStyle(
                                  color: Color(0xFFDCEEFF),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (docs.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No past papers have been published yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AtlasColors.secondaryText),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final title = (data['name'] ?? 'Past Paper').toString();
                        final subject = (data['subjectName'] ?? 'Subject').toString();
                        final year = (data['paperYear'] ?? '').toString();
                        final duration = data['durationMinutes'] ?? 60;

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(19),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(19),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentMcqPracticeScreen(
                                  examSetId: doc.id,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(color: AtlasColors.border),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A123B68),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const _PastPaperGlossyIcon(size: 42),
                                      const Spacer(),
                                      const Icon(
                                        Icons.arrow_outward_rounded,
                                        color: AtlasColors.royalBlue,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AtlasColors.navy,
                                      fontSize: 13,
                                      height: 1.25,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    [subject, if (year.isNotEmpty) year].join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AtlasColors.secondaryText,
                                      fontSize: 11,
                                      height: 1.3,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$duration min',
                                    style: const TextStyle(
                                      color: AtlasColors.secondaryText,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: AtlasColors.paleBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Start paper',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AtlasColors.navy,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PastPaperGlossyIcon extends StatelessWidget {
  final double size;
  const _PastPaperGlossyIcon({this.size = 58});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9BCDF2), Color(0xFF2469A4)],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x552469A4),
            blurRadius: 11,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        Icons.history_edu_rounded,
        color: Colors.white,
        size: size * 0.5,
        shadows: const [
          Shadow(color: Color(0x55304F70), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
