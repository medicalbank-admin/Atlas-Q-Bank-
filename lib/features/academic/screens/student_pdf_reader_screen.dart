import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../app/atlas_academy_app.dart';
import '../models/learning_resource_model.dart';
import '../services/pdf_highlight_service.dart';

class StudentPdfReaderScreen extends StatefulWidget {
  final LearningResourceModel resource;
  final int initialPage;

  const StudentPdfReaderScreen({
    super.key,
    required this.resource,
    this.initialPage = 0,
  });

  @override
  State<StudentPdfReaderScreen> createState() => _StudentPdfReaderScreenState();
}

class _StudentPdfReaderScreenState extends State<StudentPdfReaderScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _viewerKey = GlobalKey<SfPdfViewerState>();
  Timer? _progressTimer;
  String? _selectedText;
  int _pageCount = 0;
  int _currentPage = 1;
  Color _selectedColor = const Color(0xFFFFE082);
  bool _restoring = false;
  bool _restored = false;
  bool _savingHighlight = false;

  static const List<Color> _highlightColors = [
    Color(0xFFFFE082),
    Color(0xFFA5D6A7),
    Color(0xFF90CAF9),
    Color(0xFFF48FB1),
  ];

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restoreHighlights() async {
    if (_restored || _restoring) return;
    _restoring = true;
    try {
      final items = await PdfHighlightService.loadForResource(widget.resource.id);
      for (final item in items) {
        final rawLines = item['lines'];
        if (rawLines is! List) continue;
        final lines = <PdfTextLine>[];
        for (final raw in rawLines.whereType<Map>()) {
          final data = Map<String, dynamic>.from(raw);
          final page = (data['pageNumber'] as num?)?.toInt() ?? 0;
          final left = (data['left'] as num?)?.toDouble() ?? 0;
          final top = (data['top'] as num?)?.toDouble() ?? 0;
          final width = (data['width'] as num?)?.toDouble() ?? 0;
          final height = (data['height'] as num?)?.toDouble() ?? 0;
          final text = (data['text'] ?? '').toString();
          if (width > 0 && height > 0 && text.isNotEmpty) {
            lines.add(PdfTextLine(
              Rect.fromLTWH(left, top, width, height), text, page));
          }
        }
        if (lines.isEmpty) continue;
        final annotation = HighlightAnnotation(textBoundsCollection: lines)
          ..color = Color((item['colorValue'] as num?)?.toInt() ?? 0xFFFFE082)
          ..opacity = .42;
        _controller.addAnnotation(annotation);
      }
      _restored = true;
    } catch (error) {
      _showMessage('Saved highlights could not be restored: $error');
    } finally {
      _restoring = false;
    }
  }

  Future<void> _onDocumentLoaded(PdfDocumentLoadedDetails details) async {
    if (!mounted) return;
    setState(() => _pageCount = details.document.pages.count);
    await _restoreHighlights();
    if (!mounted) return;
    var target = widget.initialPage;
    if (target <= 0) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final progress = await FirebaseFirestore.instance
              .collection('student_resource_progress')
              .doc('${uid}_${widget.resource.id}').get();
          target = (progress.data()?['lastPdfPage'] as num?)?.toInt() ?? 1;
        } catch (_) {}
      }
    }
    if (target > 0 && target <= _pageCount) {
      _controller.jumpToPage(target);
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    _currentPage = details.newPageNumber;
    _progressTimer?.cancel();
    _progressTimer = Timer(const Duration(milliseconds: 700), _savePageProgress);
    if (mounted) setState(() {});
  }

  Future<void> _savePageProgress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('student_resource_progress')
          .doc('${uid}_${widget.resource.id}').set({
        'userId': uid,
        'resourceId': widget.resource.id,
        'completed': false,
        'lastPdfPage': _currentPage,
        'lastPdfPageCount': _pageCount,
        'lastOpenedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Reading remains available even if progress sync is temporarily unavailable.
    }
  }

  Future<void> _addHighlight() async {
    final selected = _selectedText?.trim() ?? '';
    final lines = _viewerKey.currentState?.getSelectedTextLines() ?? [];
    if (selected.isEmpty || lines.isEmpty) {
      _showMessage('Select a passage in the PDF first.');
      return;
    }
    setState(() => _savingHighlight = true);
    try {
      final geometry = lines.map((line) => <String, dynamic>{
        'pageNumber': line.pageNumber,
        'text': line.text,
        'left': line.bounds.left,
        'top': line.bounds.top,
        'width': line.bounds.width,
        'height': line.bounds.height,
      }).toList();
      await PdfHighlightService.save(
        resourceId: widget.resource.id,
        resourceTitle: widget.resource.title,
        resourceUrl: widget.resource.resourceUrl,
        subjectId: widget.resource.subjectId,
        subjectName: widget.resource.subjectName,
        topicId: widget.resource.topicId,
        topicName: widget.resource.topicName,
        systemName: widget.resource.systemName,
        resourceVersion: widget.resource.versionNumber,
        pageNumber: lines.first.pageNumber,
        selectedText: selected,
        lines: geometry,
        colorValue: _selectedColor.toARGB32(),
      );
      final annotation = HighlightAnnotation(textBoundsCollection: lines)
        ..color = _selectedColor
        ..opacity = .42;
      _controller.addAnnotation(annotation);
      _controller.clearSelection();
      if (mounted) setState(() => _selectedText = null);
      _showMessage('Highlight saved to My Highlights.');
    } catch (error) {
      _showMessage('Could not save highlight: $error');
    } finally {
      if (mounted) setState(() => _savingHighlight = false);
    }
  }

  Future<void> _searchPdf() async {
    final query = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Search this PDF'),
        content: TextField(
          controller: query,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter a word or phrase',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (text) => Navigator.pop(dialogContext, text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, query.text.trim()),
            child: const Text('Search')),
        ],
      ),
    );
    query.dispose();
    if (value != null && value.isNotEmpty) _controller.searchText(value);
  }

  Future<void> _goToPage() async {
    final input = TextEditingController(text: _currentPage.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Go to page'),
        content: TextField(
          controller: input,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Page (1–$_pageCount)'),
          onSubmitted: (text) => Navigator.pop(dialogContext, int.tryParse(text)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, int.tryParse(input.text)),
            child: const Text('Go')),
        ],
      ),
    );
    input.dispose();
    if (value != null && value >= 1 && value <= _pageCount) {
      _controller.jumpToPage(value);
    }
  }

  void _showMessage(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    appBar: AppBar(
      title: Text(widget.resource.title, maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      backgroundColor: Colors.white,
      foregroundColor: AtlasColors.navy,
      actions: [
        IconButton(tooltip: 'Search PDF', onPressed: _searchPdf,
          icon: const Icon(Icons.search_rounded)),
        TextButton(
          onPressed: _pageCount == 0 ? null : _goToPage,
          child: Text('$_currentPage / $_pageCount',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
    body: Column(children: [
      Expanded(
        child: SfPdfViewer.network(
          widget.resource.resourceUrl,
          key: _viewerKey,
          controller: _controller,
          canShowTextSelectionMenu: false,
          onDocumentLoaded: _onDocumentLoaded,
          onPageChanged: _onPageChanged,
          onTextSelectionChanged: (details) {
            if (!mounted) return;
            setState(() => _selectedText = details.selectedText);
          },
          onDocumentLoadFailed: (details) =>
            _showMessage('Unable to open PDF: ${details.description}'),
        ),
      ),
      if (_selectedText != null && _selectedText!.trim().isNotEmpty)
        Material(
          color: Colors.white,
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Align(alignment: Alignment.centerLeft,
                  child: Text('SAVE IMPORTANT PASSAGE',
                    style: TextStyle(color: AtlasColors.navy,
                      fontSize: 10, letterSpacing: 1.1,
                      fontWeight: FontWeight.w900))),
                const SizedBox(height: 8),
                Row(children: [
                  ..._highlightColors.map((color) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 30, height: 30,
                      margin: const EdgeInsets.only(right: 9),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color
                            ? AtlasColors.navy : const Color(0xFFD4DEE8),
                          width: _selectedColor == color ? 2.5 : 1)),
                    ),
                  )),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _savingHighlight ? null : _addHighlight,
                    icon: _savingHighlight
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.highlight_rounded),
                    label: const Text('Highlight'),
                  ),
                ]),
              ]),
            ),
          ),
        ),
    ]),
  );
}
