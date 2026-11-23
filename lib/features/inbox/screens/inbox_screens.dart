import 'dart:typed_data';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/atlas_academy_app.dart';
import '../services/inbox_service.dart';

const _inboxBlue = Color(0xFF1768C8);
const _inboxNavy = Color(0xFF102B4E);
const _inboxCanvas = Color(0xFFF1F6FC);

class AtlasVerifiedBadge extends StatelessWidget {
  const AtlasVerifiedBadge({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: compact ? 3 : 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F1FF),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFFB9D5F6)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.verified_rounded, color: _inboxBlue, size: compact ? 13 : 15),
      if (!compact) ...[
        const SizedBox(width: 4),
        const Text('VERIFIED', style: TextStyle(color: _inboxBlue, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .55)),
      ],
    ]),
  );
}

class StudentInboxScreen extends StatefulWidget {
  const StudentInboxScreen({super.key});
  @override
  State<StudentInboxScreen> createState() => _StudentInboxScreenState();
}

class _StudentInboxScreenState extends State<StudentInboxScreen> {
  final _service = InboxService();
  bool _loading = true;
  String? _error;
  StreamSubscription? _conversationSubscription;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please sign in again.');
      final profile = await _service.loadStudentProfile(user.uid);
      await _service.ensureStudentConversation(studentUid: user.uid, profile: profile);
      _conversationSubscription = _service.studentConversation(user.uid).listen((snapshot) {
        final unread = (snapshot.data()?['unreadForStudent'] as num?)?.toInt() ?? 0;
        if (unread > 0) _service.markIncomingAsDelivered(studentUid: user.uid);
      });
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() { _conversationSubscription?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: _inboxCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _inboxNavy,
        elevation: 0,
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _InboxError(message: _error!, onRetry: () { setState(() { _loading = true; _error = null; }); _prepare(); })
              : user == null
                  ? const _InboxError(message: 'Please sign in to open your inbox.')
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _service.studentConversation(user.uid),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data() ?? {};
                        final unread = (data['unreadForStudent'] as num?)?.toInt() ?? 0;
                        return ListView(padding: const EdgeInsets.all(18), children: [
                          const Text('YOUR ACADEMY SUPPORT', style: TextStyle(color: AtlasColors.secondaryText, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(23),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(23),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => InboxChatScreen(studentUid: user.uid, isAdmin: false),
                              )),
                              child: Container(
                                padding: const EdgeInsets.all(17),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(23),
                                  border: Border.all(color: const Color(0xFFDCE8F4)),
                                  boxShadow: const [BoxShadow(color: Color(0x0A102B4E), blurRadius: 18, offset: Offset(0, 7))],
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 58, height: 58,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [_inboxNavy, _inboxBlue]),
                                      borderRadius: BorderRadius.circular(19),
                                    ),
                                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 29),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      const Flexible(child: Text('The Atlas Administrator', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _inboxNavy, fontSize: 14, fontWeight: FontWeight.w900))),
                                      const SizedBox(width: 5),
                                      const AtlasVerifiedBadge(compact: true),
                                    ]),
                                    const SizedBox(height: 6),
                                    Text((data['lastMessage'] ?? 'Message the academy administration').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF73869A), fontSize: 11)),
                                    const SizedBox(height: 5),
                                    const Text('Private conversation • Text and photos', style: TextStyle(color: _inboxBlue, fontSize: 10, fontWeight: FontWeight.w700)),
                                  ])),
                                  if (unread > 0) ...[
                                    const SizedBox(width: 8),
                                    _UnreadPill(count: unread),
                                  ] else
                                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF91A4B8), size: 25),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: const Color(0xFFE6F0FC), borderRadius: BorderRadius.circular(17)),
                            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Icon(Icons.lock_rounded, color: _inboxBlue, size: 18),
                              SizedBox(width: 10),
                              Expanded(child: Text('Your conversation is private. Only you and authorized Atlas administrators can access these messages.', style: TextStyle(color: _inboxNavy, fontSize: 11, height: 1.5))),
                            ]),
                          ),
                        ]);
                      },
                    ),
    );
  }
}

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});
  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  final _service = InboxService();
  final _search = TextEditingController();
  String _query = '';
  bool _authorized = false;
  bool _checking = true;
  StreamSubscription? _conversationSubscription;

  @override
  void initState() {
    super.initState();
    _authorize();
  }

  Future<void> _authorize() async {
    final user = FirebaseAuth.instance.currentUser;
    var allowed = false;
    if (user != null) {
      try { allowed = (await user.getIdTokenResult(true)).claims?['admin'] == true; } catch (_) {}
    }
    if (mounted) setState(() { _authorized = allowed; _checking = false; });
    if (allowed) {
      _conversationSubscription = _service.adminConversations().listen((snapshot) {
        for (final doc in snapshot.docs) {
          final unread = (doc.data()['unreadForAdmin'] as num?)?.toInt() ?? 0;
          if (unread > 0) _service.markIncomingAsDelivered(studentUid: doc.id);
        }
      });
    }
  }

  @override
  void dispose() { _conversationSubscription?.cancel(); _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(backgroundColor: _inboxCanvas, body: Center(child: CircularProgressIndicator()));
    if (!_authorized) return const Scaffold(backgroundColor: _inboxCanvas, body: _InboxError(message: 'Administrator access is required.'));
    return Scaffold(
      backgroundColor: _inboxCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _inboxNavy,
        elevation: 0,
        title: Row(children: [
          const Text('Inbox', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 9),
          const AtlasVerifiedBadge(),
        ]),
        actions: [
          IconButton(tooltip: 'Start a conversation', onPressed: _chooseStudent, icon: const Icon(Icons.edit_rounded, color: _inboxBlue)),
          const SizedBox(width: 5),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
          child: TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search students or conversations',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded)),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFFDCE8F4))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFFDCE8F4))),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.adminConversations(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const _InboxError(message: 'Unable to load conversations. Check the deployed Firestore inbox rules.');
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs.where((doc) {
                final d = doc.data();
                final haystack = '${d['studentName'] ?? ''} ${d['studentEmail'] ?? ''} ${d['studentPhone'] ?? ''}'.toLowerCase();
                return haystack.contains(_query);
              }).toList();
              if (docs.isEmpty) return _EmptyInbox(onStart: _chooseStudent);
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(15, 2, 15, 25),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final d = doc.data();
                  final name = (d['studentName'] ?? 'Student').toString();
                  final unread = (d['unreadForAdmin'] as num?)?.toInt() ?? 0;
                  final photo = (d['studentProfileImageUrl'] ?? '').toString();
                  final last = (d['lastMessage'] ?? 'Start a conversation').toString();
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => InboxChatScreen(studentUid: doc.id, isAdmin: true, studentName: name, studentProfileUrl: photo),
                      )),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Row(children: [
                          _StudentAvatar(name: name, photoUrl: photo, radius: 25),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _inboxNavy, fontSize: 13, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(last, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: unread > 0 ? _inboxNavy : const Color(0xFF8091A4), fontSize: 11, fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text((d['studentEmail'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF9AA9B8), fontSize: 10)),
                          ])),
                          const SizedBox(width: 8),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(_shortTime(d['lastMessageAt']), style: const TextStyle(color: Color(0xFF9AA9B8), fontSize: 9)),
                            const SizedBox(height: 8),
                            if (unread > 0) _UnreadPill(count: unread) else const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA9B8)),
                          ]),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _chooseStudent() async {
    final selected = await showModalBottomSheet<QueryDocumentSnapshot<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _StudentPickerSheet(),
    );
    if (selected == null || !mounted) return;
    final profile = selected.data();
    try {
      await _service.ensureAdminConversation(studentUid: selected.id, profile: profile);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => InboxChatScreen(
          studentUid: selected.id,
          isAdmin: true,
          studentName: (profile['fullName'] ?? 'Student').toString(),
          studentProfileUrl: (profile['profileImageUrl'] ?? '').toString(),
        ),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start conversation: $e')));
    }
  }
}

