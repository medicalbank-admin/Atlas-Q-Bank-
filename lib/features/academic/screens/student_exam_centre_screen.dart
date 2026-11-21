import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../mcqs/screens/student_mcq_practice_screen.dart';

class StudentExamCentreScreen extends StatelessWidget {
  final bool pathwaysOnly;
  const StudentExamCentreScreen({super.key, this.pathwaysOnly = false});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AtlasColors.ivory,
    appBar: AppBar(title: Text(pathwaysOnly ? 'Exam Pathways' : 'Examinations')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AtlasColors.navy, AtlasColors.royalBlue]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(pathwaysOnly ? Icons.route_rounded : Icons.assignment_rounded, color: AtlasColors.champagne, size: 30),
          const SizedBox(height: 10),
          Text(pathwaysOnly ? 'Choose your licensing pathway' : 'Your examination centre',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(pathwaysOnly
            ? 'Browse published question sets grouped by your selected medical licensing route.'
            : 'Explore published academy examinations and practice sets.',
            style: const TextStyle(color: Colors.white70, height: 1.5)),
        ]),
      ),
      const SizedBox(height: 20),
      if (pathwaysOnly) _pathways(context) else ...[
        const Text('Published examinations', style: TextStyle(color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        _examList(context),
        const SizedBox(height: 22),
        const Text('Practice exam sets', style: TextStyle(color: AtlasColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        _setList(context, null),
      ],
    ]),
  );

  Widget _pathways(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream: FirebaseFirestore.instance.collection('licensing_pathways').where('isActive',isEqualTo:true).snapshots(),
    builder: (c,s) {
      if(s.hasError)return _message('Unable to load pathways. Please try again.');
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final docs=s.data!.docs;
      if(docs.isEmpty)return _message('No licensing pathways are available yet.');
      return Column(children:docs.map((d) {
        final data=d.data();
        final name=(data['name']??'Licensing pathway').toString();
        final desc=(data['description']??'').toString();
        return Card(child:ExpansionTile(
          leading:const Icon(Icons.route_rounded,color:AtlasColors.royalBlue),
          title:Text(name,style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900)),
          subtitle:Text(desc.isEmpty?'View subjects and published exam sets':desc,style:const TextStyle(color:AtlasColors.secondaryText)),
          children:[_pathwaySubjects(context,d.id)],
        ));
      }).toList());
    },
  );

  Widget _pathwaySubjects(BuildContext context,String pathwayId) =>
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream:FirebaseFirestore.instance.collection('mcq_exam_sets')
        .where('pathwayId',isEqualTo:pathwayId).where('trackType',isEqualTo:'licensing').where('isPublished',isEqualTo:true).snapshots(),
      builder:(c,s){
        if(s.hasError)return const ListTile(title:Text('Unable to load exam sets.',style:TextStyle(color:AtlasColors.error)));
        if(!s.hasData)return const Padding(padding:EdgeInsets.all(12),child:CircularProgressIndicator());
        if(s.data!.docs.isEmpty)return const ListTile(title:Text('No published exam sets in this pathway yet.',style:TextStyle(color:AtlasColors.secondaryText)));
        final grouped=<String,List<QueryDocumentSnapshot<Map<String,dynamic>>>>{};
        for(final d in s.data!.docs){final subject=(d.data()['subjectName']??'Other subjects').toString();grouped.putIfAbsent(subject,()=>[]).add(d);}
        return Column(children:grouped.entries.map((e)=>ExpansionTile(
          title:Text(e.key,style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w800)),
          children:e.value.map((d)=>_setTile(context,d)).toList(),
        )).toList());
      },
    );

  Widget _setList(BuildContext context,String? pathwayId) =>
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream:FirebaseFirestore.instance.collection('mcq_exam_sets').where('trackType',isEqualTo:'mbbs').where('isPublished',isEqualTo:true).snapshots(),
      builder:(c,s){
        if(s.hasError)return _message('Unable to load published practice sets.');
        if(!s.hasData)return const Center(child:CircularProgressIndicator());
        final docs=s.data!.docs;
        if(docs.isEmpty)return _message('No practice sets have been published yet.');
        final groups=<String,List<QueryDocumentSnapshot<Map<String,dynamic>>>>{};
        for(final d in docs){final x=d.data();final group=x['trackType']=='licensing'?(x['pathwayName']??'Licensing'):(x['yearName']??'MBBS');groups.putIfAbsent(group.toString(),()=>[]).add(d);}
        return Column(children:groups.entries.map((g)=>ExpansionTile(
          title:Text(g.key,style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900)),
          children:g.value.map((d)=>_setTile(context,d)).toList(),
        )).toList());
      },
    );

  Widget _examList(BuildContext context) =>
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream:FirebaseFirestore.instance.collection('exams').where('isPublished',isEqualTo:true).snapshots(),
      builder:(c,s){
        if(s.hasError)return _message('Unable to load examinations. Please try again.');
        if(!s.hasData)return const Center(child:CircularProgressIndicator());
        if(s.data!.docs.isEmpty)return _message('No examinations have been published yet.');
        return Column(children:s.data!.docs.map((d){
          final x=d.data();
          final title=(x['title']??x['name']??'Examination').toString();
          final description=(x['description']??'').toString();
          final duration=x['durationMinutes']??x['duration']??0;
          final count=x['totalQuestions']??(x['questions'] is List?(x['questions'] as List).length:0);
          return Card(child:ListTile(
            leading:const CircleAvatar(backgroundColor:AtlasColors.paleBlue,child:Icon(Icons.assignment_turned_in_rounded,color:AtlasColors.royalBlue)),
            title:Text(title,style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900)),
            subtitle:Text([description,'$duration minutes','$count questions'].where((v)=>v.isNotEmpty).join(' • '),style:const TextStyle(color:AtlasColors.secondaryText)),
            isThreeLine:description.isNotEmpty,
            trailing:Icon(x['examSetId'] is String ? Icons.play_circle_fill_rounded : Icons.info_outline_rounded,color:AtlasColors.royalBlue),
            onTap:() {
              final examSetId=(x['examSetId']??'').toString().trim();
              if(examSetId.isNotEmpty) {
                Navigator.push(context,MaterialPageRoute(builder:(_)=>StudentMcqPracticeScreen(examSetId:examSetId)));
                return;
              }
              showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
              title:Text(title,style:const TextStyle(color:AtlasColors.navy)),
              content:Text(description.isEmpty?'This examination is published by the academy. Contact your administrator for its instructions.':description,style:const TextStyle(color:AtlasColors.charcoal)),
              actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close'))],
            ));
            },
          ));
        }).toList());
      },
    );

  Widget _setTile(BuildContext context,QueryDocumentSnapshot<Map<String,dynamic>> d) {
    final x=d.data();
    final name=(x['name']??'Practice set').toString();
    final subject=(x['subjectName']??'Subject').toString();
    return ListTile(
      leading:const Icon(Icons.quiz_rounded,color:AtlasColors.royalBlue),
      title:Text(name,style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w800)),
      subtitle:Text(subject,style:const TextStyle(color:AtlasColors.secondaryText)),
      trailing:const Icon(Icons.play_circle_outline_rounded,color:AtlasColors.royalBlue),
      onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>StudentMcqPracticeScreen(examSetId: d.id))),
    );
  }

  Widget _message(String text)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),child:Text(text,style:const TextStyle(color:AtlasColors.secondaryText)));
}
