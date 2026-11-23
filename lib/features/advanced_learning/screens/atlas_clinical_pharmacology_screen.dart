import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';

class AtlasClinicalPharmacologyScreen extends StatefulWidget {
  const AtlasClinicalPharmacologyScreen({super.key});

  @override
  State<AtlasClinicalPharmacologyScreen> createState() =>
      _AtlasClinicalPharmacologyScreenState();
}

class _AtlasClinicalPharmacologyScreenState
    extends State<AtlasClinicalPharmacologyScreen> {
  final _search = TextEditingController();
  String _category = 'All';
  _Drug? _selected;

  static const _categories = [
    'All', 'Cardiovascular', 'Respiratory', 'Endocrine',
    'Gastrointestinal', 'Antimicrobials', 'Renal',
  ];

  static const _drugs = <_Drug>[
    _Drug(
      name: 'Metoprolol', generic: 'Metoprolol tartrate / succinate',
      group: 'Selective beta-1 adrenergic receptor blocker',
      category: 'Cardiovascular', className: 'Beta-blocker',
      summary: 'A relatively beta-1 selective antagonist used in several cardiovascular conditions. Selectivity decreases as dose increases.',
      moa: 'Competitively blocks beta-1 adrenergic receptors in the heart and juxtaglomerular apparatus. This reduces catecholamine-mediated Gs signalling, adenylyl cyclase activity and cAMP generation. Reduced PKA activity decreases calcium handling and cardiac chronotropy, inotropy and AV nodal conduction. Renal beta-1 blockade also reduces renin release.',
      steps: [
        'Metoprolol reaches cardiac tissue and binds beta-1 adrenergic receptors.',
        'Competitive antagonism limits adrenaline and noradrenaline receptor activation.',
        'Reduced Gs activation lowers adenylyl cyclase activity and intracellular cAMP.',
        'Lower PKA signalling reduces calcium-dependent pacemaker activity and contractility.',
        'Heart rate, myocardial oxygen demand and AV nodal conduction decrease; renin release is reduced.',
      ],
      indications: 'Hypertension, angina, selected tachyarrhythmias, heart failure with reduced ejection fraction (evidence-based formulations and titration), and post-myocardial-infarction care when appropriate.',
      kinetics: 'Oral absorption is good but first-pass hepatic metabolism is substantial. It is extensively metabolised by CYP2D6; exposure varies with genotype and interacting medicines. The succinate formulation is extended release.',
      dose: 'Dose is indication- and formulation-specific. In heart failure, start at a low dose and titrate gradually under clinical supervision. Do not transfer a dose between tartrate and succinate formulations without checking the regimen.',
      cautions: 'Bradycardia, significant AV block without pacing, cardiogenic shock and acute decompensated heart failure are important contraindication or caution contexts. Use carefully in bronchospastic disease; beta-1 selectivity is not absolute.',
      adverse: 'Bradycardia, hypotension, fatigue, dizziness, cold extremities, sleep disturbance and sexual dysfunction. May mask adrenergic warning symptoms of hypoglycaemia.',
      interactions: 'Verapamil, diltiazem, digoxin and other rate-slowing agents can increase bradycardia or AV block. CYP2D6 inhibitors such as fluoxetine or paroxetine may increase exposure.',
      monitoring: 'Heart rate, blood pressure, symptoms of heart failure, conduction status when indicated, and response/tolerability during dose titration.',
      pearls: 'Abrupt withdrawal may precipitate angina or other cardiac events; taper when clinically appropriate. Beta-1 selectivity is dose dependent.',
      sources: 'FDA/DailyMed metoprolol prescribing information; 2022 AHA/ACC/HFSA Heart Failure Guideline.',
    ),
    _Drug(
      name: 'Amlodipine', generic: 'Amlodipine besylate',
      group: 'Dihydropyridine L-type calcium-channel blocker',
      category: 'Cardiovascular', className: 'Calcium-channel blocker',
      summary: 'A long-acting arterial vasodilator that reduces peripheral vascular resistance.',
      moa: 'Binds dihydropyridine-sensitive L-type voltage-gated calcium channels, with predominant effects on vascular smooth muscle. Reduced transmembrane calcium influx decreases calmodulin activation and myosin light-chain kinase activity, relaxing arteriolar smooth muscle and lowering systemic vascular resistance.',
      steps: [
        'Amlodipine binds the dihydropyridine site of L-type calcium channels.',
        'Calcium entry into vascular smooth-muscle cells decreases.',
        'Intracellular calcium-calmodulin activation falls.',
        'Myosin light-chain kinase activity and actin-myosin interaction decrease.',
        'Arterioles relax, afterload and systemic vascular resistance fall, and blood pressure decreases.',
      ],
      indications: 'Hypertension and chronic stable or vasospastic angina.',
      kinetics: 'Well absorbed orally, with slow onset and a long terminal half-life. Hepatically metabolised; elimination impairment may prolong exposure.',
      dose: 'Usually administered once daily. Individualise to blood-pressure response, age, hepatic function and tolerability; consult the current product label for maximum dose and adjustments.',
      cautions: 'Severe hypotension, marked aortic stenosis and hepatic impairment require particular consideration. Use cautiously in patients with heart failure or significant coronary disease.',
      adverse: 'Peripheral oedema, flushing, dizziness, headache, palpitations and fatigue; gingival enlargement is an uncommon recognised effect.',
      interactions: 'Other antihypertensives may add to hypotension. Strong CYP3A inhibitors can increase exposure; simvastatin dose limits may apply with coadministration.',
      monitoring: 'Blood pressure, ankle oedema, dizziness and angina symptom control.',
      pearls: 'Peripheral oedema is related to preferential precapillary arteriolar dilation, not necessarily total-body fluid overload.',
      sources: 'FDA/DailyMed amlodipine prescribing information; NICE hypertension guidance.',
    ),
    _Drug(
      name: 'Lisinopril', generic: 'Lisinopril',
      group: 'Angiotensin-converting enzyme inhibitor',
      category: 'Cardiovascular', className: 'ACE inhibitor',
      summary: 'Reduces formation of angiotensin II and degradation of bradykinin.',
      moa: 'Inhibits angiotensin-converting enzyme (ACE), reducing conversion of angiotensin I to angiotensin II. Reduced angiotensin II lowers vasoconstriction and aldosterone secretion. Reduced aldosterone decreases sodium and water retention while increasing potassium retention. Reduced bradykinin breakdown contributes to vasodilation and cough/angioedema risk.',
      steps: [
        'Lisinopril inhibits ACE on vascular endothelium.',
        'Conversion of angiotensin I to angiotensin II decreases.',
        'AT1-mediated vasoconstriction and aldosterone secretion decrease.',
        'Systemic vascular resistance and sodium/water retention fall; potassium may rise.',
        'Blood pressure and cardiac afterload decrease; efferent arteriolar tone in the kidney also falls.',
      ],
      indications: 'Hypertension, heart failure, and selected patients after myocardial infarction; renal protection in appropriate proteinuric conditions according to guidelines.',
      kinetics: 'Active drug, not requiring hepatic activation. Oral bioavailability is moderate and the drug is excreted largely unchanged by the kidneys.',
      dose: 'Start and titrate according to indication, blood pressure, renal function and potassium. Lower starting doses may be required with volume depletion or renal impairment.',
      cautions: 'Pregnancy, previous ACE-inhibitor-associated angioedema and concurrent aliskiren in diabetes are important contraindication contexts. Assess renal artery stenosis, volume depletion and hyperkalaemia risk.',
      adverse: 'Dry cough, hyperkalaemia, hypotension, increased creatinine and rare but potentially life-threatening angioedema.',
      interactions: 'Potassium supplements, potassium-sparing diuretics and salt substitutes increase hyperkalaemia risk. NSAIDs may impair renal function and antihypertensive effect. Lithium toxicity risk may increase.',
      monitoring: 'Blood pressure, serum creatinine/eGFR and potassium before initiation and after starting or increasing the dose.',
      pearls: 'A modest creatinine rise can occur after initiation due to altered glomerular haemodynamics; a substantial rise requires prompt assessment.',
      sources: 'FDA/DailyMed lisinopril prescribing information; KDIGO CKD guideline.',
    ),
    _Drug(
      name: 'Furosemide', generic: 'Furosemide',
      group: 'Loop diuretic',
      category: 'Renal', className: 'Loop diuretic',
      summary: 'Produces potent natriuresis by inhibiting salt reabsorption in the thick ascending limb.',
      moa: 'Inhibits the luminal Na-K-2Cl cotransporter (NKCC2) in the thick ascending limb of the loop of Henle. This reduces NaCl reabsorption and dissipates the medullary osmotic gradient, impairing urine concentration. Increased distal sodium delivery promotes potassium and hydrogen ion loss; calcium and magnesium excretion also increase.',
      steps: [
        'Furosemide is secreted into the proximal tubule and reaches the tubular lumen.',
        'It inhibits NKCC2 on the luminal membrane of the thick ascending limb.',
        'Sodium, potassium and chloride reabsorption falls; the medullary concentration gradient weakens.',
        'More sodium and water remain in tubular fluid and reach distal nephron segments.',
        'Urine output rises; potassium, magnesium, calcium and hydrogen losses may occur.',
      ],
      indications: 'Oedema associated with heart failure, renal or hepatic disease; selected cases of hypertension and acute pulmonary oedema as part of urgent care.',
      kinetics: 'Oral absorption is variable; also available intravenously. Highly protein bound and delivered to its site of action by tubular secretion. Renal impairment can alter response.',
      dose: 'Highly individualised to indication, prior diuretic exposure, renal function and response. Acute pulmonary oedema requires urgent clinician-directed management; monitor response rather than relying on a fixed dose.',
      cautions: 'Anuria, severe electrolyte depletion and hypovolaemia are important concerns. Excessive diuresis can cause hypotension, azotaemia and metabolic alkalosis.',
      adverse: 'Hypokalaemia, hyponatraemia, hypomagnesaemia, dehydration, hypotension, metabolic alkalosis, hyperuricaemia and ototoxicity (especially with rapid high-dose IV administration or interacting drugs).',
      interactions: 'Aminoglycosides and other ototoxic drugs increase ototoxicity risk. NSAIDs may blunt diuretic response. Lithium toxicity and digoxin-related arrhythmia risk may rise with electrolyte disturbance.',
      monitoring: 'Fluid balance, weight, blood pressure, renal function, sodium, potassium, magnesium and clinical congestion.',
      pearls: 'Loop diuretics increase urinary calcium excretion, unlike thiazide diuretics which tend to reduce it.',
      sources: 'FDA/DailyMed furosemide prescribing information; major heart-failure guidance.',
    ),
    _Drug(
      name: 'Salbutamol', generic: 'Albuterol (salbutamol)',
      group: 'Short-acting beta-2 adrenergic agonist',
      category: 'Respiratory', className: 'Short-acting bronchodilator',
      summary: 'Relieves reversible bronchoconstriction through beta-2 receptor stimulation.',
      moa: 'Stimulates beta-2 adrenergic receptors on bronchial smooth muscle. Gs activation stimulates adenylyl cyclase, increasing cAMP and PKA activity. This reduces myosin light-chain kinase activity and intracellular contractile signalling, producing smooth-muscle relaxation and bronchodilation.',
      steps: [
        'Inhaled salbutamol reaches beta-2 receptors on bronchial smooth muscle.',
        'Receptor activation stimulates the Gs protein.',
        'Adenylyl cyclase generates more intracellular cAMP.',
        'PKA signalling reduces contractile calcium signalling and myosin light-chain kinase activity.',
        'Bronchial smooth muscle relaxes and airflow improves.',
      ],
      indications: 'Relief and prevention of bronchospasm in asthma and other reversible obstructive airway disease; use in acute asthma follows severity-based protocols.',
      kinetics: 'Inhaled delivery provides rapid local action. Systemically absorbed drug is metabolised mainly by conjugation and excreted in urine.',
      dose: 'Device, age and clinical setting determine dose. Acute exacerbations require a severity-based protocol and reassessment; do not delay emergency care for severe symptoms.',
      cautions: 'Use carefully in tachyarrhythmia, cardiovascular disease, hyperthyroidism, diabetes and patients predisposed to hypokalaemia.',
      adverse: 'Tremor, tachycardia, palpitations, headache, muscle cramps and transient hypokalaemia; paradoxical bronchospasm is rare but serious.',
      interactions: 'Non-selective beta-blockers can antagonise bronchodilation and provoke bronchospasm. Other sympathomimetics and drugs that lower potassium may increase adverse effects.',
      monitoring: 'Symptom relief, respiratory rate, oxygenation and peak flow when appropriate; monitor heart rate and potassium in high-dose or severe-care settings.',
      pearls: 'Frequent need for reliever therapy indicates poor asthma control and need for reassessment of anti-inflammatory treatment.',
      sources: 'GINA Global Strategy for Asthma Management; FDA/DailyMed albuterol prescribing information.',
    ),
    _Drug(
      name: 'Metformin', generic: 'Metformin hydrochloride',
      group: 'Biguanide antihyperglycaemic agent',
      category: 'Endocrine', className: 'Biguanide',
      summary: 'Primarily lowers hepatic glucose production and improves insulin sensitivity.',
      moa: 'Reduces hepatic gluconeogenesis through multiple cellular mechanisms involving mitochondrial energy state and AMP-activated protein kinase (AMPK)-related signalling. It also improves peripheral insulin sensitivity and reduces intestinal glucose absorption. It does not directly stimulate pancreatic insulin secretion.',
      steps: [
        'Metformin enters hepatocytes and affects mitochondrial energy metabolism.',
        'Cellular energy signalling changes, including increased AMP relative to ATP in relevant pathways.',
        'AMPK-related and AMPK-independent pathways suppress gluconeogenic gene expression and substrate flux.',
        'Hepatic glucose output falls; peripheral insulin sensitivity improves.',
        'Fasting and postprandial glucose decrease without directly forcing insulin release.',
      ],
      indications: 'Type 2 diabetes as foundational therapy when appropriate; selected off-label or guideline-supported uses depend on local practice.',
      kinetics: 'Not significantly metabolised. Absorbed orally and excreted unchanged by the kidneys through filtration and tubular secretion.',
      dose: 'Start low and increase gradually with meals to improve gastrointestinal tolerance. Renal function determines eligibility and maximum dosing; consult current local labelling.',
      cautions: 'Contraindicated when eGFR is below 30 mL/min/1.73 m². Temporary interruption may be needed around selected contrast procedures, acute hypoxia, severe illness or surgery according to risk and local guidance.',
      adverse: 'Diarrhoea, nausea, abdominal discomfort, reduced vitamin B12 over time and rare but serious lactic acidosis in predisposed settings.',
      interactions: 'Alcohol excess increases lactic acidosis risk. Drugs affecting renal tubular transport can alter exposure. Review iodinated contrast and acute illness precautions.',
      monitoring: 'eGFR before and during treatment, glycaemic response, gastrointestinal tolerance and periodic vitamin B12 in at-risk or long-term users.',
      pearls: 'Metformin alone rarely causes hypoglycaemia because it does not directly stimulate insulin secretion.',
      sources: 'ADA Standards of Care in Diabetes; FDA/DailyMed metformin prescribing information.',
    ),
    _Drug(
      name: 'Omeprazole', generic: 'Omeprazole',
      group: 'Proton-pump inhibitor',
      category: 'Gastrointestinal', className: 'Acid suppression',
      summary: 'Suppresses gastric acid secretion by inhibiting the parietal-cell proton pump.',
      moa: 'A prodrug that accumulates in the acidic secretory canaliculi of gastric parietal cells, where it is converted to a reactive sulfenamide. This forms covalent disulfide bonds with cysteine residues on the H+/K+-ATPase, irreversibly inhibiting the final step of gastric acid secretion until new pumps are synthesised.',
      steps: [
        'Omeprazole is absorbed and reaches gastric parietal cells.',
        'It concentrates in the acidic secretory canaliculi.',
        'Acid converts the prodrug into a reactive sulfenamide.',
        'The active metabolite covalently binds cysteine residues on H+/K+-ATPase.',
        'The proton pump is inhibited, reducing basal and stimulated gastric acid secretion.',
      ],
      indications: 'Gastro-oesophageal reflux disease, erosive oesophagitis, peptic ulcer disease, H. pylori combination regimens and selected NSAID-ulcer prevention indications.',
      kinetics: 'Enteric-coated formulations protect the acid-labile drug. Hepatically metabolised, notably through CYP2C19 and CYP3A4. Acid suppression persists beyond plasma half-life due to irreversible pump inhibition.',
      dose: 'Indication, formulation and duration determine regimen. H. pylori treatment requires combination therapy chosen according to current resistance patterns and guidelines.',
      cautions: 'Review persistent symptoms, alarm features and need for long-term therapy. Consider risks in patients with osteoporosis risk, hypomagnesaemia, recurrent infections or severe hepatic disease.',
      adverse: 'Headache, abdominal pain, nausea, diarrhoea or constipation. Long-term use has associations with hypomagnesaemia, vitamin B12 deficiency, enteric infection and other risks.',
      interactions: 'Can reduce activation of clopidogrel through CYP2C19 inhibition; review alternatives where clinically appropriate. May alter absorption of drugs dependent on gastric pH and interact with selected CYP substrates.',
      monitoring: 'Symptom response and indication/duration review; magnesium, B12 or bone health assessment when risk factors or prolonged treatment warrant it.',
      pearls: 'Best acid suppression generally occurs when taken before a meal; the drug inhibits pumps activated by food.',
      sources: 'ACG GERD guideline; FDA/DailyMed omeprazole prescribing information.',
    ),
    _Drug(
      name: 'Ceftriaxone', generic: 'Ceftriaxone sodium',
      group: 'Third-generation cephalosporin antibiotic',
      category: 'Antimicrobials', className: 'Beta-lactam antibiotic',
      summary: 'A parenteral bactericidal antibiotic that inhibits bacterial cell-wall synthesis.',
      moa: 'The beta-lactam ring binds penicillin-binding proteins (PBPs), especially transpeptidases, preventing cross-linking of peptidoglycan strands. The weakened cell wall cannot withstand osmotic stress, leading to bacterial lysis in susceptible actively dividing organisms.',
      steps: [
        'Ceftriaxone reaches the bacterial periplasmic space.',
        'Its beta-lactam ring binds susceptible penicillin-binding proteins.',
        'Transpeptidation and peptidoglycan cross-linking are inhibited.',
        'New cell wall becomes structurally weak during bacterial growth.',
        'Autolytic processes and osmotic stress contribute to bactericidal cell lysis.',
      ],
      indications: 'Selected susceptible bacterial infections including community-acquired pneumonia, meningitis, gonorrhoea and sepsis; choice depends on site, organism, resistance and guidelines.',
      kinetics: 'Administered intramuscularly or intravenously. High protein binding, broad tissue distribution and dual renal/biliary elimination; a long half-life permits once- or twice-daily regimens in many indications.',
      dose: 'Dose and duration depend strongly on infection site, organism, age and severity. Meningitis, neonatal infection and gonorrhoea have distinct regimens; use current guidelines and local resistance data.',
      cautions: 'Serious beta-lactam allergy requires assessment. Avoid mixing or simultaneous administration with calcium-containing IV solutions in neonates; biliary sludging can occur.',
      adverse: 'Diarrhoea, rash, injection-site reactions, altered liver tests, biliary precipitation and C. difficile-associated diarrhoea; rare haemolytic anaemia or severe hypersensitivity.',
      interactions: 'Warfarin effect may increase; monitor coagulation where relevant. Calcium-containing IV products require specific compatibility precautions, especially in neonates.',
      monitoring: 'Clinical response, cultures and susceptibility, allergy, renal/hepatic status in complex cases, blood counts with prolonged therapy and signs of antibiotic-associated diarrhoea.',
      pearls: 'Antibiotics should be narrowed when culture and susceptibility results permit. Ceftriaxone does not reliably cover Pseudomonas or Enterococcus.',
      sources: 'IDSA guidance relevant to infection; FDA/DailyMed ceftriaxone prescribing information.',
    ),
  ];

  List<_Drug> get _filtered => _drugs.where((drug) {
    final matchesCategory = _category == 'All' || drug.category == _category;
    final q = _search.text.trim().toLowerCase();
    final matchesSearch = q.isEmpty ||
        drug.name.toLowerCase().contains(q) ||
        drug.generic.toLowerCase().contains(q) ||
        drug.className.toLowerCase().contains(q) ||
        drug.category.toLowerCase().contains(q);
    return matchesCategory && matchesSearch;
  }).toList();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return _DrugDetailScreen(
      drug: _selected!,
      onBack: () => setState(() => _selected = null),
    );
    final drugs = _filtered;
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: const Text('Clinical Pharmacology'),
        actions: [
          IconButton(
            tooltip: 'About this library',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Atlas Clinical Pharmacology',
              children: const [Text('An educational drug library. Verify prescribing decisions against current local guidance and product information.')],
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102B4C), Color(0xFF2369A5)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.biotech_rounded, color: Color(0xFFB9DDF7), size: 25),
                SizedBox(width: 9),
                Text('ATLAS MEDICAL REFERENCE', style: TextStyle(
                  color: Color(0xFFB9DDF7), fontSize: 9,
                  fontWeight: FontWeight.w900, letterSpacing: 1.3)),
              ]),
              const SizedBox(height: 13),
              const Text('Understand every drug.', style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Explore pharmacology from molecular target to clinical effect.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _HeroPill(icon: Icons.account_tree_rounded, label: 'MOA diagrams'),
                _HeroPill(icon: Icons.science_rounded, label: 'PK / PD'),
                _HeroPill(icon: Icons.health_and_safety_rounded, label: 'Clinical safety'),
              ]),
            ]),
          ),
          const SizedBox(height: 17),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search drug, class or generic name',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty ? null : IconButton(
                onPressed: () { _search.clear(); setState(() {}); },
                icon: const Icon(Icons.close_rounded)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 38, child: ListView(
            scrollDirection: Axis.horizontal,
            children: _categories.map((category) => Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
            )).toList(),
          )),
          const SizedBox(height: 17),
          Row(children: [
            const Expanded(child: Text('DRUG LIBRARY', style: TextStyle(
              color: AtlasColors.navy, fontSize: 11, letterSpacing: 1.1,
              fontWeight: FontWeight.w900))),
            Text('${drugs.length} profiles', style: const TextStyle(
              color: AtlasColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          if (drugs.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(
              child: Text('No matching drugs. Try another search or category.')))
          else
            ...drugs.map((drug) => _DrugCard(
              drug: drug, onTap: () => setState(() => _selected = drug))),
          const SizedBox(height: 18),
          const _SafetyNote(),
        ],
      ),
    );
  }
}