class _StudentPickerSheet extends StatefulWidget {
  const _StudentPickerSheet();
  @override
  State<_StudentPickerSheet> createState() => _StudentPickerSheetState();
}
class _StudentPickerSheetState extends State<_StudentPickerSheet> {
  String query = '';
  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.sizeOf(context).height * .78,
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(27))),
    child: SafeArea(child: Column(children: [
      const SizedBox(height: 12),
      Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD7E1EA), borderRadius: BorderRadius.circular(5))),
      const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 8), child: Align(alignment: Alignment.centerLeft, child: Text('New message', style: TextStyle(color: _inboxNavy, fontSize: 21, fontWeight: FontWeight.w900)))),
      Padding(padding: const EdgeInsets.fromLTRB(18, 6, 18, 12), child: TextField(onChanged: (v) => setState(() => query = v.trim().toLowerCase()), decoration: InputDecoration(hintText: 'Find a student', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: _inboxCanvas, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)))),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Unable to load students.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((doc) {
            final d = doc.data();
            return '${d['fullName'] ?? ''} ${d['email'] ?? ''} ${d['whatsappNumber'] ?? ''}'.toLowerCase().contains(query);
          }).toList();
          if (docs.isEmpty) return const Center(child: Text('No students found.'));
          docs.sort((a,b) => (a.data()['fullName'] ?? '').toString().compareTo((b.data()['fullName'] ?? '').toString()));
          return ListView.builder(itemCount: docs.length, itemBuilder: (context, i) {
            final doc = docs[i]; final d = doc.data(); final name = (d['fullName'] ?? 'Student').toString();
            return ListTile(
              leading: _StudentAvatar(name: name, photoUrl: (d['profileImageUrl'] ?? '').toString(), radius: 22),
              title: Text(name, style: const TextStyle(color: _inboxNavy, fontWeight: FontWeight.w800)),
              subtitle: Text((d['email'] ?? '').toString(), style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chat_bubble_outline_rounded, color: _inboxBlue),
              onTap: () => Navigator.pop(context, doc),
            );
          });
        },
      )),
    ])),
  );
}

