import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../app/atlas_academy_app.dart';
import '../models/learning_resource_model.dart';
import '../services/pdf_highlight_service.dart';
import '../services/pdf_offline_service.dart';
import '../services/pdf_offline_store.dart';

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
  bool _downloadingPdf = false;
  double _downloadProgress = 0;
  Uint8List? _offlineBytes;
  Uint8List? _remoteBytes;
  String? _remoteLoadError;
  bool _loadingRemotePdf = true;
  bool _isOfflineSaved = false;
  bool _isOfflineOutdated = false;
  List<int> _bookmarkedPages = [];

  static const List<Color> _highlightColors = [
    Color(0xFFFFE082),
    Color(0xFFA5D6A7),
    Color(0xFF90CAF9),
    Color(0xFFF48FB1),
  ];

  @override
  void initState() {
    super.initState();
    _loadOfflinePdf();
  }

  Future<void> _loadOfflinePdf() async {
    try {
      final bytes = await readOfflinePdf(widget.resource.id);
      final records = await listOfflinePdfs();
      final matches = records.where((item) => item['id'] == widget.resource.id);
      final saved = matches.isEmpty ? null : matches.first;
      final savedVersion = (saved?['versionNumber'] as num?)?.toInt() ?? 0;
      final savedUpdated = DateTime.tryParse((saved?['updatedAt'] ?? '').toString());
      final outdated = savedVersion != widget.resource.versionNumber ||
        (savedUpdated != null && widget.resource.updatedAt.isAfter(savedUpdated.add(const Duration(seconds: 2))));
      if (!mounted) return;
      if (bytes != null) {
        if (!mounted) return;
        setState(() {
          _offlineBytes = bytes;
          _isOfflineSaved = true;
          _isOfflineOutdated = outdated;
          _loadingRemotePdf = false;
        });
        return;
      }
    } catch (_) {}
    await _loadRemotePdf();
  }

  /// Fetch and validate the PDF before handing bytes to the viewer.
  Future<void> _loadRemotePdf() async {
    if (!mounted) return;
    setState(() {
      _loadingRemotePdf = true;
      _remoteLoadError = null;
    });
    final uri = Uri.tryParse(widget.resource.resourceUrl);
    if (uri == null || !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      if (mounted) setState(() {
        _loadingRemotePdf = false;
        _remoteLoadError = 'This PDF has an invalid download address.';
      });
      return;
    }
    final client = http.Client();
    try {
      final response = await client.get(uri).timeout(const Duration(minutes: 2));
      if (response.statusCode != 200) {
        throw Exception('The file server returned HTTP ${response.statusCode}.');
      }
      final bytes = response.bodyBytes;
      if (bytes.length < 5 ||
          String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        final contentType = response.headers['content-type'] ?? 'unknown';
        throw Exception('The saved link did not return a PDF (content type: $contentType). Please ask the administrator to re-upload this chapter.');
      }
      if (!mounted) return;
      setState(() {
        _remoteBytes = bytes;
        _loadingRemotePdf = false;
        _remoteLoadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingRemotePdf = false;
        _remoteLoadError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      client.close();
    }
  }

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
    await _loadBookmarks();
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

  Future<void> _loadBookmarks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('student_resource_progress')
        .doc('${uid}_${widget.resource.id}').get();
      final raw = snap.data()?['pdfBookmarks'];
      if (mounted) setState(() => _bookmarkedPages = raw is List
        ? (raw.whereType<num>().map((v) => v.toInt()).toSet().toList()..sort())
        : <int>[]);
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final pages = List<int>.from(_bookmarkedPages);
    final wasSaved = pages.contains(_currentPage);
    if (wasSaved) { pages.remove(_currentPage); } else { pages.add(_currentPage); pages.sort(); }
    try {
      await FirebaseFirestore.instance.collection('student_resource_progress')
        .doc('${uid}_${widget.resource.id}').set({
          'userId': uid, 'resourceId': widget.resource.id, 'completed': false,
          'pdfBookmarks': pages, 'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      if (mounted) setState(() => _bookmarkedPages = pages);
      _showMessage(wasSaved ? 'Page bookmark removed.' : 'Page bookmarked.');
    } catch (error) { _showMessage('Could not save bookmark: $error'); }
  }

  void _showBookmarks() {
    showModalBottomSheet<void>(context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: SizedBox(height: 360,
        child: Column(children: [
          const Padding(padding: EdgeInsets.all(14), child: Text('Bookmarked pages',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
          Expanded(child: _bookmarkedPages.isEmpty
            ? const Center(child: Text('No bookmarked pages yet.'))
            : ListView(children: _bookmarkedPages.map((page) => ListTile(
              leading: const Icon(Icons.bookmark_rounded, color: AtlasColors.royalBlue),
              title: Text('Page $page'),
              onTap: () { Navigator.pop(sheetContext); _controller.jumpToPage(page); },
            )).toList())),
        ]))));
  }

  Future<void> _downloadPdf() async {
    if (_isOfflineSaved && !_isOfflineOutdated) {
      _showMessage('This PDF is already available offline and up to date.');
      return;
    }
    setState(() { _downloadingPdf = true; _downloadProgress = 0; });
    try {
      await PdfOfflineService.download(widget.resource, onProgress: (received, total) {
        if (mounted) setState(() => _downloadProgress = total > 0 ? received / total : 0);
      });
      final bytes = await readOfflinePdf(widget.resource.id);
      if (mounted) setState(() {
        _offlineBytes = bytes;
        _isOfflineSaved = bytes != null;
        _isOfflineOutdated = false;
      });
      _showMessage('PDF downloaded. It is now available offline.');
    } catch (error) { _showMessage('Download failed: $error'); }
    finally { if (mounted) setState(() => _downloadingPdf = false); }
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
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(widget.resource.title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        Text([widget.resource.subjectName, widget.resource.systemName, 'PDF READER']
          .where((v) => v.trim().isNotEmpty).join(' • '), maxLines: 1,
          overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9,
            color: AtlasColors.secondaryText, fontWeight: FontWeight.w700)),
      ]),
      backgroundColor: Colors.white,
      foregroundColor: AtlasColors.navy,
      elevation: 0,
      actions: [
        IconButton(tooltip: 'Bookmarked pages', onPressed: _showBookmarks,
          icon: const Icon(Icons.bookmarks_outlined)),
        IconButton(tooltip: _bookmarkedPages.contains(_currentPage) ? 'Remove bookmark' : 'Bookmark page',
          onPressed: _toggleBookmark,
          icon: Icon(_bookmarkedPages.contains(_currentPage) ? Icons.bookmark_rounded : Icons.bookmark_add_outlined)),
        IconButton(tooltip: _isOfflineOutdated ? 'Update offline PDF' : 'Download PDF for offline use',
          onPressed: (_downloadingPdf || (_isOfflineSaved && !_isOfflineOutdated)) ? null : _downloadPdf,
          icon: _downloadingPdf ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(_isOfflineOutdated ? Icons.system_update_alt_rounded :
              _isOfflineSaved ? Icons.offline_pin_rounded : Icons.download_for_offline_outlined)),
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
      Container(height: 3, color: const Color(0xFFE3EAF2),
        child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(
          widthFactor: _pageCount == 0 ? 0 : (_currentPage / _pageCount).clamp(0.0, 1.0),
          child: Container(color: AtlasColors.royalBlue)))),
      if (_downloadingPdf) LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
      if (_isOfflineOutdated)
        Material(
          color: const Color(0xFFFFF4D8),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.system_update_alt_rounded, color: Color(0xFF946200)),
            title: const Text('A newer PDF revision is available.',
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF684900))),
            subtitle: const Text('Update your offline copy to study the latest version.'),
            trailing: TextButton(onPressed: _downloadingPdf ? null : _downloadPdf,
              child: const Text('UPDATE')),
          ),
        ),
      Expanded(
        child: _offlineBytes != null || _remoteBytes != null
          ? SfPdfViewer.memory(
              (_offlineBytes ?? _remoteBytes)!, key: _viewerKey, controller: _controller,
              canShowTextSelectionMenu: false,
              onDocumentLoaded: _onDocumentLoaded,
              onPageChanged: _onPageChanged,
              onTextSelectionChanged: (details) {
                if (!mounted) return;
                setState(() => _selectedText = details.selectedText);
              },
              onDocumentLoadFailed: (details) => _showMessage('Unable to open offline PDF: ${details.description}'),
            )
          : _loadingRemotePdf
            ? const Center(child: CircularProgressIndicator())
            : Center(child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.picture_as_pdf_outlined,
                    size: 48, color: AtlasColors.royalBlue),
                  const SizedBox(height: 12),
                  const Text('Unable to load this PDF',
                    style: TextStyle(fontWeight: FontWeight.w900,
                      color: AtlasColors.navy, fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(_remoteLoadError ?? 'The document could not be downloaded.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AtlasColors.secondaryText)),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _loadRemotePdf,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ]),
              )),
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
