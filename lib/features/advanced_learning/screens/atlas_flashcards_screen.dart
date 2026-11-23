import 'package:flutter/material.dart';

class AtlasFlashcard {
  final String subject, question, answer;
  const AtlasFlashcard(this.subject, this.question, this.answer);
}

/// Offline-ready authored medical recall collection. 50 core facts in four recall formats.
const String _rows = r'''
Anatomy|Recall: Phrenic nerve roots?|C3–C5; C3, 4 and 5 keep the diaphragm alive.
Anatomy|Recall: Adult femoral-head blood supply?|Retinacular branches of the medial circumflex femoral artery.
Anatomy|Recall: Nerve at risk in midshaft humeral fracture?|Radial nerve in the spiral groove.
Anatomy|Recall: Carpal tunnel contents?|Median nerve and nine flexor tendons: four FDS, four FDP and one FPL.
Anatomy|Recall: Muscle initiating shoulder abduction?|Supraspinatus initiates the first 15 degrees; deltoid continues.
Anatomy|Recall: Cranial nerve to lateral rectus?|Abducens nerve, CN VI.
Anatomy|Recall: Optic canal contents?|Optic nerve (CN II) and ophthalmic artery.
Anatomy|Recall: Femoral triangle boundaries?|Inguinal ligament superiorly, sartorius laterally and adductor longus medially.
Anatomy|Recall: Jugular foramen nerves?|Cranial nerves IX, X and XI.
Anatomy|Recall: Most common ectopic pregnancy site?|Ampulla of the uterine tube.
Physiology|Recall: Resting neuronal membrane potential?|Approximately −70 mV, largely due to potassium permeability and ion gradients.
Physiology|Recall: Ventricular action-potential plateau?|L-type calcium influx balanced by potassium efflux.
Physiology|Recall: Cardiac output formula?|Heart rate multiplied by stroke volume.
Physiology|Recall: Frank–Starling mechanism?|Greater end-diastolic filling stretches myocardium and increases contraction force within physiological limits.
Physiology|Recall: Central chemoreceptor stimulus?|CSF hydrogen ion concentration generated as CO₂ crosses the blood–brain barrier.
Physiology|Recall: Bohr effect?|Increased CO₂ and H⁺ reduce haemoglobin oxygen affinity, promoting tissue oxygen unloading.
Physiology|Recall: Hormone increasing collecting-duct water permeability?|ADH (vasopressin), via V2 receptors and aquaporin-2 insertion.
Physiology|Recall: Renal action of aldosterone?|Increases sodium reabsorption and potassium and hydrogen secretion.
Physiology|Recall: Pulmonary surfactant function?|Reduces alveolar surface tension and prevents alveolar collapse.
Physiology|Recall: Mean arterial pressure approximation?|Cardiac output multiplied by systemic vascular resistance.
Biochemistry|Recall: Rate-limiting enzyme of glycolysis?|Phosphofructokinase-1 (PFK-1).
Biochemistry|Recall: Rate-limiting enzyme of cholesterol synthesis?|HMG-CoA reductase.
Biochemistry|Recall: Vitamin needed for clotting factor gamma-carboxylation?|Vitamin K for factors II, VII, IX and X and proteins C and S.
Biochemistry|Recall: Purpose of the urea cycle?|Converts toxic ammonia to urea for excretion.
Biochemistry|Recall: Enzyme deficient in classic phenylketonuria?|Phenylalanine hydroxylase, most commonly.
Biochemistry|Recall: What HbA1c estimates?|Average glycaemic exposure over roughly the preceding 2–3 months.
Biochemistry|Recall: Apolipoprotein activating lipoprotein lipase?|Apolipoprotein C-II.
Biochemistry|Recall: Rate-limiting enzyme of heme synthesis?|ALA synthase.
Biochemistry|Recall: Cofactors required by pyruvate dehydrogenase?|TPP, lipoic acid, CoA, FAD and NAD⁺.
Biochemistry|Recall: Main source of NADPH in red cells?|Pentose phosphate pathway via glucose-6-phosphate dehydrogenase.
Pathology|Recall: Necrosis typical of myocardial infarction?|Coagulative necrosis.
Pathology|Recall: Necrosis typical of cerebral infarction?|Liquefactive necrosis.
Pathology|Recall: Classic association of caseous necrosis?|Tuberculosis; it has a granular, cheese-like appearance.
Pathology|Recall: Characteristic cell in Hodgkin lymphoma?|Reed–Sternberg cell, classically CD15 and CD30 positive.
Pathology|Recall: Definition of metaplasia?|Reversible replacement of one mature cell type by another better suited to a stress.
Pathology|Recall: Definition of dysplasia?|Disordered epithelial maturation with cytological atypia; it may be premalignant.
Pathology|Recall: Tumour suppressor associated with Li–Fraumeni syndrome?|TP53.
Pathology|Recall: Genetic hallmark of chronic myeloid leukaemia?|BCR::ABL1 fusion from t(9;22), the Philadelphia chromosome.
Pathology|Recall: Key pathological feature of emphysema?|Permanent airspace enlargement distal to terminal bronchioles with alveolar wall destruction.
Pathology|Recall: Most common nephrotic syndrome in children?|Minimal change disease.
Pharmacology|Recall: Mechanism of ACE inhibitors?|Inhibit angiotensin-converting enzyme, reducing angiotensin II and aldosterone and increasing bradykinin.
Pharmacology|Recall: Important ACE inhibitor adverse effects?|Cough, hyperkalaemia, hypotension and angioedema; avoid in pregnancy.
Pharmacology|Recall: Mechanism of warfarin?|Inhibits vitamin K epoxide reductase, reducing functional vitamin K-dependent clotting factors.
Pharmacology|Recall: Reversal agent for unfractionated heparin?|Protamine sulfate.
Pharmacology|Recall: Mechanism of aspirin antiplatelet action?|Irreversibly acetylates platelet COX-1, reducing thromboxane A₂.
Pharmacology|Recall: How statins reduce LDL?|Inhibit HMG-CoA reductase and increase hepatic LDL receptor-mediated clearance.
Pharmacology|Recall: How metformin lowers glucose?|Primarily reduces hepatic glucose production and improves insulin sensitivity.
Pharmacology|Recall: How sulfonylureas stimulate insulin release?|Close beta-cell ATP-sensitive potassium channels, causing depolarisation and calcium entry.
Pharmacology|Recall: Mechanism of SGLT2 inhibitors?|Block proximal tubular glucose reabsorption, increasing urinary glucose excretion.
Pharmacology|Recall: How salbutamol relieves bronchospasm?|Beta-2 receptor stimulation increases cAMP and relaxes bronchial smooth muscle.
Anatomy|Foramen ovale transmits?|Mandibular nerve (V3), accessory meningeal artery, lesser petrosal nerve variably, and emissary vein.
Anatomy|Foramen rotundum transmits?|Maxillary nerve (V2).
Anatomy|Foramen spinosum transmits?|Middle meningeal artery and meningeal branch of V3.
Anatomy|Floor of anatomical snuffbox?|Scaphoid and trapezium; radial artery crosses it.
Anatomy|Nerve to thenar muscles for thumb opposition?|Recurrent branch of median nerve.
Anatomy|Main nerve supply of little finger sensation?|Ulnar nerve.
Anatomy|Most frequently torn rotator cuff tendon?|Supraspinatus tendon.
Anatomy|Primary action of infraspinatus?|External rotation of the arm.
Anatomy|Contents of portal triad?|Hepatic artery proper, portal vein, and bile duct.
Anatomy|Main lymphatic drainage of testes?|Para-aortic (lumbar) lymph nodes.
Anatomy|Embryological origin of adrenal medulla?|Neural crest cells.
Anatomy|Muscles of first pharyngeal arch?|Muscles of mastication, mylohyoid, anterior digastric, tensor tympani and tensor veli palatini.
Anatomy|Cranial nerve of second pharyngeal arch?|Facial nerve (CN VII).
Anatomy|Arterial supply of hindgut?|Inferior mesenteric artery.
Anatomy|Posterior boundary of epiploic foramen?|Inferior vena cava.
Anatomy|Which nerve passes through the optic canal?|Optic nerve (CN II), with ophthalmic artery.
Anatomy|Which artery supplies the medial compartment of thigh?|Obturator artery contributes; profunda femoris perforating branches are also important.
Anatomy|Main nerve of anterior thigh compartment?|Femoral nerve.
Anatomy|Main nerve of posterior thigh compartment?|Sciatic nerve, predominantly tibial division.
Anatomy|What forms the roof of the carpal tunnel?|Flexor retinaculum.
Physiology|What drives simple diffusion?|Concentration or electrochemical gradient.
Physiology|Cause of first heart sound?|Closure and tensing of mitral and tricuspid valves.
Physiology|Cause of second heart sound?|Closure of aortic and pulmonary valves.
Physiology|Normal adult SA node rate?|Approximately 60–100 impulses per minute.
Physiology|Nephron site of greatest sodium and water reabsorption?|Proximal convoluted tubule.
Physiology|Where is the renal countercurrent multiplier?|Loop of Henle.
Physiology|Transporter in thick ascending limb?|NKCC2; this segment is relatively impermeable to water.
Physiology|Overall effect of PTH on calcium and phosphate?|Raises serum calcium and lowers serum phosphate.
Physiology|Pancreatic cells that secrete glucagon?|Alpha cells.
Physiology|Pancreatic cells that secrete insulin?|Beta cells.
Physiology|Main stimulus for erythropoietin release?|Renal tissue hypoxia.
Physiology|Which gastric cells produce intrinsic factor?|Parietal cells.
Physiology|Where is intrinsic-factor-bound B12 absorbed?|Terminal ileum.
Physiology|Hormone causing gallbladder contraction?|Cholecystokinin (CCK).
Physiology|Main stimulus for secretin release?|Acidic chyme in duodenum.
Physiology|Which lung volume is not measured by simple spirometry?|Residual volume.
Physiology|Effect of increased temperature on oxygen dissociation curve?|Right shift, promoting oxygen unloading.
Physiology|What determines glomerular filtration rate?|Net filtration pressure and filtration coefficient.
Physiology|Which hormone increases renal calcium reabsorption?|Parathyroid hormone.
Physiology|What is the main effect of ANP?|Promotes natriuresis and reduces blood volume and pressure.
Biochemistry|Enzyme converting pyruvate to lactate?|Lactate dehydrogenase.
Biochemistry|Committed step enzyme of purine synthesis?|Glutamine-PRPP amidotransferase.
Biochemistry|Enzyme producing deoxyribonucleotides?|Ribonucleotide reductase.
Biochemistry|End product of human purine degradation?|Uric acid.
Biochemistry|Enzyme deficient in Lesch–Nyhan syndrome?|HGPRT.
Biochemistry|Amino acid precursor of serotonin?|Tryptophan.
Biochemistry|Amino acid precursor of catecholamines?|Tyrosine.
Biochemistry|Vitamin deficiency causing methylmalonic acid elevation?|Vitamin B12 deficiency.
Biochemistry|Vitamin deficiency causing homocysteine elevation without methylmalonic acid elevation?|Folate deficiency.
Biochemistry|Main transport role of carnitine?|Moves long-chain fatty acyl groups into mitochondria for beta-oxidation.
Biochemistry|Enzyme deficient in classic galactosaemia?|Galactose-1-phosphate uridyltransferase.
Biochemistry|Enzyme deficient in hereditary fructose intolerance?|Aldolase B.
Biochemistry|Biochemical defect in alkaptonuria?|Homogentisate oxidase deficiency.
Biochemistry|Main collagen type in bone?|Type I collagen.
Biochemistry|Main collagen type in cartilage?|Type II collagen.
Biochemistry|Plasma iron transport protein?|Transferrin.
Biochemistry|What does ferritin store?|Intracellular iron; serum ferritin broadly reflects iron stores but rises with inflammation.
Biochemistry|Rate-limiting enzyme of gluconeogenesis?|Fructose-1,6-bisphosphatase.
Biochemistry|Enzyme releasing free glucose from hepatic glucose-6-phosphate?|Glucose-6-phosphatase.
Biochemistry|Which molecule carries activated sulfate for glycosaminoglycan synthesis?|PAPS (3'-phosphoadenosine-5'-phosphosulfate).
Pathology|Defining feature of apoptosis?|Programmed cell death with cell shrinkage and apoptotic bodies, usually little inflammation.
Pathology|Predominant cells in acute bacterial inflammation?|Neutrophils.
Pathology|Predominant cells in chronic inflammation?|Macrophages, lymphocytes and plasma cells.
Pathology|Microscopic hallmark of granuloma?|Epithelioid macrophage aggregates, sometimes with multinucleated giant cells.
Pathology|Special stain for amyloid?|Congo red with apple-green birefringence under polarised light.
Pathology|Main protein in Alzheimer plaques?|Amyloid-beta.
Pathology|Protein in Alzheimer neurofibrillary tangles?|Hyperphosphorylated tau.
Pathology|Classic translocation in follicular lymphoma?|t(14;18), causing BCL2 overexpression.
Pathology|Early tumour suppressor alteration in colorectal adenoma-carcinoma sequence?|APC inactivation.
Pathology|Classic nuclei in papillary thyroid carcinoma?|Orphan Annie eye nuclei, grooves and intranuclear inclusions.
Pathology|Common marker associated with hepatocellular carcinoma?|Alpha-fetoprotein (AFP), not diagnostic alone.
Pathology|Clinical pattern of nephritic syndrome?|Haematuria, reduced GFR, oliguria and hypertension.
Pathology|Core features of nephrotic syndrome?|Heavy proteinuria, hypoalbuminaemia and oedema, often hyperlipidaemia.
Pathology|Renal disease with linear IgG on immunofluorescence?|Anti-GBM disease.
Pathology|Classic histology of membranous nephropathy?|Subepithelial immune deposits with capillary-wall thickening and spikes.
Pathology|Common infectious association of peptic ulcer disease?|Helicobacter pylori.
Pathology|Defining physiological feature of asthma?|Variable, usually reversible airflow obstruction and bronchial hyperresponsiveness.
Pathology|Cells prominent in allergic asthma?|Eosinophils and Th2 lymphocytes.
Pathology|Which hypersensitivity is IgE-mediated?|Type I.
Pathology|Which hypersensitivity is immune-complex mediated?|Type III.
Microbiology|Gram stain and key tests for Staphylococcus aureus?|Gram-positive cocci in clusters; catalase-positive and coagulase-positive.
Microbiology|Key identification of Streptococcus pyogenes?|Group A beta-haemolytic streptococcus; PYR-positive.
Microbiology|Cause of antibiotic-associated pseudomembranous colitis?|Clostridioides difficile.
Microbiology|Major virulence factor of Streptococcus pneumoniae?|Polysaccharide capsule.
Microbiology|Acid-fast bacterium causing tuberculosis?|Mycobacterium tuberculosis.
Microbiology|Transmission route of hepatitis A?|Faecal–oral.
Microbiology|Which hepatitis virus is partially double-stranded DNA?|Hepatitis B virus.
Microbiology|Virus classically causing infectious mononucleosis?|Epstein–Barr virus.
Microbiology|HIV entry receptor and co-receptor?|CD4 plus CCR5 or CXCR4.
Microbiology|Yeast causing thrush and pseudohyphae?|Candida albicans.
Microbiology|Encapsulated yeast associated with meningitis in immunocompromised people?|Cryptococcus neoformans.
Microbiology|Mosquito genus transmitting malaria?|Female Anopheles.
Microbiology|Which malaria parasites form dormant liver hypnozoites?|Plasmodium vivax and P. ovale.
Microbiology|Infective stage of Entamoeba histolytica?|Mature quadrinucleate cyst.
Microbiology|Organism causing pertussis?|Bordetella pertussis.
Microbiology|Mechanism of diphtheria toxin?|ADP-ribosylates EF-2 and blocks protein synthesis.
Microbiology|Mechanism of cholera toxin?|ADP-ribosylates Gs alpha, persistently activating adenylate cyclase and raising cAMP.
Microbiology|Organism associated with rusty sputum and lancet diplococci?|Streptococcus pneumoniae.
Microbiology|Which organism causes atypical pneumonia and lacks a cell wall?|Mycoplasma pneumoniae.
Immunology|Which immunoglobulin crosses placenta?|IgG.
Immunology|First immunoglobulin produced in primary response?|IgM.
Immunology|Main immunoglobulin in mucosal secretions?|Secretory IgA.
Immunology|Potent complement-derived neutrophil chemoattractant?|C5a.
Immunology|Complement components forming membrane attack complex?|C5b–C9.
Immunology|MHC class presenting endogenous peptides to CD8 cells?|MHC class I.
Immunology|MHC class presenting exogenous peptides to CD4 cells?|MHC class II.
Immunology|Transcription factor associated with regulatory T cells?|FOXP3.
Immunology|Major cytokine stimulating hepatic acute-phase proteins?|IL-6.
Immunology|Cells that secrete antibodies?|Plasma cells.
Pharmacology|Mechanism of beta-lactam antibiotics?|Bind penicillin-binding proteins and inhibit peptidoglycan cross-linking.
Pharmacology|Mechanism of macrolide antibiotics?|Bind 50S ribosomal subunit and inhibit protein synthesis.
Pharmacology|Major toxicities of aminoglycosides?|Nephrotoxicity and ototoxicity.
Pharmacology|Antibiotic class associated with tendon injury and QT prolongation?|Fluoroquinolones.
Pharmacology|Mechanism of proton-pump inhibitors?|Irreversibly inhibit gastric H+/K+-ATPase.
Pharmacology|Mechanism of loop diuretics?|Inhibit NKCC2 in thick ascending limb.
Pharmacology|Mechanism of thiazide diuretics?|Inhibit Na+/Cl− cotransporter in distal convoluted tubule.
Pharmacology|Mechanism of spironolactone?|Mineralocorticoid receptor antagonism.
Pharmacology|Antidote for paracetamol overdose?|N-acetylcysteine replenishes glutathione.
Pharmacology|Antidote for opioid-induced respiratory depression?|Naloxone; repeat doses may be needed.
Pharmacology|Mechanism of local anaesthetics?|Block voltage-gated sodium channels.
Pharmacology|How does levodopa help Parkinson disease?|Crosses blood–brain barrier and is converted to dopamine.
Pharmacology|Mechanism of SSRIs?|Inhibit serotonin reuptake transporter.
Pharmacology|Two xanthine oxidase inhibitors used for gout?|Allopurinol and febuxostat.
Pharmacology|Mechanism of clopidogrel?|Irreversible blockade of platelet P2Y12 ADP receptors.
Pharmacology|How is unfractionated heparin commonly monitored?|aPTT or calibrated anti-Xa assay.
Pharmacology|How is warfarin monitored?|Prothrombin time expressed as INR.
Pharmacology|Mechanism of methotrexate?|Inhibits dihydrofolate reductase; low-dose anti-inflammatory effects also involve adenosine signalling.
Pharmacology|Which antidote reverses benzodiazepine effects?|Flumazenil in selected cases; use caution due to seizure risk.
Pharmacology|Mechanism of ondansetron?|Selective 5-HT3 receptor antagonism.
Clinical Medicine|First-line immediate drug for anaphylaxis?|Intramuscular adrenaline into anterolateral thigh, alongside emergency supportive care.
Clinical Medicine|Classic triad of normal-pressure hydrocephalus?|Gait disturbance, cognitive impairment and urinary incontinence.
Clinical Medicine|Leading causes of acute pancreatitis?|Gallstones and alcohol.
Clinical Medicine|Core ECG feature of STEMI?|ST elevation in contiguous leads in the appropriate clinical context.
Clinical Medicine|Typical pattern of stable angina?|Predictable exertional chest discomfort relieved by rest or nitroglycerin.
Clinical Medicine|Defining biochemical pattern of diabetic ketoacidosis?|Ketonaemia with high-anion-gap metabolic acidosis, usually with hyperglycaemia.
Clinical Medicine|Acid-base disturbance caused by prolonged vomiting?|Metabolic alkalosis.
Clinical Medicine|Acid-base disturbance caused by severe diarrhoea?|Non-anion-gap metabolic acidosis.
Clinical Medicine|Typical weakness pattern in myasthenia gravis?|Fluctuating fatigable skeletal muscle weakness, often ocular or bulbar.
Clinical Medicine|Common autoantibody in Graves disease?|TSH-receptor stimulating antibody.
Clinical Medicine|Biochemical pattern of primary hypothyroidism?|Raised TSH with low free T4.
Clinical Medicine|Classic symptom triad of pheochromocytoma?|Headache, sweating and palpitations.
Clinical Medicine|Typical blood count pattern in iron deficiency?|Microcytic hypochromic anaemia, often with raised RDW.
Clinical Medicine|Typical smear in hereditary spherocytosis?|Spherocytes; confirm with tests such as eosin-5-maleimide binding.
Clinical Medicine|First-line imaging for suspected gallstones?|Right upper quadrant ultrasound.
Clinical Medicine|Classic presentation of aortic dissection?|Abrupt severe chest or back pain, sometimes with pulse or blood-pressure asymmetry.
Clinical Medicine|Clinical definition of sepsis?|Life-threatening organ dysfunction due to a dysregulated host response to infection.
Clinical Medicine|Most important immediate test in suspected ectopic pregnancy?|Pregnancy testing with urgent clinical assessment and pelvic ultrasound as indicated.
Clinical Medicine|Typical symptom of peripheral arterial disease?|Exertional leg pain (claudication) relieved by rest.
Clinical Medicine|Usual diagnostic test for suspected deep-vein thrombosis?|Compression venous ultrasonography, guided by clinical probability and D-dimer.
Clinical Medicine|Classic feature of acute pericarditis?|Sharp pleuritic chest pain relieved by sitting forward, often with a pericardial friction rub.
''';