class InboxChatScreen extends StatefulWidget {
  const InboxChatScreen({
    super.key,
    required this.studentUid,
    required this.isAdmin,
    this.studentName,
    this.studentProfileUrl = '',
  });
  final String studentUid;
  final bool isAdmin;
  final String? studentName;
  final String studentProfileUrl;
  @override
  State<InboxChatScreen> createState() => _InboxChatScreenState();
}

class _InboxChatScreenState extends State<InboxChatScreen> {
  final _service = InboxService();
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  bool _sending = false;
  Uint8List? _pendingImage;
  String? _pendingName;
  String? _pendingType;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _markRead();
    _messageSubscription = _service.messages(widget.studentUid).listen((_) => _markRead());
  }

  Future<void> _markRead() => _service.markConversationRead(studentUid: widget.studentUid, forAdmin: widget.isAdmin);

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAdmin ? (widget.studentName ?? 'Student') : 'The Atlas Administrator';
    return Scaffold(
      backgroundColor: _inboxCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _inboxNavy,
        elevation: 0,
        titleSpacing: 0,
        title: Row(children: [
          if (widget.isAdmin)
            _StudentAvatar(name: title, photoUrl: widget.studentProfileUrl, radius: 20)
          else
            Container(width: 40, height: 40, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_inboxNavy, _inboxBlue]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.school_rounded, color: Colors.white, size: 21)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: _inboxNavy, fontWeight: FontWeight.w900)),
            if (widget.isAdmin)
              const Text('Student conversation', style: TextStyle(color: Color(0xFF8293A5), fontSize: 10))
            else
              const Row(children: [Text('Official academy account', style: TextStyle(color: _inboxBlue, fontSize: 10, fontWeight: FontWeight.w700)), SizedBox(width: 4), AtlasVerifiedBadge(compact: true)]),
          ])),
        ]),
        actions: [
          if (widget.isAdmin) IconButton(tooltip: 'Student profile', onPressed: _showStudentDetails, icon: const Icon(Icons.info_outline_rounded, color: _inboxBlue)),
        ],
      ),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.messages(widget.studentUid),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const _InboxError(message: 'Unable to load messages. Check the deployed Firestore inbox rules.');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return _ChatWelcome(isAdmin: widget.isAdmin, studentName: title);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
            });
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final mine = data['senderUid'] == FirebaseAuth.instance.currentUser?.uid;
                return _MessageBubble(data: data, mine: mine);
              },
            );
          },
        )),
        _Composer(
          controller: _composer,
          sending: _sending,
          pendingImage: _pendingImage,
          onPick: _pickImage,
          onRemoveImage: () => setState(() { _pendingImage = null; _pendingName = null; _pendingType = null; }),
          onSend: _send,
        ),
      ]),
    );
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose an image smaller than 8 MB.')));
        return;
      }
      final ext = file.name.toLowerCase().split('.').last;
      final type = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';
      if (mounted) setState(() { _pendingImage = bytes; _pendingName = file.name; _pendingType = type; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to select image: $e')));
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _composer.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    setState(() => _sending = true);
    try {
      String? imageUrl;
      String? imagePath;
      if (_pendingImage != null) {
        final bytes = _pendingImage!;
        final name = _pendingName ?? 'attachment.jpg';
        final type = _pendingType ?? 'image/jpeg';
        imagePath = await _service.uploadImage(studentUid: widget.studentUid, bytes: bytes, fileName: name, contentType: type);
      }
      await _service.sendMessage(
        studentUid: widget.studentUid,
        body: text,
        imageUrl: imageUrl,
        imagePath: imagePath,
        fromAdmin: widget.isAdmin,
      );
      _composer.clear();
      if (mounted) setState(() { _pendingImage = null; _pendingName = null; _pendingType = null; });
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 160, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message not sent: ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showStudentDetails() async {
    final profile = await _service.loadStudentProfile(widget.studentUid);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(27))),
        child: SafeArea(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD8E2EC), borderRadius: BorderRadius.circular(8)))),
          const SizedBox(height: 20),
          Row(children: [
            _StudentAvatar(name: (profile['fullName'] ?? widget.studentName ?? 'Student').toString(), photoUrl: (profile['profileImageUrl'] ?? widget.studentProfileUrl).toString(), radius: 29),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((profile['fullName'] ?? widget.studentName ?? 'Student').toString(), style: const TextStyle(color: _inboxNavy, fontSize: 18, fontWeight: FontWeight.w900)),
              const Text('Student profile', style: TextStyle(color: Color(0xFF7B8FA3), fontSize: 11)),
            ])),
          ]),
          const SizedBox(height: 22),
          _ProfileDetail(label: 'Email', value: profile['email']),
          _ProfileDetail(label: 'Father name', value: profile['fatherName']),
          _ProfileDetail(label: 'WhatsApp number', value: profile['whatsappNumber']),
          _ProfileDetail(label: 'National ID / Passport', value: profile['nationalId']),
          _ProfileDetail(label: 'Country of study', value: profile['countryOfStudy']),
          _ProfileDetail(label: 'University', value: profile['university']),
          _ProfileDetail(label: 'Account status', value: profile['accountStatus']),
          _ProfileDetail(label: 'Subscription status', value: profile['subscriptionStatus']),
          _ProfileDetail(label: 'Subscription plan', value: profile['subscriptionPlanName']),
          _ProfileDetail(label: 'Student UID', value: widget.studentUid),
        ]))),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.data, required this.mine});
  final Map<String, dynamic> data;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final body = (data['body'] ?? '').toString();
    final imagePath = (data['imagePath'] ?? '').toString();
    final time = _shortTime(data['createdAt']);
    final read = data['readAt'] != null;
    final delivered = data['deliveredAt'] != null;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.fromLTRB(13, 10, 11, 8),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFDCEBFC) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 5), bottomRight: Radius.circular(mine ? 5 : 18),
          ),
          border: Border.all(color: mine ? const Color(0xFFC8DDF4) : const Color(0xFFE5ECF3)),
          boxShadow: const [BoxShadow(color: Color(0x080E315A), blurRadius: 9, offset: Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (imagePath.isNotEmpty) ...[
            ClipRRect(borderRadius: BorderRadius.circular(12), child: _SecureInboxImage(path: imagePath)),
            if (body.isNotEmpty) const SizedBox(height: 8),
          ],
          if (body.isNotEmpty) Text(body, style: const TextStyle(color: _inboxNavy, fontSize: 13, height: 1.45)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(time, style: const TextStyle(color: Color(0xFF7C8FA3), fontSize: 9)),
            if (mine) ...[
              const SizedBox(width: 5),
              Icon((read || delivered) ? Icons.done_all_rounded : Icons.done_rounded, size: 15, color: read ? _inboxBlue : (delivered ? const Color(0xFF6387AC) : const Color(0xFF9AAABC))),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _SecureInboxImage extends StatefulWidget {
  const _SecureInboxImage({required this.path});
  final String path;
  @override
  State<_SecureInboxImage> createState() => _SecureInboxImageState();
}
class _SecureInboxImageState extends State<_SecureInboxImage> {
  late Future<Uint8List?> _imageFuture;
  @override
  void initState() {
    super.initState();
    _imageFuture = FirebaseStorage.instance.ref(widget.path).getData(8 * 1024 * 1024);
  }
  @override
  void didUpdateWidget(covariant _SecureInboxImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _imageFuture = FirebaseStorage.instance.ref(widget.path).getData(8 * 1024 * 1024);
    }
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _imageFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Container(width: 230, height: 100, color: const Color(0xFFE8EFF6), child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF8195AA))));
      if (!snapshot.hasData) return Container(width: 230, height: 150, color: const Color(0xFFE8EFF6), child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
      return Image.memory(snapshot.data!, width: 230, fit: BoxFit.cover);
    },
  );
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.sending, required this.pendingImage, required this.onPick, required this.onRemoveImage, required this.onSend});
  final TextEditingController controller;
  final bool sending;
  final Uint8List? pendingImage;
  final VoidCallback onPick, onRemoveImage, onSend;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.viewInsetsOf(context).bottom * 0),
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE0E9F2))), boxShadow: [BoxShadow(color: Color(0x080E315A), blurRadius: 12, offset: Offset(0, -3))]),
    child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (pendingImage != null) Align(alignment: Alignment.centerLeft, child: Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(pendingImage!, width: 76, height: 76, fit: BoxFit.cover)),
          Positioned(right: 2, top: 2, child: InkWell(onTap: onRemoveImage, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 14)))),
        ]),
      )),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        IconButton(tooltip: 'Attach image', onPressed: sending ? null : onPick, icon: const Icon(Icons.add_photo_alternate_rounded, color: _inboxBlue, size: 25)),
        Expanded(child: Container(
          decoration: BoxDecoration(color: const Color(0xFFF1F5FA), borderRadius: BorderRadius.circular(23), border: Border.all(color: const Color(0xFFE0E8F1))),
          child: TextField(
            controller: controller,
            minLines: 1, maxLines: 5, textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Write a message...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
        )),
        const SizedBox(width: 8),
        Material(
          color: _inboxBlue, shape: const CircleBorder(),
          child: InkWell(onTap: sending ? null : onSend, customBorder: const CircleBorder(), child: SizedBox(width: 46, height: 46, child: Center(child: sending ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white, size: 21)))),
        ),
      ]),
    ])),
  );
}

