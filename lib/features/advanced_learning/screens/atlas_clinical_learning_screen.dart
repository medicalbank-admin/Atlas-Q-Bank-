import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:interactive_3d/interactive_3d.dart';
import '../../../app/atlas_academy_app.dart';
import '../../anatomy/data/anatomy_catalog.dart';
import '../../anatomy/data/detailed_skeleton_catalog.dart';

class AtlasClinicalLearningScreen extends StatefulWidget {
  final String initialMode;
  const AtlasClinicalLearningScreen({super.key, this.initialMode = 'spotter'});
  @override State<AtlasClinicalLearningScreen> createState() => _AtlasClinicalLearningScreenState();
}

class _AtlasClinicalLearningScreenState extends State<AtlasClinicalLearningScreen> {
  late String mode;
  @override void initState() { super.initState(); mode = widget.initialMode; }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AtlasColors.ivory,
    appBar: AppBar(title: const Text('Clinical Learning Studio')),
    body: Column(children: [
      Container(margin: const EdgeInsets.fromLTRB(16, 8, 16, 12), padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AtlasColors.navy, AtlasColors.royalBlue]), borderRadius: BorderRadius.circular(20)),
        child: const Row(children: [
          Icon(Icons.medical_information_rounded, color: Colors.white, size: 34), SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Think clinically. Learn deeply.', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            SizedBox(height: 4), Text('Spotters • Clinical correlations • Advanced MCQs', style: TextStyle(color: Color(0xFFDCEBFA), fontSize: 12))
          ]))
        ])),
      Row(children: [
        _Mode(label: 'Spotters', icon: Icons.view_in_ar_rounded, active: mode == 'spotter', onTap: () => setState(() => mode = 'spotter')),
        _Mode(label: 'Clinical cases', icon: Icons.monitor_heart_rounded, active: mode == 'cases', onTap: () => setState(() => mode = 'cases')),
        _Mode(label: 'MCQ bank', icon: Icons.quiz_rounded, active: mode == 'quiz', onTap: () => setState(() => mode = 'quiz')),
      ]),
      const SizedBox(height: 8),
      Expanded(child: mode == 'spotter' ? const _SpotterScreen() : mode == 'cases' ? const _CasesScreen() : const _QuizScreen())
    ])
  );
}

class _Mode extends StatelessWidget {
  final String label; final IconData icon; final bool active; final VoidCallback onTap;
  const _Mode({required this.label, required this.icon, required this.active, required this.onTap});
  @override Widget build(BuildContext context) => Expanded(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? AtlasColors.navy : Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: active ? AtlasColors.navy : AtlasColors.border)),
        child: Column(children: [
          Icon(icon, color: active ? Colors.white : AtlasColors.royalBlue, size: 19),
          const SizedBox(height: 5),
          FittedBox(child: Text(label, style: TextStyle(color: active ? Colors.white : AtlasColors.charcoal, fontSize: 11, fontWeight: FontWeight.w800)))
        ]))
    )
  ));
}

const _maleSpotterModel = 'https://cdn.jsdelivr.net/npm/open-anatomy-3d@0.1.0/models/anatomy-male.glb';
const _femaleSpotterModel = 'https://cdn.jsdelivr.net/npm/open-anatomy-3d@0.1.0/models/anatomy-female.glb';
const _skeletonSpotterModel = 'https://raw.githubusercontent.com/organui/skeleton-3d/120fc17278559057b37aff516eee89d263b604c6/public/models/skeleton.glb';

class _SpotterScreen extends StatefulWidget {
  const _SpotterScreen();
  @override State<_SpotterScreen> createState() => _SpotterScreenState();
}
class _SpotterScreenState extends State<_SpotterScreen> {
  final Interactive3dController controller = Interactive3dController();
  String system = 'organs';
  String sex = 'male';
  String? selectedKey;
  Map<String,String>? target;
  int correct = 0, step = 0;
  static const int total = 5;
  bool finished = false;
  String get modelUrl => system == 'skeleton' ? _skeletonSpotterModel : (sex == 'male' ? _maleSpotterModel : _femaleSpotterModel);
  List<Map<String,String>> get targets {
    final source = system == 'skeleton' ? detailedSkeletonCatalog : anatomyCatalog;
    return source.where((e) => e['system'] == system && e['key'] != null && e['label'] != null).map((e) => Map<String,String>.from(e)).toList();
  }
  void start() {
    final list = targets;
    if (list.isEmpty) return;
    list.shuffle(Random());
    setState(() { target = list.first; step = 0; correct = 0; finished = false; selectedKey = null; });
  }
  void nextTarget() {
    final list = targets.where((e) => e['key'] != target?['key']).toList()..shuffle(Random());
    if (list.isEmpty) { finish(); return; }
    setState(() { target = list.first; selectedKey = null; });
  }
  void finish() {
    setState(() { finished = true; target = null; });
    _saveAttempt('3d_spotter', system, correct, total);
  }
  void onSelection(List<EntityData> parts) {
    if (parts.isEmpty || target == null || finished) return;
    final name = parts.last.name;
    setState(() => selectedKey = name);
    if (name == target!['key']) {
      setState(() { correct++; step++; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correct identification.')));
      if (step >= total) { finish(); } else { nextTarget(); }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not quite. Rotate or zoom the model and try again.')));
    }
  }
  @override Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16,10,16,24), children: [
      Text('Interactive 3D spotter challenge', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AtlasColors.navy,fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      const Text('Rotate, zoom and tap anatomical structures directly on the 3D model. Complete five identification stations per round.', style: TextStyle(color: AtlasColors.secondaryText,height:1.45)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(value: system, isExpanded: true, decoration: const InputDecoration(labelText: 'Model system'), items: const [
          DropdownMenuItem(value:'organs',child:Text('Organs and viscera')),
          DropdownMenuItem(value:'muscles',child:Text('Muscles')),
          DropdownMenuItem(value:'vessels',child:Text('Blood vessels')),
          DropdownMenuItem(value:'nerves',child:Text('Nerves')),
          DropdownMenuItem(value:'skeleton',child:Text('Detailed skeleton')),
          DropdownMenuItem(value:'skin',child:Text('Skin')),
          DropdownMenuItem(value:'joints',child:Text('Joints')),
        ], onChanged: (v) { if(v!=null) setState(() { system=v; target=null; selectedKey=null; finished=false; step=0; correct=0; }); })),
        if (system != 'skeleton') ...[
          const SizedBox(width:8),
          SizedBox(width:105, child: DropdownButtonFormField<String>(value:sex, decoration: const InputDecoration(labelText:'Model'), items: const [
            DropdownMenuItem(value:'male',child:Text('Male')),
            DropdownMenuItem(value:'female',child:Text('Female')),
          ], onChanged:(v){ if(v!=null) setState(() { sex=v; target=null; selectedKey=null; finished=false; }); })),
        ]
      ]),
      const SizedBox(height: 12),
      Container(height: 390, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: const Color(0xFF07182C),borderRadius: BorderRadius.circular(20),border: Border.all(color: const Color(0xFF183A5C))), child: Interactive3d(
        key: ValueKey(modelUrl),
        controller: controller,
        modelUrl: modelUrl,
        defaultZoom: 1.3,
        backgroundColor: const Color(0xFF07182C),
        selectionColor: const [0.20,0.66,1.0,1.0],
        onSelectionChanged: onSelection,
        loadingWidget: const Center(child: Column(mainAxisSize: MainAxisSize.min,children: [
          CircularProgressIndicator(color: Color(0xFF9CC9ED)),
          SizedBox(height:12),
          Text('Loading interactive 3D model…',style:TextStyle(color:Colors.white70,fontSize:12))
        ])),
        errorBuilder: (context,error) => Center(child: Padding(padding: const EdgeInsets.all(20),child: Column(mainAxisSize:MainAxisSize.min,children: [
          const Icon(Icons.cloud_off_rounded,color:Color(0xFF9CC9ED),size:36),
          const SizedBox(height:8),
          const Text('3D model could not be loaded',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),
          Text(error.toString(),textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:11))
        ]))),
      )),
      const SizedBox(height: 12),
      if (target == null && !finished) SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:start,icon:const Icon(Icons.play_arrow_rounded),label:const Text('Start 5-station challenge'))),
      if (target != null) Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Expanded(child:Text('STATION '+(step+1).toString()+' OF '+total.toString(),style:const TextStyle(color:AtlasColors.royalBlue,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:.8))),
          Text(correct.toString()+'/'+total.toString(),style:const TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900))
        ]),
        const SizedBox(height:7),
        Text('Find: '+(target!['label']??'Target structure'),style:const TextStyle(color:AtlasColors.navy,fontSize:19,fontWeight:FontWeight.w900)),
        const SizedBox(height:6),
        Text('Tap the correct structure on the model. Your selection will be checked automatically.',style:const TextStyle(color:AtlasColors.secondaryText,height:1.4)),
        if(selectedKey!=null) Padding(padding:const EdgeInsets.only(top:8),child:Text('Selected: '+selectedKey!,style:const TextStyle(color:AtlasColors.royalBlue,fontWeight:FontWeight.w800)))
      ]))),
      if(finished) Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
        const Icon(Icons.emoji_events_rounded,color:AtlasColors.warning,size:38),
        const SizedBox(height:7),
        const Text('Challenge completed',style:TextStyle(color:AtlasColors.navy,fontWeight:FontWeight.w900,fontSize:19)),
        Text(correct.toString()+' / '+total.toString()+' correct',style:const TextStyle(color:AtlasColors.royalBlue,fontSize:24,fontWeight:FontWeight.w900)),
        const SizedBox(height:10),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:start,child:const Text('Start another round')))
      ]))),
      const SizedBox(height: 8),
      const _Notice('3D models are streamed from the model providers when the spotter is opened. An internet connection is required for the initial model load.'),
    ]);
  }
}

