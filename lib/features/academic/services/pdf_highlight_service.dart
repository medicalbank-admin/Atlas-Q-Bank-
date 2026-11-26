import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfHighlightService {
  PdfHighlightService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('student_pdf_highlights');

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMine() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _items.where('userId', isEqualTo: uid).snapshots();
  }

  static Future<List<Map<String, dynamic>>> loadForResource(
    String resourceId,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final snapshot = await _items.where('userId', isEqualTo: uid).get();
    return snapshot.docs
        .where((doc) => doc.data()['resourceId'] == resourceId)
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  static Future<String> save({
    required String resourceId,
    required String resourceTitle,
    required String resourceUrl,
    required String subjectId,
    required String subjectName,
    required String topicId,
    required String topicName,
    required String systemName,
    required int resourceVersion,
    required int pageNumber,
    required String selectedText,
    required List<Map<String, dynamic>> lines,
    required int colorValue,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Please sign in to save highlights.');
    if (selectedText.trim().isEmpty || lines.isEmpty) {
      throw ArgumentError('Select text in the PDF before highlighting.');
    }
    final ref = await _items.add({
      'userId': uid,
      'resourceId': resourceId,
      'resourceTitle': resourceTitle,
      'resourceUrl': resourceUrl,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'topicId': topicId,
      'topicName': topicName,
      'systemName': systemName,
      'resourceVersion': resourceVersion,
      'pageNumber': pageNumber,
      'selectedText': selectedText.trim(),
      'lines': lines,
      'colorValue': colorValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> delete(String highlightId) async {
    if (highlightId.trim().isEmpty) return;
    await _items.doc(highlightId).delete();
  }

  static Future<void> updateColor(String highlightId, int colorValue) async {
    await _items.doc(highlightId).update({
      'colorValue': colorValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