class _Drug {
  final String name, generic, group, category, className, summary, moa;
  final List<String> steps;
  final String indications, kinetics, dose, cautions, adverse, interactions,
      monitoring, pearls, sources;
  const _Drug({
    required this.name, required this.generic, required this.group,
    required this.category, required this.className, required this.summary,
    required this.moa, required this.steps, required this.indications,
    required this.kinetics, required this.dose, required this.cautions,
    required this.adverse, required this.interactions, required this.monitoring,
    required this.pearls, required this.sources,
  });
}

class _DrugCard extends StatelessWidget {
  final _Drug drug;
  final VoidCallback onTap;
  const _DrugCard({required this.drug, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(19),
      child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
        Container(width: 47, height: 47, decoration: BoxDecoration(
          color: const Color(0xFFEAF3FC), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.medication_liquid_rounded,
            color: AtlasColors.royalBlue, size: 25)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(drug.name, style: const TextStyle(color: AtlasColors.navy,
            fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(drug.generic, style: const TextStyle(
            color: AtlasColors.secondaryText, fontSize: 11)),
          const SizedBox(height: 6),
          Text('${drug.className} • ${drug.category}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AtlasColors.royalBlue,
              fontSize: 10, fontWeight: FontWeight.w800)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AtlasColors.secondaryText),
      ])),
    ),
  );
}

