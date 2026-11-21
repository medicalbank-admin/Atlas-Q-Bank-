import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';

class AdminAnalyticsScreen extends StatelessWidget{
 const AdminAnalyticsScreen({super.key});
 Future<Map<String,int>> _load() async{
  final db=FirebaseFirestore.instance;
  final results=await Future.wait([
   db.collection('users').where('role',isEqualTo:'student').get(),
   db.collection('subscription_requests').get(),
   db.collection('mcq_attempts').get(),
   db.collection('subscription_plans').get(),
   db.collection('learning_resources').get(),
   db.collection('mcqs').get(),
  ]);
  final students=results[0].docs;
  final active=students.where((d){final x=d.data();final expiry=x['subscriptionExpiryAt'];return x['subscriptionStatus']=='active'&&x['accessEnabled']==true&&expiry is Timestamp&&expiry.toDate().isAfter(DateTime.now());}).length;
  final pending=results[1].docs.where((d)=>d.data()['status']=='pending').length;
  final approved=results[1].docs.where((d)=>d.data()['status']=='approved').length;
  return {'students':students.length,'active':active,'pending':pending,'approved':approved,'attempts':results[2].size,'plans':results[3].size,'resources':results[4].size,'mcqs':results[5].size};
 }
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:AtlasColors.ivory,appBar:AppBar(title:const Text('Analytics & Reports'),actions:[IconButton(onPressed:()=>Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>const AdminAnalyticsScreen())),icon:const Icon(Icons.refresh_rounded),tooltip:'Refresh')]),body:FutureBuilder<Map<String,int>>(future:_load(),builder:(context,snapshot){if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(snapshot.hasError)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Unable to generate report. Check admin permissions and Firestore indexes.\n\n${snapshot.error}',textAlign:TextAlign.center)));final d=snapshot.data!;return ListView(padding:const EdgeInsets.all(18),children:[
 Container(padding:const EdgeInsets.all(21),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AtlasColors.navy,AtlasColors.royalBlue]),borderRadius:BorderRadius.circular(22)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.insights_rounded,color:AtlasColors.champagne,size:30),SizedBox(height:12),Text('Academy Overview',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('Live totals from the academy database. Pull down or use refresh to update.',style:TextStyle(color:Colors.white70,height:1.5))])),
 const SizedBox(height:20),_section('Students',[('Registered Students',d['students']!,Icons.people_alt_rounded),('Active Subscriptions',d['active']!,Icons.verified_rounded)]),
 _section('Payments',[('Pending Requests',d['pending']!,Icons.pending_actions_rounded),('Approved Requests',d['approved']!,Icons.task_alt_rounded)]),
 _section('Learning Content',[('MCQ Questions',d['mcqs']!,Icons.quiz_rounded),('Practice Attempts',d['attempts']!,Icons.assessment_rounded),('Learning Resources',d['resources']!,Icons.menu_book_rounded),('Subscription Plans',d['plans']!,Icons.workspace_premium_rounded)]),
 const SizedBox(height:14),const Text('These figures are live database totals, not financial reconciliation or unique learner activity reports.',style:TextStyle(color:AtlasColors.secondaryText,fontSize:11,height:1.5))
 ]);}));
 static Widget _section(String title,List<(String,int,IconData)> items)=>Padding(padding:const EdgeInsets.only(bottom:20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:AtlasColors.navy,fontSize:17,fontWeight:FontWeight.w900)),const SizedBox(height:10),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:items.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55),itemBuilder:(context,i){final x=items[i];return Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(17),border:Border.all(color:AtlasColors.border)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Icon(x.$3,color:AtlasColors.royalBlue),const SizedBox(height:7),Text(x.$2.toString(),style:const TextStyle(color:AtlasColors.navy,fontSize:23,fontWeight:FontWeight.w900)),Text(x.$1,style:const TextStyle(color:AtlasColors.secondaryText,fontSize:11))]));})]));
}