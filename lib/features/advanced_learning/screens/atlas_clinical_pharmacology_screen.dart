import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../widgets/atlas_molecular_mechanism_diagram.dart';
import '../widgets/atlas_molecular_structure_viewer.dart';
import '../widgets/atlas_drug_conformer_viewer.dart';

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
    'Gastrointestinal', 'Antimicrobials', 'Renal', 'Neurology',
    'Psychiatry', 'Pain & Anaesthesia', 'Immunology & Oncology',
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

    _Drug(
      name: 'Losartan', generic: 'Losartan potassium',
      group: 'Angiotensin II type 1 receptor antagonist', category: 'Cardiovascular', className: 'ARB',
      summary: 'Blocks AT1 receptors to reduce angiotensin-II-mediated vasoconstriction and aldosterone release.',
      moa: 'Selectively antagonises angiotensin II at AT1 receptors in vascular smooth muscle, adrenal tissue and other organs. It reduces vasoconstriction, aldosterone secretion and sympathetic facilitation without inhibiting bradykinin breakdown. Its active metabolite contributes substantially to the pharmacological effect.',
      steps: ['Oral losartan is absorbed and converted partly to an active metabolite.', 'Losartan and its metabolite occupy angiotensin-II AT1 receptors.', 'Angiotensin-II-mediated vasoconstriction and aldosterone release are reduced.', 'Peripheral resistance and sodium retention fall while potassium retention may increase.', 'Blood pressure and intraglomerular pressure decrease in appropriate patients.'],
      indications: 'Hypertension, diabetic nephropathy in selected patients with type 2 diabetes and proteinuria, and selected heart-failure or post-infarction settings when guideline appropriate.',
      kinetics: 'Oral drug undergoes hepatic first-pass metabolism, including CYP2C9 and CYP3A4 pathways. Both parent drug and active metabolite are protein bound; elimination is biliary and renal.',
      dose: 'Individualise to indication, blood pressure, renal function and potassium. Titrate with laboratory monitoring; do not combine routinely with an ACE inhibitor.',
      cautions: 'Contraindicated in pregnancy. Assess volume depletion, renal artery stenosis, hyperkalaemia and renal impairment. Avoid dual renin-angiotensin system blockade in most patients.',
      adverse: 'Dizziness, hypotension, hyperkalaemia and changes in renal function; angioedema is uncommon.',
      interactions: 'Potassium products and potassium-sparing diuretics increase hyperkalaemia risk. NSAIDs can impair renal function. Lithium concentrations may rise.',
      monitoring: 'Blood pressure, serum potassium and creatinine/eGFR before treatment and after initiation or dose increases.',
      pearls: 'Unlike ACE inhibitors, ARBs do not usually cause bradykinin-mediated cough.',
      sources: 'FDA/DailyMed losartan prescribing information; KDIGO CKD guidance.'
    ),
    _Drug(
      name: 'Hydrochlorothiazide', generic: 'Hydrochlorothiazide',
      group: 'Thiazide diuretic', category: 'Renal', className: 'Thiazide diuretic',
      summary: 'Reduces sodium chloride reabsorption in the distal convoluted tubule.',
      moa: 'Inhibits the thiazide-sensitive Na+/Cl− cotransporter (NCC) on the luminal membrane of distal convoluted tubule cells. Increased sodium delivery to the collecting duct promotes potassium and hydrogen secretion. Chronic blood-pressure lowering also reflects reduced peripheral vascular resistance.',
      steps: ['Drug reaches the tubular lumen after renal delivery.', 'NCC in the early distal convoluted tubule is inhibited.', 'Sodium and chloride reabsorption decreases and urinary sodium loss rises.', 'More sodium reaches collecting segments, increasing potassium and hydrogen loss.', 'Extracellular volume initially falls; longer-term blood pressure reduction includes lower vascular resistance.'],
      indications: 'Hypertension and oedema in selected cardiac, hepatic or renal conditions.',
      kinetics: 'Orally absorbed and largely excreted unchanged by the kidneys. Diuretic response depends on delivery to the tubular site and renal function.',
      dose: 'Use the lowest effective regimen for the indication. Select dose according to blood pressure, renal function and electrolyte response.',
      cautions: 'Use caution with gout, diabetes, hyponatraemia, hypokalaemia and significant renal impairment. Sulfonamide-related hypersensitivity history requires clinical assessment.',
      adverse: 'Hyponatraemia, hypokalaemia, hypomagnesaemia, hyperuricaemia, hyperglycaemia, photosensitivity and metabolic alkalosis.',
      interactions: 'Lithium toxicity may increase. NSAIDs may reduce diuretic and antihypertensive effects. Digoxin toxicity risk rises with hypokalaemia.',
      monitoring: 'Blood pressure, sodium, potassium, magnesium, uric acid when indicated and renal function.',
      pearls: 'Thiazides reduce urinary calcium excretion, which contrasts with loop diuretics.',
      sources: 'FDA/DailyMed hydrochlorothiazide prescribing information; hypertension guidelines.'
    ),
    _Drug(
      name: 'Atorvastatin', generic: 'Atorvastatin calcium',
      group: 'HMG-CoA reductase inhibitor', category: 'Cardiovascular', className: 'Statin',
      summary: 'Lowers LDL cholesterol by reducing hepatic cholesterol synthesis and increasing LDL-receptor clearance.',
      moa: 'Competitively inhibits HMG-CoA reductase, the rate-limiting enzyme converting HMG-CoA to mevalonate. Reduced hepatocyte cholesterol activates SREBP-mediated upregulation of LDL receptors, increasing clearance of circulating LDL particles.',
      steps: ['Atorvastatin enters hepatocytes and inhibits HMG-CoA reductase.', 'Conversion of HMG-CoA to mevalonate decreases.', 'Hepatic intracellular cholesterol falls.', 'Hepatocytes increase LDL-receptor expression and surface availability.', 'Circulating LDL cholesterol is cleared more rapidly and cardiovascular risk is reduced.'],
      indications: 'Primary and secondary prevention of atherosclerotic cardiovascular disease and treatment of dyslipidaemia.',
      kinetics: 'Orally administered with extensive hepatic uptake and metabolism, mainly via CYP3A4. Active metabolites contribute to inhibitory activity; elimination is predominantly biliary.',
      dose: 'Choose intensity based on cardiovascular risk and LDL response. Review interactions, pregnancy status and tolerability; use current lipid guidelines.',
      cautions: 'Active liver disease and pregnancy are important avoidance contexts. Assess unexplained muscle symptoms and factors increasing myopathy risk.',
      adverse: 'Myalgia, mild transaminase elevations, rare myopathy or rhabdomyolysis and a small increase in diabetes risk in predisposed people.',
      interactions: 'Strong CYP3A4 inhibitors, cyclosporine, some macrolides and azole antifungals can increase exposure. Grapefruit may interact at high intake.',
      monitoring: 'Lipid profile response, adherence, muscle symptoms and liver enzymes when clinically indicated.',
      pearls: 'The major benefit is reduction of atherogenic LDL particle burden, not simply a change in a laboratory number.',
      sources: 'FDA/DailyMed atorvastatin prescribing information; major lipid-management guidelines.'
    ),
    _Drug(
      name: 'Aspirin', generic: 'Acetylsalicylic acid',
      group: 'Irreversible cyclooxygenase inhibitor', category: 'Cardiovascular', className: 'Antiplatelet',
      summary: 'Irreversibly inhibits platelet COX-1 and reduces thromboxane A2 formation.',
      moa: 'Acetylates platelet cyclooxygenase-1 irreversibly, preventing conversion of arachidonic acid to prostaglandin H2 and downstream thromboxane A2. Platelets lack nuclei and cannot replace the enzyme, so inhibition persists for their lifespan.',
      steps: ['Aspirin is absorbed and reaches circulating platelets.', 'It transfers an acetyl group to a serine residue in COX-1.', 'Thromboxane A2 synthesis falls.', 'Platelet activation, granule release and aggregation are reduced.', 'Primary haemostatic platelet plug formation is impaired for the life of affected platelets.'],
      indications: 'Secondary prevention of atherosclerotic cardiovascular events and selected acute coronary syndromes; primary prevention only for carefully selected patients.',
      kinetics: 'Rapidly hydrolysed to salicylate. Low-dose antiplatelet action is driven by presystemic platelet exposure and irreversible enzyme inhibition.',
      dose: 'Antiplatelet regimens differ from analgesic or anti-inflammatory dosing. Use only when the benefit-risk balance supports it.',
      cautions: 'Active bleeding, aspirin hypersensitivity and active peptic ulceration are important concerns. Avoid in children with viral illness because of Reye syndrome risk.',
      adverse: 'Dyspepsia, gastrointestinal ulceration or bleeding, bruising, bronchospasm in susceptible patients and tinnitus at higher exposure.',
      interactions: 'Anticoagulants, other antiplatelets, NSAIDs and corticosteroids may increase bleeding risk. Ibuprofen can interfere with aspirin platelet action depending on timing.',
      monitoring: 'Bleeding symptoms, gastrointestinal tolerance, haemoglobin when indicated and ongoing indication for therapy.',
      pearls: 'Platelet inhibition is irreversible, unlike the reversible inhibition produced by many other NSAIDs.',
      sources: 'FDA/DailyMed aspirin information; AHA/ACC cardiovascular prevention guidance.'
    ),
    _Drug(
      name: 'Apixaban', generic: 'Apixaban',
      group: 'Direct factor Xa inhibitor', category: 'Cardiovascular', className: 'Direct oral anticoagulant',
      summary: 'Reduces thrombin generation by directly and selectively inhibiting factor Xa.',
      moa: 'Directly inhibits free and clot-associated factor Xa, reducing conversion of prothrombin to thrombin. Reduced thrombin generation decreases fibrin formation and thrombin-mediated platelet activation.',
      steps: ['Apixaban is absorbed into the circulation.', 'It binds reversibly to the active site of factor Xa.', 'Conversion of prothrombin to thrombin decreases.', 'Fibrin generation and thrombin-amplified coagulation are reduced.', 'Formation and propagation of thrombi become less likely.'],
      indications: 'Stroke and systemic embolism prevention in eligible non-valvular atrial fibrillation; treatment and prevention of recurrence of venous thromboembolism; selected postoperative prophylaxis.',
      kinetics: 'Oral administration with mixed elimination including renal, intestinal and metabolic pathways. P-glycoprotein and CYP3A4 affect exposure.',
      dose: 'Indication-specific dose reduction criteria apply, including age, body weight, renal function and interacting medicines. Verify current product label.',
      cautions: 'Active pathological bleeding is a contraindication. Assess renal/hepatic function, adherence, procedures, pregnancy and neuraxial anaesthesia risks.',
      adverse: 'Bleeding, bruising, anaemia and nausea; serious or fatal haemorrhage can occur.',
      interactions: 'Strong combined P-gp/CYP3A4 inhibitors can increase exposure; strong inducers can reduce it. Antiplatelets and NSAIDs increase bleeding.',
      monitoring: 'Clinical bleeding, adherence, renal/hepatic function and haemoglobin. Routine INR monitoring is not used to titrate apixaban.',
      pearls: 'A normal PT or aPTT does not reliably exclude clinically relevant apixaban activity.',
      sources: 'FDA/DailyMed apixaban prescribing information; anticoagulation guidelines.'
    ),
    _Drug(
      name: 'Amiodarone', generic: 'Amiodarone hydrochloride',
      group: 'Class III antiarrhythmic with multi-channel effects', category: 'Cardiovascular', className: 'Antiarrhythmic',
      summary: 'Prolongs cardiac repolarisation and has sodium-channel, calcium-channel and antiadrenergic actions.',
      moa: 'Predominantly blocks cardiac potassium currents, prolonging phase 3 repolarisation and effective refractory period. It also blocks sodium and calcium channels and has noncompetitive antiadrenergic effects, slowing sinus and AV nodal activity.',
      steps: ['Amiodarone distributes into cardiac tissue and membrane compartments.', 'Potassium-channel blockade reduces outward repolarising current.', 'Action-potential duration and effective refractory period increase.', 'Additional sodium/calcium-channel and antiadrenergic effects slow conduction and nodal activity.', 'Re-entry and selected tachyarrhythmias may be suppressed.'],
      indications: 'Selected serious atrial and ventricular arrhythmias under specialist supervision.',
      kinetics: 'Extremely large volume of distribution, extensive tissue accumulation, hepatic metabolism and very long, variable terminal half-life.',
      dose: 'Loading and maintenance regimens vary by arrhythmia and route. Initiation and monitoring require specialist protocols.',
      cautions: 'Pulmonary, thyroid, hepatic, ocular and cardiac toxicity; bradycardia, QT prolongation and interactions are major concerns.',
      adverse: 'Pulmonary pneumonitis/fibrosis, thyroid dysfunction, liver injury, corneal deposits, photosensitivity, skin discoloration, bradycardia and QT prolongation.',
      interactions: 'Raises exposure to warfarin, digoxin and some statins; interacts with QT-prolonging medicines and CYP/P-gp substrates.',
      monitoring: 'ECG, thyroid and liver tests, pulmonary symptoms and assessment, eye review when symptomatic, electrolytes and interacting medicines.',
      pearls: 'Because tissue accumulation and elimination are prolonged, adverse effects and interactions may persist after discontinuation.',
      sources: 'FDA/DailyMed amiodarone prescribing information; arrhythmia guidelines.'
    ),
    _Drug(
      name: 'Empagliflozin', generic: 'Empagliflozin',
      group: 'Sodium-glucose cotransporter 2 inhibitor', category: 'Endocrine', className: 'SGLT2 inhibitor',
      summary: 'Promotes urinary glucose and sodium excretion and provides cardiorenal benefits in selected patients.',
      moa: 'Selectively inhibits SGLT2 in the proximal renal tubule, reducing filtered glucose reabsorption and increasing glucosuria. The accompanying natriuresis and haemodynamic effects contribute to blood-pressure and intraglomerular-pressure changes.',
      steps: ['Empagliflozin reaches the proximal tubular lumen.', 'SGLT2-mediated glucose and sodium reabsorption is inhibited.', 'Urinary glucose excretion and modest natriuresis increase.', 'Tubuloglomerular feedback is restored and intraglomerular pressure may fall.', 'Glycaemia and selected heart-failure and kidney outcomes improve in eligible populations.'],
      indications: 'Type 2 diabetes in appropriate patients and reduction of cardiovascular or kidney risk in selected heart failure and chronic kidney disease populations according to current indications.',
      kinetics: 'Orally absorbed and metabolised mainly by glucuronidation. Renal function affects glucose-lowering efficacy and clinical eligibility.',
      dose: 'Use indication-specific dosing and eGFR criteria from current labelling. Assess volume status before initiation.',
      cautions: 'Ketoacidosis can occur, sometimes with only modest glucose elevation. Withhold around major surgery or prolonged fasting according to guidance; assess genital infection and volume depletion risks.',
      adverse: 'Genital mycotic infections, volume depletion, increased urination, rare ketoacidosis and uncommon serious perineal infection.',
      interactions: 'Diuretics may increase volume depletion. Insulin or sulfonylureas may require review because hypoglycaemia risk can rise in combination.',
      monitoring: 'Renal function, volume status, genital symptoms, glycaemic response and symptoms suggestive of ketoacidosis.',
      pearls: 'SGLT2 benefits in heart failure and kidney disease extend beyond glucose lowering.',
      sources: 'FDA/DailyMed empagliflozin prescribing information; ADA and KDIGO guidance.'
    ),
    _Drug(
      name: 'Semaglutide', generic: 'Semaglutide',
      group: 'Glucagon-like peptide-1 receptor agonist', category: 'Endocrine', className: 'GLP-1 receptor agonist',
      summary: 'Enhances glucose-dependent insulin secretion, suppresses glucagon and slows gastric emptying.',
      moa: 'Activates GLP-1 receptors on pancreatic beta cells and other tissues. It increases glucose-dependent insulin secretion, reduces inappropriate glucagon release, delays gastric emptying and acts on central appetite pathways to increase satiety.',
      steps: ['Semaglutide activates GLP-1 receptors.', 'Beta-cell cAMP signalling enhances glucose-dependent insulin release.', 'Alpha-cell glucagon secretion decreases when glucose is elevated.', 'Gastric emptying slows and central satiety signalling increases.', 'Postprandial glucose and appetite decrease, supporting glycaemic and weight effects.'],
      indications: 'Type 2 diabetes and chronic weight management for eligible patients depending on product, formulation and local approval; selected cardiovascular risk reduction indications.',
      kinetics: 'Long-acting peptide analogue with albumin binding and resistance to enzymatic degradation; administered weekly by injection or as a specific oral formulation.',
      dose: 'Titration is gradual and product-specific to improve gastrointestinal tolerability. Do not interchange oral and injectable regimens.',
      cautions: 'Avoid in patients with personal/family history of medullary thyroid carcinoma or MEN2 where labelled contraindication applies. Consider pancreatitis, gallbladder disease, severe gastroparesis and dehydration risk.',
      adverse: 'Nausea, vomiting, diarrhoea, constipation, gallbladder events and rare pancreatitis; hypoglycaemia risk rises with insulin or sulfonylureas.',
      interactions: 'Delayed gastric emptying can affect absorption of oral medicines. Review insulin and sulfonylurea doses and monitor narrow-therapeutic-index oral drugs when relevant.',
      monitoring: 'Glycaemic response, weight, gastrointestinal tolerance, hydration, gallbladder or pancreatitis symptoms and diabetic retinopathy status in relevant patients.',
      pearls: 'The glucose-dependent action means hypoglycaemia is less common when used alone than with insulin secretagogues.',
      sources: 'FDA/DailyMed semaglutide prescribing information; ADA Standards of Care.'
    ),
    _Drug(
      name: 'Levothyroxine', generic: 'Levothyroxine sodium',
      group: 'Synthetic thyroxine (T4)', category: 'Endocrine', className: 'Thyroid hormone replacement',
      summary: 'Replaces deficient thyroid hormone and is converted peripherally to active T3.',
      moa: 'Synthetic T4 enters cells and is converted by deiodinases to T3. T3 binds nuclear thyroid hormone receptors, regulating transcription of genes involved in metabolism, growth, thermogenesis and cardiovascular function. Pituitary feedback reduces TSH when replacement is adequate.',
      steps: ['Oral levothyroxine is absorbed, mainly in the small intestine.', 'T4 enters target tissues and undergoes deiodination to T3.', 'T3 binds nuclear thyroid hormone receptors.', 'Receptor complexes alter transcription of thyroid-responsive genes.', 'Metabolic activity and negative feedback on pituitary TSH are restored.'],
      indications: 'Replacement therapy for hypothyroidism and TSH suppression in selected thyroid cancer care.',
      kinetics: 'High protein binding, long half-life and absorption affected by food and several medicines. Metabolised by deiodination and conjugation.',
      dose: 'Individualise to age, weight, cardiac status, pregnancy and cause of hypothyroidism. Adjust gradually and reassess TSH after an appropriate interval.',
      cautions: 'Not for weight loss. Untreated adrenal insufficiency should be addressed before starting thyroid hormone. Use cautious titration in older adults and ischaemic heart disease.',
      adverse: 'Excess replacement causes palpitations, tremor, anxiety, heat intolerance, weight loss, atrial arrhythmias and bone loss.',
      interactions: 'Calcium, iron, bile-acid sequestrants and some antacids reduce absorption. Warfarin effect may change; enzyme inducers alter requirements.',
      monitoring: 'TSH and free T4 when indicated, symptoms, adherence and administration timing.',
      pearls: 'Take consistently on an empty stomach or according to product instructions; separate from interfering supplements.',
      sources: 'American Thyroid Association hypothyroidism guidance; FDA/DailyMed levothyroxine information.'
    ),
    _Drug(
      name: 'Prednisolone', generic: 'Prednisolone',
      group: 'Systemic glucocorticoid', category: 'Immunology & Oncology', className: 'Corticosteroid',
      summary: 'Suppresses inflammatory and immune gene expression through intracellular glucocorticoid receptors.',
      moa: 'Enters cells and binds cytosolic glucocorticoid receptors. The complex translocates to the nucleus, where it binds glucocorticoid response elements and modulates transcription. It suppresses pro-inflammatory cytokines and eicosanoid pathways while altering glucose, protein and lipid metabolism.',
      steps: ['Prednisolone diffuses across the cell membrane.', 'It binds the intracellular glucocorticoid receptor and changes receptor conformation.', 'The activated complex translocates to the nucleus.', 'Transcription of inflammatory mediators is suppressed and anti-inflammatory genes are regulated.', 'Inflammation and immune activity decrease, alongside systemic metabolic effects.'],
      indications: 'A wide range of inflammatory, allergic, autoimmune and haematological conditions under indication-specific protocols.',
      kinetics: 'Orally absorbed and hepatically metabolised; systemic exposure depends on dose, duration, liver function and interacting medicines.',
      dose: 'Dose and taper depend on disease, severity and duration. Long courses may suppress the HPA axis; never stop prolonged therapy abruptly without a plan.',
      cautions: 'Infection risk, diabetes, hypertension, osteoporosis, peptic ulcer risk, glaucoma, psychiatric effects and adrenal suppression require consideration.',
      adverse: 'Hyperglycaemia, mood and sleep changes, fluid retention, hypertension, infection, weight gain, osteoporosis, skin thinning and adrenal suppression.',
      interactions: 'NSAIDs increase gastrointestinal risk. CYP3A modifiers affect exposure. Vaccination with live vaccines may be unsafe during significant immunosuppression.',
      monitoring: 'Blood pressure, glucose, infection, weight, bone protection needs, eyes and adrenal suppression risk according to duration.',
      pearls: 'Glucocorticoid potency, mineralocorticoid activity and biological duration differ across agents.',
      sources: 'Endocrine Society guidance on glucocorticoid-induced adrenal insufficiency; product information.'
    ),
    _Drug(
      name: 'Cetirizine', generic: 'Cetirizine hydrochloride',
      group: 'Second-generation H1 antihistamine', category: 'Respiratory', className: 'H1 antihistamine',
      summary: 'Reduces histamine-mediated allergic symptoms with relatively limited central sedation.',
      moa: 'Acts as an inverse agonist at peripheral H1 histamine receptors, stabilising the inactive receptor conformation and reducing histamine-mediated vascular permeability, itch and sensory nerve stimulation.',
      steps: ['Cetirizine reaches peripheral H1 receptors.', 'It stabilises the inactive receptor state.', 'Histamine-driven signalling through H1 receptors decreases.', 'Vasodilation, capillary leakage and sensory nerve stimulation are reduced.', 'Sneezing, itching, rhinorrhoea and urticaria symptoms improve.'],
      indications: 'Allergic rhinitis and chronic spontaneous urticaria symptom control.',
      kinetics: 'Rapid oral absorption; limited hepatic metabolism and substantial renal excretion. Dose adjustment may be needed in renal impairment.',
      dose: 'Use age-appropriate product dosing and adjust for renal impairment. Avoid duplicate antihistamine products.',
      cautions: 'May cause drowsiness, especially with alcohol or sedatives. Assess renal function in older adults.',
      adverse: 'Somnolence, fatigue, dry mouth and headache.',
      interactions: 'Alcohol and CNS depressants may increase impairment. Theophylline may modestly alter cetirizine clearance.',
      monitoring: 'Symptom response, sedation and renal function when clinically relevant.',
      pearls: 'Second-generation antihistamines generally cause less sedation than first-generation agents, but impairment remains possible.',
      sources: 'ARIA allergic rhinitis guidance; FDA/DailyMed cetirizine prescribing information.'
    ),
    _Drug(
      name: 'Budesonide', generic: 'Budesonide',
      group: 'Inhaled glucocorticoid', category: 'Respiratory', className: 'Inhaled corticosteroid',
      summary: 'Provides anti-inflammatory control of airway disease through local glucocorticoid activity.',
      moa: 'Binds intracellular glucocorticoid receptors in airway cells, suppressing inflammatory transcription factors and cytokine production. It reduces eosinophilic inflammation, mucosal oedema and airway hyperresponsiveness.',
      steps: ['Inhaled particles deposit in the airways.', 'Budesonide enters airway epithelial and inflammatory cells.', 'Glucocorticoid receptors are activated.', 'Inflammatory gene transcription and mediator release decrease.', 'Airway inflammation and exacerbation risk are reduced over time.'],
      indications: 'Controller therapy in asthma and selected chronic airway inflammatory conditions; formulation-specific uses differ.',
      kinetics: 'High local airway activity with substantial first-pass hepatic metabolism of swallowed fraction via CYP3A4.',
      dose: 'Select inhaler or nebulised formulation and dose according to age, severity and current asthma strategy. Not a rapid rescue bronchodilator.',
      cautions: 'Rinse mouth and spit after inhalation. Consider infection risk, growth in children and adrenal effects at high doses.',
      adverse: 'Oral candidiasis, dysphonia, throat irritation and, at high cumulative exposure, systemic corticosteroid effects.',
      interactions: 'Strong CYP3A4 inhibitors can increase systemic exposure. Other corticosteroids add to cumulative steroid burden.',
      monitoring: 'Asthma control, inhaler technique, exacerbations, oral candidiasis and growth in children.',
      pearls: 'Correct inhaler technique and adherence are essential; use a spacer with compatible pressurised metered-dose devices.',
      sources: 'GINA Global Strategy for Asthma Management; product information.'
    ),
    _Drug(
      name: 'Ipratropium', generic: 'Ipratropium bromide',
      group: 'Short-acting muscarinic antagonist', category: 'Respiratory', className: 'Antimuscarinic bronchodilator',
      summary: 'Blocks airway muscarinic receptors and reduces vagally mediated bronchoconstriction.',
      moa: 'Competitively antagonises muscarinic acetylcholine receptors, particularly M3 receptors on bronchial smooth muscle. This inhibits Gq-phospholipase C-IP3 calcium signalling and reduces bronchial smooth-muscle contraction and mucus secretion.',
      steps: ['Inhaled ipratropium deposits in the conducting airways.', 'It antagonises muscarinic receptors on airway smooth muscle.', 'Acetylcholine-driven Gq and IP3 calcium signalling is reduced.', 'Smooth-muscle contraction and glandular secretion decrease.', 'Bronchial tone falls and airflow improves.'],
      indications: 'Maintenance bronchodilation in COPD and adjunctive treatment in selected acute asthma exacerbations.',
      kinetics: 'Quaternary ammonium compound with limited systemic absorption after inhalation; swallowed portion is poorly absorbed.',
      dose: 'Use device-specific schedules. Acute severe exacerbation treatment should follow local emergency protocols.',
      cautions: 'Avoid spraying into eyes, particularly in narrow-angle glaucoma. Use cautiously with urinary retention or prostatic symptoms.',
      adverse: 'Dry mouth, cough, throat irritation, blurred vision if aerosol reaches eyes and urinary retention rarely.',
      interactions: 'Other anticholinergic medicines may increase antimuscarinic adverse effects.',
      monitoring: 'Breathlessness, rescue use, lung function when indicated, eye symptoms and urinary symptoms.',
      pearls: 'Ipratropium has slower onset and less beta-agonist-like cardiac stimulation than short-acting beta-2 agonists.',
      sources: 'GOLD COPD strategy; product information.'
    ),
    _Drug(
      name: 'Amoxicillin', generic: 'Amoxicillin trihydrate',
      group: 'Aminopenicillin beta-lactam antibiotic', category: 'Antimicrobials', className: 'Penicillin antibiotic',
      summary: 'Kills susceptible bacteria by inhibiting peptidoglycan cell-wall cross-linking.',
      moa: 'The beta-lactam ring binds penicillin-binding proteins and inhibits transpeptidation during peptidoglycan synthesis. Bacterial cell-wall integrity fails during growth. Beta-lactamases can hydrolyse the drug; clavulanate inhibits selected beta-lactamases.',
      steps: ['Amoxicillin reaches the bacterial periplasm.', 'The beta-lactam ring binds susceptible PBPs.', 'Peptidoglycan cross-linking is blocked.', 'New cell wall weakens during bacterial growth.', 'Osmotic stress and autolytic activity cause bacterial death.'],
      indications: 'Selected susceptible respiratory, ear, sinus, urinary, dental and skin infections; H. pylori regimens use combination therapy.',
      kinetics: 'Good oral absorption, wide extracellular distribution and predominantly renal elimination.',
      dose: 'Choose regimen by infection site, organism, severity, age, renal function and local resistance. Adjust in renal impairment.',
      cautions: 'Serious immediate beta-lactam allergy is important. Consider infectious mononucleosis-associated rash and antibiotic-associated colitis.',
      adverse: 'Diarrhoea, nausea, rash, candidiasis, allergy and C. difficile-associated diarrhoea.',
      interactions: 'Warfarin effect may change; allopurinol can increase rash risk; probenecid increases amoxicillin exposure.',
      monitoring: 'Clinical response, allergy, renal function when impaired and antibiotic-associated diarrhoea.',
      pearls: 'Antibiotics do not treat viral upper respiratory infections; obtain cultures when indicated and narrow therapy when possible.',
      sources: 'FDA/DailyMed amoxicillin prescribing information; antimicrobial stewardship guidance.'
    ),
    _Drug(
      name: 'Azithromycin', generic: 'Azithromycin',
      group: 'Macrolide antibiotic', category: 'Antimicrobials', className: 'Macrolide',
      summary: 'Inhibits bacterial protein synthesis by binding the 50S ribosomal subunit.',
      moa: 'Binds 23S rRNA in the 50S ribosomal subunit, interfering with translocation and elongation of the nascent peptide chain. It is usually bacteriostatic, although activity varies by organism and concentration.',
      steps: ['Azithromycin enters susceptible bacteria.', 'It binds the 50S ribosomal subunit near the peptide exit tunnel.', 'Ribosomal translocation and peptide elongation are impaired.', 'Bacterial protein synthesis is reduced.', 'Growth of susceptible organisms is inhibited.'],
      indications: 'Selected respiratory and sexually transmitted infections and atypical pathogen coverage when guideline supported.',
      kinetics: 'Extensive tissue distribution, intracellular accumulation and long terminal tissue half-life; biliary elimination is important.',
      dose: 'Regimens depend on infection and local resistance. Avoid using macrolides when resistance makes them unreliable.',
      cautions: 'QT prolongation, hepatic injury and myasthenia gravis exacerbation are important considerations.',
      adverse: 'Nausea, diarrhoea, abdominal pain, liver enzyme abnormalities and QT-related arrhythmia rarely.',
      interactions: 'Review QT-prolonging drugs, warfarin and other narrow-therapeutic-index agents. Interaction profile differs from erythromycin and clarithromycin.',
      monitoring: 'Clinical response, ECG/electrolytes in high-risk patients and liver symptoms.',
      pearls: 'A long tissue half-life means antimicrobial exposure continues after the final tablet.',
      sources: 'FDA/DailyMed azithromycin prescribing information; local antimicrobial guidelines.'
    ),
    _Drug(
      name: 'Ciprofloxacin', generic: 'Ciprofloxacin',
      group: 'Fluoroquinolone antibiotic', category: 'Antimicrobials', className: 'Fluoroquinolone',
      summary: 'Inhibits bacterial DNA gyrase and topoisomerase IV, disrupting DNA replication.',
      moa: 'Stabilises enzyme-DNA cleavage complexes formed by DNA gyrase and topoisomerase IV, preventing resealing of DNA strands. This causes lethal chromosome damage and bactericidal activity.',
      steps: ['Ciprofloxacin enters susceptible bacteria.', 'It binds DNA gyrase and/or topoisomerase IV cleavage complexes.', 'DNA strand resealing is blocked.', 'Replication forks and chromosome segregation fail.', 'DNA damage accumulates and bacterial death follows.'],
      indications: 'Selected complicated urinary, gastrointestinal, bone and other infections when susceptibility and safety profile support use.',
      kinetics: 'Orally absorbed and also available intravenously; chelation with polyvalent cations reduces absorption. Renal elimination is significant.',
      dose: 'Use only when appropriate alternatives and susceptibility support it. Adjust for renal function and follow infection-specific guidance.',
      cautions: 'Tendinopathy/rupture, peripheral neuropathy, CNS effects, dysglycaemia, QT prolongation and aortic risks are important warnings.',
      adverse: 'Nausea, diarrhoea, CNS effects, photosensitivity, tendon injury, neuropathy and C. difficile-associated diarrhoea.',
      interactions: 'Antacids, iron, zinc and calcium reduce absorption. Tizanidine is contraindicated; warfarin and QT-prolonging medicines need review.',
      monitoring: 'Clinical response, tendon or neuropathy symptoms, glucose in at-risk patients, renal function and interacting drugs.',
      pearls: 'Fluoroquinolones should be reserved when safer effective options are unsuitable because serious adverse effects can be disabling.',
      sources: 'FDA fluoroquinolone safety communications; product information and antimicrobial guidelines.'
    ),
    _Drug(
      name: 'Gentamicin', generic: 'Gentamicin sulfate',
      group: 'Aminoglycoside antibiotic', category: 'Antimicrobials', className: 'Aminoglycoside',
      summary: 'Causes bacterial misreading of mRNA by binding the 30S ribosomal subunit.',
      moa: 'Enters susceptible bacteria through oxygen-dependent transport and binds the 30S ribosomal subunit. It disrupts initiation and causes misreading of mRNA, producing abnormal proteins and bactericidal membrane injury.',
      steps: ['Gentamicin reaches bacteria through oxygen-dependent uptake.', 'It binds the 30S ribosomal subunit.', 'Initiation and accurate decoding of mRNA are disrupted.', 'Abnormal proteins are incorporated into bacterial membranes.', 'Membrane damage and impaired protein synthesis produce bacterial killing.'],
      indications: 'Serious aerobic Gram-negative infections and selected synergistic regimens under specialist protocols.',
      kinetics: 'Poor oral absorption; given parenterally for systemic infection. Minimal metabolism and renal elimination; concentration-dependent killing and post-antibiotic effect.',
      dose: 'Use weight- and renal-function-based protocols with therapeutic drug monitoring. Extended-interval and conventional regimens are not interchangeable.',
      cautions: 'Nephrotoxicity, cochlear and vestibular ototoxicity, and neuromuscular blockade are major risks.',
      adverse: 'Acute kidney injury, hearing loss, tinnitus, vertigo and rarely neuromuscular blockade.',
      interactions: 'Other nephrotoxic or ototoxic drugs increase toxicity. Potent diuretics and neuromuscular blockers require review.',
      monitoring: 'Drug concentrations according to regimen, renal function, fluid status and hearing/vestibular symptoms.',
      pearls: 'Therapeutic drug monitoring is essential for many systemic courses; do not use fixed dosing without patient-specific assessment.',
      sources: 'FDA/DailyMed gentamicin prescribing information; antimicrobial therapeutic-drug-monitoring guidance.'
    ),
    _Drug(
      name: 'Acyclovir', generic: 'Acyclovir',
      group: 'Guanosine nucleoside analogue antiviral', category: 'Antimicrobials', className: 'Antiviral',
      summary: 'Selectively inhibits herpesvirus DNA polymerase after activation by viral thymidine kinase.',
      moa: 'Viral thymidine kinase phosphorylates acyclovir to monophosphate, followed by host kinases to active triphosphate. Acyclovir triphosphate competes with dGTP for viral DNA polymerase and terminates DNA chain elongation because it lacks a 3-prime hydroxyl group.',
      steps: ['Acyclovir enters infected and uninfected cells.', 'Viral thymidine kinase preferentially forms acyclovir monophosphate in infected cells.', 'Cellular kinases produce acyclovir triphosphate.', 'The active metabolite competes for viral DNA polymerase and is incorporated into viral DNA.', 'DNA chain elongation terminates and viral replication is suppressed.'],
      indications: 'Herpes simplex and varicella-zoster infections, including severe disease requiring intravenous therapy.',
      kinetics: 'Oral bioavailability is limited; IV and topical formulations are available. Renal elimination predominates.',
      dose: 'Regimen depends on virus, site, severity, immune status and route. Adjust for renal function and ensure appropriate hydration with IV treatment.',
      cautions: 'Renal impairment increases accumulation and neurotoxicity risk. IV infusion must follow appropriate dilution and rate guidance.',
      adverse: 'Nausea, headache, crystal-associated kidney injury with IV use, confusion, tremor and encephalopathy in accumulation.',
      interactions: 'Other nephrotoxic drugs increase renal risk; probenecid can reduce renal clearance.',
      monitoring: 'Renal function, hydration, neurological status in high-risk patients and clinical response.',
      pearls: 'Selectivity depends on preferential activation in virus-infected cells, not absolute virus-only activity.',
      sources: 'FDA/DailyMed acyclovir prescribing information; infectious disease guidance.'
    ),
    _Drug(
      name: 'Fluconazole', generic: 'Fluconazole',
      group: 'Triazole antifungal', category: 'Antimicrobials', className: 'Azole antifungal',
      summary: 'Disrupts fungal ergosterol synthesis by inhibiting lanosterol 14-alpha-demethylase.',
      moa: 'Inhibits fungal CYP-dependent lanosterol 14-alpha-demethylase (Erg11), reducing ergosterol and causing accumulation of abnormal sterols. Fungal cell membrane structure and function are impaired.',
      steps: ['Fluconazole enters fungal cells.', 'It inhibits fungal lanosterol 14-alpha-demethylase.', 'Lanosterol conversion to ergosterol decreases.', 'Abnormal sterols accumulate and membrane composition changes.', 'Membrane-dependent fungal growth and function are impaired.'],
      indications: 'Selected Candida infections, cryptococcal disease regimens and susceptible fungal infections according to species and site.',
      kinetics: 'High oral bioavailability, good CSF penetration and predominantly renal excretion unchanged.',
      dose: 'Species, site, susceptibility, immune status and renal function determine regimen. Some infections require loading and prolonged therapy.',
      cautions: 'Hepatic injury, QT prolongation, pregnancy considerations and resistance in some Candida species require review.',
      adverse: 'Nausea, abdominal pain, rash, elevated liver enzymes and rare severe hepatic or cardiac events.',
      interactions: 'Inhibits CYP2C9, CYP2C19 and CYP3A4 to varying degrees; may raise warfarin, sulfonylurea, phenytoin and other drug concentrations.',
      monitoring: 'Clinical response, cultures/susceptibility, liver tests for prolonged or high-risk courses and interacting medicines.',
      pearls: 'Candida krusei is intrinsically resistant and Candida glabrata susceptibility is variable; species identification matters.',
      sources: 'IDSA candidiasis guidance; FDA/DailyMed fluconazole prescribing information.'
    ),
    _Drug(
      name: 'Isoniazid', generic: 'Isoniazid',
      group: 'Antimycobacterial prodrug', category: 'Antimicrobials', className: 'Antitubercular',
      summary: 'Inhibits mycolic-acid synthesis in susceptible Mycobacterium tuberculosis.',
      moa: 'Activated by the mycobacterial KatG catalase-peroxidase enzyme to reactive species that inhibit InhA, an enoyl-acyl carrier protein reductase required for mycolic-acid synthesis. Mycolic acids are essential components of the mycobacterial cell wall.',
      steps: ['Isoniazid enters the mycobacterial cell.', 'KatG catalase-peroxidase activates the prodrug.', 'Reactive metabolites inhibit InhA.', 'Mycolic-acid synthesis is interrupted.', 'The mycobacterial cell wall is weakened and bacillary growth is inhibited.'],
      indications: 'Part of multidrug treatment for active tuberculosis and selected latent tuberculosis preventive regimens.',
      kinetics: 'Orally absorbed; hepatic acetylation varies with NAT2 genotype. Metabolites are renally excreted.',
      dose: 'Always use within a complete guideline-based TB regimen; monotherapy for active TB is unsafe because resistance emerges rapidly.',
      cautions: 'Hepatotoxicity and peripheral neuropathy are major concerns. Pyridoxine is recommended for selected risk groups and regimens.',
      adverse: 'Hepatitis, nausea, rash, peripheral neuropathy, lupus-like syndrome and rarely seizures.',
      interactions: 'Inhibits metabolism of phenytoin and carbamazepine; alcohol increases hepatic risk. Review hepatotoxic co-medications.',
      monitoring: 'Liver symptoms and tests based on risk, adherence, neuropathy symptoms and full TB treatment response.',
      pearls: 'NAT2 slow acetylators can have higher exposure and toxicity risk.',
      sources: 'WHO consolidated TB guidelines; CDC latent TB guidance; product information.'
    ),
    _Drug(
      name: 'Ibuprofen', generic: 'Ibuprofen',
      group: 'Non-selective cyclooxygenase inhibitor', category: 'Pain & Anaesthesia', className: 'NSAID',
      summary: 'Reduces prostaglandin synthesis to provide analgesic, antipyretic and anti-inflammatory effects.',
      moa: 'Reversibly inhibits COX-1 and COX-2, reducing conversion of arachidonic acid to prostaglandin precursors. Reduced prostaglandins lower peripheral nociceptor sensitisation, hypothalamic fever signalling and inflammatory responses.',
      steps: ['Ibuprofen is absorbed and distributes to inflamed tissues.', 'It reversibly inhibits COX-1 and COX-2.', 'Prostaglandin synthesis decreases.', 'Nociceptor sensitisation, fever signalling and inflammatory vasodilation fall.', 'Pain, fever and inflammation are reduced.'],
      indications: 'Short-term mild-to-moderate pain, fever and inflammatory musculoskeletal conditions.',
      kinetics: 'Rapid oral absorption, high protein binding and hepatic metabolism; renal excretion of metabolites.',
      dose: 'Use the lowest effective dose for the shortest duration. Follow age, pregnancy, renal and product-specific limits.',
      cautions: 'Peptic ulcer or bleeding, kidney disease, heart failure, uncontrolled hypertension, cardiovascular disease and pregnancy stage are important considerations.',
      adverse: 'Dyspepsia, ulceration, gastrointestinal bleeding, fluid retention, renal injury, hypertension and bronchospasm in susceptible patients.',
      interactions: 'Anticoagulants, antiplatelets, corticosteroids and SSRIs increase bleeding risk. ACE inhibitors/ARBs plus diuretics increase kidney injury risk.',
      monitoring: 'Pain response, blood pressure, renal function in at-risk patients and gastrointestinal bleeding symptoms.',
      pearls: 'NSAIDs can reduce renal prostaglandin-dependent afferent arteriolar dilation, especially during dehydration.',
      sources: 'FDA NSAID safety communications; product information and pain guidelines.'
    ),
    _Drug(
      name: 'Morphine', generic: 'Morphine sulfate',
      group: 'Full mu-opioid receptor agonist', category: 'Pain & Anaesthesia', className: 'Opioid analgesic',
      summary: 'Produces analgesia by activating opioid receptors in the central and peripheral nervous systems.',
      moa: 'Activates Gi/o-coupled mu-opioid receptors, inhibiting adenylyl cyclase, reducing presynaptic calcium entry and increasing postsynaptic potassium conductance. Neurotransmitter release and neuronal excitability decrease in pain pathways.',
      steps: ['Morphine reaches opioid receptors in the CNS and peripheral tissues.', 'Mu receptors couple to Gi/o proteins.', 'Adenylyl cyclase activity and presynaptic calcium influx decrease.', 'Postsynaptic potassium conductance increases and nociceptive transmitter release falls.', 'Ascending pain transmission and pain perception are reduced.'],
      indications: 'Severe acute or chronic pain in carefully selected patients and monitored settings.',
      kinetics: 'Hepatic glucuronidation produces active morphine-6-glucuronide and morphine-3-glucuronide; metabolites are renally cleared.',
      dose: 'Individualise to opioid tolerance, route, pain severity, age and organ function. Use equianalgesic conversions cautiously and follow controlled-drug rules.',
      cautions: 'Respiratory depression, sedation, dependence, misuse, ileus and accumulation in renal impairment are major risks.',
      adverse: 'Respiratory depression, constipation, nausea, vomiting, pruritus, urinary retention, sedation and hypotension.',
      interactions: 'Benzodiazepines, alcohol and other CNS depressants can cause profound sedation and respiratory depression.',
      monitoring: 'Pain, sedation, respiratory rate, oxygenation, bowel function, functional benefit and signs of misuse or withdrawal.',
      pearls: 'Renally cleared active metabolites can accumulate and prolong toxicity in kidney impairment.',
      sources: 'FDA/DailyMed morphine prescribing information; WHO pain guidance.'
    ),
    _Drug(
      name: 'Lidocaine', generic: 'Lidocaine hydrochloride',
      group: 'Amide local anaesthetic; class Ib antiarrhythmic', category: 'Pain & Anaesthesia', className: 'Local anaesthetic',
      summary: 'Blocks voltage-gated sodium channels to prevent action-potential propagation.',
      moa: 'Enters the neuronal axon in its uncharged form and binds the intracellular portion of voltage-gated sodium channels in the open or inactivated state. Sodium influx and depolarisation are inhibited, preventing nerve impulse conduction.',
      steps: ['Uncharged lidocaine crosses the nerve membrane.', 'Inside the axon it becomes protonated and accesses the sodium-channel binding site.', 'Open and inactivated voltage-gated sodium channels are blocked.', 'Action-potential upstroke and propagation fail.', 'Sensory conduction is interrupted and local anaesthesia occurs.'],
      indications: 'Local infiltration, nerve blocks, topical anaesthesia and selected ventricular arrhythmia treatment by appropriate route.',
      kinetics: 'Rapid tissue distribution; hepatic metabolism via CYP pathways. Systemic toxicity risk rises with excessive dose or rapid absorption.',
      dose: 'Maximum dose depends on route, formulation, weight, use of vasoconstrictor and patient factors. Follow local anaesthesia safety protocols.',
      cautions: 'Severe conduction disease, hepatic impairment and low cardiac output increase risk. Intravascular injection can cause seizures and cardiovascular collapse.',
      adverse: 'Perioral numbness, metallic taste, tinnitus, seizures, hypotension, bradycardia and ventricular arrhythmias with systemic toxicity.',
      interactions: 'Other local anaesthetics and antiarrhythmics may add toxicity. CYP inhibitors can increase systemic exposure.',
      monitoring: 'Total dose, injection technique, ECG and neurological status when significant systemic exposure is possible; have lipid-emulsion rescue protocol available for severe toxicity.',
      pearls: 'Local anaesthetic systemic toxicity is an emergency; prevention through aspiration, incremental injection and dose limits is critical.',
      sources: 'ASRA local anaesthetic systemic toxicity guidance; product information.'
    ),
    _Drug(
      name: 'Sertraline', generic: 'Sertraline hydrochloride',
      group: 'Selective serotonin reuptake inhibitor', category: 'Psychiatry', className: 'SSRI antidepressant',
      summary: 'Increases serotonergic neurotransmission by inhibiting the serotonin transporter.',
      moa: 'Selectively inhibits presynaptic serotonin transporter (SERT), reducing reuptake of serotonin into nerve terminals and increasing extracellular serotonin signalling. Adaptive receptor and network changes contribute to delayed clinical response.',
      steps: ['Sertraline reaches serotonergic synapses in the CNS.', 'It binds and inhibits SERT on presynaptic terminals.', 'Synaptic serotonin clearance decreases.', 'Serotonin receptor signalling is altered over repeated dosing.', 'Mood and anxiety symptoms may improve over several weeks.'],
      indications: 'Major depressive disorder, obsessive-compulsive disorder, panic disorder, PTSD, social anxiety and other approved indications depending on jurisdiction.',
      kinetics: 'Orally absorbed and extensively hepatically metabolised, including CYP pathways; long enough half-life for once-daily dosing.',
      dose: 'Start and titrate according to indication, age, response and tolerability. Allow time for effect and taper rather than abruptly stopping when appropriate.',
      cautions: 'Screen for bipolar disorder, suicidality, serotonin syndrome, hyponatraemia and bleeding risk. Do not combine with MAO inhibitors.',
      adverse: 'Nausea, diarrhoea, insomnia or somnolence, sexual dysfunction, sweating and discontinuation symptoms.',
      interactions: 'MAO inhibitors and serotonergic agents increase serotonin syndrome risk. NSAIDs and anticoagulants increase bleeding risk; CYP interactions require review.',
      monitoring: 'Mood, suicidality particularly after initiation or dose change, activation, sodium in at-risk patients and adverse effects.',
      pearls: 'Early gastrointestinal or activation effects may precede antidepressant benefit; therapeutic response often takes weeks.',
      sources: 'NICE depression guidance; FDA/DailyMed sertraline prescribing information.'
    ),
    _Drug(
      name: 'Sodium valproate', generic: 'Valproic acid / sodium valproate',
      group: 'Broad-spectrum antiseizure medicine', category: 'Neurology', className: 'Antiepileptic',
      summary: 'Reduces neuronal excitability through multiple effects on GABA and voltage-gated ion channels.',
      moa: 'Enhances GABAergic inhibitory tone through effects on GABA metabolism and also reduces sustained high-frequency neuronal firing through voltage-gated sodium-channel effects. T-type calcium-channel effects may contribute in some seizure types.',
      steps: ['Valproate reaches the CNS.', 'GABA availability and inhibitory neurotransmission increase through multiple mechanisms.', 'Voltage-gated sodium-channel-dependent repetitive firing is reduced.', 'Neuronal synchronisation and excessive excitability decrease.', 'Seizure generation and propagation are suppressed.'],
      indications: 'Selected generalised and focal seizure disorders and bipolar disorder; migraine prevention in selected settings where permitted.',
      kinetics: 'High protein binding, hepatic metabolism including glucuronidation and mitochondrial beta-oxidation; nonlinear protein binding at higher concentrations.',
      dose: 'Select by seizure type, formulation, age, weight and interacting medicines. Use serum concentrations when clinically indicated.',
      cautions: 'Major teratogenic and neurodevelopmental risks; avoid in pregnancy for migraine prevention and follow strict pregnancy-prevention requirements where relevant. Hepatic disease, pancreatitis and mitochondrial disorders are major concerns.',
      adverse: 'Weight gain, tremor, thrombocytopenia, hair loss, hyperammonaemia, hepatotoxicity and pancreatitis.',
      interactions: 'Raises lamotrigine exposure and rash risk; carbapenems can sharply reduce valproate concentrations. Highly protein-bound drugs may interact.',
      monitoring: 'Liver function, blood count/platelets, pregnancy prevention requirements, clinical response and drug levels when indicated.',
      pearls: 'Valproate is broad-spectrum but reproductive safety restrictions are central to prescribing decisions.',
      sources: 'WHO epilepsy guidance; NICE epilepsy guidance; product information.'
    ),
    _Drug(
      name: 'Haloperidol', generic: 'Haloperidol',
      group: 'First-generation butyrophenone antipsychotic', category: 'Psychiatry', className: 'Typical antipsychotic',
      summary: 'Reduces dopaminergic signalling primarily through D2 receptor antagonism.',
      moa: 'Potently antagonises dopamine D2 receptors in mesolimbic and other pathways. Therapeutic effects are associated with reduced dopaminergic signalling; blockade in nigrostriatal, tuberoinfundibular and other pathways explains important adverse effects.',
      steps: ['Haloperidol enters the CNS and binds dopamine D2 receptors.', 'Postsynaptic D2 signalling is antagonised.', 'Mesolimbic dopaminergic transmission is reduced.', 'Dopamine blockade in nigrostriatal and tuberoinfundibular pathways can also occur.', 'Psychotic symptoms may improve while extrapyramidal and prolactin effects may emerge.'],
      indications: 'Schizophrenia and selected acute agitation, delirium or tic disorders under appropriate protocols.',
      kinetics: 'Hepatically metabolised through glucuronidation, carbonyl reduction and CYP pathways; route and formulation affect onset.',
      dose: 'Use the lowest effective dose and indication-specific regimen. Long-acting formulations require specialist initiation and conversion.',
      cautions: 'QT prolongation, torsades risk, extrapyramidal symptoms, neuroleptic malignant syndrome and increased mortality risk in older adults with dementia-related psychosis.',
      adverse: 'Akathisia, dystonia, parkinsonism, tardive dyskinesia, hyperprolactinaemia, sedation and QT prolongation.',
      interactions: 'QT-prolonging drugs and electrolyte disturbances increase arrhythmia risk. CYP inhibitors can raise concentrations; CNS depressants increase sedation.',
      monitoring: 'Movement symptoms, ECG and electrolytes when risk factors present, metabolic and prolactin effects as clinically indicated.',
      pearls: 'Acute dystonia, akathisia and tardive dyskinesia are distinct movement syndromes and need different management.',
      sources: 'NICE psychosis guidance; FDA/DailyMed haloperidol prescribing information.'
    ),
    _Drug(
      name: 'Diazepam', generic: 'Diazepam',
      group: 'Benzodiazepine positive allosteric modulator', category: 'Neurology', className: 'Benzodiazepine',
      summary: 'Enhances GABA-A receptor-mediated chloride conductance and neuronal inhibition.',
      moa: 'Binds the benzodiazepine site at the interface of alpha and gamma subunits on GABA-A receptors. It increases the frequency of chloride-channel opening in the presence of GABA, hyperpolarising neurons and reducing excitability.',
      steps: ['Diazepam binds the benzodiazepine allosteric site on GABA-A receptors.', 'GABA binding produces greater receptor-channel response.', 'Frequency of chloride-channel opening increases when GABA is present.', 'Neuronal membrane hyperpolarisation and inhibitory tone increase.', 'Anxiolysis, sedation, anticonvulsant and muscle-relaxant effects occur.'],
      indications: 'Selected anxiety states, acute seizures/status epilepticus protocols, alcohol withdrawal and muscle spasm depending on route and jurisdiction.',
      kinetics: 'Highly lipophilic with rapid CNS entry; hepatic metabolism produces long-lived active metabolites.',
      dose: 'Use indication-specific, short-duration regimens where possible. Repeated dosing can accumulate, especially in older adults or liver impairment.',
      cautions: 'Respiratory depression, dependence, falls and withdrawal. Avoid combination with opioids or alcohol except under closely supervised protocols.',
      adverse: 'Sedation, impaired coordination, memory impairment, falls, respiratory depression and paradoxical disinhibition.',
      interactions: 'Opioids, alcohol and other CNS depressants can cause profound respiratory depression. CYP modifiers alter exposure.',
      monitoring: 'Sedation, respiratory status, falls, duration of use, dependence and withdrawal risk.',
      pearls: 'Abrupt cessation after sustained use can cause severe withdrawal, including seizures.',
      sources: 'FDA benzodiazepine boxed-warning communications; product information.'
    ),
    _Drug(
      name: 'Methotrexate', generic: 'Methotrexate',
      group: 'Folate antimetabolite and disease-modifying antirheumatic drug', category: 'Immunology & Oncology', className: 'Antimetabolite',
      summary: 'Inhibits folate-dependent enzymes and alters nucleotide synthesis and immune-cell activity.',
      moa: 'At higher oncology exposures, inhibits dihydrofolate reductase, reducing tetrahydrofolate needed for purine and thymidylate synthesis. In inflammatory disease, polyglutamated methotrexate and adenosine-related effects contribute to immunomodulation. Weekly low-dose regimens are fundamentally different from daily dosing.',
      steps: ['Methotrexate enters cells through folate transport pathways.', 'Intracellular polyglutamation promotes retention.', 'Folate-dependent nucleotide synthesis and immune signalling are altered.', 'Rapidly dividing cells and activated inflammatory pathways are suppressed.', 'Antineoplastic or anti-inflammatory effects occur depending on dose and context.'],
      indications: 'Selected cancers and autoimmune diseases including rheumatoid arthritis and psoriasis under specialist protocols.',
      kinetics: 'Renal elimination is important; protein binding and tissue distribution vary with dose. Drug interactions can delay clearance.',
      dose: 'For many inflammatory indications it is taken once weekly, never daily. Oncology regimens are specialist-specific. Folic acid supplementation is commonly used in low-dose inflammatory treatment.',
      cautions: 'Pregnancy, breastfeeding, significant liver disease, renal impairment, bone-marrow suppression and active serious infection are major concerns.',
      adverse: 'Mucositis, nausea, cytopenias, hepatotoxicity, pneumonitis, renal toxicity at high exposure and teratogenicity.',
      interactions: 'Trimethoprim-sulfamethoxazole, NSAIDs, penicillins and other drugs can increase toxicity or delay clearance; avoid live vaccines in significant immunosuppression.',
      monitoring: 'CBC, liver enzymes, renal function, pregnancy status and pulmonary symptoms according to regimen.',
      pearls: 'A weekly-versus-daily dosing error can be fatal; patient education and prescription safeguards are essential.',
      sources: 'ACR rheumatoid arthritis guidance; FDA/DailyMed methotrexate prescribing information.'
    ),
    _Drug(
      name: 'Nitroglycerin', generic: 'Glyceryl trinitrate',
      group: 'Organic nitrate vasodilator', category: 'Cardiovascular', className: 'Nitrate antianginal',
      summary: 'Generates nitric oxide signalling that relaxes vascular smooth muscle and reduces myocardial preload.',
      moa: 'Bioactivation releases nitric oxide or related species that stimulate soluble guanylyl cyclase. Increased cGMP activates protein kinase G, reducing intracellular calcium and myosin light-chain phosphorylation. Venodilation predominates at usual doses, reducing preload and myocardial oxygen demand.',
      steps: ['Nitroglycerin is bioactivated within vascular smooth muscle.', 'Nitric oxide activates soluble guanylyl cyclase.', 'Intracellular cGMP rises and activates protein kinase G.', 'Calcium signalling and myosin light-chain phosphorylation decrease.', 'Venous capacitance increases, preload and myocardial oxygen demand fall, and angina may improve.'],
      indications: 'Acute relief and prevention of angina; selected acute coronary and pulmonary oedema settings under monitored protocols.',
      kinetics: 'Extensive first-pass metabolism limits oral bioavailability; sublingual, transdermal, buccal and IV forms have distinct kinetics.',
      dose: 'Route-specific dosing is essential. Acute chest pain requires emergency assessment; do not delay emergency services while repeating doses.',
      cautions: 'Severe hypotension, right ventricular infarction, raised intracranial pressure and concurrent PDE5 inhibitor or riociguat use are major contraindication contexts.',
      adverse: 'Headache, flushing, dizziness, hypotension, reflex tachycardia and tolerance with continuous exposure.',
      interactions: 'PDE5 inhibitors and riociguat can cause profound hypotension. Other antihypertensives and alcohol add to blood-pressure lowering.',
      monitoring: 'Blood pressure, heart rate, symptom response and tolerance; continuous ECG/BP monitoring for IV use.',
      pearls: 'A nitrate-free interval may reduce tolerance with some long-acting formulations.',
      sources: 'FDA/DailyMed nitroglycerin prescribing information; acute coronary syndrome guidance.'
    ),
    _Drug(
      name: 'Gliclazide', generic: 'Gliclazide',
      group: 'Sulfonylurea insulin secretagogue', category: 'Endocrine', className: 'Sulfonylurea',
      summary: 'Stimulates pancreatic beta-cell insulin release by closing ATP-sensitive potassium channels.',
      moa: 'Binds SUR1 regulatory subunits of beta-cell ATP-sensitive potassium channels, closing the channel. Membrane depolarisation opens voltage-gated calcium channels, calcium influx triggers insulin granule exocytosis.',
      steps: ['Gliclazide binds SUR1 on beta-cell KATP channels.', 'Potassium efflux decreases as KATP channels close.', 'The beta-cell membrane depolarises.', 'Voltage-gated calcium channels open and intracellular calcium rises.', 'Insulin granules are released, lowering blood glucose but creating hypoglycaemia risk.'],
      indications: 'Type 2 diabetes when an insulin secretagogue is appropriate and hypoglycaemia risk is acceptable.',
      kinetics: 'Orally absorbed and hepatically metabolised; modified-release and immediate-release products have different release profiles.',
      dose: 'Use formulation-specific dosing with meals and careful titration. Do not double a missed dose; follow local product instructions.',
      cautions: 'Hypoglycaemia risk increases with missed meals, renal/hepatic impairment, frailty and interacting medicines.',
      adverse: 'Hypoglycaemia, weight gain, gastrointestinal symptoms and rash.',
      interactions: 'Alcohol, some antimicrobials and other glucose-lowering agents may increase hypoglycaemia risk; beta-blockers can mask warning symptoms.',
      monitoring: 'Glucose, HbA1c, hypoglycaemia episodes, renal/hepatic function and meal regularity.',
      pearls: 'Unlike metformin, sulfonylureas directly stimulate insulin secretion and can cause hypoglycaemia even when food intake is reduced.',
      sources: 'ADA Standards of Care in Diabetes; product information.'
    ),
    _Drug(
      name: 'Metronidazole', generic: 'Metronidazole',
      group: 'Nitroimidazole antimicrobial', category: 'Antimicrobials', className: 'Anaerobic antibacterial / antiprotozoal',
      summary: 'Forms reactive metabolites in susceptible anaerobes and protozoa that damage DNA.',
      moa: 'In low-redox-potential organisms, the nitro group is reduced by electron-transfer proteins to reactive intermediates. These damage DNA and inhibit nucleic-acid synthesis. Oxygen can reverse or limit activation, contributing to selective activity against anaerobes and susceptible protozoa.',
      steps: ['Metronidazole enters susceptible anaerobic organisms.', 'Low-redox electron transport reduces its nitro group.', 'Reactive nitro radical intermediates form.', 'Intermediates damage DNA and disrupt nucleic-acid synthesis.', 'The organism loses viability.'],
      indications: 'Selected anaerobic bacterial infections, bacterial vaginosis, trichomoniasis, giardiasis and amoebiasis according to regimen.',
      kinetics: 'Well absorbed orally with broad tissue distribution, hepatic metabolism and renal excretion of metabolites.',
      dose: 'Regimen depends on organism, infection site and indication. Treat sexual partners where indicated for sexually transmitted infection.',
      cautions: 'Use caution in severe hepatic impairment and neurological disease. Review pregnancy and breastfeeding guidance for the specific indication.',
      adverse: 'Metallic taste, nausea, diarrhoea, headache, dark urine and rarely peripheral neuropathy or seizures with prolonged exposure.',
      interactions: 'Can potentiate warfarin. Review lithium and disulfiram; avoid alcohol according to current product guidance.',
      monitoring: 'Clinical response, neurological symptoms with prolonged courses and INR when combined with warfarin.',
      pearls: 'It has no reliable activity against aerobic bacteria; select therapy according to likely organisms and source control.',
      sources: 'FDA/DailyMed metronidazole prescribing information; infectious disease guidance.'
    ),
    _Drug(
      name: 'Pantoprazole', generic: 'Pantoprazole sodium',
      group: 'Proton-pump inhibitor', category: 'Gastrointestinal', className: 'Proton-pump inhibitor',
      summary: 'Suppresses gastric acid by covalently inhibiting the parietal-cell H+/K+-ATPase.',
      moa: 'A prodrug accumulates in acidic parietal-cell canaliculi and is converted to a reactive sulfenamide. It forms covalent bonds with cysteine residues on the gastric H+/K+-ATPase, irreversibly inhibiting the final step of acid secretion.',
      steps: ['Pantoprazole is absorbed from a protected formulation.', 'It concentrates in acidic parietal-cell secretory canaliculi.', 'Acid converts it to a reactive sulfenamide.', 'The active metabolite covalently binds the H+/K+-ATPase.', 'Active proton pumps are inhibited until new pumps are synthesised.'],
      indications: 'GERD, erosive oesophagitis and selected hypersecretory conditions; ulcer prevention only when clinically indicated.',
      kinetics: 'Enteric-coated oral and IV formulations are available. Hepatic metabolism is important and acid suppression outlasts plasma exposure.',
      dose: 'Dose and duration depend on indication and formulation. Reassess ongoing need and step down when appropriate.',
      cautions: 'Long-term use should have a clear indication. Consider hypomagnesaemia, B12 deficiency, enteric infection and fracture risk in susceptible patients.',
      adverse: 'Headache, diarrhoea, abdominal pain and, with prolonged exposure in some patients, low magnesium or B12 and infection risk.',
      interactions: 'May affect absorption of pH-dependent medicines; review high-dose methotrexate and selected antiretroviral interactions.',
      monitoring: 'Symptom response and ongoing indication; magnesium, B12 or renal evaluation when risk factors warrant.',
      pearls: 'PPIs irreversibly inhibit active pumps; repeated daily dosing increases the fraction of pumps inhibited.',
      sources: 'ACG GERD guideline; FDA/DailyMed pantoprazole prescribing information.'
    ),
    _Drug(
      name: 'Ondansetron', generic: 'Ondansetron',
      group: 'Selective 5-HT3 receptor antagonist', category: 'Gastrointestinal', className: 'Antiemetic',
      summary: 'Blocks serotonin 5-HT3 receptors on vagal afferents and in central emetic pathways.',
      moa: 'Competitively antagonises ligand-gated 5-HT3 receptors on vagal afferent nerves and in the nucleus tractus solitarius and chemoreceptor trigger zone. This reduces serotonin-mediated activation of emetic reflex pathways.',
      steps: ['Serotonin release activates 5-HT3 receptors in gut and CNS emetic pathways.', 'Ondansetron competitively blocks 5-HT3 receptors.', 'Vagal afferent signalling from the gastrointestinal tract decreases.', 'Central emetic pathway activation is reduced.', 'Nausea and vomiting are less likely.'],
      indications: 'Prevention and treatment of chemotherapy-, radiotherapy- and postoperative-associated nausea and vomiting.',
      kinetics: 'Oral and IV formulations; hepatic metabolism through CYP enzymes and variable exposure with hepatic impairment.',
      dose: 'Regimen depends on emetogenic risk, route and indication. Follow maximum dosing and hepatic impairment restrictions.',
      cautions: 'QT prolongation, congenital long-QT syndrome, electrolyte abnormalities and serotonin syndrome risk with serotonergic combinations.',
      adverse: 'Headache, constipation, dizziness and QT prolongation; rare serotonin syndrome.',
      interactions: 'Other QT-prolonging drugs increase arrhythmia risk. Apomorphine coadministration is contraindicated; serotonergic medicines require review.',
      monitoring: 'ECG and electrolytes in high-risk patients, bowel function and antiemetic response.',
      pearls: 'It blocks serotonin-mediated emesis but does not reliably treat motion sickness.',
      sources: 'ASCO antiemetic guidance; FDA/DailyMed ondansetron prescribing information.'
    )

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

