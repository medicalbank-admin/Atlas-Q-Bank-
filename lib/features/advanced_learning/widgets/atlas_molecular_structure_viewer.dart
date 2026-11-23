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
              if (mounted) setState(() => _loaded = true);
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