class _ChatWelcome extends StatelessWidget {
  const _ChatWelcome({required this.isAdmin, required this.studentName});
  final bool isAdmin;
  final String studentName;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 82, height: 82, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_inboxNavy, _inboxBlue]), borderRadius: BorderRadius.circular(28)), child: Icon(isAdmin ? Icons.waving_hand_rounded : Icons.forum_rounded, color: Colors.white, size: 36)),
      const SizedBox(height: 18),
      Text(isAdmin ? 'Start the conversation' : 'Welcome to your academy inbox', textAlign: TextAlign.center, style: const TextStyle(color: _inboxNavy, fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(isAdmin ? 'Send a private message to $studentName.' : 'Send a message to The Atlas Administrator. Our team will respond here.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7B8FA3), fontSize: 12, height: 1.6)),
      const SizedBox(height: 15),
      const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_outline_rounded, size: 13, color: _inboxBlue), SizedBox(width: 5), Text('Private conversation', style: TextStyle(color: _inboxBlue, fontSize: 10, fontWeight: FontWeight.w800))]),
    ]),
  ));
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.onStart});
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 74, height: 74, decoration: BoxDecoration(color: const Color(0xFFE2EEFB), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.mark_chat_unread_outlined, color: _inboxBlue, size: 34)),
      const SizedBox(height: 15),
      const Text('No conversations yet', style: TextStyle(color: _inboxNavy, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 7),
      const Text('Choose a student to start a private conversation.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7B8FA3), fontSize: 12)),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.edit_rounded), label: const Text('New message')),
    ]),
  ));
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.name, required this.photoUrl, required this.radius});
  final String name, photoUrl;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFDCEBFC),
    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
    child: photoUrl.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(color: _inboxNavy, fontWeight: FontWeight.w900)) : null,
  );
}

class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: Color(0xFF1768C8), shape: BoxShape.circle),
    child: Text(count > 99 ? '99+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
  );
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.label, required this.value});
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF8092A5), fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      SelectableText(value?.toString().isNotEmpty == true ? value.toString() : 'Not provided', style: const TextStyle(color: _inboxNavy, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _InboxError extends StatelessWidget {
  const _InboxError({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, color: Color(0xFF8EA2B8), size: 42),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF61788F), height: 1.5, fontSize: 12)),
      if (onRetry != null) ...[const SizedBox(height: 15), OutlinedButton(onPressed: onRetry, child: const Text('Try again'))],
    ]),
  ));
}

String _shortTime(dynamic value) {
  if (value is! Timestamp) return '';
  final date = value.toDate();
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
