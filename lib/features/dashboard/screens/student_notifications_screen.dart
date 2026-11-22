import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/atlas_academy_app.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final globalStream = FirebaseFirestore.instance.collection('notifications')
        .where('audience', isEqualTo: 'all')
        .where('isActive', isEqualTo: true).limit(50).snapshots();
    final personalStream = uid == null
        ? null
        : FirebaseFirestore.instance.collection('notifications')
            .where('userId', isEqualTo: uid).limit(50).snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F7FF),
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: globalStream,
        builder: (context, global) {
          if (global.hasError) return const _NoticeMessage(
              text: 'Notifications could not be loaded. Please try again.');
          if (!global.hasData) return const Center(child: CircularProgressIndicator());
          if (personalStream == null) return _noticeList(context, global.data!.docs);
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: personalStream,
            builder: (context, personal) {
              if (personal.hasError) return const _NoticeMessage(
                  text: 'Notifications could not be loaded. Please try again.');
              if (!personal.hasData) return const Center(child: CircularProgressIndicator());
              final byId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
              for (final doc in global.data!.docs) { byId[doc.id] = doc; }
              for (final doc in personal.data!.docs) { byId[doc.id] = doc; }
              final docs = byId.values.toList()
                ..sort((a, b) => _date(b.data()).compareTo(_date(a.data())));
              return _noticeList(context, docs);
            },
          );
        },
      ),
    );
  }

  static DateTime _date(Map<String, dynamic> data) {
    final value = data['createdAt'];
    return value is Timestamp ? value.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget _noticeList(BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return const _NoticeMessage(text: 'You are all caught up. New academy announcements will appear here.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 11),
      itemBuilder: (context, index) {
        final data = docs[index].data();
        final title = (data['title'] ?? 'Academy announcement').toString();
        final body = (data['body'] ?? '').toString();
        final link = (data['linkUrl'] ?? '').toString().trim();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE0EAF5)),
            boxShadow: [BoxShadow(
              color: AtlasColors.navy.withValues(alpha: .045),
              blurRadius: 13, offset: const Offset(0, 4),
            )],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 43, height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFF1768D1), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: AtlasColors.navy, fontSize: 15, fontWeight: FontWeight.w900,
                )),
                const SizedBox(height: 5),
                Text(body, style: const TextStyle(
                  color: Color(0xFF52647C), fontSize: 13, height: 1.45,
                )),
                if (link.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        final uri = Uri.tryParse(link);
                        if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Text('Open announcement  →'),
                    ),
                  ),
                ],
              ],
            )),
          ]),
        );
      },
    );
  }
}

class _NoticeMessage extends StatelessWidget {
  final String text;
  const _NoticeMessage({required this.text});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Text(text, textAlign: TextAlign.center,
        style: const TextStyle(color: AtlasColors.secondaryText, height: 1.5)),
    ),
  );
}
