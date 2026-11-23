import 'package:flutter/material.dart';

class AtlasFlashcard {
  final String subject, question, answer;
  const AtlasFlashcard(this.subject, this.question, this.answer);
}

/// Offline-ready authored medical recall collection. 50 core facts in four recall formats.
const String _rows = r'''
Anatomy|Recall: Phrenic nerve roots?|C3–C5; C3, 4 and 5 keep the diaphragm alive.
Anatomy|What is the key fact about phrenic nerve roots?|C3–C5; C3, 4 and 5 keep the diaphragm alive.
Anatomy|Clinical revision point — Phrenic nerve roots|C3–C5; C3, 4 and 5 keep the diaphragm alive.
Anatomy|Complete this high-yield recall prompt: Phrenic nerve roots|C3–C5; C3, 4 and 5 keep the diaphragm alive.
Anatomy|Recall: Adult femoral-head blood supply?|Retinacular branches of the medial circumflex femoral artery.
Anatomy|What is the key fact about adult femoral-head blood supply?|Retinacular branches of the medial circumflex femoral artery.
Anatomy|Clinical revision point — Adult femoral-head blood supply|Retinacular branches of the medial circumflex femoral artery.
Anatomy|Complete this high-yield recall prompt: Adult femoral-head blood supply|Retinacular branches of the medial circumflex femoral artery.
Anatomy|Recall: Nerve at risk in midshaft humeral fracture?|Radial nerve in the spiral groove.
Anatomy|What is the key fact about nerve at risk in midshaft humeral fracture?|Radial nerve in the spiral groove.
Anatomy|Clinical revision point — Nerve at risk in midshaft humeral fracture|Radial nerve in the spiral groove.
Anatomy|Complete this high-yield recall prompt: Nerve at risk in midshaft humeral fracture|Radial nerve in the spiral groove.
Anatomy|Recall: Carpal tunnel contents?|Median nerve and nine flexor tendons: four FDS, four FDP and one FPL.
Anatomy|What is the key fact about carpal tunnel contents?|Median nerve and nine flexor tendons: four FDS, four FDP and one FPL.
Anatomy|Clinical revision point — Carpal tunnel contents|Median nerve and nine flexor tendons: four FDS, four FDP and one FPL.
Anatomy|Complete this high-yield recall prompt: Carpal tunnel contents|Median nerve and nine flexor tendons: four FDS, four FDP and one FPL.
Anatomy|Recall: Muscle initiating shoulder abduction?|Supraspinatus initiates the first 15 degrees; deltoid continues.
Anatomy|What is the key fact about muscle initiating shoulder abduction?|Supraspinatus initiates the first 15 degrees; deltoid continues.
Anatomy|Clinical revision point — Muscle initiating shoulder abduction|Supraspinatus initiates the first 15 degrees; deltoid continues.
Anatomy|Complete this high-yield recall prompt: Muscle initiating shoulder abduction|Supraspinatus initiates the first 15 degrees; deltoid continues.
Anatomy|Recall: Cranial nerve to lateral rectus?|Abducens nerve, CN VI.
Anatomy|What is the key fact about cranial nerve to lateral rectus?|Abducens nerve, CN VI.
Anatomy|Clinical revision point — Cranial nerve to lateral rectus|Abducens nerve, CN VI.
Anatomy|Complete this high-yield recall prompt: Cranial nerve to lateral rectus|Abducens nerve, CN VI.
Anatomy|Recall: Optic canal contents?|Optic nerve (CN II) and ophthalmic artery.
Anatomy|What is the key fact about optic canal contents?|Optic nerve (CN II) and ophthalmic artery.
Anatomy|Clinical revision point — Optic canal contents|Optic nerve (CN II) and ophthalmic artery.
Anatomy|Complete this high-yield recall prompt: Optic canal contents|Optic nerve (CN II) and ophthalmic artery.
Anatomy|Recall: Femoral triangle boundaries?|Inguinal ligament superiorly, sartorius laterally and adductor longus medially.
Anatomy|What is the key fact about femoral triangle boundaries?|Inguinal ligament superiorly, sartorius laterally and adductor longus medially.
Anatomy|Clinical revision point — Femoral triangle boundaries|Inguinal ligament superiorly, sartorius laterally and adductor longus medially.
Anatomy|Complete this high-yield recall prompt: Femoral triangle boundaries|Inguinal ligament superiorly, sartorius laterally and adductor longus medially.
Anatomy|Recall: Jugular foramen nerves?|Cranial nerves IX, X and XI.
Anatomy|What is the key fact about jugular foramen nerves?|Cranial nerves IX, X and XI.
Anatomy|Clinical revision point — Jugular foramen nerves|Cranial nerves IX, X and XI.
Anatomy|Complete this high-yield recall prompt: Jugular foramen nerves|Cranial nerves IX, X and XI.
Anatomy|Recall: Most common ectopic pregnancy site?|Ampulla of the uterine tube.
Anatomy|What is the key fact about most common ectopic pregnancy site?|Ampulla of the uterine tube.
Anatomy|Clinical revision point — Most common ectopic pregnancy site|Ampulla of the uterine tube.
Anatomy|Complete this high-yield recall prompt: Most common ectopic pregnancy site|Ampulla of the uterine tube.
Physiology|Recall: Resting neuronal membrane potential?|Approximately −70 mV, largely due to potassium permeability and ion gradients.
Physiology|What is the key fact about resting neuronal membrane potential?|Approximately −70 mV, largely due to potassium permeability and ion gradients.
Physiology|Clinical revision point — Resting neuronal membrane potential|Approximately −70 mV, largely due to potassium permeability and ion gradients.
Physiology|Complete this high-yield recall prompt: Resting neuronal membrane potential|Approximately −70 mV, largely due to potassium permeability and ion gradients.
Physiology|Recall: Ventricular action-potential plateau?|L-type calcium influx balanced by potassium efflux.
Physiology|What is the key fact about ventricular action-potential plateau?|L-type calcium influx balanced by potassium efflux.
Physiology|Clinical revision point — Ventricular action-potential plateau|L-type calcium influx balanced by potassium efflux.
Physiology|Complete this high-yield recall prompt: Ventricular action-potential plateau|L-type calcium influx balanced by potassium efflux.
Physiology|Recall: Cardiac output formula?|Heart rate multiplied by stroke volume.
Physiology|What is the key fact about cardiac output formula?|Heart rate multiplied by stroke volume.
Physiology|Clinical revision point — Cardiac output formula|Heart rate multiplied by stroke volume.
Physiology|Complete this high-yield recall prompt: Cardiac output formula|Heart rate multiplied by stroke volume.
Physiology|Recall: Frank–Starling mechanism?|Greater end-diastolic filling stretches myocardium and increases contraction force within physiological limits.
Physiology|What is the key fact about frank–starling mechanism?|Greater end-diastolic filling stretches myocardium and increases contraction force within physiological limits.
Physiology|Clinical revision point — Frank–Starling mechanism|Greater end-diastolic filling stretches myocardium and increases contraction force within physiological limits.
Physiology|Complete this high-yield recall prompt: Frank–Starling mechanism|Greater end-diastolic filling stretches myocardium and increases contraction force within physiological limits.
Physiology|Recall: Central chemoreceptor stimulus?|CSF hydrogen ion concentration generated as CO₂ crosses the blood–brain barrier.
Physiology|What is the key fact about central chemoreceptor stimulus?|CSF hydrogen ion concentration generated as CO₂ crosses the blood–brain barrier.
Physiology|Clinical revision point — Central chemoreceptor stimulus|CSF hydrogen ion concentration generated as CO₂ crosses the blood–brain barrier.
Physiology|Complete this high-yield recall prompt: Central chemoreceptor stimulus|CSF hydrogen ion concentration generated as CO₂ crosses the blood–brain barrier.
Physiology|Recall: Bohr effect?|Increased CO₂ and H⁺ reduce haemoglobin oxygen affinity, promoting tissue oxygen unloading.
Physiology|What is the key fact about bohr effect?|Increased CO₂ and H⁺ reduce haemoglobin oxygen affinity, promoting tissue oxygen unloading.
Physiology|Clinical revision point — Bohr effect|Increased CO₂ and H⁺ reduce haemoglobin oxygen affinity, promoting tissue oxygen unloading.
Physiology|Complete this high-yield recall prompt: Bohr effect|Increased CO₂ and H⁺ reduce haemoglobin oxygen affinity, promoting tissue oxygen unloading.
Physiology|Recall: Hormone increasing collecting-duct water permeability?|ADH (vasopressin), via V2 receptors and aquaporin-2 insertion.
Physiology|What is the key fact about hormone increasing collecting-duct water permeability?|ADH (vasopressin), via V2 receptors and aquaporin-2 insertion.
Physiology|Clinical revision point — Hormone increasing collecting-duct water permeability|ADH (vasopressin), via V2 receptors and aquaporin-2 insertion.
Physiology|Complete this high-yield recall prompt: Hormone increasing collecting-duct water permeability|ADH (vasopressin), via V2 receptors and aquaporin-2 insertion.
Physiology|Recall: Renal action of aldosterone?|Increases sodium reabsorption and potassium and hydrogen secretion.
Physiology|What is the key fact about renal action of aldosterone?|Increases sodium reabsorption and potassium and hydrogen secretion.
Physiology|Clinical revision point — Renal action of aldosterone|Increases sodium reabsorption and potassium and hydrogen secretion.
Physiology|Complete this high-yield recall prompt: Renal action of aldosterone|Increases sodium reabsorption and potassium and hydrogen secretion.
Physiology|Recall: Pulmonary surfactant function?|Reduces alveolar surface tension and prevents alveolar collapse.
Physiology|What is the key fact about pulmonary surfactant function?|Reduces alveolar surface tension and prevents alveolar collapse.
Physiology|Clinical revision point — Pulmonary surfactant function|Reduces alveolar surface tension and prevents alveolar collapse.
Physiology|Complete this high-yield recall prompt: Pulmonary surfactant function|Reduces alveolar surface tension and prevents alveolar collapse.
Physiology|Recall: Mean arterial pressure approximation?|Cardiac output multiplied by systemic vascular resistance.
Physiology|What is the key fact about mean arterial pressure approximation?|Cardiac output multiplied by systemic vascular resistance.
Physiology|Clinical revision point — Mean arterial pressure approximation|Cardiac output multiplied by systemic vascular resistance.
Physiology|Complete this high-yield recall prompt: Mean arterial pressure approximation|Cardiac output multiplied by systemic vascular resistance.
Biochemistry|Recall: Rate-limiting enzyme of glycolysis?|Phosphofructokinase-1 (PFK-1).
Biochemistry|What is the key fact about rate-limiting enzyme of glycolysis?|Phosphofructokinase-1 (PFK-1).
Biochemistry|Clinical revision point — Rate-limiting enzyme of glycolysis|Phosphofructokinase-1 (PFK-1).
Biochemistry|Complete this high-yield recall prompt: Rate-limiting enzyme of glycolysis|Phosphofructokinase-1 (PFK-1).
Biochemistry|Recall: Rate-limiting enzyme of cholesterol synthesis?|HMG-CoA reductase.
Biochemistry|What is the key fact about rate-limiting enzyme of cholesterol synthesis?|HMG-CoA reductase.
Biochemistry|Clinical revision point — Rate-limiting enzyme of cholesterol synthesis|HMG-CoA reductase.
Biochemistry|Complete this high-yield recall prompt: Rate-limiting enzyme of cholesterol synthesis|HMG-CoA reductase.
Biochemistry|Recall: Vitamin needed for clotting factor gamma-carboxylation?|Vitamin K for factors II, VII, IX and X and proteins C and S.
Biochemistry|What is the key fact about vitamin needed for clotting factor gamma-carboxylation?|Vitamin K for factors II, VII, IX and X and proteins C and S.
Biochemistry|Clinical revision point — Vitamin needed for clotting factor gamma-carboxylation|Vitamin K for factors II, VII, IX and X and proteins C and S.
Biochemistry|Complete this high-yield recall prompt: Vitamin needed for clotting factor gamma-carboxylation|Vitamin K for factors II, VII, IX and X and proteins C and S.
Biochemistry|Recall: Purpose of the urea cycle?|Converts toxic ammonia to urea for excretion.
Biochemistry|What is the key fact about purpose of the urea cycle?|Converts toxic ammonia to urea for excretion.
Biochemistry|Clinical revision point — Purpose of the urea cycle|Converts toxic ammonia to urea for excretion.
Biochemistry|Complete this high-yield recall prompt: Purpose of the urea cycle|Converts toxic ammonia to urea for excretion.
Biochemistry|Recall: Enzyme deficient in classic phenylketonuria?|Phenylalanine hydroxylase, most commonly.
Biochemistry|What is the key fact about enzyme deficient in classic phenylketonuria?|Phenylalanine hydroxylase, most commonly.
Biochemistry|Clinical revision point — Enzyme deficient in classic phenylketonuria|Phenylalanine hydroxylase, most commonly.
Biochemistry|Complete this high-yield recall prompt: Enzyme deficient in classic phenylketonuria|Phenylalanine hydroxylase, most commonly.
Biochemistry|Recall: What HbA1c estimates?|Average glycaemic exposure over roughly the preceding 2–3 months.
Biochemistry|What is the key fact about what hba1c estimates?|Average glycaemic exposure over roughly the preceding 2–3 months.
Biochemistry|Clinical revision point — What HbA1c estimates|Average glycaemic exposure over roughly the preceding 2–3 months.
Biochemistry|Complete this high-yield recall prompt: What HbA1c estimates|Average glycaemic exposure over roughly the preceding 2–3 months.
Biochemistry|Recall: Apolipoprotein activating lipoprotein lipase?|Apolipoprotein C-II.
Biochemistry|What is the key fact about apolipoprotein activating lipoprotein lipase?|Apolipoprotein C-II.
Biochemistry|Clinical revision point — Apolipoprotein activating lipoprotein lipase|Apolipoprotein C-II.
Biochemistry|Complete this high-yield recall prompt: Apolipoprotein activating lipoprotein lipase|Apolipoprotein C-II.
Biochemistry|Recall: Rate-limiting enzyme of heme synthesis?|ALA synthase.
Biochemistry|What is the key fact about rate-limiting enzyme of heme synthesis?|ALA synthase.
Biochemistry|Clinical revision point — Rate-limiting enzyme of heme synthesis|ALA synthase.
Biochemistry|Complete this high-yield recall prompt: Rate-limiting enzyme of heme synthesis|ALA synthase.
Biochemistry|Recall: Cofactors required by pyruvate dehydrogenase?|TPP, lipoic acid, CoA, FAD and NAD⁺.
Biochemistry|What is the key fact about cofactors required by pyruvate dehydrogenase?|TPP, lipoic acid, CoA, FAD and NAD⁺.
Biochemistry|Clinical revision point — Cofactors required by pyruvate dehydrogenase|TPP, lipoic acid, CoA, FAD and NAD⁺.
Biochemistry|Complete this high-yield recall prompt: Cofactors required by pyruvate dehydrogenase|TPP, lipoic acid, CoA, FAD and NAD⁺.
Biochemistry|Recall: Main source of NADPH in red cells?|Pentose phosphate pathway via glucose-6-phosphate dehydrogenase.
Biochemistry|What is the key fact about main source of nadph in red cells?|Pentose phosphate pathway via glucose-6-phosphate dehydrogenase.
Biochemistry|Clinical revision point — Main source of NADPH in red cells|Pentose phosphate pathway via glucose-6-phosphate dehydrogenase.
Biochemistry|Complete this high-yield recall prompt: Main source of NADPH in red cells|Pentose phosphate pathway via glucose-6-phosphate dehydrogenase.
Pathology|Recall: Necrosis typical of myocardial infarction?|Coagulative necrosis.
Pathology|What is the key fact about necrosis typical of myocardial infarction?|Coagulative necrosis.
Pathology|Clinical revision point — Necrosis typical of myocardial infarction|Coagulative necrosis.
Pathology|Complete this high-yield recall prompt: Necrosis typical of myocardial infarction|Coagulative necrosis.
Pathology|Recall: Necrosis typical of cerebral infarction?|Liquefactive necrosis.
Pathology|What is the key fact about necrosis typical of cerebral infarction?|Liquefactive necrosis.
Pathology|Clinical revision point — Necrosis typical of cerebral infarction|Liquefactive necrosis.
Pathology|Complete this high-yield recall prompt: Necrosis typical of cerebral infarction|Liquefactive necrosis.
Pathology|Recall: Classic association of caseous necrosis?|Tuberculosis; it has a granular, cheese-like appearance.
Pathology|What is the key fact about classic association of caseous necrosis?|Tuberculosis; it has a granular, cheese-like appearance.
Pathology|Clinical revision point — Classic association of caseous necrosis|Tuberculosis; it has a granular, cheese-like appearance.
Pathology|Complete this high-yield recall prompt: Classic association of caseous necrosis|Tuberculosis; it has a granular, cheese-like appearance.
Pathology|Recall: Characteristic cell in Hodgkin lymphoma?|Reed–Sternberg cell, classically CD15 and CD30 positive.
Pathology|What is the key fact about characteristic cell in hodgkin lymphoma?|Reed–Sternberg cell, classically CD15 and CD30 positive.
Pathology|Clinical revision point — Characteristic cell in Hodgkin lymphoma|Reed–Sternberg cell, classically CD15 and CD30 positive.
Pathology|Complete this high-yield recall prompt: Characteristic cell in Hodgkin lymphoma|Reed–Sternberg cell, classically CD15 and CD30 positive.
Pathology|Recall: Definition of metaplasia?|Reversible replacement of one mature cell type by another better suited to a stress.
Pathology|What is the key fact about definition of metaplasia?|Reversible replacement of one mature cell type by another better suited to a stress.
Pathology|Clinical revision point — Definition of metaplasia|Reversible replacement of one mature cell type by another better suited to a stress.
Pathology|Complete this high-yield recall prompt: Definition of metaplasia|Reversible replacement of one mature cell type by another better suited to a stress.
Pathology|Recall: Definition of dysplasia?|Disordered epithelial maturation with cytological atypia; it may be premalignant.
Pathology|What is the key fact about definition of dysplasia?|Disordered epithelial maturation with cytological atypia; it may be premalignant.
Pathology|Clinical revision point — Definition of dysplasia|Disordered epithelial maturation with cytological atypia; it may be premalignant.
Pathology|Complete this high-yield recall prompt: Definition of dysplasia|Disordered epithelial maturation with cytological atypia; it may be premalignant.
Pathology|Recall: Tumour suppressor associated with Li–Fraumeni syndrome?|TP53.
Pathology|What is the key fact about tumour suppressor associated with li–fraumeni syndrome?|TP53.
Pathology|Clinical revision point — Tumour suppressor associated with Li–Fraumeni syndrome|TP53.
Pathology|Complete this high-yield recall prompt: Tumour suppressor associated with Li–Fraumeni syndrome|TP53.
Pathology|Recall: Genetic hallmark of chronic myeloid leukaemia?|BCR::ABL1 fusion from t(9;22), the Philadelphia chromosome.
Pathology|What is the key fact about genetic hallmark of chronic myeloid leukaemia?|BCR::ABL1 fusion from t(9;22), the Philadelphia chromosome.
Pathology|Clinical revision point — Genetic hallmark of chronic myeloid leukaemia|BCR::ABL1 fusion from t(9;22), the Philadelphia chromosome.
Pathology|Complete this high-yield recall prompt: Genetic hallmark of chronic myeloid leukaemia|BCR::ABL1 fusion from t(9;22), the Philadelphia chromosome.
Pathology|Recall: Key pathological feature of emphysema?|Permanent airspace enlargement distal to terminal bronchioles with alveolar wall destruction.
Pathology|What is the key fact about key pathological feature of emphysema?|Permanent airspace enlargement distal to terminal bronchioles with alveolar wall destruction.
Pathology|Clinical revision point — Key pathological feature of emphysema|Permanent airspace enlargement distal to terminal bronchioles with alveolar wall destruction.
Pathology|Complete this high-yield recall prompt: Key pathological feature of emphysema|Permanent airspace enlargement distal to terminal bronchioles with alveolar wall destruction.
Pathology|Recall: Most common nephrotic syndrome in children?|Minimal change disease.
Pathology|What is the key fact about most common nephrotic syndrome in children?|Minimal change disease.
Pathology|Clinical revision point — Most common nephrotic syndrome in children|Minimal change disease.
Pathology|Complete this high-yield recall prompt: Most common nephrotic syndrome in children|Minimal change disease.
Pharmacology|Recall: Mechanism of ACE inhibitors?|Inhibit angiotensin-converting enzyme, reducing angiotensin II and aldosterone and increasing bradykinin.
Pharmacology|What is the key fact about mechanism of ace inhibitors?|Inhibit angiotensin-converting enzyme, reducing angiotensin II and aldosterone and increasing bradykinin.
Pharmacology|Clinical revision point — Mechanism of ACE inhibitors|Inhibit angiotensin-converting enzyme, reducing angiotensin II and aldosterone and increasing bradykinin.
Pharmacology|Complete this high-yield recall prompt: Mechanism of ACE inhibitors|Inhibit angiotensin-converting enzyme, reducing angiotensin II and aldosterone and increasing bradykinin.
Pharmacology|Recall: Important ACE inhibitor adverse effects?|Cough, hyperkalaemia, hypotension and angioedema; avoid in pregnancy.
Pharmacology|What is the key fact about important ace inhibitor adverse effects?|Cough, hyperkalaemia, hypotension and angioedema; avoid in pregnancy.
Pharmacology|Clinical revision point — Important ACE inhibitor adverse effects|Cough, hyperkalaemia, hypotension and angioedema; avoid in pregnancy.
Pharmacology|Complete this high-yield recall prompt: Important ACE inhibitor adverse effects|Cough, hyperkalaemia, hypotension and angioedema; avoid in pregnancy.
Pharmacology|Recall: Mechanism of warfarin?|Inhibits vitamin K epoxide reductase, reducing functional vitamin K-dependent clotting factors.
Pharmacology|What is the key fact about mechanism of warfarin?|Inhibits vitamin K epoxide reductase, reducing functional vitamin K-dependent clotting factors.
Pharmacology|Clinical revision point — Mechanism of warfarin|Inhibits vitamin K epoxide reductase, reducing functional vitamin K-dependent clotting factors.
Pharmacology|Complete this high-yield recall prompt: Mechanism of warfarin|Inhibits vitamin K epoxide reductase, reducing functional vitamin K-dependent clotting factors.
Pharmacology|Recall: Reversal agent for unfractionated heparin?|Protamine sulfate.
Pharmacology|What is the key fact about reversal agent for unfractionated heparin?|Protamine sulfate.
Pharmacology|Clinical revision point — Reversal agent for unfractionated heparin|Protamine sulfate.
Pharmacology|Complete this high-yield recall prompt: Reversal agent for unfractionated heparin|Protamine sulfate.
Pharmacology|Recall: Mechanism of aspirin antiplatelet action?|Irreversibly acetylates platelet COX-1, reducing thromboxane A₂.
Pharmacology|What is the key fact about mechanism of aspirin antiplatelet action?|Irreversibly acetylates platelet COX-1, reducing thromboxane A₂.
Pharmacology|Clinical revision point — Mechanism of aspirin antiplatelet action|Irreversibly acetylates platelet COX-1, reducing thromboxane A₂.
Pharmacology|Complete this high-yield recall prompt: Mechanism of aspirin antiplatelet action|Irreversibly acetylates platelet COX-1, reducing thromboxane A₂.
Pharmacology|Recall: How statins reduce LDL?|Inhibit HMG-CoA reductase and increase hepatic LDL receptor-mediated clearance.
Pharmacology|What is the key fact about how statins reduce ldl?|Inhibit HMG-CoA reductase and increase hepatic LDL receptor-mediated clearance.
Pharmacology|Clinical revision point — How statins reduce LDL|Inhibit HMG-CoA reductase and increase hepatic LDL receptor-mediated clearance.
Pharmacology|Complete this high-yield recall prompt: How statins reduce LDL|Inhibit HMG-CoA reductase and increase hepatic LDL receptor-mediated clearance.
Pharmacology|Recall: How metformin lowers glucose?|Primarily reduces hepatic glucose production and improves insulin sensitivity.
Pharmacology|What is the key fact about how metformin lowers glucose?|Primarily reduces hepatic glucose production and improves insulin sensitivity.
Pharmacology|Clinical revision point — How metformin lowers glucose|Primarily reduces hepatic glucose production and improves insulin sensitivity.
Pharmacology|Complete this high-yield recall prompt: How metformin lowers glucose|Primarily reduces hepatic glucose production and improves insulin sensitivity.
Pharmacology|Recall: How sulfonylureas stimulate insulin release?|Close beta-cell ATP-sensitive potassium channels, causing depolarisation and calcium entry.
Pharmacology|What is the key fact about how sulfonylureas stimulate insulin release?|Close beta-cell ATP-sensitive potassium channels, causing depolarisation and calcium entry.
Pharmacology|Clinical revision point — How sulfonylureas stimulate insulin release|Close beta-cell ATP-sensitive potassium channels, causing depolarisation and calcium entry.
Pharmacology|Complete this high-yield recall prompt: How sulfonylureas stimulate insulin release|Close beta-cell ATP-sensitive potassium channels, causing depolarisation and calcium entry.
Pharmacology|Recall: Mechanism of SGLT2 inhibitors?|Block proximal tubular glucose reabsorption, increasing urinary glucose excretion.
Pharmacology|What is the key fact about mechanism of sglt2 inhibitors?|Block proximal tubular glucose reabsorption, increasing urinary glucose excretion.
Pharmacology|Clinical revision point — Mechanism of SGLT2 inhibitors|Block proximal tubular glucose reabsorption, increasing urinary glucose excretion.
Pharmacology|Complete this high-yield recall prompt: Mechanism of SGLT2 inhibitors|Block proximal tubular glucose reabsorption, increasing urinary glucose excretion.
Pharmacology|Recall: How salbutamol relieves bronchospasm?|Beta-2 receptor stimulation increases cAMP and relaxes bronchial smooth muscle.
Pharmacology|What is the key fact about how salbutamol relieves bronchospasm?|Beta-2 receptor stimulation increases cAMP and relaxes bronchial smooth muscle.
Pharmacology|Clinical revision point — How salbutamol relieves bronchospasm|Beta-2 receptor stimulation increases cAMP and relaxes bronchial smooth muscle.
Pharmacology|Complete this high-yield recall prompt: How salbutamol relieves bronchospasm|Beta-2 receptor stimulation increases cAMP and relaxes bronchial smooth muscle.
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
  bool revealed = false, bookmarksOnly = false, reversed = false;
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
    return reversed ? ids.reversed.toList() : ids;
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
            onPressed: () => setState(() { reversed = !reversed; index = 0; revealed = false; }),
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
