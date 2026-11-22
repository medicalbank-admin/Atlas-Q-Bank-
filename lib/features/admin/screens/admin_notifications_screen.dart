import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../advanced_learning/services/push_notification_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
 const AdminNotificationsScreen({super.key});
 @override State<AdminNotificationsScreen> createState()=>_AdminNotificationsScreenState();
}
class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>{
 final _title=TextEditingController(),_body=TextEditingController(),_link=TextEditingController();
 bool _sending=false;
 Future<void> _publish() async {
  if(_title.text.trim().isEmpty||_body.text.trim().isEmpty){_message('Enter both a title and message.',true);return;}
  final publishedTitle=_title.text.trim();final publishedBody=_body.text.trim();
  final link=_link.text.trim();
  if(link.isNotEmpty){final uri=Uri.tryParse(link);if(uri==null||!['https','http'].contains(uri.scheme)){_message('Enter a valid http or https link.',true);return;}}
  setState(()=>_sending=true);
  try{
   await FirebaseFirestore.instance.collection('notifications').add({
    'title':publishedTitle,'body':publishedBody,'audience':'all',
    'isActive':true,'createdAt':FieldValue.serverTimestamp(),
    if(link.isNotEmpty)'linkUrl':link,
    'createdBy':FirebaseAuth.instance.currentUser?.uid,
   });
   try{final sent=await PushNotificationService().sendAnnouncement(title:publishedTitle,body:publishedBody);if(mounted)_message('Announcement and push notification sent to $sent devices.',false);}catch(e){if(mounted)_message('Announcement published in the app; push delivery unavailable: $e',true);}_title.clear();_body.clear();_link.clear();
  }catch(e){if(mounted)_message('Could not publish: $e',true);}
  finally{if(mounted)setState(()=>_sending=false);}
 }
 Future<void> _toggle(String id,bool active) async{
  try{await FirebaseFirestore.instance.collection('notifications').doc(id).update({'isActive':!active,'updatedAt':FieldValue.serverTimestamp()});}
  catch(e){_message('Unable to update announcement: $e',true);}
 }
 Future<void> _delete(String id) async{
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Delete announcement?'),content:const Text('This cannot be undone.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))]));
  if(yes==true){try{await FirebaseFirestore.instance.collection('notifications').doc(id).delete();}catch(e){_message('Delete failed: $e',true);}}
 }
 void _message(String s,bool error)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),backgroundColor:error?AtlasColors.error:AtlasColors.success));
 @override void dispose(){_title.dispose();_body.dispose();_link.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:AtlasColors.ivory,appBar:AppBar(title:const Text('Notifications & Announcements')),body:ListView(padding:const EdgeInsets.all(18),children:[
 Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AtlasColors.navy,AtlasColors.royalBlue]),borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.campaign_rounded,color:AtlasColors.champagne,size:30),SizedBox(height:10),Text('Academy Announcements',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Publish notices for students. You can pause or remove an announcement at any time.',style:TextStyle(color:Colors.white70,height:1.5))])),
 const SizedBox(height:20),const Text('Create Announcement',style:TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:12),
 TextField(controller:_title,decoration:const InputDecoration(labelText:'Announcement title',prefixIcon:Icon(Icons.title_rounded))),
 const SizedBox(height:12),TextField(controller:_body,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Message for students',alignLabelWithHint:true,prefixIcon:Icon(Icons.notes_rounded))),
 const SizedBox(height:12),TextField(controller:_link,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'Optional action link (https://...)',prefixIcon:Icon(Icons.link_rounded))),
 const SizedBox(height:12),SizedBox(height:50,child:FilledButton.icon(onPressed:_sending?null:_publish,icon:const Icon(Icons.send_rounded),label:Text(_sending?'Publishing…':'Publish to Students'))),
 const SizedBox(height:25),const Text('Published Announcements',style:TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:10),
 StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('notifications').orderBy('createdAt',descending:true).snapshots(),builder:(context,snapshot){if(snapshot.hasError)return Text('Unable to load announcements: ${snapshot.error}');if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());final docs=snapshot.data!.docs.where((d)=>d.data()['audience']=='all'||d.data()['userId']==null).toList();if(docs.isEmpty)return const Padding(padding:EdgeInsets.all(25),child:Text('No announcements have been published yet.',textAlign:TextAlign.center));return Column(children:docs.map((d){final data=d.data();final active=data['isActive']!=false;return Card(color:Colors.white,margin:const EdgeInsets.only(bottom:10),child:ListTile(title:Text((data['title']??'Announcement').toString(),style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w800)),subtitle:Text((data['body']??'').toString(),maxLines:3,overflow:TextOverflow.ellipsis),leading:Icon(active?Icons.notifications_active_rounded:Icons.notifications_off_rounded,color:active?AtlasColors.royalBlue:AtlasColors.secondaryText),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='toggle')_toggle(d.id,active);if(v=='delete')_delete(d.id);},itemBuilder:(_)=>[PopupMenuItem(value:'toggle',child:Text(active?'Pause':'Activate')),const PopupMenuItem(value:'delete',child:Text('Delete'))])));}).toList());})
 ]));
}