class _Case {
  final String title, specialty, presentation, history, examination, investigations, reasoning, differential, management, question, answer, explanation;
  const _Case(this.title, this.specialty, this.presentation, this.history, this.examination, this.investigations, this.reasoning, this.differential, this.management, this.question, this.answer, this.explanation);
}
const _cases = <_Case>[
  _Case('Inferior STEMI with right ventricular involvement','Cardiology','A 62-year-old man has 45 minutes of crushing chest pain radiating to the left arm, diaphoresis and nausea.','Hypertension, type 2 diabetes and tobacco exposure. Pain began at rest.','Hypotension after nitrate, elevated JVP and clear lungs. ECG shows ST elevation in II, III and aVF.','Obtain serial high-sensitivity troponin, electrolytes, renal function, ECG with right-sided leads and urgent coronary angiography as indicated.','Inferior STEMI with hypotension, raised JVP and clear lungs suggests right ventricular infarction. Assess haemodynamic stability and AV conduction.','Aortic dissection, pulmonary embolism, pericarditis and non-ST-elevation ACS.','Activate immediate reperfusion pathway; use antiplatelet and anticoagulant therapy according to local ACS protocol. Avoid preload reduction in suspected RV infarction and monitor closely.','Which coronary artery is the commonest culprit in an inferior STEMI in a right-dominant circulation?','Right coronary artery','The RCA usually supplies the inferior wall in right-dominant circulation; the circumflex may be responsible in left dominance.'),
  _Case('Severe acute asthma','Respiratory','A 24-year-old with asthma develops rapidly worsening breathlessness after a viral illness and cannot complete sentences.','Frequent reliever use and poor adherence to inhaled corticosteroid. Previous asthma admission.','RR 32/min, pulse 128/min, SpO2 91% on room air, accessory muscle use and PEF 35% of personal best.','Serial peak flow and pulse oximetry; blood gas if severe or deteriorating. A normalising or rising PaCO2 is concerning.','The clinical picture meets severe exacerbation criteria. A quiet chest, exhaustion, altered consciousness or rising PaCO2 indicates life-threatening disease.','Pneumothorax, pneumonia, anaphylaxis, pulmonary embolism and inducible laryngeal obstruction.','Urgent senior review, controlled oxygen, repeated inhaled beta-2 agonist, ipratropium in severe attacks, early systemic corticosteroid and IV magnesium when response is inadequate, following local emergency guidance.','Why is a normal or rising PaCO2 concerning in a severely breathless asthmatic?','Respiratory muscle fatigue and impending ventilatory failure','Early asthma usually causes hypocapnia. Normalising or rising PaCO2 in a distressed patient may indicate exhaustion and failing ventilation.'),
  _Case('Diabetic ketoacidosis','Endocrinology','A 19-year-old with type 1 diabetes presents with vomiting, abdominal pain, polyuria and deep rapid breathing.','Missed insulin during a febrile illness with marked thirst and weight loss.','Dry mucosa, tachycardia, hypotension and Kussmaul respiration.','Glucose 28 mmol/L, beta-hydroxybutyrate 5.8 mmol/L, venous pH 7.12 and bicarbonate 9 mmol/L. Check potassium, renal function and precipitant.','Hyperglycaemia, ketonaemia and metabolic acidosis establish DKA. Total body potassium is depleted even if serum potassium is initially high.','Starvation ketosis, alcoholic ketoacidosis, lactic acidosis and hyperosmolar state.','Protocol-based IV isotonic fluid, fixed-rate IV insulin, potassium replacement based on measured level and close monitoring of glucose, ketones, electrolytes and pH.','Why can serum potassium fall rapidly after insulin is started?','Insulin shifts potassium into cells','DKA causes total-body potassium loss; insulin stimulates cellular potassium uptake and can reveal severe depletion.'),
  _Case('Dominant MCA stroke','Neurology','A 72-year-old develops sudden right facial droop, right arm weakness and expressive aphasia while eating breakfast.','Atrial fibrillation and hypertension. Last known well 70 minutes before arrival.','Aphasia, right lower facial weakness, right arm power 2/5 and right leg power 4/5.','Urgent non-contrast CT to exclude haemorrhage; CT angiography for large-vessel occlusion. Check glucose and reperfusion eligibility.','The abrupt focal cortical syndrome localises to the dominant left hemisphere, likely left MCA territory. Establish exact last-known-well time.','Intracranial haemorrhage, hypoglycaemia, seizure with postictal paresis and migraine aura.','Activate stroke pathway and assess IV thrombolysis and thrombectomy eligibility under current imaging and local guideline criteria.','Which territory best explains aphasia with contralateral face and arm weakness greater than leg?','Left middle cerebral artery territory','The dominant MCA supplies lateral frontal and parietal cortex involved in language and face-arm motor function.'),
  _Case('Variceal upper GI haemorrhage','Gastroenterology','A 54-year-old with cirrhosis presents with large-volume haematemesis and dizziness.','Alcohol-related cirrhosis with previous ascites and splenomegaly.','Tachycardia, hypotension, cool peripheries and stigmata of chronic liver disease.','FBC, coagulation, renal and liver profile, group-and-crossmatch and urgent endoscopy after resuscitation.','Portal hypertension makes variceal bleeding a major concern. Resuscitation and early vasoactive therapy should not await endoscopy.','Peptic ulcer, erosive gastritis, Mallory-Weiss tear and malignancy.','Resuscitate, start vasoactive therapy and antibiotic prophylaxis for suspected variceal bleeding, then arrange urgent endoscopic haemostasis with specialist input.','Which vasoactive agent is commonly started early for suspected variceal haemorrhage?','Terlipressin','Terlipressin reduces splanchnic inflow and portal pressure; use local protocols and monitor for adverse effects.'),
  _Case('Ectopic pregnancy','Obstetrics and gynaecology','A 29-year-old with seven weeks of amenorrhoea presents with unilateral pelvic pain and vaginal spotting.','Previous pelvic inflammatory disease and presyncope on standing.','Tachycardia and lower abdominal tenderness. Assess haemodynamic stability and peritoneal signs.','Pregnancy test, quantitative beta-hCG and transvaginal ultrasound in stable patients; FBC and group-and-save.','Pregnancy with unilateral pain and bleeding is ectopic until excluded. Instability or peritoneal signs suggest rupture.','Threatened miscarriage, ovarian torsion, ruptured ovarian cyst and PID.','Urgent gynaecology review. Resuscitate suspected rupture and arrange emergency surgery; stable cases may qualify for expectant, medical or surgical management.','Which history is a recognised risk factor for tubal ectopic pregnancy?','Previous pelvic inflammatory disease','Tubal inflammation and scarring can impair embryo transport and increase tubal implantation risk.'),
  _Case('Acute kidney injury with volume depletion','Nephrology','A 78-year-old develops oliguria and confusion after three days of diarrhoea and poor oral intake.','CKD stage 3; taking an ACE inhibitor and NSAIDs.','Dry mucosa, postural hypotension and reduced skin turgor. Assess volume status and bladder distension.','Creatinine rises from 110 to 260 micromol/L. Check electrolytes, urinalysis, urine output and bladder scan; image if obstruction suspected.','Volume depletion plus medicines that impair renal autoregulation suggests pre-renal AKI, but obstruction and intrinsic disease must be assessed.','Acute tubular injury, interstitial nephritis, glomerulonephritis and post-renal obstruction.','Review nephrotoxic or haemodynamically adverse drugs, restore volume with reassessment, monitor potassium and urine output, and escalate complications.','Why can ACE inhibition plus NSAID use worsen renal function during hypovolaemia?','Reduced efferent constriction and afferent prostaglandin-mediated dilation','ACE inhibition reduces efferent tone while NSAIDs reduce afferent dilation, lowering intraglomerular pressure.'),
];

