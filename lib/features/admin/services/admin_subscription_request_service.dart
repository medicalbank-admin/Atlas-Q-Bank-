import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../subscriptions/models/subscription_request_model.dart';
import '../../advanced_learning/services/push_notification_service.dart';

class AdminSubscriptionRequestService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminSubscriptionRequestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('subscription_requests');

  void _requireSignedIn() {
    if (_auth.currentUser == null) {
      throw Exception('Please sign in to continue.');
    }
  }

  Future<void> _requireAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to continue.');
    }
    final token = await user.getIdTokenResult(true);
    if (token.claims?['admin'] != true) {
      throw Exception(
        'Administrator permission is required. Please sign in again '
        'with an authorized administrator account.',
      );
    }
  }

  Stream<List<SubscriptionRequestModel>> watchAllRequests() {
    _requireSignedIn();
    return _requests
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscriptionRequestModel.fromFirestore(
                  doc.id,
                  doc.data(),
                ))
            .toList());
  }

  Stream<List<SubscriptionRequestModel>> watchPendingRequests() {
    _requireSignedIn();
    return _requests
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscriptionRequestModel.fromFirestore(
                  doc.id,
                  doc.data(),
                ))
            .toList());
  }

  Future<SubscriptionRequestModel?> getRequest(String requestId) async {
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
    await _requireAdmin();
    final id = requestId.trim();
    if (id.isEmpty) throw Exception('Invalid subscription request.');

    final adminUid = _auth.currentUser!.uid;
    final requestRef = _requests.doc(id);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw Exception(
          'Payment request not found. Refresh the requests list and try again.',
        );
      }

      final request = requestSnapshot.data()!;
      if (request['status'] != 'pending') {
        throw Exception('This request has already been reviewed.');
      }

      final studentUid = request['studentUid'] as String?;
      final planId = request['planId'] as String?;
      if (studentUid == null || studentUid.isEmpty ||
          planId == null || planId.isEmpty) {
        throw Exception('The request is missing student or plan information.');
      }

      final studentRef = _firestore.collection('users').doc(studentUid);
      final planRef = _firestore.collection('subscription_plans').doc(planId);
      final studentSnapshot = await transaction.get(studentRef);
      final planSnapshot = await transaction.get(planRef);

      if (!studentSnapshot.exists) {
        throw Exception('The student account could not be found.');
      }
      if (!planSnapshot.exists) {
        throw Exception('The selected membership plan could not be found.');
      }

      final plan = planSnapshot.data()!;
      final student = studentSnapshot.data()!;
      if (plan['isActive'] != true) {
        throw Exception('This membership plan is no longer active.');
      }

      final durationDays = (plan['durationDays'] as num?)?.toInt() ?? 0;
      final amount = (plan['price'] as num?)?.toDouble();
      final currency = plan['currency'] as String?;
      if (durationDays < 1 || durationDays > 3650 ||
          amount == null || currency == null ||
          request['durationDays'] != durationDays ||
          (request['amount'] as num?)?.toDouble() != amount ||
          request['currency'] != currency) {
        throw Exception(
          'The payment request no longer matches the selected plan. '
          'Please review it before approval.',
        );
      }

      final configured = plan['accessPermissions'];
      if (configured is! Map) {
        throw Exception('The membership plan has invalid access permissions.');
      }
      final permissions = Map<String, dynamic>.from(configured);
      if (permissions['pastPapers'] == true) {
        permissions['examinations'] = true;
      }

      final now = DateTime.now();
      var startDate = now;
      var expiryBase = now;
      final currentExpiry = student['subscriptionExpiryAt'];
      if (student['subscriptionStatus'] == 'active' &&
          currentExpiry is Timestamp &&
          currentExpiry.toDate().isAfter(now)) {
        expiryBase = currentExpiry.toDate();
        final currentStart = student['subscriptionStartedAt'];
        if (currentStart is Timestamp) {
          startDate = currentStart.toDate();
        }
      }
      final expiryDate = expiryBase.add(Duration(days: durationDays));
      final serverNow = FieldValue.serverTimestamp();

      transaction.update(requestRef, {
        'status': 'approved',
        'adminNote': adminNote.trim(),
        'reviewedBy': adminUid,
        'reviewedAt': serverNow,
        'updatedAt': serverNow,
      });
      transaction.update(studentRef, {
        'accountStatus': 'approved',
        'subscriptionStatus': 'active',
        'accessEnabled': true,
        'subscriptionPlanId': planId,
        'subscriptionPlanName': plan['name'] ?? 'Subscription',
        'subscriptionDurationDays': durationDays,
        'subscriptionAccessPermissions': permissions,
        'subscriptionStartedAt': Timestamp.fromDate(startDate),
        'subscriptionExpiryAt': Timestamp.fromDate(expiryDate),
        'updatedAt': serverNow,
      });
    });
    try {
      final approved = await getRequest(id);
      if (approved != null) {
        await PushNotificationService().sendCampaign(notificationId: 'membership_approved_' + id, title: 'Membership approved', body: 'Your ' + approved.planName + ' membership is now active. Enjoy your academy access.', destination: 'membership', audience: 'selected', userIds: [approved.studentUid]);
      }
    } catch (_) {}
  }

  Future<void> rejectRequest({
    required String requestId,
    required String adminNote,
  }) async {
    await _requireAdmin();
    final id = requestId.trim();
    final note = adminNote.trim();
    if (id.isEmpty) throw Exception('Invalid subscription request.');
    if (note.isEmpty) {
      throw Exception('Please provide a reason for rejecting this request.');
    }

    final ref = _requests.doc(id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw Exception('Payment request not found. Refresh and try again.');
      }
      if (snapshot.data()?['status'] != 'pending') {
        throw Exception('This request has already been reviewed.');
      }
      transaction.update(ref, {
        'status': 'rejected',
        'adminNote': note,
        'reviewedBy': _auth.currentUser!.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
