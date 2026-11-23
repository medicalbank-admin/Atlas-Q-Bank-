import 'package:flutter/material.dart';

/// Interactive, class-aware molecular pathway illustration used by the
/// Clinical Pharmacology drug profiles. The diagram is educational and
/// deliberately labels the molecular target instead of implying every drug
/// binds a cell-surface receptor.
class AtlasMolecularMechanismDiagram extends StatefulWidget {
  final String drugName;
  final String className;
  final List<String> steps;

  const AtlasMolecularMechanismDiagram({
    super.key,
    required this.drugName,
    required this.className,
    required this.steps,
  });

  @override
  State<AtlasMolecularMechanismDiagram> createState() =>
      _AtlasMolecularMechanismDiagramState();
}

class _AtlasMolecularMechanismDiagramState
    extends State<AtlasMolecularMechanismDiagram> {
  bool _drugAction = true;
  int? _expandedNode;

  static const Map<String, List<String>> _targets = {
    'Beta-blocker': ['β₁-adrenergic receptor', 'Gs / adenylyl cyclase', 'cAMP ↓ · PKA ↓', 'Heart rate & contractility ↓'],
    'Calcium-channel blocker': ['L-type Ca²⁺ channel', 'Ca²⁺ entry into smooth muscle', 'Calmodulin / MLCK activity ↓', 'Arteriolar tone ↓'],
    'ACE inhibitor': ['Angiotensin-converting enzyme', 'Angiotensin I → angiotensin II', 'AT₁ signalling & aldosterone ↓', 'Vascular resistance ↓'],
    'Loop diuretic': ['NKCC2 cotransporter', 'Na⁺ / K⁺ / 2Cl⁻ transport', 'Medullary gradient ↓', 'Natriuresis & diuresis ↑'],
    'Short-acting bronchodilator': ['β₂-adrenergic receptor', 'Gs → adenylyl cyclase', 'cAMP ↑ · PKA ↑', 'Bronchial smooth muscle relaxes'],
    'Biguanide': ['Hepatic mitochondrial energy pathways', 'Cellular AMP : ATP signalling', 'Gluconeogenic flux ↓', 'Hepatic glucose output ↓'],
    'Acid suppression': ['H⁺ / K⁺-ATPase proton pump', 'Parietal-cell H⁺ secretion', 'Final acid-secretory step blocked', 'Gastric acidity ↓'],
    'Beta-lactam antibiotic': ['Penicillin-binding proteins (PBPs)', 'Peptidoglycan cross-linking', 'Cell-wall integrity fails', 'Susceptible bacteria lyse'],
    'ARB': ['Angiotensin II AT₁ receptor', 'Angiotensin II binding', 'Vasoconstrictor / aldosterone signalling ↓', 'Blood pressure ↓'],
    'Thiazide diuretic': ['NCC cotransporter', 'Na⁺ / Cl⁻ reabsorption', 'Distal NaCl uptake ↓', 'Natriuresis; BP ↓'],
    'Statin': ['HMG-CoA reductase', 'HMG-CoA → mevalonate', 'Hepatic cholesterol synthesis ↓', 'LDL-receptor expression ↑'],
    'Antiplatelet': ['Platelet COX-1 enzyme', 'Arachidonic acid → thromboxane A₂', 'TXA₂ generation ↓', 'Platelet aggregation ↓'],
    'Direct oral anticoagulant': ['Activated factor Xa', 'Prothrombin → thrombin', 'Fibrin generation ↓', 'Clot propagation ↓'],
    'Antiarrhythmic': ['Cardiac ion channels / transporters', 'Ion currents & action potential', 'Refractoriness / conduction altered', 'Arrhythmia burden may fall'],
    'SGLT2 inhibitor': ['Proximal-tubule SGLT2', 'Filtered glucose / Na⁺ uptake', 'Glucosuria & natriuresis ↑', 'Plasma glucose / volume ↓'],
    'GLP-1 receptor agonist': ['GLP-1 receptor (Gs-coupled)', 'Glucose-dependent cAMP signalling', 'Insulin ↑ · glucagon ↓', 'Glycaemia & appetite ↓'],
    'Thyroid hormone replacement': ['Nuclear thyroid hormone receptors', 'T₃-responsive gene transcription', 'Metabolic gene expression restored', 'Tissue thyroid signalling restored'],
    'Corticosteroid': ['Intracellular glucocorticoid receptor', 'Receptor–DNA / transcriptional control', 'Pro-inflammatory mediators ↓', 'Inflammation & immune activity ↓'],
    'H1 antihistamine': ['Histamine H₁ receptor', 'Gq / PLC signalling', 'Histamine response blocked', 'Itch, sneeze & oedema ↓'],
    'Inhaled corticosteroid': ['Airway-cell glucocorticoid receptor', 'Inflammatory gene transcription', 'Eosinophilic inflammation ↓', 'Airway hyper-responsiveness ↓'],
    'Antimuscarinic bronchodilator': ['Airway M₃ muscarinic receptor', 'Gq / IP₃ / intracellular Ca²⁺', 'Cholinergic contraction blocked', 'Bronchial smooth muscle relaxes'],
    'Penicillin antibiotic': ['Penicillin-binding proteins', 'Peptidoglycan transpeptidation', 'Cell-wall cross-links ↓', 'Bacterial cell-wall failure'],
    'Macrolide': ['50S ribosomal subunit (23S rRNA)', 'Peptide-chain elongation / exit tunnel', 'Bacterial protein synthesis ↓', 'Bacterial growth inhibited'],
    'Fluoroquinolone': ['DNA gyrase / topoisomerase IV', 'DNA supercoiling & decatenation', 'DNA replication / repair disrupted', 'Bacterial DNA damage'],
    'Aminoglycoside': ['30S ribosomal subunit', 'mRNA decoding accuracy', 'Misreading & abnormal proteins ↑', 'Bacterial protein synthesis fails'],
    'Antiviral': ['Viral DNA polymerase', 'Viral genome replication', 'Chain elongation / DNA synthesis blocked', 'Viral replication ↓'],
    'Azole antifungal': ['Fungal lanosterol 14-α-demethylase', 'Lanosterol → ergosterol', 'Ergosterol synthesis ↓', 'Fungal membrane function impaired'],
    'Antitubercular': ['Mycobacterial InhA pathway', 'Mycolic-acid synthesis', 'Cell-wall lipid synthesis ↓', 'Mycobacterial growth inhibited'],
    'NSAID': ['Cyclo-oxygenase COX-1 / COX-2', 'Arachidonic acid → prostaglandins', 'Prostaglandin synthesis ↓', 'Pain, fever & inflammation ↓'],
    'Opioid analgesic': ['μ-opioid receptor (Gi/o-coupled)', 'Adenylyl cyclase / Ca²⁺ / K⁺ channels', 'Neuronal transmitter release ↓', 'Pain transmission ↓'],
    'Local anaesthetic': ['Voltage-gated Na⁺ channel', 'Axonal Na⁺ influx', 'Action-potential propagation blocked', 'Regional sensation ↓'],
    'SSRI antidepressant': ['Serotonin transporter (SERT)', 'Synaptic serotonin reuptake', 'Extracellular 5-HT availability ↑', 'Serotonergic signalling changes'],
    'Antiepileptic': ['Voltage-gated channels / GABA pathways', 'Neuronal firing & synaptic signalling', 'Network excitability ↓', 'Seizure probability ↓'],
    'Typical antipsychotic': ['D₂ dopamine receptor', 'Mesolimbic dopaminergic signalling', 'D₂ transmission reduced', 'Positive psychotic symptoms ↓'],
    'Benzodiazepine': ['GABA-A receptor allosteric site', 'GABA-gated chloride-channel opening', 'Inhibitory signalling enhanced', 'Neuronal excitability ↓'],
    'Antimetabolite': ['Dihydrofolate reductase (DHFR)', 'DHF → THF one-carbon cycle', 'Purine / thymidylate synthesis ↓', 'Cell proliferation ↓'],
    'Nitrate antianginal': ['Smooth-muscle soluble guanylyl cyclase pathway', 'Nitric oxide → cGMP', 'Myosin light-chain dephosphorylation', 'Venodilation; preload ↓'],
    'Sulfonylurea': ['Pancreatic β-cell KATP channel', 'K⁺ efflux / membrane potential', 'Depolarisation → Ca²⁺ entry', 'Insulin secretion ↑'],
    'Anaerobic antibacterial / antiprotozoal': ['Microbial nitroreductase activation', 'Nitro group → reactive intermediates', 'DNA strand / helix damage', 'Susceptible anaerobe death'],
    'Proton-pump inhibitor': ['Gastric H⁺ / K⁺-ATPase', 'Parietal-cell proton transport', 'Active pump covalently inhibited', 'Gastric acid secretion ↓'],
    'Antiemetic': ['5-HT₃ ligand-gated receptor', 'Vagal afferent / central emetic signalling', 'Serotonin-triggered transmission blocked', 'Nausea & vomiting ↓'],
  };

  static const Map<String, String> _normal = {
    'Beta-blocker': 'Catecholamines activate β₁ receptors, increasing cAMP, calcium cycling and cardiac workload.',
    'Calcium-channel blocker': 'L-type channels allow calcium entry, supporting vascular smooth-muscle contraction.',
    'ACE inhibitor': 'ACE forms angiotensin II, which activates AT₁ receptors and promotes aldosterone release.',
    'Loop diuretic': 'NKCC2 reabsorbs sodium, potassium and chloride in the thick ascending limb.',
    'Short-acting bronchodilator': 'β₂ stimulation raises cAMP and relaxes bronchial smooth muscle.',
    'Biguanide': 'Hepatic gluconeogenesis contributes glucose to the circulation between meals.',
    'Acid suppression': 'The parietal-cell proton pump secretes hydrogen ions into the gastric lumen.',
    'Beta-lactam antibiotic': 'PBPs cross-link peptidoglycan to maintain bacterial cell-wall strength.',
    'ARB': 'Angiotensin II activates AT₁ receptors, causing vasoconstriction and aldosterone release.',
    'Thiazide diuretic': 'NCC reabsorbs sodium and chloride in the distal convoluted tubule.',
    'Statin': 'HMG-CoA reductase supplies mevalonate for hepatic cholesterol synthesis.',
    'Antiplatelet': 'Platelet COX-1 produces thromboxane A₂, amplifying platelet activation.',
    'Direct oral anticoagulant': 'Factor Xa converts prothrombin to thrombin in the coagulation cascade.',
    'SGLT2 inhibitor': 'SGLT2 reabsorbs filtered glucose and sodium in the proximal tubule.',
    'GLP-1 receptor agonist': 'Endogenous GLP-1 enhances glucose-dependent insulin secretion.',
    'H1 antihistamine': 'Histamine activates H₁ receptors, producing itch, vasodilation and increased permeability.',
    'NSAID': 'COX enzymes generate prostaglandins involved in pain, fever and inflammation.',
    'Local anaesthetic': 'Voltage-gated sodium channels propagate action potentials along sensory nerves.',
    'SSRI antidepressant': 'SERT clears serotonin from the synaptic cleft after release.',
    'Typical antipsychotic': 'Dopamine activates D₂ receptors in multiple central pathways.',
    'Benzodiazepine': 'GABA binding increases inhibitory chloride-channel opening at GABA-A receptors.',
    'Antiemetic': 'Serotonin activates 5-HT₃ receptors on vagal afferents and central emetic pathways.',
  };

  List<String> get _path => _targets[widget.className] ??
      ['Drug-specific molecular target', 'Target interaction', 'Downstream signalling', 'Physiological response'];

  String get _normalText => _normal[widget.className] ??
      'The endogenous ligand or substrate interacts with its target and maintains the normal physiological pathway.';

  @override
  Widget build(BuildContext context) {
    final labels = _path;
    final details = _drugAction
        ? <String>[
            '${widget.drugName} engages or modulates its molecular target.',
            labels[1],
            labels[2],
            labels[3],
          ]
        : <String>[
            'Endogenous ligand / substrate reaches the target.',
            labels[1].replaceAll('↓', '↑').replaceAll('blocked', 'active'),
            'Physiological signalling proceeds.',
            'Normal pathway output is maintained.',
          ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE8F4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.biotech_rounded, color: Color(0xFF2369A5), size: 19),
          const SizedBox(width: 8),
          const Expanded(child: Text('INTERACTIVE MOLECULAR PATHWAY',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
              letterSpacing: .65, color: Color(0xFF173653)))),
          IconButton(
            tooltip: 'Reset diagram view',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _expandedNode = null),
            icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
          ),
        ]),
        const SizedBox(height: 5),
        Text('Target: ${labels[0]}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF42617D),
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Normal pathway'), icon: Icon(Icons.favorite_border_rounded)),
            ButtonSegment(value: true, label: Text('Drug action'), icon: Icon(Icons.medication_rounded)),
          ],
          selected: {_drugAction},
          onSelectionChanged: (value) => setState(() {
            _drugAction = value.first;
            _expandedNode = null;
          }),
          showSelectedIcon: false,
          style: const ButtonStyle(
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: InteractiveViewer(
            minScale: .75,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(30),
            child: SizedBox(
              width: 620,
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: _drugAction ? const Color(0xFFE5F1FF) : const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _drugAction ? const Color(0xFFB8D4F1) : const Color(0xFFB8DDC9)),
                  ),
                  child: Row(children: [
                    Icon(_drugAction ? Icons.medication_liquid_rounded : Icons.science_outlined,
                      color: _drugAction ? const Color(0xFF2369A5) : const Color(0xFF287A54)),
                    const SizedBox(width: 9),
                    Expanded(child: Text(_drugAction ? '${widget.drugName} • pharmacological intervention' : 'Endogenous ligand / substrate • baseline physiology',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF173653)))),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 7),
                  child: Icon(Icons.arrow_downward_rounded, color: Color(0xFF7795B1), size: 20),
                ),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: List.generate(4, (index) {
                  final isTarget = index == 0;
                  final selected = _expandedNode == index;
                  return Expanded(child: Padding(
                    padding: EdgeInsets.only(right: index == 3 ? 0 : 7),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _expandedNode = selected ? null : index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        constraints: const BoxConstraints(minHeight: 132),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFDCEBFA) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? const Color(0xFF2369A5) : const Color(0xFFDCE6F0),
                            width: selected ? 1.7 : 1,
                          ),
                          boxShadow: selected ? [const BoxShadow(color: Color(0x182369A5), blurRadius: 10, offset: Offset(0, 3))] : null,
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(width: 27, height: 27,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isTarget ? const Color(0xFF2369A5) : const Color(0xFFEAF1F8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              [Icons.track_changes_rounded, Icons.swap_horiz_rounded, Icons.account_tree_rounded, Icons.monitor_heart_rounded][index],
                              size: 15,
                              color: isTarget ? Colors.white : const Color(0xFF2369A5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(['MOLECULAR TARGET', 'PRIMARY PROCESS', 'CELL SIGNAL', 'ORGAN EFFECT'][index],
                            style: const TextStyle(fontSize: 8, letterSpacing: .25,
                              fontWeight: FontWeight.w900, color: Color(0xFF66819B))),
                          const SizedBox(height: 5),
                          Text(index == 0 ? labels[0] : details[index],
                            maxLines: selected ? 8 : 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, height: 1.35,
                              fontWeight: FontWeight.w800, color: Color(0xFF173653))),
                        ]),
                      ),
                    ),
                  ));
                })),
                const SizedBox(height: 8),
                const Row(children: [
                  Expanded(child: Divider(color: Color(0xFFB8CADB))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('CELLULAR / TISSUE RESPONSE',
                      style: TextStyle(fontSize: 8, letterSpacing: .7,
                        fontWeight: FontWeight.w900, color: Color(0xFF66819B))),
                  ),
                  Expanded(child: Divider(color: Color(0xFFB8CADB))),
                ]),
                const SizedBox(height: 7),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173653),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(details[3],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w900, height: 1.4)),
                ),
              ]),
            ),
          ),
        ),
        if (_expandedNode != null) ...[
          const SizedBox(height: 9),
          Text(details[_expandedNode!],
            style: const TextStyle(fontSize: 11, height: 1.5,
              color: Color(0xFF294B69), fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 9),
        Text(_drugAction ? 'Drug action: ${widget.steps.isNotEmpty ? widget.steps.first : labels[0]}' : _normalText,
          style: const TextStyle(fontSize: 10, height: 1.5, color: Color(0xFF58728B))),
        const SizedBox(height: 4),
        const Text('Tap a node for detail • Pinch to zoom • Switch modes to compare',
          style: TextStyle(fontSize: 9, color: Color(0xFF71879A), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
