import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class McqDestination {
  final String trackType, yearId, yearName, pathwayId, pathwayName;
  final String subjectId, subjectName, examSetId, examSetName;
  const McqDestination({required this.trackType, this.yearId='', this.yearName='', this.pathwayId='', this.pathwayName='', required this.subjectId, required this.subjectName, required this.examSetId, required this.examSetName});
}

class McqDestinationSelector extends StatefulWidget {
  final McqDestination? initialValue;
  final ValueChanged<McqDestination?> onChanged;
  const McqDestinationSelector({super.key, this.initialValue, required this.onChanged});
  @override State<McqDestinationSelector> createState()=>_McqDestinationSelectorState();
}
class _McqDestinationSelectorState extends State<McqDestinationSelector> {
  String _track='mbbs', _parentId='', _parentName='', _subjectId='', _subjectName='', _setId='', _setName='';
  @override void initState(){super.initState(); final v=widget.initialValue; if(v!=null){_track=v.trackType;_parentId=v.trackType=='mbbs'?v.yearId:v.pathwayId;_parentName=v.trackType=='mbbs'?v.yearName:v.pathwayName;_subjectId=v.subjectId;_subjectName=v.subjectName;_setId=v.examSetId;_setName=v.examSetName;}}
  void _emit(){if(_parentId.isEmpty||_subjectId.isEmpty||_setId.isEmpty){widget.onChanged(null);return;} widget.onChanged(McqDestination(trackType:_track,yearId:_track=='mbbs'?_parentId:'',yearName:_track=='mbbs'?_parentName:'',pathwayId:_track=='licensing'?_parentId:'',pathwayName:_track=='licensing'?_parentName:'',subjectId:_subjectId,subjectName:_subjectName,examSetId:_setId,examSetName:_setName));}
  Widget _drop(String label,List<QueryDocumentSnapshot<Map<String,dynamic>>> docs,String? value,ValueChanged<QueryDocumentSnapshot<Map<String,dynamic>>?> change){
    final valid=docs.any((d)=>d.id==value);
    return Padding(padding:const EdgeInsets.only(bottom:12),child:DropdownButtonFormField<String>(value:valid?value:null,isExpanded:true,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),items:docs.map((d)=>DropdownMenuItem(value:d.id,child:Text((d.data()['name']??d.data()['title']??d.id).toString(),overflow:TextOverflow.ellipsis))).toList(),onChanged:(id)=>change(id==null?null:docs.firstWhere((d)=>d.id==id)));
  }
  @override Widget build(BuildContext context){
    final parentCollection=_track=='mbbs'?'academic_years':'licensing_pathways';
    final subjectCollection=_track=='mbbs'?'academic_subjects':'licensing_pathway_subjects';
    return Card(elevation:0,color:const Color(0xFFF3F6FC),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('MCQ DESTINATION',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1,color:Color(0xFF071B3D))),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(value:_track,decoration:const InputDecoration(labelText:'Track',border:OutlineInputBorder()),items:const [DropdownMenuItem(value:'mbbs',child:Text('MBBS')),DropdownMenuItem(value:'licensing',child:Text('Licensing pathways'))],onChanged:(v){if(v==null)return;setState((){_track=v;_parentId='';_parentName='';_subjectId='';_subjectName='';_setId='';_setName='';});widget.onChanged(null);}),
      StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection(parentCollection).snapshots(),builder:(c,s){if(!s.hasData)return const LinearProgressIndicator();return _drop(_track=='mbbs'?'Academic year':'Licensing pathway',s.data!.docs,_parentId,(d){setState((){_parentId=d?.id??'';_parentName=(d?.data()['name']??d?.data()['title']??'').toString();_subjectId='';_subjectName='';_setId='';_setName='';});widget.onChanged(null);});}),
      if(_parentId.isNotEmpty) StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection(subjectCollection).where(_track=='mbbs'?'yearId':'pathwayId',isEqualTo:_parentId).snapshots(),builder:(c,s){if(!s.hasData)return const LinearProgressIndicator();return _drop('Subject',s.data!.docs,_subjectId,(d){setState((){_subjectId=d?.id??'';_subjectName=(d?.data()['name']??'').toString();_setId='';_setName='';});widget.onChanged(null);});}),
      if(_subjectId.isNotEmpty) StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('mcq_exam_sets').where('trackType',isEqualTo:_track).where(_track=='mbbs'?'yearId':'pathwayId',isEqualTo:_parentId).where('subjectId',isEqualTo:_subjectId).snapshots(),builder:(c,s){if(!s.hasData)return const LinearProgressIndicator();final docs=s.data!.docs.where((d)=>d.data()['isActive']!=false).toList();return _drop('Exam set',docs,_setId,(d){setState((){_setId=d?.id??'';_setName=(d?.data()['name']??'').toString();});_emit();});}),
      if(_parentId.isNotEmpty&&_subjectId.isNotEmpty&&_setId.isEmpty) const Text('Create an exam set for this subject in MCQ Curriculum Management.',style:TextStyle(color:Colors.deepOrange,fontSize:12)),
    ])));
  }
}
