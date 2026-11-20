import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/subscription_plan_model.dart';
import '../models/subscription_request_model.dart';

class SubscriptionRequestService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  SubscriptionRequestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('subscription_requests');

  Future<String> submitRequest({
    required SubscriptionPlanModel plan,
    required String paymentMethod,
    required String transactionReference,
    required XFile paymentProof,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in before submitting a request.');
    }

    await user.reload();

    final currentUser = _auth.currentUser;

    if (currentUser == null || !currentUser.emailVerified) {
      throw Exception('Please verify your email before continuing.');
    }

    if (!plan.isActive) {
      throw Exception('This subscription plan is no longer available.');
    }

    if (paymentMethod.trim().isEmpty) {
      throw Exception('Please select a payment method.');
    }

    if (transactionReference.trim().isEmpty) {
      throw Exception('Please enter your transaction reference.');
    }

    if (plan.durationDays <= 0 || plan.price <= 0) {
      throw Exception('This subscription plan has invalid details.');
    }

    final profileSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    if (!profileSnapshot.exists) {
      throw Exception('Your student profile could not be found.');
    }

    final profile = profileSnapshot.data()!;

    final studentName = (profile['fullName'] as String? ?? '').trim();
    final studentEmail = (profile['email'] as String? ?? '').trim();

    if (studentName.isEmpty || studentEmail.isEmpty) {
      throw Exception('Your student profile is incomplete.');
    }

    final requestId = _requests.doc().id;
    final extension = _fileExtension(paymentProof.name);
    final storagePath =
        'subscription_payment_proofs/${currentUser.uid}/$requestId.$extension';

    final bytes = await paymentProof.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('The selected payment proof is empty.');
    }

    if (bytes.length > 10 * 1024 * 1024) {
      throw Exception('Payment proof must be smaller than 10 MB.');
    }

    final contentType = _contentType(extension);

    final uploadRef = _storage.ref().child(storagePath);

    try {
      final uploadTask = await uploadRef.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final proofUrl = await uploadTask.ref.getDownloadURL();

      final request = SubscriptionRequestModel(
        id: requestId,
        studentUid: currentUser.uid,
        studentName: studentName,
        studentEmail: studentEmail,
        planId: plan.id,
        planName: plan.name,
        durationDays: plan.durationDays,
        amount: plan.price,
        currency: plan.currency,
        paymentMethod: paymentMethod.trim(),
        transactionReference: transactionReference.trim(),
        proofImageUrl: proofUrl,
        proofImagePath: storagePath,
        status: 'pending',
      );

      await _requests.doc(requestId).set(request.toFirestore());

      return requestId;
    } catch (_) {
      try {
        await uploadRef.delete();
      } catch (_) {
        // Ignore cleanup failure.
      }

      rethrow;
    }
  }

  Stream<List<SubscriptionRequestModel>> watchMyRequests() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        Exception('Please sign in to view your requests.'),
      );
    }

    return _requests
        .where('studentUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SubscriptionRequestModel.fromFirestore(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<SubscriptionRequestModel?> getRequest(String requestId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to continue.');
    }

    final snapshot = await _requests.doc(requestId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data()!;

    if (data['studentUid'] != user.uid) {
      throw Exception('You cannot access another student’s request.');
    }

    return SubscriptionRequestModel.fromFirestore(
      snapshot.id,
      data,
    );
  }

  String _fileExtension(String fileName) {
    final parts = fileName.split('.');

    if (parts.length < 2) {
      return 'jpg';
    }

    final extension = parts.last.toLowerCase();

    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw Exception('Please upload a JPG, PNG, or WEBP image.');
    }

    return extension;
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