class _CasesScreen extends StatelessWidget {
  const _CasesScreen();
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text('Clinical correlation library', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), const Text('Work from presentation to localisation, differential diagnosis, investigations and safe management.', style: TextStyle(color: AtlasColors.secondaryText)),
    const SizedBox(height: 12),
    ..._cases.map((c) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
      leading: CircleAvatar(backgroundColor: AtlasColors.paleBlue, child: Icon(Icons.medical_services_rounded, color: AtlasColors.royalBlue)),
      title: Text(c.title, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
      subtitle: Text(c.specialty+' • Case-based reasoning\n'+c.presentation, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AtlasColors.secondaryText, height: 1.4)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AtlasColors.royalBlue),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CaseDetail(c))),
    ))),
    const _Notice('Clinical cases are for education, not patient-specific advice. Verify treatment decisions against current guidelines and local protocols.')
  ]);
}

class _CaseDetail extends StatefulWidget {
  final _Case c; const _CaseDetail(this.c);
  @override State<_CaseDetail> createState() => _CaseDetailState();
}
class _CaseDetailState extends State<_CaseDetail> {
  String? selected; bool checked = false;
  @override Widget build(BuildContext context) {
    final c = widget.c;
    final options = [c.answer, 'An unrelated diagnosis', 'A normal physiological response', 'A finding that excludes the clinical syndrome']..shuffle(Random(c.title.hashCode));
    return Scaffold(backgroundColor: AtlasColors.ivory, appBar: AppBar(title: const Text('Clinical case review')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: AtlasColors.navy, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.specialty.toUpperCase(), style: const TextStyle(color: Color(0xFFB9D9F4), fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 7), Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))
        ])),
        _CasePanel('1. Presentation', c.presentation), _CasePanel('2. History', c.history),
        _CasePanel('3. Examination', c.examination), _CasePanel('4. Investigations', c.investigations),
        _CasePanel('5. Clinical reasoning', c.reasoning), _CasePanel('6. Differential diagnosis', c.differential),
        _CasePanel('7. Management principles', c.management),
        Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DECISION CHECKPOINT', style: TextStyle(color: AtlasColors.royalBlue, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8), Text(c.question, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900, fontSize: 16)),
          ...options.map((o) => RadioListTile<String>(value: o, groupValue: selected, onChanged: checked ? null : (v) => setState(() => selected = v), contentPadding: EdgeInsets.zero, title: Text(o, style: const TextStyle(color: AtlasColors.charcoal)))),
          if (!checked) SizedBox(width: double.infinity, child: FilledButton(onPressed: selected == null ? null : () { setState(() => checked = true); _saveAttempt('clinical_case', c.title, selected == c.answer ? 1 : 0, 1); }, child: const Text('Check decision'))),
          if (checked) Text('Best answer: '+c.answer+'\n\n'+c.explanation, style: const TextStyle(color: AtlasColors.charcoal, height: 1.5, fontWeight: FontWeight.w600))
        ])))
      ]));
  }
}
class _CasePanel extends StatelessWidget {
  final String title, body; const _CasePanel(this.title, this.body);
  @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 8), child: ExpansionTile(title: Text(title, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [Align(alignment: Alignment.centerLeft, child: Text(body, style: const TextStyle(color: AtlasColors.charcoal, height: 1.55)))]));
}

