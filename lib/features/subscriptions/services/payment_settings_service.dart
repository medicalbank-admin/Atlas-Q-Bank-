import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSettingsService {
  PaymentSettingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  DocumentReference<Map<String, dynamic>> get _document =>
      _firestore.collection('academy_settings').doc('payment');

  Stream<Map<String, dynamic>> watchSettings() =>
      _document.snapshots().map((snapshot) => snapshot.data() ?? {});

  Future<Map<String, dynamic>> getSettings() async {
    final snapshot = await _document.get();
    return snapshot.data() ?? {};
  }

  Future<void> saveSettings({
    required String accountHolder,
    required String provider,
    required String accountNumber,
    required String iban,
    required String instructions,
    required String whatsappNumber,
  }) async {
    await _document.set({
      'accountHolder': accountHolder.trim(),
      'provider': provider.trim(),
      'accountNumber': accountNumber.trim(),
      'iban': iban.trim(),
      'instructions': instructions.trim(),
      'whatsappNumber': whatsappNumber.replaceAll(RegExp(r'[^0-9]'), ''),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
