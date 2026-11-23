import 'dart:async';
import 'package:flutter/material.dart';

/// Responsive drug-specific MOA illustration using each profile's detailed
/// mechanism steps. This is a pathway diagram, not a docking simulation.
class AtlasMolecularMechanismDiagram extends StatefulWidget {
  final String drugName;
  final String className;
  final List<String> steps;
  const AtlasMolecularMechanismDiagram({
    super.key, required this.drugName, required this.className,
    required this.steps,
  });
  @override
  State<AtlasMolecularMechanismDiagram> createState() =>
      _AtlasMolecularMechanismDiagramState();
}

class _AtlasMolecularMechanismDiagramState
    extends State<AtlasMolecularMechanismDiagram> {
  static const navy = Color(0xFF173653);
  static const blue = Color(0xFF2369A5);
  static const teal = Color(0xFF159A9A);
  static const muted = Color(0xFF66819B);
  bool drugAction = true;
  bool playing = true;
  int activeStep = 0;
  int? expandedNode;
  Timer? timer;

  List<String> get mechanismSteps => widget.steps.isEmpty
      ? ['Molecular target engagement', 'Primary biochemical process',
         'Cellular signalling changes', 'Physiological outcome']
      : widget.steps;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted || !playing || !drugAction) return;
      setState(() => activeStep = (activeStep + 1) % mechanismSteps.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = mechanismSteps;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FBFF), Color(0xFFEFF6FC)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E5F2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 35, height: 35,
            decoration: BoxDecoration(color: const Color(0xFFE0EFFB),
              borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.account_tree_rounded, color: blue, size: 20)),
          const SizedBox(width: 9),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VISUAL MECHANISM OF ACTION',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                  letterSpacing: .65, color: navy)),
              Text('Follow the drug from molecular target to clinical effect',
                style: TextStyle(fontSize: 9, color: muted)),
            ])),
          IconButton(
            tooltip: playing ? 'Pause animation' : 'Play animation',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => playing = !playing),
            icon: Icon(playing ? Icons.pause_circle_outline
                : Icons.play_circle_outline, color: blue, size: 22)),
        ]),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Normal physiology'),
              icon: Icon(Icons.favorite_border_rounded)),
            ButtonSegment(value: true, label: Text('Drug action'),
              icon: Icon(Icons.medication_rounded)),
          ],
          selected: {drugAction},
          onSelectionChanged: (value) => setState(() {
            drugAction = value.first;
            expandedNode = null;
            activeStep = 0;
          }),
          showSelectedIcon: false,
          style: const ButtonStyle(
            textStyle: WidgetStatePropertyAll(TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800)),
            visualDensity: VisualDensity.compact)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: drugAction ? const Color(0xFFE4F0FC)
                : const Color(0xFFE7F5EC),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: drugAction
                ? const Color(0xFFB9D4EE) : const Color(0xFFB9DEC6))),
          child: Row(children: [
            Icon(drugAction ? Icons.medication_liquid_rounded
                : Icons.eco_rounded,
              color: drugAction ? blue : const Color(0xFF287A54), size: 23),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(drugAction ? widget.drugName.toUpperCase()
                    : 'BASELINE PHYSIOLOGY',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                    color: navy, letterSpacing: .5)),
                Text(drugAction ? widget.className
                    : 'Endogenous ligand / substrate and normal signalling',
                  style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: navy)),
              ])),
          ])),
        const SizedBox(height: 10),
        const Row(children: [
          Icon(Icons.track_changes_rounded, color: teal, size: 17),
          SizedBox(width: 7),
          Text('MOLECULAR TARGET / FIRST KEY EVENT',
            style: TextStyle(fontSize: 8, color: muted,
              fontWeight: FontWeight.w900, letterSpacing: .6)),
        ]),
        const SizedBox(height: 5),
        Container(width: double.infinity, padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB9DAD9))),
          child: Text(steps.first, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w900, color: navy))),
        const Center(child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Icon(Icons.arrow_downward_rounded, color: teal, size: 20))),
        Row(children: [
          const Expanded(child: Text('STEP-BY-STEP DRUG MECHANISM',
            style: TextStyle(fontSize: 8, letterSpacing: .45,
              fontWeight: FontWeight.w900, color: muted))),
          Text(steps.length.toString() + ' stages',
            style: const TextStyle(fontSize: 8, color: blue,
              fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        ...List.generate(steps.length, (index) {
          final active = drugAction && activeStep == index;
          final expanded = expandedNode == index;
          final last = index == steps.length - 1;
          return Column(children: [
            InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => setState(() =>
                  expandedNode = expanded ? null : index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFDDF4F2) : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: active ? teal
                      : const Color(0xFFD9E6F0),
                    width: active ? 1.8 : 1),
                  boxShadow: active ? [
                    BoxShadow(color: teal.withValues(alpha: .12),
                      blurRadius: 12, offset: const Offset(0, 3))
                  ] : null),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 31, height: 31, alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? teal : const Color(0xFFEAF1F8),
                        shape: BoxShape.circle),
                      child: Text((index + 1).toString(), style: TextStyle(
                        color: active ? Colors.white : blue,
                        fontSize: 12, fontWeight: FontWeight.w900))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(index == 0 ? 'DRUG–TARGET EVENT'
                            : last ? 'FINAL PHYSIOLOGICAL EFFECT'
                            : 'MECHANISM STAGE ' + (index + 1).toString(),
                          style: const TextStyle(fontSize: 8,
                            letterSpacing: .55, color: muted,
                            fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(steps[index],
                          maxLines: expanded ? 12 : 3,
                          overflow: expanded ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, height: 1.45,
                            color: navy, fontWeight: FontWeight.w700)),
                      ])),
                    Icon(expanded ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                      color: muted, size: 18),
                  ])),
            ),
            if (!last) SizedBox(height: 24,
              child: Center(child: Icon(Icons.arrow_downward_rounded,
                color: active ? teal : const Color(0xFF9BB2C7), size: 19))),
          ]);
        }),
        const SizedBox(height: 8),
        Container(width: double.infinity, padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: navy,
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.insights_rounded,
              color: Color(0xFF8FE0DC), size: 19),
            const SizedBox(width: 9),
            Expanded(child: Text(drugAction ? steps.last
                : 'Normal endogenous signalling maintains the baseline physiological response.',
              style: const TextStyle(color: Colors.white, fontSize: 11,
                height: 1.4, fontWeight: FontWeight.w800))),
          ])),
        const SizedBox(height: 9),
        Row(children: [
          Icon(playing ? Icons.auto_awesome_rounded
              : Icons.touch_app_rounded, size: 14, color: blue),
          const SizedBox(width: 6),
          Expanded(child: Text(playing
              ? 'Animated highlight follows each mechanism stage • Tap a stage to expand'
              : 'Animation paused • Tap a stage to expand',
            style: const TextStyle(fontSize: 9, height: 1.4,
              color: muted, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 5),
        const Text(
          'Educational pathway illustration based on this drug’s mechanism. It is not a molecular docking pose or molecular-dynamics simulation.',
          style: TextStyle(fontSize: 9, height: 1.4, color: muted)),
      ]));
  }
}
