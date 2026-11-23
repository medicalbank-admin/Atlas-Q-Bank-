import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/atlas_academy_app.dart';

class AtlasRadiologyLearningScreen extends StatefulWidget {
 const AtlasRadiologyLearningScreen({super.key});
 @override State<AtlasRadiologyLearningScreen> createState()=>_AtlasRadiologyLearningScreenState();
}
class _AtlasRadiologyLearningScreenState extends State<AtlasRadiologyLearningScreen>{
 String query='',filter='All'; Set<String> done={}; bool loading=true;
 static const filters=['All','X-ray','CT','Ultrasound','MRI'];
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{try{final p=await SharedPreferences.getInstance();if(!mounted)return;setState((){done=(p.getStringList('atlas_radiology_done_v1')??[]).toSet();loading=false;});}catch(_){if(mounted)setState(()=>loading=false);}}
 List<_Case> get visible=>_cases.where((c)=>(filter=='All'||filter==c.mod)&&(query.isEmpty||('${c.title} ${c.find} ${c.diag}').toLowerCase().contains(query.toLowerCase()))).toList();
 Future<void> _mark(_Case c)async{done.add(c.id);try{final p=await SharedPreferences.getInstance();await p.setStringList('atlas_radiology_done_v1',done.toList());}catch(_){}if(mounted)setState((){});}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:AtlasColors.ivory,appBar:AppBar(title:const Text('Radiology Learning Lab'),actions:[Center(child:Padding(padding:const EdgeInsets.only(right:16),child:Text('${done.length}/80',style:const TextStyle(color:AtlasColors.royalBlue,fontWeight:FontWeight.w900))))]),body:loading?const Center(child:CircularProgressIndicator()):Column(children:[
 Container(margin:const EdgeInsets.fromLTRB(16,8,16,12),padding:const EdgeInsets.all(17),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF174B68),Color(0xFF287F99),Color(0xFF53B2B5)]),borderRadius:BorderRadius.circular(21)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[Icon(Icons.image_search_rounded,color:Color(0xFFB8F1EA),size:27),SizedBox(width:10),Expanded(child:Text('REAL-WORLD RADIOLOGY CASES',style:TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w900,letterSpacing:.7)))]),const SizedBox(height:8),Text('${done.length} cases reviewed • ${80-done.length} to explore',style:const TextStyle(color:Colors.white70,fontSize:11))])),
 Padding(padding:const EdgeInsets.fromLTRB(16,0,16,9),child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:InputDecoration(hintText:'Search modality or diagnosis',prefixIcon:const Icon(Icons.search_rounded),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)))),
 SizedBox(height:40,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),children:filters.map((f)=>Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text(f),selected:filter==f,onSelected:(_)=>setState(()=>filter=f),selectedColor:AtlasColors.navy,labelStyle:TextStyle(color:filter==f?Colors.white:AtlasColors.charcoal,fontSize:10,fontWeight:FontWeight.w700)))).toList())),
  Expanded(child: visible.isEmpty
    ? const Center(child: Text('No cases match your search.'))
    : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16,6,16,22),
        itemCount: visible.length,
        itemBuilder: (context,i) {
          final c=visible[i];
          final isDone=done.contains(c.id);
          return Card(
            elevation:0,
            color:Colors.white,
            margin:const EdgeInsets.only(bottom:9),
            shape:RoundedRectangleBorder(
              borderRadius:BorderRadius.circular(15),
              side:const BorderSide(color:Color(0xFFE0EAF1)),
            ),
            child:ListTile(
              contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:7),
              leading:Container(
                width:43,height:43,
                decoration:BoxDecoration(color:const Color(0xFFE8F3F7),borderRadius:BorderRadius.circular(12)),
                child:Icon(
                  c.mod=='MRI'?Icons.image_search_rounded:
                  c.mod=='CT'?Icons.scanner_rounded:
                  c.mod=='Ultrasound'?Icons.waves_rounded:Icons.monitor_heart_rounded,
                  color:const Color(0xFF287F99),
                ),
              ),
              title:Text(c.title,style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w800,fontSize:13)),
              subtitle:Text('CASE ${c.id} • ${c.mod.toUpperCase()}',style:const TextStyle(color:AtlasColors.secondaryText,fontSize:9,fontWeight:FontWeight.w800)),
              trailing:Icon(isDone?Icons.check_circle_rounded:Icons.chevron_right_rounded,color:isDone?const Color(0xFF15958A):AtlasColors.royalBlue),
              onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_RadiologyCaseScreen(caseData:c,onComplete:()=>_mark(c)))),
            ),
          );
        },
      ),
  ),
 ]));
}