final List<AtlasFlashcard> atlasFlashcards = List.unmodifiable(
  _rows.trim().split('\n').map((line) {
    final p = line.split('|');
    return AtlasFlashcard(p[0], p[1], p[2]);
  }),
);

class AtlasFlashcardsScreen extends StatefulWidget {
  const AtlasFlashcardsScreen({super.key});
  @override
  State<AtlasFlashcardsScreen> createState() => _AtlasFlashcardsScreenState();
}

class _AtlasFlashcardsScreenState extends State<AtlasFlashcardsScreen> {
  String subject = 'All';
  int index = 0;
  bool revealed = false, bookmarksOnly = false;
  List<int> shuffledIds = [];
  final Set<int> bookmarks = {};
  final Set<int> mastered = {};
  final Set<int> review = {};

  List<int> get visible {
    final ids = <int>[];
    for (var i = 0; i < atlasFlashcards.length; i++) {
      if (subject != 'All' && atlasFlashcards[i].subject != subject) continue;
      if (bookmarksOnly && !bookmarks.contains(i)) continue;
      ids.add(i);
    }
    if (shuffledIds.isNotEmpty && !bookmarksOnly && subject == 'All') return shuffledIds.where(ids.contains).toList();
    return ids;
  }

  List<String> get subjects => ['All', ...{for (final c in atlasFlashcards) c.subject}];