class _Q {
  final String system, stem, a, b, c, d, explanation; final int answer;
  const _Q(this.system, this.stem, this.a, this.b, this.c, this.d, this.answer, this.explanation);
  _Q shuffledOptions(Random random) {
    final options = [a, b, c, d];
    final correctText = options[answer];
    options.shuffle(random);
    return _Q(system, stem, options[0], options[1], options[2], options[3], options.indexOf(correctText), explanation);
  }
}
const _bank = <_Q>[
_Q('Cardiology','Inferior STEMI with hypotension, raised JVP and clear lungs after nitrate suggests which complication?','Acute mitral regurgitation','Right ventricular infarction','Ventricular septal rupture','Papillary muscle rupture',1,'Right ventricular infarction is preload dependent; nitrates can reduce venous return and cause hypotension.'),
_Q('Cardiology','Aortic stenosis classically produces which murmur radiation?','Axilla','Carotids','Back only','Left lower sternal edge',1,'The ejection systolic murmur of aortic stenosis radiates to the carotids.'),
_Q('Cardiology','Which ECG pattern supports atrial fibrillation?','Regular P waves','Irregularly irregular RR with no discrete P waves','Fixed PR interval','Saw-tooth flutter waves',1,'Disorganised atrial activity produces absent consistent P waves and irregular ventricular intervals.'),
_Q('Cardiology','Which manoeuvre increases the murmur of hypertrophic obstructive cardiomyopathy?','Squatting','Passive leg raise','Valsalva strain','Handgrip',2,'Reduced preload during Valsalva increases dynamic LV outflow obstruction.'),
_Q('Cardiology','A patient with a mechanical mitral valve requires which standard oral anticoagulant?','Apixaban','Rivaroxaban','Warfarin','Dabigatran',2,'Vitamin K antagonist therapy is standard for mechanical valves; DOACs are not recommended.'),
_Q('Cardiology','Diffuse concave ST elevation with PR depression most strongly suggests:','Territorial STEMI','Acute pericarditis','Hyperkalaemia','Pulmonary embolism',1,'Widespread concave ST elevation and PR depression support pericarditis.'),
_Q('Cardiology','A regular wide-complex tachycardia with hypotension and a pulse requires:','Oral beta blocker','Synchronized cardioversion','Carotid massage','Observation',1,'Unstable tachycardia with a pulse requires urgent synchronized cardioversion.'),
_Q('Cardiology','BNP release is stimulated most directly by:','Ventricular wall stretch','Low atrial pressure','Hypoglycaemia','Reduced preload',0,'Ventricular myocytes release BNP in response to increased wall stress.'),
_Q('Cardiology','Aortic regurgitation produces which murmur timing?','Mid-systolic','Early diastolic','Late diastolic only','Continuous',1,'Aortic regurgitation classically produces an early diastolic decrescendo murmur.'),
_Q('Cardiology','Kussmaul sign is a paradoxical rise in JVP during:','Expiration','Inspiration','Valsalva release','Standing',1,'Failure of JVP to fall or a rise during inspiration is Kussmaul sign.'),
_Q('Respiratory','Initial oxygen target in a COPD patient at risk of hypercapnic respiratory failure is usually:','94–98%','88–92%','99–100%','80–84%',1,'Controlled oxygen targeting 88–92% is commonly used pending blood gas assessment.'),
_Q('Respiratory','Hypotension, tracheal deviation and absent breath sounds after chest trauma indicate:','Simple pneumothorax','Tension pneumothorax','Pleural effusion','Lobar pneumonia',1,'Tension pneumothorax is a clinical emergency; decompress without waiting for imaging.'),
_Q('Respiratory','Which imaging test is commonly used to confirm pulmonary embolism in a stable patient?','CT pulmonary angiography','Plain abdominal film','Bronchoscopy','Spirometry',0,'CTPA is the usual definitive imaging test when appropriate.'),
_Q('Respiratory','Pleural-to-serum protein ratio 0.62 classifies an effusion as:','Transudate','Exudate','Chylothorax by definition','Empyema by definition',1,'A protein ratio above 0.5 meets Light criteria for exudate.'),
_Q('Respiratory','Which organism is associated with severe bronchiectasis and poorer outcomes?','Pseudomonas aeruginosa','Streptococcus pyogenes','Neisseria meningitidis','Clostridium tetani',0,'Pseudomonas colonisation is associated with more severe bronchiectasis.'),
_Q('Respiratory','Idiopathic pulmonary fibrosis usually produces:','Reduced TLC and DLCO','Increased TLC and DLCO','Normal volumes with high DLCO','Isolated increased residual volume',0,'Fibrosis reduces lung volumes and impairs gas transfer.'),
_Q('Respiratory','A rising PaCO2 in severe asthma suggests:','Improving ventilation','Respiratory muscle fatigue','Resolved bronchospasm','Isolated alkalosis',1,'Normalising or rising PaCO2 in severe asthma can indicate impending ventilatory failure.'),
_Q('Respiratory','Upper-lobe cavitation, weight loss and night sweats should prompt evaluation for:','Pulmonary tuberculosis','Bronchiolitis','Croup','Pertussis only',0,'The combination is concerning for pulmonary TB; institute appropriate infection control.'),
_Q('Respiratory','Lung-protective ventilation in ARDS uses:','High tidal volume by actual weight','Low tidal volume by predicted body weight','Zero PEEP routinely','Permissive hyperoxia',1,'Low tidal volumes based on predicted body weight reduce ventilator-induced injury.'),
_Q('Respiratory','Which test establishes obstructive sleep apnoea?','Sleep study','Peak flow only','Methacholine challenge','Chest radiograph',0,'Polysomnography or validated sleep testing establishes OSA.'),
_Q('Neurology','Ipsilateral facial and contralateral body pain-temperature loss with dysphagia suggests:','Lateral medullary syndrome','Medial pontine syndrome','Pure motor lacune','Anterior spinal artery syndrome',0,'Lateral medullary infarction affects spinal trigeminal, spinothalamic and nucleus ambiguus pathways.'),
_Q('Neurology','The key neurotransmitter deficit in Parkinson disease is:','Nigrostriatal dopamine','NMJ acetylcholine','Cerebellar GABA','Spinal serotonin',0,'Degeneration of substantia nigra pars compacta reduces dopamine in the striatum.'),
_Q('Neurology','Ascending weakness and areflexia after diarrhoeal illness suggests:','Guillain–Barré syndrome','Myasthenia gravis','Multiple sclerosis','ALS',0,'GBS often follows infection and causes ascending weakness with reduced reflexes.'),
_Q('Neurology','Fatigable ptosis and diplopia are associated with antibodies against:','Acetylcholine receptor','Double-stranded DNA','Centromere','GBM',0,'Myasthenia gravis commonly involves antibodies to postsynaptic ACh receptors or related proteins.'),
_Q('Neurology','Intention tremor, dysmetria and broad-based gait localise to the:','Cerebellum','Basal ganglia','Hippocampus','Primary visual cortex',0,'Cerebellar dysfunction causes ipsilateral ataxia and dysmetria.'),
_Q('Neurology','Fluent speech with impaired comprehension is characteristic of:','Broca aphasia','Wernicke aphasia','Dysarthria','Apraxia only',1,'Wernicke aphasia is fluent with impaired comprehension.'),
_Q('Neurology','Painful monocular visual loss with impaired colour vision suggests:','Optic neuritis','Retinal detachment','Angle-closure glaucoma','Central retinal artery occlusion',0,'Optic neuritis causes painful visual loss and is associated with demyelination.'),
_Q('Neurology','Contralateral hemiballismus classically follows a lesion of the:','Subthalamic nucleus','Hippocampus','Caudate tail','Primary auditory cortex',0,'Subthalamic injury disrupts basal ganglia circuitry and can cause hemiballismus.'),
_Q('Neurology','Bitemporal hemianopia from a pituitary mass is due to compression of the:','Optic chiasm','Optic tract','Lateral geniculate body','Occipital pole',0,'Crossing nasal retinal fibres are compressed at the optic chiasm.'),
_Q('Neurology','A patient with meningitis has papilloedema and focal deficit. Before LP, prioritise:','Neuroimaging and senior review','Immediate LP without assessment','EEG','Discharge',0,'Signs of possible mass effect require imaging and senior review before LP; do not delay empiric treatment.'),
_Q('Endocrinology','Primary adrenal insufficiency causes elevated:','ACTH','Aldosterone','Cortisol','Insulin',0,'Low cortisol removes negative feedback and raises ACTH.'),
_Q('Endocrinology','Graves disease is associated with:','TSH receptor-stimulating antibodies','Anti-centromere','Anti-mitochondrial','Anti-GBM',0,'TSH receptor antibodies stimulate thyroid hormone production.'),
_Q('Endocrinology','SIADH typically causes:','Low serum osmolality with concentrated urine','High serum osmolality with dilute urine','Hypernatraemia','Glycosuria',0,'Excess ADH retains water, lowering serum osmolality while urine remains inappropriately concentrated.'),
_Q('Endocrinology','Hypercalcaemia with suppressed PTH and raised PTHrP suggests:','Humoral malignancy','Primary hyperparathyroidism','FHH','Vitamin D deficiency',0,'PTHrP mimics PTH actions while endogenous PTH is suppressed.'),
_Q('Endocrinology','A drug class with renal and heart-failure benefit in eligible type 2 diabetes patients is:','SGLT2 inhibitor','Sulfonylurea alone','Meglitinide','Alpha-glucosidase inhibitor only',0,'SGLT2 inhibitors reduce CKD progression and heart failure events in eligible patients.'),
_Q('Endocrinology','First-line biochemical screening for pheochromocytoma commonly uses:','Plasma free metanephrines','Random cortisol','Serum aldosterone alone','Urine ketones',0,'Plasma free or urinary fractionated metanephrines are sensitive markers.'),
_Q('Endocrinology','Fever, delirium, severe tachycardia and thyrotoxicosis indicate:','Thyroid storm','Myxoedema coma','Euthyroid goitre','Subclinical hypothyroidism',0,'Thyroid storm is life-threatening systemic decompensation due to thyrotoxicosis.'),
_Q('Endocrinology','Primary hyperaldosteronism commonly causes:','Hypertension, hypokalaemia, alkalosis','Hypotension, hyperkalaemia, acidosis','Hypercalcaemia','Hypoglycaemia',0,'Aldosterone promotes sodium retention and potassium and hydrogen ion excretion.'),
_Q('Endocrinology','DKA with initial serum potassium 5.7 mmol/L most accurately means:','Total body potassium may still be depleted','Total body potassium is increased','No monitoring is needed','Insulin moves K out of cells',0,'Osmotic diuresis depletes total-body potassium despite an initially elevated serum level.'),
_Q('Endocrinology','A parathyroid adenoma with raised calcium and non-suppressed PTH suggests:','Primary hyperparathyroidism','Vitamin D deficiency','Hypoparathyroidism','Malignancy with suppressed PTH',0,'Primary hyperparathyroidism produces hypercalcaemia with elevated or inappropriately normal PTH.'),
_Q('Renal','Nephrotic syndrome increases thrombosis risk partly through urinary loss of:','Antithrombin III','Haemoglobin','Intrinsic factor','Bilirubin',0,'Urinary loss of anticoagulant proteins such as antithrombin contributes to hypercoagulability.'),
_Q('Renal','Cola-coloured urine two weeks after streptococcal pharyngitis suggests:','Post-streptococcal GN','Minimal change disease','Diabetic nephropathy','Papillary necrosis',0,'Post-streptococcal GN causes a nephritic syndrome after a latent period.'),
_Q('Renal','Linear IgG staining along GBM is associated with:','Anti-GBM disease','Lupus nephritis','Membranous nephropathy','IgA nephropathy',0,'Anti-GBM antibodies produce linear IgG deposition and may cause pulmonary haemorrhage.'),
_Q('Renal','Normocytic anaemia in CKD is mainly due to reduced:','Erythropoietin','Intrinsic factor','Thrombopoietin','Vitamin K',0,'Diseased kidneys produce insufficient erythropoietin.'),
_Q('Renal','Peaked T waves and QRS widening in hyperkalaemia require immediate:','IV calcium','Oral binder only','Insulin withheld','Oral potassium',0,'IV calcium stabilises cardiac membranes; other therapies shift or remove potassium.'),
_Q('Renal','Red-cell casts in urine strongly suggest:','Glomerular bleeding','Lower UTI only','Bladder outlet obstruction','Diabetes insipidus',0,'RBC casts form in renal tubules and indicate glomerular inflammation or bleeding.'),
_Q('Renal','Muddy brown granular casts after shock indicate:','Acute tubular injury','Pre-renal state only','Minimal change disease','Cystitis',0,'Muddy brown casts are characteristic of acute tubular injury.'),
_Q('Renal','Increased fluid intake prevents calcium stones mainly by:','Reducing urinary supersaturation','Increasing urinary calcium','Reducing renal blood flow','Increasing oxalate absorption',0,'Higher urine volume lowers concentration and supersaturation of stone-forming solutes.'),
_Q('Renal','ACE inhibitor-associated creatinine rise in bilateral renal artery stenosis reflects loss of:','Efferent arteriolar constriction','Afferent prostaglandin dilation','Tubular secretion','Bladder tone',0,'Angiotensin II-mediated efferent constriction may maintain GFR in renal artery stenosis.'),
_Q('Renal','Dilute urine in hypernatraemia that concentrates after desmopressin suggests:','Central diabetes insipidus','Nephrogenic DI','SIADH','Primary polydipsia',0,'A response to desmopressin supports deficient ADH production.'),
_Q('Gastroenterology','Ulcerative colitis with beading of bile ducts on MRCP suggests:','Primary sclerosing cholangitis','Primary biliary cholangitis','Wilson disease','Autoimmune hepatitis only',0,'PSC is associated with UC and causes multifocal strictures and dilatation.'),
_Q('Gastroenterology','Iron deficiency, chronic diarrhoea and positive anti-tTG IgA suggest:','Coeliac disease','Lactose intolerance','UC','Chronic pancreatitis',0,'Coeliac disease is an immune-mediated gluten-sensitive enteropathy.'),
_Q('Gastroenterology','The defining feature of severe acute pancreatitis is:','Persistent organ failure','Mild lipase rise','Pain relieved by leaning forward','Transient nausea',0,'Persistent organ failure defines severe acute pancreatitis in the revised Atlanta classification.'),
_Q('Gastroenterology','GI bleeding can precipitate hepatic encephalopathy by increasing:','Gut-derived nitrogen load','Hepatic clearance','Renal erythropoietin','Bile acid synthesis',0,'Digested blood increases intestinal nitrogen and ammonia generation.'),
_Q('Gastroenterology','Painless jaundice, weight loss and palpable non-tender gallbladder suggest:','Pancreatic head cancer','Acute hepatitis','Appendicitis','Biliary colic',0,'Malignant distal biliary obstruction can cause Courvoisier sign.'),
_Q('Gastroenterology','Ascitic PMN count 380 cells/mm3 supports:','Spontaneous bacterial peritonitis','SBP excluded','Chylous ascites','Portal vein thrombosis proven',0,'An ascitic PMN count at least 250 cells/mm3 supports SBP.'),
_Q('Gastroenterology','Achalasia is characterised by:','Impaired LES relaxation and aperistalsis','Excess acid secretion','Pyloric obstruction','Increased peristalsis',0,'Achalasia involves impaired LES relaxation and absent or abnormal peristalsis.'),
_Q('Gastroenterology','Steatorrhoea in chronic pancreatitis results from reduced:','Pancreatic lipase','Intrinsic factor','Lactase','Bile production only',0,'Exocrine pancreatic insufficiency reduces lipase delivery and fat digestion.'),
_Q('Gastroenterology','SAAG at least 1.1 g/dL indicates:','Portal hypertension','Tuberculous peritonitis','Pancreatic ascites','Nephrotic syndrome proven',0,'A high serum-ascites albumin gradient supports portal hypertensive ascites.'),
_Q('Gastroenterology','Pseudomembranous colitis after clindamycin is caused by:','Clostridioides difficile','Campylobacter','Vibrio cholerae','Entamoeba',0,'C. difficile toxins cause antibiotic-associated colitis and pseudomembranes.'),
_Q('Infectious disease','In suspected bacterial meningitis with septic shock, antibiotics should be:','Given promptly without waiting for LP','Delayed for MRI','Withheld until rash','Given after culture results',0,'Empiric antibiotics are time-critical; cultures should not delay treatment.'),
_Q('Infectious disease','TMP-SMX prophylaxis in advanced HIV is used to prevent:','Pneumocystis jirovecii pneumonia','All CMV disease','Malaria','TB exclusively',0,'TMP-SMX is standard Pneumocystis prophylaxis for eligible patients with advanced immunosuppression.'),
_Q('Infectious disease','Toxic shock syndrome toxin acts as a:','Superantigen','DNA gyrase inhibitor','Folate antagonist','Acetylcholine agonist',0,'TSST-1 causes massive T-cell activation and cytokine release.'),
_Q('Infectious disease','Urgent malaria testing uses:','Thick and thin blood films','Widal only','Tuberculin test','Stool culture only',0,'Malaria requires urgent parasitological testing; repeat films may be needed.'),
_Q('Infectious disease','In stable suspected infective endocarditis, obtain before antibiotics:','Multiple blood culture sets','Exercise ECG','Anticoagulation','Sputum only',0,'Blood cultures before antibiotics improve organism detection in stable patients.'),
_Q('Infectious disease','Enteric fever is caused by:','Salmonella Typhi','Shigella sonnei','Yersinia pestis','Bordetella pertussis',0,'S. Typhi causes enteric fever; blood cultures are important early.'),
_Q('Infectious disease','A painless genital chancre is classically caused by:','Treponema pallidum','Haemophilus ducreyi','HSV-2','Candida albicans',0,'Primary syphilis causes a classically painless chancre.'),
_Q('Infectious disease','Severe falciparum malaria is treated urgently with:','Parenteral artesunate','Oral chloroquine in every region','Loperamide','Delayed PCR confirmation',0,'Severe malaria is an emergency; IV artesunate is preferred in major guidelines.'),
_Q('Infectious disease','Rifampicin is clinically important because it:','Potently induces hepatic enzymes','Potently inhibits CYP enzymes','Blocks vitamin K recycling','Inhibits MAO',0,'Rifampicin reduces concentrations of many medicines through enzyme induction.'),
_Q('Infectious disease','First-line immediate treatment for anaphylaxis is:','IM adrenaline','IV antihistamine alone','Oral steroid alone','Nebulised saline',0,'IM adrenaline is first-line alongside airway, breathing and circulation support.'),
_Q('Haematology','MAHA, thrombocytopenia, neurological symptoms and normal coagulation suggest:','TTP','DIC','ITP','Iron deficiency',0,'TTP causes platelet-rich microthrombi, MAHA and thrombocytopenia with often normal coagulation.'),
_Q('Haematology','Sickle cell disease with fever, chest pain, hypoxia and new infiltrate indicates:','Acute chest syndrome','Aplastic crisis','Splenic sequestration only','Iron overload',0,'Acute chest syndrome involves a new pulmonary infiltrate plus respiratory symptoms or fever.'),
_Q('Haematology','Prolonged PT and aPTT, low fibrinogen, thrombocytopenia and raised D-dimer suggest:','DIC','Haemophilia A','Von Willebrand disease','B12 deficiency',0,'DIC consumes platelets and clotting factors and increases fibrin breakdown.'),
_Q('Haematology','Smudge cells are classically associated with:','Chronic lymphocytic leukaemia','AML','Multiple myeloma','Hodgkin lymphoma',0,'Fragile clonal mature B lymphocytes produce smudge cells in CLL.'),
_Q('Haematology','Macrocytosis, neuropathy and hypersegmented neutrophils suggest deficiency of:','Vitamin B12','Iron','Vitamin K','Vitamin C',0,'B12 deficiency causes megaloblastic anaemia and neurological dysfunction.'),
_Q('Haematology','Suspected acute promyelocytic leukaemia with DIC requires urgent:','All-trans retinoic acid','Imatinib','Rituximab','Warfarin',0,'ATRA should be started promptly when APL is strongly suspected due to life-threatening coagulopathy.'),
_Q('Haematology','An isolated prolonged aPTT that corrects on mixing suggests:','Clotting factor deficiency','Lupus anticoagulant','Specific inhibitor','DIC',0,'Correction on mixing suggests factor deficiency; failure to correct suggests an inhibitor.'),
_Q('Haematology','Iron deficiency commonly causes which iron profile?','Low ferritin and high TIBC','High ferritin and low TIBC','High ferritin and high iron','Normal ferritin always',0,'Iron deficiency lowers ferritin and increases transferrin/TIBC.'),
_Q('Haematology','Haemophilia A is deficiency of:','Factor VIII','Factor IX','Factor VII','Factor XIII',0,'Haemophilia A is factor VIII deficiency.'),
_Q('Haematology','Suspected heparin-induced thrombocytopenia requires:','Stop heparin and use non-heparin anticoagulation as indicated','Increase heparin','Routine platelet transfusion','Continue pending tests',0,'HIT is prothrombotic; discontinue heparin and use an alternative anticoagulant when appropriate.'),
_Q('Emergency medicine','Hypotension, raised JVP and muffled heart sounds after penetrating chest trauma suggest:','Cardiac tamponade','Flail chest','Simple rib fracture','Asthma',0,'Beck triad suggests tamponade; urgent bedside assessment and intervention may be required.'),
_Q('Emergency medicine','Opioid toxicity with respiratory depression is treated with:','Naloxone','Flumazenil','Atropine','Pralidoxime',0,'Naloxone antagonises opioid receptors and reverses respiratory depression.'),
_Q('Emergency medicine','A head-injured patient with GCS 7 cannot protect their airway. Prioritise:','Airway management by trained team','CT before airway support','Oral fluids','Home observation',0,'Airway and trauma resuscitation take priority when airway protection is impaired.'),
_Q('Emergency medicine','Heat stroke with core temperature 41°C and confusion requires:','Rapid active cooling','Antipyretics alone','Warm blankets','Wait for labs',0,'Immediate rapid cooling and supportive care are time-critical.'),
_Q('Emergency medicine','An unconscious patient with severe hypoglycaemia and no IV access should receive:','Glucagon by available non-IV route','Oral glucose while unconscious','Long-acting insulin','Metformin',0,'Glucagon can be administered IM, SC or intranasally depending on product.'),
_Q('Emergency medicine','A stable patient with suspected aortic dissection is commonly investigated with:','CT angiography of aorta','Exercise ECG','Plain film only','Spirometry',0,'CTA rapidly defines dissection extent in stable patients.'),
_Q('Emergency medicine','Early sepsis management prioritises:','Antimicrobials, source control and perfusion support','Delay antibiotics for final cultures','Fluid restriction for all','Treat lactate only',0,'Sepsis requires timely antimicrobials, source control, haemodynamic support and reassessment.'),
_Q('Emergency medicine','An open tibial fracture requires early:','IV antibiotics and sterile wound coverage','Repeated wound probing','Delay antibiotics until fixation','Home reduction',0,'Early antibiotics, sterile coverage, tetanus assessment and urgent orthopaedic care reduce complications.'),
_Q('Emergency medicine','Persistent anaphylaxis after first IM adrenaline requires:','Repeat IM adrenaline and escalate resuscitation','Oral antihistamine only','Wait for tryptase','Give beta blocker',0,'Repeat IM adrenaline at recommended intervals with IV fluids and expert support.'),
_Q('Emergency medicine','Standard pulse oximetry may appear normal in carbon monoxide poisoning because it cannot distinguish:','Carboxyhaemoglobin from oxyhaemoglobin','MetHb from plasma','Haemoglobin from albumin','Oxygen from nitrogen',0,'Co-oximetry is required because conventional pulse oximetry can misread carboxyhaemoglobin.'),
_Q('Obstetrics','Severe hypertension after 20 weeks with headache, visual symptoms and proteinuria suggests:','Pre-eclampsia with severe features','Gestational diabetes','Placenta praevia','Hyperemesis',0,'Hypertension with proteinuria or end-organ features supports pre-eclampsia and needs urgent obstetric care.'),
_Q('Obstetrics','A boggy enlarged uterus with postpartum haemorrhage most likely indicates:','Uterine atony','Cervical ectropion','Ovarian torsion','Urinary retention',0,'Uterine atony is the commonest cause of postpartum haemorrhage.'),
_Q('Obstetrics','Painless bright-red bleeding in late pregnancy requires exclusion of:','Placenta praevia','Ectopic pregnancy','Ovarian torsion','Cervical polyp only',0,'Placenta praevia causes painless late-pregnancy bleeding; avoid digital examination until placental location is known.'),
_Q('Obstetrics','Medication used to prevent and treat eclamptic seizures is:','Magnesium sulfate','Haloperidol','Warfarin','Metformin',0,'Magnesium sulfate reduces eclamptic seizure risk and is standard in severe pre-eclampsia protocols.'),
_Q('Obstetrics','Dopamine antagonists can cause galactorrhoea by increasing:','Prolactin','Cortisol','Aldosterone','Thyroxine',0,'Dopamine normally inhibits prolactin release; antagonists can raise prolactin.'),
_Q('Surgery','Early periumbilical pain in appendicitis is referred via afferents around:','T10','C3','S2','L5',0,'The appendix is midgut-derived and visceral pain is referred to the T10 dermatome.'),
_Q('Surgery','Continuous severe pain, fever, tachycardia and acidosis in bowel obstruction suggest:','Strangulation and ischaemia','Uncomplicated constipation','Dyspepsia','Haemorrhoids',0,'Systemic deterioration and continuous pain suggest compromised bowel perfusion.'),
_Q('Surgery','A painful irreducible groin lump with vomiting suggests strangulated hernia. Management is:','Urgent surgical assessment','Forceful home reduction','Elective review in months','Laxatives only',0,'Strangulation threatens bowel viability and requires urgent surgical management.'),
_Q('Surgery','Fever, jaundice, RUQ pain, hypotension and confusion indicate:','Severe acute cholangitis','Uncomplicated biliary colic','IBS','Chronic pancreatitis',0,'Reynolds pentad indicates severe cholangitis requiring antibiotics and urgent biliary drainage.'),
_Q('Surgery','Board-like rigidity with sudden severe abdominal pain suggests perforated viscus. An upright chest film may show:','Free subdiaphragmatic air','Bladder air-fluid level','Cardiomegaly','Widened mediastinum only',0,'Free air under the diaphragm supports pneumoperitoneum; CT is more sensitive when appropriate.')
];

