import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../../advanced_learning/services/push_notification_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
 const AdminNotificationsScreen({super.key});
 @override State<AdminNotificationsScreen> createState()=>_AdminNotificationsScreenState();
}
class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>{
 final db=FirebaseFirestore.instance;
 final title=TextEditingController(),body=TextEditingController(),image=TextEditingController(),destination=TextEditingController(),userIds=TextEditingController(),plan=TextEditingController(),pathway=TextEditingController();
 String audience='all',subscriptionStatus='active';DateTime? scheduledAt;bool busy=false;
 @override void dispose(){title.dispose();body.dispose();image.dispose();destination.dispose();userIds.dispose();plan.dispose();pathway.dispose();super.dispose();}
 void toast(String s,[bool error=false]){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s),backgroundColor:error?AtlasColors.error:AtlasColors.success));}
 Widget field(TextEditingController c,String label,{int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,minLines:lines,maxLines:lines,decoration:InputDecoration(labelText:label)));
 Future<void> chooseTime()async{final now=DateTime.now();final d=await showDatePicker(context:context,initialDate:now.add(const Duration(days:1)),firstDate:now,lastDate:now.add(const Duration(days:365)));if(d==null||!mounted)return;final t=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(now.add(const Duration(hours:1))));if(t!=null)setState(()=>scheduledAt=DateTime(d.year,d.month,d.day,t.hour,t.minute));}
 Future<void> save({required String mode})async{
  if(title.text.trim().isEmpty||body.text.trim().isEmpty){toast('Enter a title and message.',true);return;}
  for(final s in [image.text.trim(),destination.text.trim()]){if(s.isNotEmpty){final u=Uri.tryParse(s);if(u==null||!['https','http'].contains(u.scheme)){toast('Image and destination must be valid http/https URLs.',true);return;}}}
  if(audience=='selected'&&userIds.text.trim().isEmpty){toast('Enter student UIDs.',true);return;}
  if(mode=='scheduled'&&(scheduledAt==null||!scheduledAt!.isAfter(DateTime.now()))){toast('Choose a future date and time.',true);return;}
  setState(()=>busy=true);
  try{
   final ref=await db.collection('push_notifications').add({'title':title.text.trim(),'body':body.text.trim(),'imageUrl':image.text.trim(),'destination':destination.text.trim(),'audience':audience,'selectedUserIds':userIds.text.split(RegExp(r'[,\\n]')).map((v)=>v.trim()).where((v)=>v.isNotEmpty).toList(),'membershipPlan':plan.text.trim(),'medicalPathway':pathway.text.trim(),'subscriptionStatus':subscriptionStatus,'status':mode,'scheduledAt':scheduledAt==null?null:Timestamp.fromDate(scheduledAt!),'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
   if(mode=='sending'){
    final result=await PushNotificationService().sendCampaign(notificationId:ref.id,title:title.text.trim(),body:body.text.trim(),imageUrl:image.text.trim(),destination:destination.text.trim(),audience:audience,membershipPlan:plan.text.trim(),medicalPathway:pathway.text.trim(),subscriptionStatus:subscriptionStatus,userIds:userIds.text.split(RegExp(r'[,\\n]')).map((v)=>v.trim()).where((v)=>v.isNotEmpty).toList());
    await ref.update({'status':'sent','sentCount':result['sent']??0,'failedCount':result['failed']??0,'deviceCount':result['devices']??0,'sentAt':FieldValue.serverTimestamp()});
    toast('Push sent. Devices: '+(result['sent']??0).toString()+'; failed: '+(result['failed']??0).toString());
   }else{toast(mode=='draft'?'Draft saved.':'Notification scheduled.');}
   title.clear();body.clear();image.clear();destination.clear();userIds.clear();setState(()=>scheduledAt=null);
  }catch(e){toast('Notification failed: '+e.toString(),true);}finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>DefaultTabController(length:3,child:Scaffold(backgroundColor:AtlasColors.ivory,appBar:AppBar(title:const Text('Push Notification Center'),bottom:const TabBar(isScrollable:true,tabs:[Tab(text:'Compose'),Tab(text:'Scheduled & Drafts'),Tab(text:'History')])),body:TabBarView(children:[
  ListView(padding:const EdgeInsets.all(16),children:[
   Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AtlasColors.navy,AtlasColors.royalBlue]),borderRadius:BorderRadius.circular(20)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.notifications_active,color:AtlasColors.champagne,size:30),SizedBox(height:8),Text('Targeted student communications',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900)),SizedBox(height:5),Text('Compose, target, schedule and review campaigns.',style:TextStyle(color:Colors.white70))])),
   const SizedBox(height:16),field(title,'Notification title'),field(body,'Message',lines:3),field(image,'Image URL (optional)'),field(destination,'Destination URL (optional)'),
   DropdownButtonFormField<String>(value:audience,decoration:const InputDecoration(labelText:'Audience'),items:const [DropdownMenuItem(value:'all',child:Text('All students')),DropdownMenuItem(value:'selected',child:Text('Selected students')),DropdownMenuItem(value:'plan',child:Text('Membership plan')),DropdownMenuItem(value:'pathway',child:Text('Medical pathway')),DropdownMenuItem(value:'status',child:Text('Subscription status'))],onChanged:(v)=>setState(()=>audience=v??'all')),
   if(audience=='selected')field(userIds,'Student UIDs (comma separated)',lines:3),
   if(audience=='plan')field(plan,'Exact membership plan name'),
   if(audience=='pathway')field(pathway,'Exact medical pathway name'),
   if(audience=='status')DropdownButtonFormField<String>(value:subscriptionStatus,decoration:const InputDecoration(labelText:'Subscription status'),items:const [DropdownMenuItem(value:'active',child:Text('Active')),DropdownMenuItem(value:'expired',child:Text('Expired')),DropdownMenuItem(value:'pending',child:Text('Pending')),DropdownMenuItem(value:'inactive',child:Text('Inactive'))],onChanged:(v)=>setState(()=>subscriptionStatus=v??'active')),
   const SizedBox(height:10),OutlinedButton.icon(onPressed:busy?null:chooseTime,icon:const Icon(Icons.schedule),label:const Text('Choose schedule date and time')),
   Wrap(spacing:8,children:[OutlinedButton(onPressed:busy?null:()=>save(mode:'draft'),child:const Text('Save draft')),OutlinedButton(onPressed:busy?null:()=>save(mode:'scheduled'),child:const Text('Schedule')),FilledButton(onPressed:busy||scheduledAt!=null?null:()=>save(mode:'sending'),child:Text(busy?'Working…':'Send now'))])
  ]),
  list(['scheduled','draft'],'Scheduled notifications and drafts'),
  list(['sent','failed','sending'],'Sent notification history')
 ])));
 Widget list(List<String> states,String label)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:db.collection('push_notifications').orderBy('createdAt',descending:true).limit(100).snapshots(),builder:(c,s){if(s.hasError)return Center(child:Text('Unable to load '+label+': '+s.error.toString()));if(!s.hasData)return const Center(child:CircularProgressIndicator());final docs=s.data!.docs.where((d)=>states.contains((d.data()['status']??'').toString())).toList();if(docs.isEmpty)return Center(child:Text('No '+label+' yet.'));return ListView(padding:const EdgeInsets.all(14),children:docs.map((d){final x=d.data();return Card(child:ListTile(title:Text((x['title']??'Notification').toString(),style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900)),subtitle:Text((x['body']??'').toString()+'\\nStatus: '+(x['status']??'').toString()+' • Sent: '+(x['sentCount']??0).toString()+' • Failed: '+(x['failedCount']??0).toString()),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='delete')db.collection('push_notifications').doc(d.id).delete();},itemBuilder:(_)=>const [PopupMenuItem(value:'delete',child:Text('Delete'))])));}).toList());});
}