import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import 'admin_mcq_import_screen.dart';
import '../../advanced_learning/services/push_notification_service.dart';

class AdminPastPapersScreen extends StatelessWidget {
  const AdminPastPapersScreen({super.key});
  Future<void> _edit(BuildContext context,{String? id,Map<String,dynamic>? existing}) async {
    final title=TextEditingController(text:(existing?['name']??'').toString());
    final year=TextEditingController(text:(existing?['paperYear']??'').toString());
    final subject=TextEditingController(text:(existing?['subjectName']??'').toString());
    final duration=TextEditingController(text:(existing?['durationMinutes']??60).toString());
    final description=TextEditingController(text:(existing?['description']??'').toString());
    final formKey=GlobalKey<FormState>();
    final result=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:Text(id==null?'Create Past Paper':'Edit Past Paper'),
      content:Form(key:formKey,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextFormField(controller:title,decoration:const InputDecoration(labelText:'Paper title (e.g. Anatomy 2024)'),validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
        TextFormField(controller:year,decoration:const InputDecoration(labelText:'Exam year / session'),validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
        TextFormField(controller:subject,decoration:const InputDecoration(labelText:'Subject'),validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
        TextFormField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Duration (minutes)'),validator:(v)=>int.tryParse(v??'')==null||int.parse(v!)<1?'Enter valid minutes':null),
        TextFormField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Instructions / description')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:(){if(formKey.currentState!.validate())Navigator.pop(ctx,true);},child:const Text('Save'))],
    ));
    if(result==true){
      final data=<String,dynamic>{'name':title.text.trim(),'paperYear':year.text.trim(),'subjectName':subject.text.trim(),'subjectId':id??'', 'description':description.text.trim(),'durationMinutes':int.parse(duration.text),'trackType':'past_paper','isActive':true,'updatedAt':FieldValue.serverTimestamp()};
      try{
        if(id==null){final ref=FirebaseFirestore.instance.collection('mcq_exam_sets').doc();data['subjectId']=ref.id;data.addAll({'isPublished':false,'createdAt':FieldValue.serverTimestamp(),'createdBy':FirebaseAuth.instance.currentUser?.uid});await ref.set(data);}
        else{await FirebaseFirestore.instance.collection('mcq_exam_sets').doc(id).update(data);}
        if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Past paper saved. Import MCQs into this paper, then publish it.')));
      }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save past paper: $e')));}
    }
    title.dispose();year.dispose();subject.dispose();duration.dispose();description.dispose();
  }
  Future<void> _toggle(String id,bool published) async {
    final firestore=FirebaseFirestore.instance;
    final questions=await firestore.collection('mcqs').where('examSetId',isEqualTo:id).get();
    if(!published&&questions.docs.isEmpty){
      throw Exception('Import questions into this paper before publishing it.');
    }
    for(var start=0;start<questions.docs.length;start+=450){
      final batch=firestore.batch();
      final end=(start+450<questions.docs.length)?start+450:questions.docs.length;
      for(var i=start;i<end;i++){
        batch.update(questions.docs[i].reference,{'isPublished':!published,'updatedAt':FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }
    await firestore.collection('mcq_exam_sets').doc(id).update({'isPublished':!published,'updatedAt':FieldValue.serverTimestamp()});
    if (!published) { try { await PushNotificationService().sendCampaign(notificationId: 'past_paper_' + id, title: 'New past paper available', body: 'A new past paper is ready: ' + ((await firestore.collection('mcq_exam_sets').doc(id).get()).data()?['name']?.toString() ?? 'a past paper') + '.', destination: 'past_papers', audience: 'all'); } catch (_) {} }
  }
  Future<void> _delete(BuildContext context,String id) async {
    final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Delete past paper?'),content:const Text('The paper will be removed from students. Imported MCQs will remain in the question bank and must be deleted separately.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))]));
    if(yes==true){
      final firestore=FirebaseFirestore.instance;
      final questions=await firestore.collection('mcqs').where('examSetId',isEqualTo:id).get();
      for(var start=0;start<questions.docs.length;start+=200){
        final batch=firestore.batch();
        final end=(start+200<questions.docs.length)?start+200:questions.docs.length;
        for(var i=start;i<end;i++){
          batch.delete(questions.docs[i].reference);
          batch.delete(firestore.collection('mcq_answer_keys').doc(questions.docs[i].id));
        }
        await batch.commit();
      }
      await firestore.collection('mcq_exam_sets').doc(id).delete();
    }
  }
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFFF2F7FF),appBar:AppBar(backgroundColor:const Color(0xFFF2F7FF),foregroundColor:AtlasColors.navy,elevation:0,title:const Text('Past Papers Management')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(context),icon:const Icon(Icons.add),label:const Text('Create paper')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AtlasColors.navy,AtlasColors.royalBlue]),borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.history_edu_rounded,color:AtlasColors.champagne,size:30),SizedBox(height:10),Text('Past Papers Library',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),SizedBox(height:5),Text('Create a paper, bulk-import its questions by selecting Past Papers in the import destination, then publish it for students.',style:TextStyle(color:Colors.white70,height:1.5))])),
    const SizedBox(height:14),
    FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdminMcqImportScreen())),icon:const Icon(Icons.upload_file_rounded),label:const Text('Bulk Import Questions into a Past Paper')),
    const SizedBox(height:18),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('mcq_exam_sets').where('trackType',isEqualTo:'past_paper').snapshots(),builder:(c,s){
      if(s.hasError)return Text('Unable to load papers: ${s.error}');
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      if(s.data!.docs.isEmpty)return const Padding(padding:EdgeInsets.all(25),child:Text('No past papers yet. Create your first paper.',textAlign:TextAlign.center));
      return Column(children:s.data!.docs.map((d){final x=d.data();final published=x['isPublished']==true;return Card(color:Colors.white,child:ListTile(leading:const Icon(Icons.menu_book_rounded,color:AtlasColors.royalBlue),title:Text((x['name']??'Past paper').toString(),style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900)),subtitle:Text('${x['subjectName']??'Subject'} • ${x['paperYear']??''} • ${x['durationMinutes']??60} min\n${published?'Published':'Draft'}',style:const TextStyle(color:AtlasColors.secondaryText)),isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')_edit(context,id:d.id,existing:x);if(v=='publish')_toggle(d.id,published).catchError((e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));});if(v=='delete')_delete(context,d.id);},itemBuilder:(_)=>[const PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'publish',child:Text(published?'Unpublish':'Publish')),const PopupMenuItem(value:'delete',child:Text('Delete'))])));}).toList());
    }),
  ]));
}