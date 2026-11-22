import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class McqDestination {
  final String trackType, yearId, yearName, pathwayId, pathwayName;
  final String subjectId, subjectName, examSetId, examSetName;
  const McqDestination({required this.trackType,this.yearId='',this.yearName='',this.pathwayId='',this.pathwayName='',required this.subjectId,required this.subjectName,required this.examSetId,required this.examSetName});
}
class McqDestinationSelector extends StatefulWidget {
  final McqDestination? initialValue;
  final ValueChanged<McqDestination?> onChanged;
  const McqDestinationSelector({super.key,this.initialValue,required this.onChanged});
  @override State<McqDestinationSelector> createState()=>_McqDestinationSelectorState();
}
class _McqDestinationSelectorState extends State<McqDestinationSelector> {
  String _track='mbbs',_parentId='',_parentName='',_subjectId='',_subjectName='',_setId='',_setName='';
  @override void initState(){super.initState();final v=widget.initialValue;if(v!=null){_track=v.trackType;_parentId=v.trackType=='mbbs'?v.yearId:v.pathwayId;_parentName=v.trackType=='mbbs'?v.yearName:v.pathwayName;_subjectId=v.subjectId;_subjectName=v.subjectName;_setId=v.examSetId;_setName=v.examSetName;}}
  void _reset(){setState((){_parentId='';_parentName='';_subjectId='';_subjectName='';_setId='';_setName='';});widget.onChanged(null);}
  void _emit(){if(_setId.isEmpty||_subjectId.isEmpty||(_track!='past_paper'&&_track!='structured'&&_parentId.isEmpty)){widget.onChanged(null);return;}widget.onChanged(McqDestination(trackType:_track=='structured'?'mbbs':_track,yearId:_track=='structured'?'exam_centre':_track=='mbbs'?_parentId:'',yearName:_track=='structured'?'Examination Centre':_track=='mbbs'?_parentName:'',pathwayId:_track=='licensing'?_parentId:'',pathwayName:_track=='licensing'?_parentName:'',subjectId:_subjectId,subjectName:_subjectName,examSetId:_setId,examSetName:_setName));}
  Widget _drop(String label,List<QueryDocumentSnapshot<Map<String,dynamic>>> docs,String? value,ValueChanged<QueryDocumentSnapshot<Map<String,dynamic>>?> change){
    final valid=docs.any((d)=>d.id==value);
    return Padding(padding:const EdgeInsets.only(bottom:12),child:DropdownButtonFormField<String>(initialValue:valid?value:null,isExpanded:true,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),items:docs.map((d)=>DropdownMenuItem<String>(value:d.id,child:Text((d.data()['name']??d.data()['title']??d.id).toString(),overflow:TextOverflow.ellipsis))).toList(),onChanged:(id)=>change(id==null?null:docs.firstWhere((d)=>d.id==id))));
  }
  @override Widget build(BuildContext context)=>Card(elevation:0,color:const Color(0xFFF3F6FC),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('MCQ DESTINATION',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1,color:Color(0xFF071B3D))),const SizedBox(height:12),
    DropdownButtonFormField<String>(initialValue:_track,decoration:const InputDecoration(labelText:'Import category',border:OutlineInputBorder()),items:const [DropdownMenuItem(value:'mbbs',child:Text('MBBS — select a year')),DropdownMenuItem(value:'licensing',child:Text('Licensing — select a pathway')),DropdownMenuItem(value:'structured',child:Text('Subject / System / Mock Exam')),DropdownMenuItem(value:'past_paper',child:Text('Past Papers'))],onChanged:(v){if(v==null)return;setState(() { _track=v; });_reset();}),
    if(_track=='structured') StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('mcq_exam_sets').where('yearId',isEqualTo:'exam_centre').snapshots(),builder:(c,s){
      if(s.hasError)return const Text('Unable to load structured exams.');if(!s.hasData)return const LinearProgressIndicator();
      final docs=s.data!.docs.where((d)=>d.data()['isActive']!=false).toList();
      return _drop('Select exam',docs,_setId,(d){setState((){_setId=d?.id??'';_setName=(d?.data()['name']??'').toString();_subjectId=(d?.data()['subjectId']??d?.id??'').toString();_subjectName=(d?.data()['categoryName']??d?.data()['subjectName']??'Examination').toString();});_emit();});
    })
    else if(_track=='past_paper')
      StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('mcq_exam_sets').where('trackType',isEqualTo:'past_paper').snapshots(),builder:(c,s){
        if(s.hasError)return const Text('Unable to load past papers.');if(!s.hasData)return const LinearProgressIndicator();
        final docs=s.data!.docs.where((d)=>d.data()['isActive']!=false).toList();
        return _drop('Select past paper',docs,_setId,(d){setState((){_setId=d?.id??'';_setName=(d?.data()['name']??'').toString();_subjectId=(d?.data()['subjectId']??d?.id??'').toString();_subjectName=(d?.data()['subjectName']??'Past Paper').toString();});_emit();});
      })
    else ...[
      StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection(_track=='mbbs'?'academic_years':'licensing_pathways').snapshots(),builder:(c,s){
        if(s.hasError)return const Text('Unable to load destinations.');if(!s.hasData)return const LinearProgressIndicator();
        return _drop(_track=='mbbs'?'MBBS year':'Licensing pathway',s.data!.docs,_parentId,(d){setState((){_parentId=d?.id??'';_parentName=(d?.data()['name']??d?.data()['title']??'').toString();_subjectId='';_subjectName='';_setId='';_setName='';});widget.onChanged(null);});
      }),
      if(_parentId.isNotEmpty) StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream:FirebaseFirestore.instance.collection(_track=='mbbs'?'academic_subjects':'licensing_pathway_subjects').where(_track=='mbbs'?'yearId':'pathwayId',isEqualTo:_parentId).snapshots(),builder:(c,s){
        if(s.hasError)return const Text('Unable to load subjects.');if(!s.hasData)return const LinearProgressIndicator();
        return _drop('Subject',s.data!.docs,_subjectId,(d){setState((){_subjectId=d?.id??'';_subjectName=(d?.data()['name']??'').toString();_setId='';_setName='';});widget.onChanged(null);});
      }),
      if(_subjectId.isNotEmpty) StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream:FirebaseFirestore.instance.collection('mcq_exam_sets').where('trackType',isEqualTo:_track).where(_track=='mbbs'?'yearId':'pathwayId',isEqualTo:_parentId).where('subjectId',isEqualTo:_subjectId).snapshots(),builder:(c,s){
        if(s.hasError)return const Text('Unable to load exam sets.');if(!s.hasData)return const LinearProgressIndicator();
        return _drop('Exam set',s.data!.docs.where((d)=>d.data()['isActive']!=false).toList(),_setId,(d){setState((){_setId=d?.id??'';_setName=(d?.data()['name']??'').toString();});_emit();});
      }),
    ],
    if(_track!='past_paper'&&_track!='structured'&&_parentId.isNotEmpty&&_subjectId.isNotEmpty&&_setId.isEmpty)const Text('Create an exam set for this destination in MCQ Curriculum Management.',style:TextStyle(color:Colors.deepOrange,fontSize:12)),
  ])));
}
