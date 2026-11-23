import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class InboxService {
  InboxService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? client,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final http.Client _client;
  static const String _workerBaseUrl = String.fromEnvironment('MCQ_API_URL');

  Future<Map<String, dynamic>> _workerRequest(
    String path, Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please sign in again.');
    final baseUrl = _workerBaseUrl.trim().replaceAll(RegExp(r'/+

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
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) return;
      transaction.set(ref, {
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
        'lastMessageId': '',
        'unreadForStudent': 0,
        'unreadForAdmin': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> ensureAdminConversation({
    required String studentUid,
    required Map<String, dynamic> profile,
  }) async {
    final ref = conversationRef(studentUid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) return;
      transaction.set(ref, {
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
        'lastMessageId': '',
        'unreadForStudent': 0,
        'unreadForAdmin': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
    final signature = await _workerRequest('/inbox/upload-signature', {
      'studentUid': studentUid,
    });
    final cloudName = signature['cloudName']?.toString() ?? '';
    final apiKey = signature['apiKey']?.toString() ?? '';
    final timestamp = signature['timestamp']?.toString() ?? '';
    final publicId = signature['publicId']?.toString() ?? '';
    final uploadSignature = signature['signature']?.toString() ?? '';
    if (cloudName.isEmpty || apiKey.isEmpty || timestamp.isEmpty ||
        publicId.isEmpty || uploadSignature.isEmpty) {
      throw Exception('The image service returned incomplete upload credentials.');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/authenticated/upload'),
    );
    request.fields.addAll({
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': uploadSignature,
      'folder': signature['folder'].toString(),
      'public_id': publicId,
      'overwrite': 'false',
      'type': 'authenticated',
    });
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_'),
      contentType: _mediaType(contentType),
    ));
    final streamed = await _client.send(request).timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    Map<String, dynamic> result;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      result = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw Exception('Cloudinary returned an invalid upload response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(result['error'] is Map
          ? (result['error']['message']?.toString() ?? 'Image upload failed.')
          : 'Image upload failed.');
    }
    final uploadedId = result['public_id']?.toString() ?? '';
    final format = result['format']?.toString() ?? '';
    final version = result['version']?.toString() ?? '';
    if (uploadedId != publicId || format.isEmpty || version.isEmpty) {
      throw Exception('Cloudinary did not confirm the uploaded image.');
    }
    return '$uploadedId|$format|$version';
  }

  http.MediaType _mediaType(String value) {
    final parts = value.split('/');
    if (parts.length != 2) return http.MediaType('image', 'jpeg');
    return http.MediaType(parts[0], parts[1]);
  }

  Future<String> loadImageUrl({
    required String studentUid,
    required String messageId,
    required String imagePath,
  }) async {
    final result = await _workerRequest('/inbox/image-url', {
      'studentUid': studentUid,
      'messageId': messageId,
      'imagePath': imagePath,
    });
    final url = result['url']?.toString() ?? '';
    if (!url.startsWith('https://res.cloudinary.com/')) {
      throw Exception('The image service returned an invalid viewing link.');
    }
    return url;
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
    if (text.isEmpty && (imagePath == null || imagePath.isEmpty) && (imageUrl == null || imageUrl.isEmpty)) return;

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
        'lastMessageId': message.id,
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
), '');
    if (baseUrl.isEmpty) throw Exception('The secure image service is not configured in this app build.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Your sign-in could not be verified. Please sign in again.');
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 45));
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      data = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw Exception('The secure image service returned an invalid response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'The image request could not be completed.');
    }
    return data;
  }

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
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) return;
      transaction.set(ref, {
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
        'lastMessageId': '',
        'unreadForStudent': 0,
        'unreadForAdmin': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> ensureAdminConversation({
    required String studentUid,
    required Map<String, dynamic> profile,
  }) async {
    final ref = conversationRef(studentUid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) return;
      transaction.set(ref, {
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
        'lastMessageId': '',
        'unreadForStudent': 0,
        'unreadForAdmin': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
    final normalizedName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final safeName = normalizedName.length > 120 ? normalizedName.substring(0, 120) : normalizedName;
    final path = 'inbox_media/$studentUid/$currentUid/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType, customMetadata: {
        'conversationId': studentUid,
        'uploadedBy': currentUid,
      }),
    );
    return path;
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
    if (text.isEmpty && (imagePath == null || imagePath.isEmpty) && (imageUrl == null || imageUrl.isEmpty)) return;

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
        'lastMessageId': message.id,
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