class _RadiologyCaseScreen extends StatefulWidget{
 final _Case caseData; final Future<void> Function() onComplete;
 const _RadiologyCaseScreen({required this.caseData,required this.onComplete});
 @override State<_RadiologyCaseScreen> createState()=>_RadiologyCaseScreenState();
}
class _RadiologyCaseScreenState extends State<_RadiologyCaseScreen>{
 bool reveal=false,saving=false;
 String? get imageUrl=>'assets/images/clinical/radiology/${widget.caseData.id}.jpg';
 String get attribution=>'Source, author and license details are bundled in image_manifest.json.';
 @override Widget build(BuildContext context){final c=widget.caseData;return Scaffold(backgroundColor:AtlasColors.ivory,appBar:AppBar(title:Text('Imaging Case ${c.id}')),body:ListView(padding:const EdgeInsets.all(16),children:[
 Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF174B68),Color(0xFF287F99)]),borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.mod.toUpperCase(),style:const TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1)),const SizedBox(height:10),Text(c.title,style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('SYSTEMATIC IMAGE REVIEW',style:TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1))])),
 const SizedBox(height:14),
 Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFF172D3C),borderRadius:BorderRadius.circular(17)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(children:[const Icon(Icons.photo_library_rounded,color:Color(0xFF8DD1D4)),const SizedBox(width:8),Expanded(child:Text('CLINICAL IMAGE LIBRARY',style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900)))]),
 const SizedBox(height:12),
 if(imageUrl!=null)ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.asset(imageUrl!,width:double.infinity,height:250,fit:BoxFit.contain,errorBuilder:(_,__,___)=>_imageUnavailable())) else _imageUnavailable(),
 const SizedBox(height:9),
 Text(imageUrl==null?'No unverified illustration is substituted. This case needs a diagnosis-matched, licensed clinical image before it can be published as image-complete.':attribution,style:const TextStyle(color:Color(0xFFB8C8D3),fontSize:9,height:1.4))
 ])),
 const SizedBox(height:12),_Panel(title:'YOUR TASK',body:'Identify the modality and anatomical region. Describe the dominant abnormality, its location and distribution, then build a focused differential before revealing the teaching answer.'),
 const SizedBox(height:12),
 if(!reveal)FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:const Color(0xFF236C83),padding:const EdgeInsets.symmetric(vertical:14)),onPressed:()=>setState(()=>reveal=true),icon:const Icon(Icons.visibility_rounded),label:const Text('Reveal findings & interpretation'))else ...[_Panel(title:'KEY IMAGING FINDINGS',body:c.find),const SizedBox(height:9),_Panel(title:'MOST LIKELY INTERPRETATION',body:c.diag),const SizedBox(height:12),FilledButton(style:FilledButton.styleFrom(backgroundColor:const Color(0xFF087D78),padding:const EdgeInsets.symmetric(vertical:14)),onPressed:saving?null:()async{setState(()=>saving=true);await widget.onComplete();if(mounted)Navigator.pop(context);},child:Text(saving?'Saving...':'Mark case reviewed'))],
 const SizedBox(height:14),const Text('Educational content only. Review original imaging and formal reports for clinical decisions.',textAlign:TextAlign.center,style:TextStyle(color:AtlasColors.secondaryText,fontSize:10,height:1.5))
 ]));}
 Widget _imageUnavailable()=>Container(height:180,width:double.infinity,alignment:Alignment.center,padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFF203848),borderRadius:BorderRadius.circular(10)),child:const Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.image_not_supported_outlined,color:Color(0xFF8DD1D4),size:34),SizedBox(height:9),Text('Verified clinical image is being curated for this diagnosis.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white70,fontSize:11,height:1.5))]));
}
class _Case {
 final String id,mod,title,find,diag;
 const _Case(this.id,this.mod,this.title,this.find,this.diag);
}
class _Panel extends StatelessWidget{final String title,body;const _Panel({required this.title,required this.body});@override Widget build(BuildContext context)=>Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:const Color(0xFFE0EAF1))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:AtlasColors.navy,fontSize:10,letterSpacing:.8,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(body,style:const TextStyle(color:AtlasColors.charcoal,fontSize:13,height:1.55))]));}
const List<_Case> _cases=[
  _Case('01','X-ray','Lobar pneumonia','Air-space opacity with air bronchograms confined to one lobe','Lobar consolidation'),
  _Case('02','X-ray','Pleural effusion','Meniscus-shaped basal opacity and blunted costophrenic angle','Pleural fluid'),
  _Case('03','X-ray','Pneumothorax','Visceral pleural line with absent peripheral lung markings','Pneumothorax'),
  _Case('04','X-ray','Pulmonary oedema','Bilateral perihilar opacities and septal lines','Pulmonary oedema pattern'),
  _Case('05','X-ray','Cardiomegaly','Enlarged cardiothoracic silhouette on an adequate PA film','Cardiac enlargement'),
  _Case('06','X-ray','Pulmonary tuberculosis','Upper-zone cavitation with adjacent parenchymal opacity','Cavitating upper-lobe disease'),
  _Case('07','X-ray','Miliary nodules','Numerous tiny, diffuse bilateral nodular opacities','Miliary pattern'),
  _Case('08','X-ray','COPD hyperinflation','Flattened diaphragms and increased lung volumes','Obstructive lung disease pattern'),
  _Case('09','X-ray','Lobar collapse','Opacity with fissural displacement and volume loss','Atelectasis'),
  _Case('10','X-ray','Aspiration','Dependent basal air-space opacity','Aspiration-related pneumonitis'),
  _Case('11','X-ray','ARDS','Diffuse bilateral air-space opacities','Diffuse alveolar injury pattern'),
  _Case('12','X-ray','Rib fracture','Cortical discontinuity along a rib','Rib fracture'),
  _Case('13','X-ray','Pneumoperitoneum','Free crescentic gas beneath the diaphragm','Free intraperitoneal air'),
  _Case('14','X-ray','Hiatal hernia','Retrocardiac air-fluid level','Hiatal hernia'),
  _Case('15','X-ray','Solitary lung nodule','Discrete rounded pulmonary opacity','Solitary pulmonary nodule'),
  _Case('16','X-ray','Pulmonary metastases','Multiple rounded bilateral lung opacities','Multiple pulmonary nodules'),
  _Case('17','X-ray','Interstitial fibrosis','Reticular basal markings with reduced lung volumes','Interstitial lung disease pattern'),
  _Case('18','X-ray','Pleural plaques','Bilateral focal pleural thickening, often calcified','Pleural plaques'),
  _Case('19','X-ray','Bronchiectasis','Ring shadows and tram-track bronchial markings','Bronchiectasis pattern'),
  _Case('20','X-ray','Aortic enlargement','Widened mediastinal contour','Possible thoracic aortic pathology'),
  _Case('21','CT','Epidural haematoma','Biconvex hyperdense extra-axial collection','Acute epidural haematoma'),
  _Case('22','CT','Subdural haematoma','Crescentic extra-axial blood collection','Subdural haematoma'),
  _Case('23','CT','Subarachnoid haemorrhage','Hyperdensity in basal cisterns and cortical sulci','Subarachnoid haemorrhage'),
  _Case('24','CT','Intracerebral haemorrhage','Focal hyperdense intraparenchymal blood','Intracerebral haemorrhage'),
  _Case('25','CT','Acute MCA infarct','Loss of grey-white differentiation in an arterial territory','Acute ischaemic stroke'),
  _Case('26','CT','Hydrocephalus','Ventricular enlargement with possible transependymal flow','Hydrocephalus'),
  _Case('27','CT','Midline shift','Displacement of central structures by mass effect','Intracranial mass effect'),
  _Case('28','CT','Brain abscess','Rim-enhancing lesion with central low attenuation','Brain abscess'),
  _Case('29','CT','Cerebral venous thrombosis','Dense sinus may be seen; venography shows filling defect','Cerebral venous sinus thrombosis'),
  _Case('30','CT','Pulmonary embolism','Contrast filling defect within a pulmonary artery','Pulmonary embolism'),
  _Case('31','CT','Aortic dissection','Intimal flap separating true and false lumina','Aortic dissection'),
  _Case('32','CT','Bronchiectasis','Dilated bronchi fail to taper and approach pleura','Bronchiectasis'),
  _Case('33','CT','Empyema','Pleural collection with enhancing split pleura','Pleural empyema'),
  _Case('34','CT','Sarcoidosis','Bilateral hilar and mediastinal lymphadenopathy','Sarcoidosis pattern'),
  _Case('35','CT','Appendicitis','Enlarged appendix with periappendiceal fat stranding','Acute appendicitis'),
  _Case('36','CT','Diverticulitis','Colonic wall thickening and pericolic inflammatory change','Acute diverticulitis'),
  _Case('37','CT','Small bowel obstruction','Dilated proximal bowel with a transition point','Small bowel obstruction'),
  _Case('38','CT','Acute pancreatitis','Oedematous pancreas and peripancreatic stranding','Acute pancreatitis'),
  _Case('39','CT','Renal calculus','Hyperattenuating ureteric or collecting-system focus','Urinary calculus'),
  _Case('40','CT','Abdominal aortic aneurysm','Infrarenal aortic dilatation measured outer wall to outer wall','Abdominal aortic aneurysm'),
  _Case('41','Ultrasound','Gallstones','Mobile echogenic foci with posterior acoustic shadowing','Cholelithiasis'),
  _Case('42','Ultrasound','Acute cholecystitis','Wall thickening, distension and sonographic Murphy sign','Acute cholecystitis'),
  _Case('43','Ultrasound','Bile duct dilatation','Enlarged common bile duct with possible intrahepatic duct prominence','Biliary obstruction pattern'),
  _Case('44','Ultrasound','Fatty liver','Diffuse increased hepatic echogenicity','Hepatic steatosis'),
  _Case('45','Ultrasound','Deep vein thrombosis','Vein fails to compress under probe pressure','Deep venous thrombosis'),
  _Case('46','Ultrasound','Hydronephrosis','Anechoic dilatation of renal pelvis and calyces','Hydronephrosis'),
  _Case('47','Ultrasound','Simple renal cyst','Anechoic thin-walled lesion with posterior enhancement','Simple renal cyst'),
  _Case('48','Ultrasound','Thyroid nodule','Characterise composition, echogenicity, margins and shape','Thyroid nodule requiring risk stratification'),
  _Case('49','Ultrasound','Testicular torsion','Reduced or absent intratesticular Doppler flow','Testicular torsion'),
  _Case('50','Ultrasound','Abdominal aortic aneurysm','Focal enlargement of abdominal aortic diameter','Abdominal aortic aneurysm'),
  _Case('51','Ultrasound','Ovarian torsion','Enlarged ovary with peripheral follicles and possible twisted pedicle','Ovarian torsion'),
  _Case('52','Ultrasound','Ectopic pregnancy','Adnexal mass or extrauterine gestational sac; assess free fluid','Possible ectopic pregnancy'),
  _Case('53','Ultrasound','Polycystic ovarian morphology','Increased follicle number and/or ovarian volume','Polycystic ovarian morphology'),
  _Case('54','Ultrasound','Breast simple cyst','Anechoic oval lesion with thin wall and posterior enhancement','Simple breast cyst'),
  _Case('55','Ultrasound','Breast suspicious mass','Irregular hypoechoic mass with non-circumscribed margins','Suspicious breast lesion'),
  _Case('56','Ultrasound','Placenta praevia','Placental tissue overlies or approaches internal cervical os','Low-lying placenta or praevia'),
  _Case('57','Ultrasound','Placental abruption','Ultrasound may show retroplacental collection but can be normal','Possible placental abruption'),
  _Case('58','Ultrasound','Appendicitis on ultrasound','Non-compressible blind-ending tubular structure','Acute appendicitis'),
  _Case('59','Ultrasound','Intussusception','Concentric target or doughnut sign on transverse view','Intussusception'),
  _Case('60','Ultrasound','Pyloric stenosis','Thickened elongated pyloric channel with limited passage','Hypertrophic pyloric stenosis'),
  _Case('61','MRI','Multiple sclerosis','Ovoid T2/FLAIR lesions in characteristic periventricular locations','Demyelinating disease pattern'),
  _Case('62','MRI','Acute cerebral infarct','Restricted diffusion with high DWI and low ADC signal','Acute cerebral infarction'),
  _Case('63','MRI','High-grade glioma','Irregular enhancing infiltrative mass with necrosis and oedema','High-grade glioma pattern'),
  _Case('64','MRI','Lumbar disc herniation','Focal disc material extends beyond disc margin','Intervertebral disc herniation'),
  _Case('65','MRI','Cauda equina compression','Severe canal compromise with compressed nerve roots','Cauda equina compression'),
  _Case('66','MRI','ACL tear','Discontinuous or abnormally oriented ACL fibres','Anterior cruciate ligament tear'),
  _Case('67','MRI','Rotator cuff tear','Fluid-signal defect traversing tendon fibres','Rotator cuff tear'),
  _Case('68','MRI','Femoral head osteonecrosis','Serpiginous subchondral low-signal rim','Avascular necrosis'),
  _Case('69','MRI','Endometrioma','T1-bright blood products with characteristic shading','Ovarian endometrioma'),
  _Case('70','MRI','Suspicious breast enhancement','Irregular mass or non-mass enhancement','Suspicious breast lesion'),
  _Case('71','MRI','Meningioma','Dural-based extra-axial enhancing mass','Meningioma'),
  _Case('72','MRI','Acoustic schwannoma','Enhancing internal auditory canal/cerebellopontine angle lesion','Vestibular schwannoma'),
  _Case('73','MRI','Pituitary macroadenoma','Sellar mass with possible suprasellar extension','Pituitary macroadenoma'),
  _Case('74','MRI','Spinal cord compression','Cord indentation with reduced surrounding CSF space','Spinal cord compression'),
  _Case('75','MRI','Vertebral osteomyelitis','Endplate marrow oedema and disc-space inflammatory change','Spondylodiscitis'),
  _Case('76','MRI','Meniscal tear','Linear signal reaches an articular surface','Meniscal tear'),
  _Case('77','MRI','Osteochondral injury','Subchondral defect with cartilage and marrow abnormality','Osteochondral lesion'),
  _Case('78','MRI','Hip labral tear','Fluid signal cleft at acetabular labrum','Acetabular labral tear'),
  _Case('79','MRI','Prostate lesion','Focal restricted diffusion and suspicious T2 signal','Suspicious prostate lesion'),
  _Case('80','MRI','Uterine fibroid','Well-defined low T2 signal myometrial mass','Leiomyoma'),
];
