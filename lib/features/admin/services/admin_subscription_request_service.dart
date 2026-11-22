
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../subscriptions/models/subscription_request_model.dart';

class AdminSubscriptionRequestService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  AdminSubscriptionRequestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('subscription_requests');

  void _requireSignedIn() {
    if (_auth.currentUser == null) {
      throw Exception('Please sign in to continue.');
    }
  }

  Stream<List<SubscriptionRequestModel>> watchAllRequests() {
    _requireSignedIn();

    return _requests
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

  Stream<List<SubscriptionRequestModel>> watchPendingRequests() {
    _requireSignedIn();

    return _requests
        .where('status', isEqualTo: 'pending')
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

  Future<SubscriptionRequestModel?> getRequest(
    String requestId,
  ) async {
    _requireSignedIn();

    final snapshot = await _requests.doc(requestId).get();

    if (!snapshot.exists) return null;

    return SubscriptionRequestModel.fromFirestore(
      snapshot.id,
      snapshot.data()!,
    );
  }

  Future<void> approveRequest({
    required String requestId,
    String adminNote = '',
  }) async {
    _requireSignedIn();

    if (requestId.trim().isEmpty) {
      throw Exception('Invalid subscription request.');
    }

    // Confirm the request is present in the same Firestore project used by
    // the admin app before invoking the trusted approval function.
    final requestSnapshot = await _requests.doc(requestId.trim()).get();
    if (!requestSnapshot.exists) {
      throw Exception(
        'This payment request is no longer present in the app database. '
        'Refresh the request list and try again.',
      );
    }

    try {
      final callable =
          _functions.httpsCallable('approveSubscriptionRequest');

      await callable.call({
        'requestId': requestId,
        'adminNote': adminNote.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
        e.message ?? 'Unable to approve this payment request.',
      );
    }
  }

  Future<void> rejectRequest({
    required String requestId,
    required String adminNote,
  }) async {
    _requireSignedIn();

    if (requestId.trim().isEmpty) {
      throw Exception('Invalid subscription request.');
    }

    if (adminNote.trim().isEmpty) {
      throw Exception(
        'Please provide a reason for rejecting this request.',
      );
    }

    try {
      final callable =
          _functions.httpsCallable('rejectSubscriptionRequest');

      await callable.call({
        'requestId': requestId,
        'adminNote': adminNote.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
        e.message ?? 'Unable to reject this payment request.',
      );
    }
  }
}
