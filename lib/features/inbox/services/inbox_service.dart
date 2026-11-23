import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class InboxService {
  InboxService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String get currentUid => _auth.currentUser?.uid ?? '';
  CollectionReference<Map<String, dynamic>> get conversations =>
      _db.collection('inbox_conversations');

  DocumentReference<Map<String, dynamic>> conversationRef(String studentUid) =>
      conversations.doc(studentUid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> studentConversation(
    String studentUid,
  ) => conversationRef(studentUid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> adminConversations() =>
      conversations.orderBy('lastMessageAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String studentUid) =>
      conversationRef(studentUid)
          .collection('messages')
          .orderBy('createdAt')
          .limit(300)
          .snapshots();

  Stream<int> studentUnreadCount(String studentUid) =>
      studentConversation(studentUid).map(
        (snapshot) => (snapshot.data()?['unreadForStudent'] as num?)?.toInt() ?? 0,
      );

  Future<void> ensureStudentConversation({
    required String studentUid,
    required Map<String, dynamic> profile,
  }) async {
    final ref = conversationRef(studentUid);
    final snapshot = await ref.get();
    if (snapshot.exists) return;
    await ref.set({
      'studentUid': studentUid,
      'studentName': (profile['fullName'] ?? 'Student').toString(),
      'studentEmail': (profile['email'] ?? _auth.currentUser?.email ?? '').toString(),
      'studentPhone': (profile['whatsappNumber'] ?? '').toString(),
      'studentUniversity': (profile['university'] ?? '').toString(),
      'studentCountry': (profile['countryOfStudy'] ?? '').toString(),
      'studentProfileImageUrl': (profile['profileImageUrl'] ?? '').toString(),
      'adminUid': null,
      'adminName': 'The Atlas Administrator',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderUid': '',
      'unreadForStudent': 0,
      'unreadForAdmin': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureAdminConversation({
    required String studentUid,
    required Map<String, dynamic> profile,
  }) async {
    final ref = conversationRef(studentUid);
    final snapshot = await ref.get();
    if (snapshot.exists) return;
    await ref.set({
      'studentUid': studentUid,
      'studentName': (profile['fullName'] ?? 'Student').toString(),
      'studentEmail': (profile['email'] ?? '').toString(),
      'studentPhone': (profile['whatsappNumber'] ?? '').toString(),
      'studentUniversity': (profile['university'] ?? '').toString(),
      'studentCountry': (profile['countryOfStudy'] ?? '').toString(),
      'studentProfileImageUrl': (profile['profileImageUrl'] ?? '').toString(),
      'adminUid': currentUid,
      'adminName': 'The Atlas Administrator',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderUid': '',
      'unreadForStudent': 0,
      'unreadForAdmin': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadImage({
    required String studentUid,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
      throw Exception('Images must be smaller than 8 MB.');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = 'inbox_media/$studentUid/$currentUid/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType, customMetadata: {
        'conversationId': studentUid,
        'uploadedBy': currentUid,
      }),
    );
    return ref.getDownloadURL();
  }

  Future<void> sendMessage({
    required String studentUid,
    required String body,
    String? imageUrl,
    String? imagePath,
    required bool fromAdmin,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) throw Exception('Please sign in again.');
    final text = body.trim();
    if (text.isEmpty && (imageUrl == null || imageUrl.isEmpty)) return;

    final conversation = conversationRef(studentUid);
    final message = conversation.collection('messages').doc();
    final preview = text.isNotEmpty ? text : '📷 Photo';
    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((transaction) async {
      final current = await transaction.get(conversation);
      if (!current.exists) {
        throw Exception('This conversation is not ready. Reopen the inbox.');
      }
      transaction.set(message, {
        'senderUid': uid,
        'senderRole': fromAdmin ? 'admin' : 'student',
        'body': text,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'createdAt': now,
        'deliveredAt': null,
        'readAt': null,
      });
      transaction.update(conversation, {
        'lastMessage': preview,
        'lastMessageAt': now,
        'lastSenderUid': uid,
        'unreadForAdmin': fromAdmin ? 0 : FieldValue.increment(1),
        'unreadForStudent': fromAdmin ? FieldValue.increment(1) : 0,
        'adminUid': fromAdmin ? uid : (current.data()?['adminUid']),
        'adminName': 'The Atlas Administrator',
        'updatedAt': now,
      });
    });
  }

  Future<void> markIncomingAsDelivered({
    required String studentUid,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) return;
    try {
      final ref = conversationRef(studentUid);
      final pending = await ref.collection('messages')
          .where('senderUid', isNotEqualTo: uid)
          .limit(300)
          .get();
      final batch = _db.batch();
      var count = 0;
      for (final doc in pending.docs) {
        if (doc.data()['deliveredAt'] == null) {
          batch.update(doc.reference, {'deliveredAt': FieldValue.serverTimestamp()});
          count++;
        }
      }
      if (count > 0) await batch.commit();
    } catch (_) {
      // Delivery receipts retry when the inbox stream reconnects.
    }
  }

  Future<void> markConversationRead({
    required String studentUid,
    required bool forAdmin,
  }) async {
    final uid = currentUid;
    if (uid.isEmpty) return;
    final ref = conversationRef(studentUid);
    final unreadField = forAdmin ? 'unreadForAdmin' : 'unreadForStudent';
    try {
      await ref.update({unreadField: 0, 'updatedAt': FieldValue.serverTimestamp()});
      final pending = await ref.collection('messages')
          .where('senderUid', isNotEqualTo: uid)
          .limit(300)
          .get();
      final batch = _db.batch();
      var count = 0;
      for (final doc in pending.docs) {
        final data = doc.data();
        if (data['readAt'] == null) {
          batch.update(doc.reference, {
            'deliveredAt': data['deliveredAt'] ?? FieldValue.serverTimestamp(),
            'readAt': FieldValue.serverTimestamp(),
          });
          count++;
        }
      }
      if (count > 0) await batch.commit();
    } catch (_) {
      // The message stream remains usable if a status update is temporarily offline.
    }
  }

  Future<Map<String, dynamic>> loadStudentProfile(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();
    return snapshot.data() ?? {};
  }
}
