
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subscription_plan_model.dart';
import '../models/subscription_request_model.dart';

class SubscriptionRequestService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SubscriptionRequestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('subscription_requests');

  Future<String> submitRequest({
    required SubscriptionPlanModel plan,
    required String paymentMethod,
    required String transactionReference,
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

    if (transactionReference.trim().length < 3) {
      throw Exception('Please enter a valid transaction reference.');
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
      proofImageUrl: null,
      proofImagePath: null,
      status: 'pending',
    );

    await _requests.doc(requestId).set(request.toFirestore());

    return requestId;
  }

  Stream<List<SubscriptionRequestModel>> watchMyRequests() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.error(
        Exception('Please sign in to view your requests.'),
      );
    }

    // A single-field equality query works without a composite index.
    // Sort locally to keep the student's newest request at the top.
    return _requests
        .where('studentUid', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => SubscriptionRequestModel.fromFirestore(
                    doc.id,
                    doc.data(),
                  ))
              .toList();
          requests.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return requests;
        });
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
}