  void move(int amount) {
    if (visible.isEmpty) return;
    setState(() { index = (index + amount).clamp(0, visible.length - 1); revealed = false; });
  }

  @override
  Widget build(BuildContext context) {
    final ids = visible;
    final id = ids.isEmpty ? -1 : ids[index.clamp(0, ids.length - 1)];
    final card = id < 0 ? null : atlasFlashcards[id];
    final progress = ids.isEmpty ? 0.0 : (index + 1) / ids.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        title: const Text('Smart Flashcards'),
        actions: [
          IconButton(
            tooltip: bookmarksOnly ? 'Show all cards' : 'Bookmarked cards',
            onPressed: () => setState(() { bookmarksOnly = !bookmarksOnly; index = 0; revealed = false; }),
            icon: Icon(bookmarksOnly ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
          ),
          IconButton(
            tooltip: 'Shuffle cards',
            onPressed: () => setState(() { shuffledIds = List<int>.generate(atlasFlashcards.length, (i) => i)..shuffle(); index = 0; revealed = false; }),
            icon: const Icon(Icons.shuffle_rounded),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF153F73), Color(0xFF2878C7)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ACTIVE RECALL • MEDICAL SCIENCES',
              style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Text('Learn it. Recall it. Own it.',
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(children: [
              _stat(atlasFlashcards.length.toString(), 'CARDS'),
              const SizedBox(width: 8),
              _stat(mastered.length.toString(), 'MASTERED'),
              const SizedBox(width: 8),
              _stat(review.length.toString(), 'REVIEW'),
              const Spacer(),
              Text((ids.isEmpty ? 0 : index + 1).toString() + '/' + ids.length.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 11),
            ClipRRect(borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: progress, minHeight: 5,
                backgroundColor: Colors.white24, color: const Color(0xFF9FE4D6))),
          ]),
        ),
        SizedBox(
          height: 58,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, i) {
              final s = subjects[i], selected = s == subject;
              return ChoiceChip(
                label: Text(s), selected: selected,
                onSelected: (_) => setState(() { subject = s; index = 0; revealed = false; }),
                selectedColor: const Color(0xFF1D64A8), backgroundColor: Colors.white,
                labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF456078),
                  fontSize: 10, fontWeight: FontWeight.w800),
                side: BorderSide(color: selected ? const Color(0xFF1D64A8) : const Color(0xFFDCE7F2)),
                showCheckmark: false,
              );
            },
          ),
        ),
        Expanded(
          child: card == null ? _empty() : Padding(
            padding: const EdgeInsets.fromLTRB(17, 5, 17, 15),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFE5F0FC), borderRadius: BorderRadius.circular(20)),
                  child: Text(card.subject.toUpperCase(), style: const TextStyle(color: Color(0xFF225E9A),
                    fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                Text('CARD ' + (id + 1).toString().padLeft(3, '0'),
                  style: const TextStyle(color: Color(0xFF8192A6), fontSize: 10, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => revealed = !revealed),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(id.toString() + revealed.toString()),
                      width: double.infinity, padding: const EdgeInsets.all(23),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: revealed ? const [Color(0xFFEDF9F5), Colors.white] : const [Colors.white, Color(0xFFF4F8FF)]),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: revealed ? const Color(0xFFBDE8D8) : const Color(0xFFDCE7F3)),
                        boxShadow: const [BoxShadow(color: Color(0x0D173B63), blurRadius: 22, offset: Offset(0, 8))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(revealed ? Icons.lightbulb_rounded : Icons.psychology_rounded,
                            color: revealed ? const Color(0xFF16856C) : const Color(0xFF3477B9), size: 20),
                          const SizedBox(width: 8),
                          Text(revealed ? 'KEY LEARNING' : 'ACTIVE RECALL',
                            style: TextStyle(color: revealed ? const Color(0xFF16856C) : const Color(0xFF3477B9),
                              fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w900)),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() {
                              if (!bookmarks.add(id)) bookmarks.remove(id);
                            }),
                            icon: Icon(bookmarks.contains(id) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: const Color(0xFF3477B9)),
                          ),
                        ]),
                        const Spacer(),
                        Text(revealed ? 'ANSWER' : 'QUESTION',
                          style: const TextStyle(color: Color(0xFF8293A7), fontSize: 9, letterSpacing: 1.3, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 14),
                        Text(revealed ? card.answer : card.question,
                          style: TextStyle(color: const Color(0xFF193653), fontSize: revealed ? 18 : 21,
                            height: 1.48, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Center(child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                          decoration: BoxDecoration(color: revealed ? const Color(0xFFDDF3E9) : const Color(0xFFE7F0FB),
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(revealed ? 'TAP TO SEE QUESTION' : 'TAP TO REVEAL ANSWER',
                            style: TextStyle(color: revealed ? const Color(0xFF16856C) : const Color(0xFF2866A1),
                              fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900)),
                        )),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => setState(() { review.add(id); mastered.remove(id); }),
                  icon: const Icon(Icons.replay_rounded, size: 17), label: const Text('Review again'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB66B24),
                    side: const BorderSide(color: Color(0xFFE7C99F))),
                )),
                const SizedBox(width: 9),
                Expanded(child: FilledButton.icon(
                  onPressed: () => setState(() { mastered.add(id); review.remove(id); }),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 17), label: const Text('I know this'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16856C), foregroundColor: Colors.white),
                )),
              ]),
              const SizedBox(height: 7),
              Row(children: [
                TextButton.icon(onPressed: () => move(-1), icon: const Icon(Icons.chevron_left_rounded), label: const Text('Previous')),
                const Spacer(),
                TextButton.icon(onPressed: () => move(1), icon: const Icon(Icons.chevron_right_rounded), label: const Text('Next')),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _stat(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(11)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8, letterSpacing: .6, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _empty() => const Center(
    child: Padding(padding: EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bookmark_outline_rounded, size: 45, color: Color(0xFF7890AA)),
        SizedBox(height: 12),
        Text('No cards in this view', style: TextStyle(color: Color(0xFF193653), fontWeight: FontWeight.w900, fontSize: 17)),
        SizedBox(height: 6),
        Text('Choose another subject or bookmark some cards first.', textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7890AA), fontSize: 12)),
      ]),
    ),
  );
}