class _DrugDetailScreen extends StatelessWidget {
  final _Drug drug;
  final VoidCallback onBack;
  const _DrugDetailScreen({required this.drug, required this.onBack});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AtlasColors.ivory,
    appBar: AppBar(
      leading: IconButton(onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded)),
      title: Text(drug.name),
    ),
    body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
      Container(padding: const EdgeInsets.all(19), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF102B4C), Color(0xFF2369A5)]),
        borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(drug.category.toUpperCase(), style: const TextStyle(
            color: Color(0xFFB9DDF7), fontSize: 9, letterSpacing: 1.2,
            fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(drug.name, style: const TextStyle(color: Colors.white,
            fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(drug.generic, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 11),
          Text(drug.group, style: const TextStyle(color: Colors.white,
            fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(drug.summary, style: const TextStyle(color: Colors.white70,
            fontSize: 12, height: 1.5)),
        ])),
      const SizedBox(height: 15),
      _SectionCard(title: 'MECHANISM OF ACTION', icon: Icons.account_tree_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(drug.moa, style: const TextStyle(color: AtlasColors.charcoal,
            fontSize: 13, height: 1.65)),
          const SizedBox(height: 16),
          const Text('MOLECULAR-TO-CLINICAL PATHWAY',
            style: TextStyle(color: AtlasColors.royalBlue, fontSize: 9,
              letterSpacing: .8, fontWeight: FontWeight.w900)),
          const SizedBox(height: 11),
          ...drug.steps.asMap().entries.map((entry) => _MechanismStep(
            number: entry.key + 1, text: entry.value,
            isLast: entry.key == drug.steps.length - 1)),
        ])),
      _SectionCard(title: 'INDICATIONS & CLINICAL USES',
        icon: Icons.medical_services_outlined, text: drug.indications),
      _SectionCard(title: 'PHARMACOKINETICS',
        icon: Icons.science_outlined, text: drug.kinetics),
      _SectionCard(title: 'DOSING PRINCIPLES',
        icon: Icons.calculate_outlined, text: drug.dose),
      _SectionCard(title: 'CONTRAINDICATIONS & PRECAUTIONS',
        icon: Icons.warning_amber_rounded, text: drug.cautions),
      _SectionCard(title: 'ADVERSE EFFECTS',
        icon: Icons.healing_outlined, text: drug.adverse),
      _SectionCard(title: 'IMPORTANT DRUG INTERACTIONS',
        icon: Icons.compare_arrows_rounded, text: drug.interactions),
      _SectionCard(title: 'MONITORING',
        icon: Icons.monitor_heart_outlined, text: drug.monitoring),
      _SectionCard(title: 'CLINICAL PEARLS',
        icon: Icons.lightbulb_outline_rounded, text: drug.pearls),
      _SectionCard(title: 'LEARNING REFERENCES',
        icon: Icons.menu_book_outlined, text: drug.sources),
      const SizedBox(height: 8),
      const _SafetyNote(),
    ]),
  );
}

