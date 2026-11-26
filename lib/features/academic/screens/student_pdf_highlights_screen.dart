import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/atlas_academy_app.dart';
import '../services/pdf_highlight_service.dart';

class StudentPdfHighlightsScreen extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onOpen;

  const StudentPdfHighlightsScreen({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('My PDF Highlights'),
        backgroundColor: Colors.white,
        foregroundColor: AtlasColors.navy,
        bottom: const TabBar(
          labelColor: AtlasColors.royalBlue,
          unselectedLabelColor: AtlasColors.secondaryText,
          tabs: [
            Tab(icon: Icon(Icons.format_list_bulleted_rounded), text: 'All Highlights'),
            Tab(icon: Icon(Icons.bolt_rounded), text: 'Quick Revision'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: PdfHighlightService.watchMine(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(
            child: Text('Unable to load your highlights. Check your connection.'));
          if (!snapshot.hasData) return const Center(
            child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final av = a.data()['createdAt'];
              final bv = b.data()['createdAt'];
              final ad = av is Timestamp ? av.toDate() : DateTime(2000);
              final bd = bv is Timestamp ? bv.toDate() : DateTime(2000);
              return bd.compareTo(ad);
            });
          if (docs.isEmpty) return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.highlight_alt_rounded, size: 52, color: AtlasColors.royalBlue),
                SizedBox(height: 12),
                Text('Your important passages will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AtlasColors.secondaryText, height: 1.5)),
                SizedBox(height: 5),
                Text('Open a PDF, select a passage and tap Highlight.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AtlasColors.secondaryText, fontSize: 12)),
              ]),
            ),
          );
          return TabBarView(children: [
            _HighlightsList(docs: docs, onOpen: onOpen, quick: false),
            _HighlightsList(docs: docs, onOpen: onOpen, quick: true),
          ]);
        },
      ),
    ),
  );
}

class _HighlightsList extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final bool quick;

  const _HighlightsList({
    required this.docs, required this.onOpen, required this.quick,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in docs) {
      final title = (doc.data()['resourceTitle'] ?? 'PDF document').toString();
      groups.putIfAbsent(title, () => []).add(doc);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 28),
      children: [
        if (quick)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AtlasColors.navy, AtlasColors.royalBlue]),
              borderRadius: BorderRadius.circular(18)),
            child: const Row(children: [
              Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QUICK REVISION', style: TextStyle(
                    color: Color(0xFFB9DDF7), fontSize: 10,
                    letterSpacing: 1.2, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Revise only what you marked important.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              )),
            ]),
          ),
        ...groups.entries.map((entry) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
              child: Row(children: [
                const Icon(Icons.picture_as_pdf_rounded,
                  color: AtlasColors.royalBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.key, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AtlasColors.navy,
                    fontWeight: FontWeight.w900, fontSize: 15))),
                Text('${entry.value.length} saved',
                  style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 11)),
              ]),
            ),
            ...entry.value.map((doc) {
              final data = doc.data();
              final color = Color((data['colorValue'] as num?)?.toInt() ?? 0xFFFFE082);
              final page = (data['pageNumber'] as num?)?.toInt() ?? 1;
              final passage = (data['selectedText'] ?? '').toString();
              final subject = (data['subjectName'] ?? data['subjectId'] ?? '').toString();
              final topic = (data['topicName'] ?? data['topicId'] ?? '').toString();
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: color.withValues(alpha: .8), width: 1.5)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => onOpen({'id': doc.id, ...data}),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(height: 5, width: 48,
                        decoration: BoxDecoration(color: color,
                          borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 10),
                      Text(passage, style: const TextStyle(
                        color: AtlasColors.navy, fontSize: 14,
                        height: 1.55, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 5, children: [
                        if (subject.isNotEmpty) _Tag(subject),
                        if (topic.isNotEmpty) _Tag(topic),
                        _Tag('Page $page'),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.open_in_new_rounded,
                          size: 15, color: AtlasColors.royalBlue),
                        const SizedBox(width: 5),
                        const Text('Open original PDF',
                          style: TextStyle(color: AtlasColors.royalBlue,
                            fontSize: 12, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Delete highlight',
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            try {
                              await PdfHighlightService.delete(doc.id);
                            } catch (error) {
                              if (context.mounted) ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Could not delete: $error')));
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                            color: AtlasColors.secondaryText, size: 19),
                        ),
                      ]),
                    ]),
                  ),
                ),
              );
            }),
          ],
        )),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFEAF2FA),
      borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(
      color: AtlasColors.navy, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}
