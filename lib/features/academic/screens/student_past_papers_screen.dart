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
      appBar: AppBar(title: const Text('Past Papers')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AtlasColors.navy, AtlasColors.royalBlue],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.history_edu_rounded, color: AtlasColors.champagne, size: 32),
                SizedBox(height: 10),
                Text('Past Examination Papers', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Solve previous examination papers in a timed environment and review your performance.', style: TextStyle(color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('mcq_exam_sets')
                .where('trackType', isEqualTo: 'past_paper')
                .where('isPublished', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(padding: const EdgeInsets.all(18), child: Text('Past papers could not be loaded: ${snapshot.error}', style: const TextStyle(color: AtlasColors.error)));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text('No past papers have been published yet.', textAlign: TextAlign.center, style: TextStyle(color: AtlasColors.secondaryText)),
                );
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data();
                  final title = (data['name'] ?? 'Past Paper').toString();
                  final subject = (data['subjectName'] ?? 'Subject').toString();
                  final year = (data['paperYear'] ?? '').toString();
                  final duration = data['durationMinutes'] ?? 60;
                  return Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AtlasColors.paleBlue,
                        child: Icon(Icons.description_rounded, color: AtlasColors.royalBlue),
                      ),
                      title: Text(title, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
                      subtitle: Text('$subject • $year • $duration min', style: const TextStyle(color: AtlasColors.secondaryText)),
                      trailing: const Icon(Icons.play_circle_fill_rounded, color: AtlasColors.royalBlue),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentMcqPracticeScreen(examSetId: doc.id),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}