class _MechanismStep extends StatelessWidget {
  final int number;
  final String text;
  final bool isLast;
  const _MechanismStep({required this.number, required this.text, required this.isLast});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: 31, child: Column(children: [
        Container(width: 27, height: 27, alignment: Alignment.center,
          decoration: const BoxDecoration(color: AtlasColors.royalBlue,
            shape: BoxShape.circle),
          child: Text('$number', style: const TextStyle(color: Colors.white,
            fontSize: 11, fontWeight: FontWeight.w900))),
        if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFB8D4ED))),
      ])),
      const SizedBox(width: 9),
      Expanded(child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF0F6FC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFDCEAF6))),
        child: Text(text, style: const TextStyle(color: AtlasColors.charcoal,
          fontSize: 12, height: 1.5, fontWeight: FontWeight.w600)),
      )),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? text;
  final Widget? child;
  const _SectionCard({required this.title, required this.icon,
    this.text, this.child});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 11),
    child: Padding(padding: const EdgeInsets.all(15), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AtlasColors.royalBlue, size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(
            color: AtlasColors.navy, fontSize: 10, letterSpacing: .65,
            fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 10),
        if (child != null) child!,
        if (text != null) Text(text!, style: const TextStyle(
          color: AtlasColors.charcoal, fontSize: 12, height: 1.6)),
      ],
    )),
  );
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white24)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 13),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white,
        fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: const Color(0xFFFFF6E8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF0D8AD))),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.health_and_safety_outlined, color: Color(0xFF9B6721), size: 18),
      SizedBox(width: 9),
      Expanded(child: Text(
        'For medical education only. This reference is not a prescribing tool. Doses and treatment choices depend on indication, patient factors, local resistance and current guidance. Verify current product information and institutional protocols before clinical use.',
        style: TextStyle(color: Color(0xFF76521F), fontSize: 10, height: 1.5))),
    ]),
  );
}
