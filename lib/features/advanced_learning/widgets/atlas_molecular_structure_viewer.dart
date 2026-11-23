import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:interactive_3d/interactive_3d.dart';

/// Native Filament (Android) / SceneKit (iOS) atom-level molecular structure
/// viewer. The GLB is generated from experimental PDB coordinates in CI.
class AtlasMolecularStructureViewer extends StatefulWidget {
  final String structureKey;
  final String structureTitle;
  final String pdbId;
  final String ligandName;
  final String resolution;
  final String note;

  const AtlasMolecularStructureViewer({
    super.key,
    required this.structureKey,
    required this.structureTitle,
    required this.pdbId,
    required this.ligandName,
    required this.resolution,
    required this.note,
  });

  @override
  State<AtlasMolecularStructureViewer> createState() =>
      _AtlasMolecularStructureViewerState();
}

class _AtlasMolecularStructureViewerState
    extends State<AtlasMolecularStructureViewer> {
  final Interactive3dController _controller = Interactive3dController();
  String? _selectedAtom;
  bool _loaded = false;
  bool _animateInteractions = true;
  int _pulsePhase = 0;
  String _interactionLabel = 'Experimental ligand pose';
  List<String> _ligandAtoms = const [];
  List<String> _bindingAtoms = const [];
  Timer? _interactionTimer;

  Future<void> _loadInteractionMetadata() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/pharmacology/molecular/manifest.json');
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      final record = manifest[widget.structureKey] as Map<String, dynamic>;
      _ligandAtoms = List<String>.from(record['ligand_atom_names'] as List);
      _bindingAtoms = List<String>.from(record['binding_site_atom_names'] as List);
      _startInteractionAnimation();
    } catch (error) {
      debugPrint('Molecular interaction metadata unavailable: $error');
    }
  }

  void _startInteractionAnimation() {
    _interactionTimer?.cancel();
    if (!_animateInteractions || !_loaded) return;
    _interactionTimer = Timer.periodic(const Duration(milliseconds: 1350),
      (_) async {
        if (!mounted || _ligandAtoms.isEmpty) return;
        final phase = _pulsePhase++ % 3;
        final names = phase == 0
            ? _ligandAtoms
            : phase == 1
                ? _bindingAtoms
                : [..._ligandAtoms, ..._bindingAtoms];
        final glow = phase == 0
            ? <double>[0.04, 0.58, 0.78]
            : phase == 1
                ? <double>[0.12, 0.34, 0.62]
                : <double>[0.08, 0.48, 0.66];
        try {
          await _controller.resetAllMaterialOverrides();
          await _controller.setEntityMaterials(names.map((name) =>
            MaterialOverride(name: name, emissive: glow, roughness: 0.3)).toList());
        } catch (error) {
          debugPrint('Molecular interaction highlight failed: $error');
        }
        if (mounted) setState(() {
          _interactionLabel = phase == 0
              ? 'Drug ligand: co-crystallised pose'
              : phase == 1
                  ? 'Receptor: atoms within 4.2 Å of ligand'
                  : 'Ligand–binding-site contact network';
        });
      });
  }

  @override
  void dispose() {
    _interactionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = 'assets/pharmacology/molecular/${widget.structureKey}.glb';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071A2D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF244968)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
          child: Row(children: [
            const Icon(Icons.biotech_rounded, color: Color(0xFF73DDE1), size: 19),
            const SizedBox(width: 8),
            const Expanded(child: Text('EXPERIMENTAL ATOM-LEVEL STRUCTURE',
              style: TextStyle(color: Color(0xFFB8D8E9), fontSize: 9,
                fontWeight: FontWeight.w900, letterSpacing: .8))),
            if (_loaded)
              const Icon(Icons.verified_rounded, color: Color(0xFF70D6A5), size: 16),
          ]),
        ),
        SizedBox(
          height: 300,
          child: Interactive3d(
            key: ValueKey(asset),
            controller: _controller,
            modelPath: asset,
            backgroundColor: const Color(0xFF071A2D),
            solidBackgroundColor: const [0.027, 0.102, 0.176, 1.0],
            defaultZoom: 1.0,
            selectionColor: const [0.25, 0.95, 0.98, 1.0],
            onModelLoaded: () {
              if (mounted) {
                setState(() => _loaded = true);
                _loadInteractionMetadata();
              }
            },
            onModelLoadError: (error, stack) {
              debugPrint('Molecular structure load failed: $error');
            },
            onSelectionChanged: (entities) {
              if (!mounted) return;
              setState(() => _selectedAtom =
                  entities.isEmpty ? null : entities.last.name);
            },
            loadingWidget: const Center(child: CircularProgressIndicator(
              color: Color(0xFF73DDE1))),
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Could not load this molecular structure. Rebuild the APK after the molecular asset-generation step.\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.structureTitle,
              style: const TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('PDB ${widget.pdbId} • X-ray structure • ${widget.resolution}',
              style: const TextStyle(color: Color(0xFF8EADC4), fontSize: 10)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.animation_rounded,
                color: Color(0xFF73DDE1), size: 15),
              const SizedBox(width: 6),
              Expanded(child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(_interactionLabel, key: ValueKey(_interactionLabel),
                  style: const TextStyle(color: Color(0xFF73DDE1),
                    fontSize: 9, fontWeight: FontWeight.w800)),
              )),
              IconButton(
                tooltip: _animateInteractions ? 'Pause interaction animation' : 'Play interaction animation',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _animateInteractions = !_animateInteractions;
                  if (_animateInteractions) {
                    _startInteractionAnimation();
                  } else {
                    _interactionTimer?.cancel();
                    _controller.resetAllMaterialOverrides();
                    _interactionLabel = 'Animation paused';
                  }
                }),
                icon: Icon(_animateInteractions ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFFB8D8E9), size: 18),
              ),
            ]),
            const SizedBox(height: 5),
            const Wrap(spacing: 12, runSpacing: 5, children: [
              _AtomLegend(color: Color(0xFF73DDE1), label: 'Co-crystallised ligand carbon'),
              _AtomLegend(color: Color(0xFFB5C0CD), label: 'Protein carbon'),
              _AtomLegend(color: Color(0xFF4779E8), label: 'Nitrogen'),
              _AtomLegend(color: Color(0xFFE34B46), label: 'Oxygen'),
            ]),
            if (_selectedAtom != null) ...[
              const SizedBox(height: 8),
              Text('Selected atom: $_selectedAtom',
                style: const TextStyle(color: Color(0xFF73DDE1),
                  fontSize: 10, fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 8),
            Row(children: [
              const Expanded(child: Text('Drag to rotate • Pinch to zoom • Tap atoms to inspect',
                style: TextStyle(color: Color(0xFF8EADC4), fontSize: 9))),
              IconButton(
                tooltip: 'Reset molecular view',
                visualDensity: VisualDensity.compact,
                onPressed: () => _controller.resetCamera(),
                icon: const Icon(Icons.center_focus_strong_rounded,
                  color: Color(0xFFB8D8E9), size: 18),
              ),
            ]),
            Text(widget.note,
              style: const TextStyle(color: Color(0xFF8EADC4),
                fontSize: 9, height: 1.45)),
          ]),
        ),
      ]),
    );
  }
}

class _AtomLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _AtomLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Color(0xFFB4C8D8), fontSize: 8)),
    ]);
}
