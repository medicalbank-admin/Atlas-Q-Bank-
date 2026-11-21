import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../app/atlas_academy_app.dart';

class DashboardAnnouncementWelcome extends StatefulWidget {
  final String displayName;
  const DashboardAnnouncementWelcome({super.key,required this.displayName});
  @override State<DashboardAnnouncementWelcome> createState()=>_DashboardAnnouncementWelcomeState();
}
class _DashboardAnnouncementWelcomeState extends State<DashboardAnnouncementWelcome>{
  Timer? _rotation;
  int _index=0;
  final Set<String> _popupSeenIds={};
  String _seenSignature='';
  List<QueryDocumentSnapshot<Map<String,dynamic>>> _active=[];
  @override void dispose(){_rotation?.cancel();super.dispose();}
  void _startRotation(){
    _rotation?.cancel();
    if(_active.length>1){
      _rotation=Timer.periodic(const Duration(seconds:4),(_){
        if(mounted)setState(()=>_index=(_index+1)%_active.length);
      });
    }
  }
  void _sync(List<QueryDocumentSnapshot<Map<String,dynamic>>> docs){
    final signature=docs.map((d)=>d.id).join('|');
    if(signature==_seenSignature)return;
    _seenSignature=signature;
    _active=docs;
    if(_index>=_active.length)_index=0;
    _rotation?.cancel();
    if(mounted)setState((){});
    final unseen=_active.where((d)=>!_popupSeenIds.contains(d.id)).toList();
    if(unseen.isNotEmpty){
      final first=unseen.first;
      _popupSeenIds.add(first.id);
      WidgetsBinding.instance.addPostFrameCallback((_)async{
        await _showInitialPopup(first.data());
        if(mounted)_startRotation();
      });
    }else{
      _startRotation();
    }
  }
  Future<void> _showInitialPopup(Map<String,dynamic> item) async {
    if(!mounted)return;
    await showDialog<void>(context:context,barrierDismissible:true,builder:(dialogContext){
      Timer(const Duration(seconds:3),(){if(dialogContext.mounted)Navigator.of(dialogContext).pop();});
      return AlertDialog(
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),
        title:Row(children:[const Icon(Icons.campaign_rounded,color:AtlasColors.royalBlue),const SizedBox(width:9),Expanded(child:Text((item['title']??'Academy announcement').toString(),style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900)))]),
        content:Text((item['body']??'').toString(),style:const TextStyle(color:AtlasColors.charcoal,height:1.5)),
      );
    });
  }
  @override Widget build(BuildContext context)=>StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream:FirebaseFirestore.instance.collection('notifications').where('audience',isEqualTo:'all').where('isActive',isEqualTo:true).snapshots(),
    builder:(context,snapshot){
      if(snapshot.hasData){
        final docs=[...snapshot.data!.docs]..sort((a,b){
          final at=a.data()['createdAt'];final bt=b.data()['createdAt'];
          final ad=at is Timestamp?at.toDate():DateTime.fromMillisecondsSinceEpoch(0);
          final bd=bt is Timestamp?bt.toDate():DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });
        WidgetsBinding.instance.addPostFrameCallback((_)=>_sync(docs));
      }
      final hasNotice=_active.isNotEmpty;
      final current=hasNotice?_active[_index.clamp(0,_active.length-1)].data():null;
      return AnimatedSwitcher(duration:const Duration(milliseconds:350),child:Container(
        key:ValueKey(hasNotice?'notice-${_index}-${_seenSignature}':'welcome'),
        width:double.infinity,padding:const EdgeInsets.fromLTRB(23,22,23,20),
        decoration:BoxDecoration(gradient:const LinearGradient(colors:[AtlasColors.navy,AtlasColors.royalBlue,AtlasColors.brightBlue],begin:Alignment.topLeft,end:Alignment.bottomRight),borderRadius:BorderRadius.circular(27),boxShadow:[BoxShadow(color:AtlasColors.navy.withValues(alpha:.19),blurRadius:23,offset:const Offset(0,10))]),
        child:hasNotice?Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[const Icon(Icons.notifications_active_rounded,color:AtlasColors.champagne,size:19),const SizedBox(width:8),const Expanded(child:Text('ACADEMY ANNOUNCEMENT',style:TextStyle(color:AtlasColors.champagne,fontSize:10,letterSpacing:1.2,fontWeight:FontWeight.w900))),if(_active.length>1)Text('${_index+1}/${_active.length}',style:const TextStyle(color:Colors.white70,fontSize:11))]),
          const SizedBox(height:16),
          Text((current?['title']??'Announcement').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),
          const SizedBox(height:9),
          Text((current?['body']??'').toString(),maxLines:4,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,height:1.55,fontSize:13)),
          if(_active.length>1)...[
            const SizedBox(height:14),
            Row(mainAxisAlignment:MainAxisAlignment.end,children:[
              IconButton(visualDensity:VisualDensity.compact,onPressed:()=>setState(()=>_index=(_index-1+_active.length)%_active.length),icon:const Icon(Icons.chevron_left_rounded,color:Colors.white)),
              IconButton(visualDensity:VisualDensity.compact,onPressed:()=>setState(()=>_index=(_index+1)%_active.length),icon:const Icon(Icons.chevron_right_rounded,color:Colors.white)),
            ]),
          ],
        ]):Stack(children:[
          Positioned(right:-18,top:-22,child:Icon(Icons.school_rounded,size:155,color:Colors.white.withValues(alpha:.055))),
          Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.12),borderRadius:BorderRadius.circular(30),border:Border.all(color:Colors.white.withValues(alpha:.15))),child:const Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.auto_awesome_rounded,color:AtlasColors.champagne,size:14),SizedBox(width:7),Text('YOUR MEDICAL JOURNEY',style:TextStyle(color:AtlasColors.champagne,fontSize:9,letterSpacing:1.3,fontWeight:FontWeight.w900))])),
            const SizedBox(height:20),const Text('Welcome back,',style:TextStyle(color:Colors.white70,fontSize:15)),const SizedBox(height:5),
            Text(widget.displayName,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:27,height:1.2,fontWeight:FontWeight.w900)),
            const SizedBox(height:12),Text('Your next achievement begins with what you learn today. Stay focused and keep moving forward.',style:TextStyle(color:Colors.white.withValues(alpha:.83),fontSize:12,height:1.65)),
            const SizedBox(height:20),Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),decoration:BoxDecoration(color:AtlasColors.champagne,borderRadius:BorderRadius.circular(12)),child:const Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.menu_book_rounded,size:16,color:AtlasColors.navy),SizedBox(width:8),Text('Learn. Practice. Excel.',style:TextStyle(color:AtlasColors.navy,fontSize:11,fontWeight:FontWeight.w900))])),
          ]),
        ]),
      ));
    },
  );
}