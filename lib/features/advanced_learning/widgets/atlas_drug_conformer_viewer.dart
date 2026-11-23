import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactive_3d/interactive_3d.dart';

/// Isolated 3D conformer for each drug; not a bound docking pose.
class AtlasDrugConformerViewer extends StatefulWidget {
  final String drugName, slug;
  const AtlasDrugConformerViewer({super.key, required this.drugName, required this.slug});
  @override
  State<AtlasDrugConformerViewer> createState() => _AtlasDrugConformerViewerState();
}
class _AtlasDrugConformerViewerState extends State<AtlasDrugConformerViewer> {
  final Interactive3dController _controller = Interactive3dController();
  final Interactive3dController _targetController = Interactive3dController();
  bool _loaded = false;
  String _target = 'Loading target annotation…', _organism = '', _method = '3D conformer', _atomCount = '';
  String? _selectedAtom;
  String? _targetAsset;
  String _targetSource = '';
  String _scientificNote = '';
  @override
  void initState() { super.initState(); _loadMetadata(); }
  Future<void> _loadMetadata() async {
    try {
      final raw = await rootBundle.loadString('assets/pharmacology/molecular/drug_manifest.json');
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      final item = manifest[widget.slug] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _target = item['target'] as String? ?? 'Target not annotated';
        _organism = item['organism'] as String? ?? '';
        _method = item['coordinate_method'] as String? ?? 'Computed conformer';
        _atomCount = '${item['atom_count'] ?? '—'} atoms • ${item['bond_count'] ?? '—'} bonds';
        _targetAsset = item['target_asset'] as String?;
        _targetSource = item['target_structure_source'] as String? ?? '';
        _scientificNote = item['scientific_note'] as String? ?? '';
      });
    } catch (error) {
      debugPrint('Drug conformer metadata unavailable: $error');
      if (mounted) setState(() => _target = 'Target metadata unavailable');
    }
  }
  @override
  Widget build(BuildContext context) {
    final asset = 'assets/pharmacology/molecular/drugs/${widget.slug}.glb';
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF071A2D),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF244968))),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(15,14,15,8), child: Row(children: [
          const Icon(Icons.biotech_rounded, color: Color(0xFF73DDE1), size: 19),
          const SizedBox(width: 8),
          const Expanded(child: Text('INTERACTIVE 3D MOLECULAR CONFORMER',
            style: TextStyle(color: Color(0xFFB8D8E9), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .8))),
          if (_loaded) const Icon(Icons.verified_rounded, color: Color(0xFF70D6A5), size: 16),
        ])),
        SizedBox(height: 290, child: Interactive3d(
          key: ValueKey(asset), controller: _controller, modelPath: asset,
          backgroundColor: const Color(0xFF071A2D),
          solidBackgroundColor: const [0.027,0.102,0.176,1.0], defaultZoom: 1.0,
          selectionColor: const [0.25,0.95,0.98,1.0],
          onModelLoaded: () { if (mounted) setState(() => _loaded = true); },
          onModelLoadError: (error, stack) { debugPrint('Drug conformer load failed: $error'); },
          onSelectionChanged: (entities) { if (mounted) setState(() => _selectedAtom = entities.isEmpty ? null : entities.last.name); },
          loadingWidget: const Center(child: CircularProgressIndicator(color: Color(0xFF73DDE1))),
          errorBuilder: (context,error) => Center(child: Padding(padding: const EdgeInsets.all(20),
            child: Text('3D conformer asset unavailable. Rebuild after molecular asset generation.\\n$error',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70,fontSize: 11)))),
        )),
        if (_targetAsset != null) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 13, 14, 6),
            child: Text('PREDICTED TARGET PROTEIN STRUCTURE',
              style: TextStyle(color: Color(0xFF73DDE1), fontSize: 9,
                fontWeight: FontWeight.w900, letterSpacing: .8)),
          ),
          SizedBox(height: 270, child: Interactive3d(
            key: ValueKey(_targetAsset), controller: _targetController,
            modelPath: _targetAsset!,
            backgroundColor: const Color(0xFF071A2D),
            solidBackgroundColor: const [0.027,0.102,0.176,1.0],
            defaultZoom: 1.0,
            selectionColor: const [0.95,0.70,0.22,1.0],
            onModelLoadError: (error, stack) => debugPrint('Target protein model load failed: $error'),
            loadingWidget: const Center(child: CircularProgressIndicator(color: Color(0xFF73DDE1))),
            errorBuilder: (context,error) => Center(child: Text('Target protein model unavailable\\n$error',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70,fontSize: 10))),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Text('$_targetSource • Predicted unbound target structure; not a drug-bound complex.',
              style: const TextStyle(color: Color(0xFF8EADC4), fontSize: 9)),
          ),
        ],
        Padding(padding: const EdgeInsets.fromLTRB(14,5,14,14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.drugName, style: const TextStyle(color: Colors.white,fontSize: 13,fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('$_atomCount • $_method', style: const TextStyle(color: Color(0xFF8EADC4),fontSize: 9)),
          const SizedBox(height: 8),
          const Text('PRIMARY PHARMACOLOGICAL TARGET', style: TextStyle(color: Color(0xFF73DDE1),fontSize: 8,fontWeight: FontWeight.w900,letterSpacing: .7)),
          const SizedBox(height: 3),
          Text(_target, style: const TextStyle(color: Color(0xFFE4F1F8),fontSize: 11,fontWeight: FontWeight.w700)),
          if (_organism.isNotEmpty) Text('Reference organism: $_organism',style: const TextStyle(color: Color(0xFF8EADC4),fontSize: 9)),
          if (_scientificNote.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(_scientificNote, style: const TextStyle(color: Color(0xFFB8D8E9),fontSize: 9,height: 1.4))),
          if (_selectedAtom != null) ...[const SizedBox(height: 7),Text('Selected: $_selectedAtom',style: const TextStyle(color: Color(0xFF73DDE1),fontSize: 10,fontWeight: FontWeight.w800))],
          const SizedBox(height: 8),
          Row(children: [
            const Expanded(child: Text('Drag to rotate • Pinch to zoom • Tap atoms to inspect',style: TextStyle(color: Color(0xFF8EADC4),fontSize: 9))),
            IconButton(tooltip: 'Reset molecular view',visualDensity: VisualDensity.compact,
              onPressed: () => _controller.resetCamera(),
              icon: const Icon(Icons.center_focus_strong_rounded,color: Color(0xFFB8D8E9),size: 18)),
          ]),
          const Text('Scientific distinction: this is an isolated-molecule 3D conformer generated from PubChem chemical identity data. It is not an experimentally observed protein-bound pose, docking result, or molecular-dynamics simulation. Target annotation is shown separately.',
            style: TextStyle(color: Color(0xFF8EADC4),fontSize: 9,height: 1.45)),
        ])),
      ]),
    );
  }
}
