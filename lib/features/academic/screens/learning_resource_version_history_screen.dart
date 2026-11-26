import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../services/learning_resource_version_service.dart';

class LearningResourceVersionHistoryScreen extends StatelessWidget {
  final String resourceId;
  final String title;
  const LearningResourceVersionHistoryScreen({super.key,required this.resourceId,required this.title});

  Future<void> _restore(BuildContext context,int version) async {
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Restore this revision?'),
      content:Text('Version $version will become the latest published revision. Existing history will be preserved.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Restore'))]));
    if(ok!=true)return;
    try{
      await LearningResourceVersionService.restore(resourceId:resourceId,selectedVersion:version);
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Version $version restored as a new revision.')));
    }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text('Restore failed: $e')));}
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFFF3F6FA),
    appBar:AppBar(title:const Text('Chapter version history'),
      backgroundColor:const Color(0xFFF3F6FA),foregroundColor:AtlasColors.navy),
    body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream:FirebaseFirestore.instance.collection('learning_resources').doc(resourceId)
        .collection('versions').orderBy('versionNumber',descending:true).snapshots(),
      builder:(context,s){
        if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),
          child:Text('Could not load version history. Check Firestore permissions.\n${s.error}',
            textAlign:TextAlign.center)));
        if(!s.hasData)return const Center(child:CircularProgressIndicator());
        final docs=s.data!.docs;
        if(docs.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(28),
          child:Text('No published revisions yet. The first version will be recorded on publication.',
            textAlign:TextAlign.center)));
        return ListView.builder(padding:const EdgeInsets.all(16),itemCount:docs.length,
          itemBuilder:(context,i){
            final d=docs[i].data();
            final v=(d['versionNumber'] as num?)?.toInt()??i+1;
            final ts=d['savedAt'];
            final date=ts is Timestamp?ts.toDate().toLocal().toString().substring(0,16):'Date unavailable';
            return Card(elevation:0,color:Colors.white,margin:const EdgeInsets.only(bottom:12),
              child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:7),
                leading:CircleAvatar(backgroundColor:const Color(0xFFE8F1FC),
                  child:Text('v$v',style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900,fontSize:12))),
                title:Text((d['title']??title).toString(),style:const TextStyle(
                  color:AtlasColors.navy,fontWeight:FontWeight.w800)),
                subtitle:Text('${d['changeNote']??'Published revision'}\n$date'),
                isThreeLine:true,trailing:TextButton(onPressed:()=>_restore(context,v),child:const Text('Restore'))));
          });
      }),
  );
}