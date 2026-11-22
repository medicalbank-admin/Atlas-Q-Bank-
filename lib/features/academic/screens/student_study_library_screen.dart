import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/atlas_academy_app.dart';
import '../models/learning_resource_model.dart';

class StudentStudyLibraryScreen extends StatefulWidget {
  const StudentStudyLibraryScreen({super.key});
  @override
  State<StudentStudyLibraryScreen> createState() => _StudentStudyLibraryScreenState();
}

class _StudentStudyLibraryScreenState extends State<StudentStudyLibraryScreen> {
  String? yearId, subjectId, topicId;
  String yearName = '', subjectName = '', topicName = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F7FF),
    appBar: AppBar(title: const Text('Study Library'), backgroundColor: Colors.white, foregroundColor: AtlasColors.navy, elevation: 0, scrolledUnderElevation: 0),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 22), children: [
      _banner(),
      const SizedBox(height: 18),
      if (yearId == null) _years()
      else if (subjectId == null) _subjects()
      else if (topicId == null) _topics()
      else _resources(),
    ]),
  );

  Widget _banner() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFE4F0FF), Color(0xFFD5E8FF)]),
      borderRadius: BorderRadius.circular(19),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.local_library_rounded, color: AtlasColors.royalBlue, size: 30),
      const SizedBox(height: 10),
      const Text('Your Study Library', style: TextStyle(color: AtlasColors.navy, fontSize: 21, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text([yearName, subjectName, topicName].where((e) => e.isNotEmpty).join('  •  ').isEmpty
        ? 'Browse published notes, videos and learning materials.'
        : [yearName, subjectName, topicName].where((e) => e.isNotEmpty).join('  •  '),
        style: const TextStyle(color: const Color(0xFF526B87), height: 1.5)),
    ]),
  );

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: AtlasColors.secondaryText)),
    ]),
  );

  Widget _loadingOrError(AsyncSnapshot snapshot) {
    if (snapshot.hasError) return const Padding(
      padding: EdgeInsets.all(18),
      child: Text('Unable to load learning materials. Please check your connection or contact the academy.',
        style: TextStyle(color: AtlasColors.error)),
    );
    return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
  }

  Widget _years() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('Choose academic year', 'Select your MBBS year to browse its subjects.'),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: FirebaseFirestore.instance.collection('academic_years').snapshots(),
      builder: (c,s) {
        if (!s.hasData) return _loadingOrError(s);
        final docs=s.data!.docs;
        if(docs.isEmpty) return _empty('No academic years have been added yet.');
        return Column(children: docs.map((d) => _tile(
          (d.data()['name'] ?? d.data()['title'] ?? 'Academic year').toString(),
          'Browse study materials',
          Icons.school_outlined,
          () => setState(() { yearId=d.id; yearName=(d.data()['name'] ?? d.data()['title'] ?? '').toString(); }),
        )).toList());
      },
    ),
  ]);

  Widget _subjects() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _back('Academic years', () => setState(() { yearId=null; subjectId=null; topicId=null; })),
    _heading('Subjects', yearName),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: FirebaseFirestore.instance.collection('academic_subjects').where('yearId',isEqualTo:yearId).snapshots(),
      builder: (c,s) {
        if(!s.hasData)return _loadingOrError(s);
        if(s.data!.docs.isEmpty)return _empty('No subjects are available for this academic year yet.');
        return Column(children:s.data!.docs.map((d)=>_tile((d.data()['name']??'Subject').toString(),'Open topics',Icons.menu_book_rounded,()=>setState(() { subjectId=d.id; subjectName=(d.data()['name']??'').toString(); }))).toList());
      },
    ),
  ]);

  Widget _topics() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _back('Subjects', () => setState(() { subjectId=null; topicId=null; })),
    _heading('Topics', subjectName),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: FirebaseFirestore.instance.collection('academic_topics').where('yearId',isEqualTo:yearId).where('subjectId',isEqualTo:subjectId).snapshots(),
      builder: (c,s) {
        if(!s.hasData)return _loadingOrError(s);
        if(s.data!.docs.isEmpty)return _empty('No topics are available for this subject yet.');
        return Column(children:s.data!.docs.map((d)=>_tile((d.data()['title']??d.data()['name']??'Topic').toString(),'View learning resources',Icons.topic_rounded,()=>setState(() { topicId=d.id; topicName=(d.data()['title']??d.data()['name']??'').toString(); }))).toList());
      },
    ),
  ]);

  Widget _resources() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _back('Topics', () => setState(()=>topicId=null)),
    _heading('Learning materials', topicName),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: FirebaseFirestore.instance.collection('learning_resources')
        .where('yearId',isEqualTo:yearId).where('subjectId',isEqualTo:subjectId)
        .where('topicId',isEqualTo:topicId).where('isPublished',isEqualTo:true).snapshots(),
      builder: (c,s) {
        if(!s.hasData)return _loadingOrError(s);
        final docs=s.data!.docs;
        if(docs.isEmpty)return _empty('No published materials are available in this topic yet.');
        return Column(children:docs.map((d){
          final r=LearningResourceModel.fromFirestore(d);
          return _tile(r.title,r.description.isEmpty?r.type.name:r.description,_icon(r.type),()=>_openResource(r));
        }).toList());
      },
    ),
  ]);

  IconData _icon(LearningResourceType t) => switch(t) {
    LearningResourceType.pdf => Icons.picture_as_pdf_rounded,
    LearningResourceType.video => Icons.play_circle_fill_rounded,
    LearningResourceType.presentation => Icons.slideshow_rounded,
    LearningResourceType.externalLink => Icons.open_in_new_rounded,
    LearningResourceType.document => Icons.description_rounded,
    LearningResourceType.text => Icons.notes_rounded,
  };

  Future<void> _openResource(LearningResourceModel resource) async {
    if (resource.type == LearningResourceType.text) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(resource.title, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: SelectableText(
                resource.textContent,
                style: const TextStyle(color: AtlasColors.navy, height: 1.65, fontSize: 15),
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
        ),
      );
      return;
    }
    final uri=Uri.tryParse(resource.resourceUrl);
    if(uri==null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('This resource link is invalid.')));
      return;
    }
    try {
      final opened=await launchUrl(uri,mode:LaunchMode.externalApplication);
      if(!opened) throw Exception('No application could open this resource.');
      if (!mounted) return;
      final markCompleted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Finish this resource?',
            style: TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'After you have finished studying this material, mark it as completed. Opening a link alone will not count as completion.',
            style: TextStyle(color: AtlasColors.secondaryText, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not yet'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Mark completed'),
            ),
          ],
        ),
      );
      if (markCompleted == true) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('student_resource_progress')
              .doc('${uid}_${resource.id}')
              .set({
            'userId': uid,
            'resourceId': resource.id,
            'yearId': resource.yearId,
            'subjectId': resource.subjectId,
            'topicId': resource.topicId,
            'completed': true,
            'completedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resource marked as completed.')),
            );
          }
        }
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Unable to open this resource: $e')));
    }
  }

  Widget _tile(String title,String subtitle,IconData icon,VoidCallback tap)=>Card(
    child: ListTile(onTap:tap,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:7),
      leading:CircleAvatar(backgroundColor:AtlasColors.paleBlue,child:Icon(icon,color:AtlasColors.royalBlue)),
      title:Text(title,style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w800)),
      subtitle:Text(subtitle,style:const TextStyle(color:AtlasColors.secondaryText),maxLines:2,overflow:TextOverflow.ellipsis),
      trailing:const Icon(Icons.chevron_right_rounded,color:AtlasColors.royalBlue)),
  );

  Widget _back(String label,VoidCallback action)=>Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:action,icon:const Icon(Icons.arrow_back),label:Text('Back to $label')));
  Widget _empty(String text)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),child:Text(text,style:const TextStyle(color:AtlasColors.secondaryText)));
}