class _QuizScreen extends StatefulWidget {
  const _QuizScreen();
  @override State<_QuizScreen> createState() => _QuizScreenState();
}
class _QuizScreenState extends State<_QuizScreen> {
  String system = 'All systems';
  int amount = 20;
  List<_Q> questions = [];
  final Map<int,int> selected = {};
  final PageController pager = PageController();
  Timer? timer; int seconds = 0; bool done = false;
  int get score => questions.asMap().entries.where((e) => selected[e.key] == e.value.answer).length;
  List<String> get systems => ['All systems', ..._bank.map((q) => q.system).toSet().toList()..sort()];
  List<_Q> get pool => _bank.where((q) => system == 'All systems' || q.system == system).toList();
  void begin() {
    final random = Random();
    questions = pool.map((q) => q.shuffledOptions(random)).toList()..shuffle(random);
    questions = questions.take(min(amount, questions.length)).toList();
    selected.clear(); done = false; seconds = questions.length * 75; timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || done) { t.cancel(); return; }
      if (seconds <= 1) { setState(() => seconds = 0); finish(); }
      else { setState(() => seconds--); }
    });
    setState(() {});
  }
  Future<void> finish() async {
    if (done || questions.isEmpty) return;
    timer?.cancel(); setState(() => done = true);
    await _saveAttempt('advanced_quiz', system, score, questions.length);
  }
  void reset() { timer?.cancel(); setState(() { questions = []; selected.clear(); done = false; }); }
  @override void dispose() { timer?.cancel(); pager.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (questions.isEmpty) return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Advanced medical MCQ bank', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), Text(_bank.length.toString()+' original hardcoded single-best-answer MCQs across '+(systems.length-1).toString()+' medical systems.', style: const TextStyle(color: AtlasColors.secondaryText)),
      const SizedBox(height: 12), _Config(title: 'Medical system', child: DropdownButtonFormField<String>(value: system, isExpanded: true, items: systems.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => system = v ?? 'All systems'))),
      _Config(title: 'Questions per attempt', child: Wrap(spacing: 7, children: [10,20,50,100].map((n) => ChoiceChip(label: Text(n.toString()), selected: amount == n, onSelected: (_) => setState(() => amount = n))).toList())),
      Card(child: Padding(padding: const EdgeInsets.all(15), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ADVANCED TOOLS', style: TextStyle(color: AtlasColors.royalBlue, fontWeight: FontWeight.w900, fontSize: 10)),
        SizedBox(height: 9), _Tool('Timed sessions','75 seconds per question'), _Tool('Randomisation','New question order each attempt'), _Tool('Review','Answer key and rationale after submission'), _Tool('Progress','Score and attempt saved to your account'), _Tool('Offline','Hardcoded bank loads without network')
      ]))),
      const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: pool.isEmpty ? null : begin, icon: const Icon(Icons.play_arrow_rounded), label: Text('Start '+min(amount,pool.length).toString()+'-question quiz'))),
      const SizedBox(height: 8), const _Notice('The fixed bank is educational content. Clinical practice and high-stakes decisions must follow current evidence and local protocols.')
    ]);
    if (done) return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AtlasColors.navy,AtlasColors.royalBlue]), borderRadius: BorderRadius.circular(20)), child: Column(children: [
        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD88A), size: 40), const SizedBox(height: 8),
        const Text('Quiz completed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8), Text(score.toString()+' / '+questions.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
        Text((score / questions.length * 100).round().toString()+'% accuracy', style: const TextStyle(color: Color(0xFFDCEBFA)))
      ])),
      const SizedBox(height: 12), Row(children: [Expanded(child: OutlinedButton(onPressed: reset, child: const Text('Back to setup'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: begin, child: const Text('Try another')))]),
      ...List.generate(questions.length, (i) {
        final q = questions[i]; final hit = selected[i] == q.answer;
        final opts = [q.a,q.b,q.c,q.d];
        return Card(margin: const EdgeInsets.only(top: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('QUESTION '+(i+1).toString()+' • '+q.system, style: const TextStyle(color: AtlasColors.royalBlue, fontSize: 10, fontWeight: FontWeight.w900))), Icon(hit ? Icons.check_circle : Icons.cancel, color: hit ? AtlasColors.success : AtlasColors.error)]),
          const SizedBox(height: 7), Text(q.stem, style: const TextStyle(color: AtlasColors.charcoal, fontWeight: FontWeight.w700, height: 1.45)),
          const SizedBox(height: 6), Text('Your answer: '+(selected[i] == null ? 'Not answered' : opts[selected[i]!]), style: const TextStyle(color: AtlasColors.secondaryText)),
          Text('Best answer: '+opts[q.answer], style: const TextStyle(color: AtlasColors.success, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5), Text(q.explanation, style: const TextStyle(color: AtlasColors.charcoal, height: 1.45))
        ])));
      })
    ]);
    final m = (seconds ~/ 60).toString().padLeft(2,'0'); final s = (seconds % 60).toString().padLeft(2,'0');
    return Column(children: [
      Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Answered '+selected.length.toString()+' of '+questions.length.toString(), style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5), LinearProgressIndicator(value: selected.length/questions.length, minHeight: 6)
        ])),
        const SizedBox(width: 12), Text(m+':'+s, style: TextStyle(color: seconds < 60 ? AtlasColors.error : AtlasColors.navy, fontWeight: FontWeight.w900, fontSize: 17))
      ])),
      Expanded(child: PageView.builder(controller: pager, itemCount: questions.length, itemBuilder: (context,i) {
        final q = questions[i]; final opts = [q.a,q.b,q.c,q.d];
        return ListView(padding: const EdgeInsets.fromLTRB(16,5,16,16), children: [
          Text(q.system.toUpperCase()+' • HARD', style: const TextStyle(color: AtlasColors.royalBlue, fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 9), Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(q.stem, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800, fontSize: 17, height: 1.5)))),
          ...List.generate(4,(j) => Card(color: selected[i] == j ? AtlasColors.paleBlue : Colors.white, child: RadioListTile<int>(value: j, groupValue: selected[i], onChanged: (v) => setState(() => selected[i] = v!), title: Text(opts[j], style: const TextStyle(color: AtlasColors.charcoal)), activeColor: AtlasColors.royalBlue))),
          Row(children: [
            if (i > 0) Expanded(child: OutlinedButton(onPressed: () => pager.previousPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut), child: const Text('Previous'))),
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: () {
              if (i < questions.length - 1) pager.nextPage(duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
              else showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Submit quiz?'), content: Text(selected.length.toString()+' of '+questions.length.toString()+' questions answered. Unanswered items count as incorrect.'), actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Review')),
                FilledButton(onPressed: () { Navigator.pop(ctx); finish(); }, child: const Text('Submit'))
              ]));
            }, child: Text(i == questions.length-1 ? 'Submit quiz' : 'Next question')))
          ])
        ]);
      }))
    ]);
  }
}