Widget? _molecularStructureFor(_Drug drug) {
  switch (drug.name) {
    case 'Lisinopril':
      return const AtlasMolecularStructureViewer(
        structureKey: 'ace_lisinopril',
        structureTitle: 'Human angiotensin-converting enzyme + lisinopril',
        pdbId: '1O86', ligandName: 'Lisinopril', resolution: '2.00 Å',
        note: 'Experimental co-crystal: the ligand is shown in its deposited binding pose. Protein coordinates are from the PDB entry; the model is not a docking prediction.',
      );
    case 'Atorvastatin':
      return const AtlasMolecularStructureViewer(
        structureKey: 'hmgcr_atorvastatin',
        structureTitle: 'Human HMG-CoA reductase + atorvastatin',
        pdbId: '1HWK', ligandName: 'Atorvastatin', resolution: '2.22 Å',
        note: 'Experimental co-crystal: atorvastatin coordinates are taken from ligand component 117 in the deposited complex.',
      );
    case 'Ibuprofen':
      return const AtlasMolecularStructureViewer(
        structureKey: 'cox1_ibuprofen',
        structureTitle: 'Ovine cyclo-oxygenase-1 + ibuprofen',
        pdbId: '1EQG', ligandName: 'Ibuprofen', resolution: '2.61 Å',
        note: 'Experimental co-crystal: ibuprofen is shown in the deposited COX-1 binding site. The protein is ovine, not human.',
      );
    case 'Apixaban':
      return const AtlasMolecularStructureViewer(
        structureKey: 'factorxa_apixaban',
        structureTitle: 'Human coagulation factor Xa + apixaban',
        pdbId: '2P16', ligandName: 'Apixaban', resolution: '2.30 Å',
        note: 'Experimental co-crystal: apixaban is ligand component GG2 in the deposited factor Xa complex.',
      );
    case 'Azithromycin':
      return const AtlasMolecularStructureViewer(
        structureKey: 'rrna_azithromycin',
        structureTitle: '50S ribosomal subunit 23S rRNA + azithromycin',
        pdbId: '1M1K', ligandName: 'Azithromycin', resolution: '3.20 Å',
        note: 'Experimental X-ray co-crystal from Haloarcula marismortui. This archaeal 50S ribosomal-subunit homolog shows azithromycin in the conserved 23S rRNA macrolide-binding pocket.',
      );
    case 'Gentamicin':
      return const AtlasMolecularStructureViewer(
        structureKey: 'rrna_gentamicin',
        structureTitle: '16S rRNA decoding A-site + gentamicin C1a',
        pdbId: '2ET3', ligandName: 'Gentamicin C1a', resolution: '2.80 Å',
        note: 'Experimental X-ray complex of gentamicin C1a with an isolated 16S rRNA decoding-site oligonucleotide. It is the RNA binding site, not a full 30S ribosome model.',
      );
    case 'Semaglutide':
      return const AtlasMolecularStructureViewer(
        structureKey: 'glp1r_semaglutide',
        structureTitle: 'Human GLP-1 receptor + semaglutide peptide',
        pdbId: '7KI0', ligandName: 'Semaglutide', resolution: '2.50 Å',
        method: 'Cryo-EM structure',
        note: 'Experimental cryo-EM complex of semaglutide bound to GLP-1R with Gs protein. The peptide chain is shown in its deposited receptor-bound conformation; this is not an isolated peptide conformer.',
      );
    case 'Methotrexate':
      return const AtlasMolecularStructureViewer(
        structureKey: 'dhfr_methotrexate',
        structureTitle: 'Human dihydrofolate reductase + methotrexate',
        pdbId: '1U72', ligandName: 'Methotrexate', resolution: '1.90 Å',
        note: 'Wild-type human DHFR ternary crystal complex with methotrexate and NADPH. The deposited structure directly represents the human drug target.',
      );
    default:
      final slug = drug.name.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|- extends StatelessWidget {
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
          const SizedBox(height: 14),
          AtlasMolecularMechanismDiagram(
            drugName: drug.name,
            className: drug.className,
            steps: drug.steps,
          ),
          const SizedBox(height: 14),
          const Text('DETAILED MECHANISM SEQUENCE',
            style: TextStyle(color: AtlasColors.royalBlue, fontSize: 9,
              letterSpacing: .8, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...drug.steps.asMap().entries.map((entry) => _MechanismStep(
            number: entry.key + 1, text: entry.value,
            isLast: entry.key == drug.steps.length - 1)),
        ])),
      if (_molecularStructureFor(drug) != null)
        _SectionCard(title: '3D MOLECULAR STRUCTURE & BINDING SITE',
          icon: Icons.view_in_ar_rounded,
          child: _molecularStructureFor(drug)!),
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
), '');
      return AtlasDrugConformerViewer(drugName: drug.name, slug: slug);
  }
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
          const SizedBox(height: 14),
          AtlasMolecularMechanismDiagram(
            drugName: drug.name,
            className: drug.className,
            steps: drug.steps,
          ),
          const SizedBox(height: 14),
          const Text('DETAILED MECHANISM SEQUENCE',
            style: TextStyle(color: AtlasColors.royalBlue, fontSize: 9,
              letterSpacing: .8, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...drug.steps.asMap().entries.map((entry) => _MechanismStep(
            number: entry.key + 1, text: entry.value,
            isLast: entry.key == drug.steps.length - 1)),
        ])),
      if (_molecularStructureFor(drug) != null)
        _SectionCard(title: '3D MOLECULAR STRUCTURE & BINDING SITE',
          icon: Icons.view_in_ar_rounded,
          child: _molecularStructureFor(drug)!),
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
