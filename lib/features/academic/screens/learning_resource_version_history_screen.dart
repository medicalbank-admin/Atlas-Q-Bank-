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

  Future<void> _compare(BuildContext context, Map<String,dynamic> newer,
      Map<String,dynamic> older, int newerVersion, int olderVersion) async {
    final newBlocks = (newer['contentBlocks'] as List? ?? const [])
      .whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
    final oldBlocks = (older['contentBlocks'] as List? ?? const [])
      .whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
    final count = newBlocks.length > oldBlocks.length ? newBlocks.length : oldBlocks.length;
    final changes = <Widget>[];
    for (var i=0;i<count;i++) {
      final before = i<oldBlocks.length ? oldBlocks[i] : null;
      final after = i<newBlocks.length ? newBlocks[i] : null;
      final beforeText = before == null ? '' : '${before['type'] ?? 'paragraph'}: ${before['text'] ?? before['caption'] ?? before['imageUrl'] ?? ''}';
      final afterText = after == null ? '' : '${after['type'] ?? 'paragraph'}: ${after['text'] ?? after['caption'] ?? after['imageUrl'] ?? ''}';
      if (beforeText == afterText) continue;
      changes.add(Container(
        margin: const EdgeInsets.only(bottom:10), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2EAF3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
          Text('Content block ${i+1}',style:const TextStyle(fontWeight:FontWeight.w900,color:AtlasColors.navy)),
          if(before!=null) Padding(padding:const EdgeInsets.only(top:7),child:Text('− Previous: $beforeText',
            style:const TextStyle(color:Color(0xFFB54747),height:1.4))),
          if(after!=null) Padding(padding:const EdgeInsets.only(top:5),child:Text('+ Updated: $afterText',
            style:const TextStyle(color:Color(0xFF16734A),height:1.4))),
        ]),
      ));
    }
    final titleChanged = (newer['title']??'') != (older['title']??'');
    final descriptionChanged = (newer['description']??'') != (older['description']??'');
    if(titleChanged) changes.insert(0,Text('Title: "${older['title']??''}" → "${newer['title']??''}"',
      style:const TextStyle(fontWeight:FontWeight.w800,color:AtlasColors.navy)));
    if(descriptionChanged) changes.insert(titleChanged?1:0,Text('Description updated',
      style:const TextStyle(fontWeight:FontWeight.w700,color:AtlasColors.navy)));
    if(changes.isEmpty) changes.add(const Text('No text or block-level differences detected. Some metadata or image changes may not appear in this comparison.'));
    await showDialog<void>(context:context,builder:(c)=>AlertDialog(
      title:Text('Compare v$olderVersion → v$newerVersion'),
      content:SizedBox(width:520,height:420,child:ListView(children:changes)),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Close'))]));
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
                isThreeLine:true,
                trailing:PopupMenuButton<String>(
                  onSelected:(action){
                    if(action=='restore')_restore(context,v);
                    if(action=='compare'&&i+1<docs.length){
                      _compare(context,d,docs[i+1].data(),v,
                        (docs[i+1].data()['versionNumber'] as num?)?.toInt()??v-1);
                    }
                  },
                  itemBuilder:(_)=>[
                    if(i+1<docs.length)const PopupMenuItem(value:'compare',child:Text('Compare with previous')),
                    const PopupMenuItem(value:'restore',child:Text('Restore this version')),
                  ])));
          });
      }),
  );
}