class _Config extends StatelessWidget {
  final String title; final Widget child; const _Config({required this.title,required this.child});
  @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AtlasColors.navy,fontWeight: FontWeight.w900)), const SizedBox(height: 8), child])));
}
class _Tool extends StatelessWidget {
  final String title, detail; const _Tool(this.title,this.detail);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [const Icon(Icons.check_circle,color: AtlasColors.success,size:17), const SizedBox(width:8), Expanded(child: Text(title,style: const TextStyle(color: AtlasColors.charcoal,fontWeight: FontWeight.w800))), Text(detail,style: const TextStyle(color: AtlasColors.secondaryText,fontSize:11))]));
}
class _Notice extends StatelessWidget {
  final String text; const _Notice(this.text);
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF5E5),borderRadius: BorderRadius.circular(13)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline,color: AtlasColors.warning,size:18), const SizedBox(width:8), Expanded(child: Text(text,style: const TextStyle(color: AtlasColors.charcoal,fontSize:11,height:1.45)))]));
}
Future<void> _saveAttempt(String mode,String title,int correct,int total) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  try {
    await FirebaseFirestore.instance.collection('advanced_learning_attempts').add({
      'userId':user.uid,'mode':mode,'title':title,'correctAnswers':correct,
      'totalQuestions':total,'percentage':total == 0 ? 0 : correct/total*100,
      'completedAt':FieldValue.serverTimestamp()
    });
  } catch (_) { /* Offline learning must remain usable if syncing fails. */ }
}
