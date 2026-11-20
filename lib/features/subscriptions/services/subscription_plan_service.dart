import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subscription_plan_model.dart';

class SubscriptionPlanService {
  SubscriptionPlanService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _plans =>
      _firestore.collection('subscription_plans');

  /// Streams active plans for the student app.
  Stream<List<SubscriptionPlanModel>> watchActivePlans() {
    return _plans
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SubscriptionPlanModel.fromFirestore)
              .toList(),
        );
  }

  /// Streams all plans for the admin dashboard.
  Stream<List<SubscriptionPlanModel>> watchAllPlans() {
    return _plans
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SubscriptionPlanModel.fromFirestore)
              .toList(),
        );
  }

  /// Retrieves one plan by its Firestore document ID.
  Future<SubscriptionPlanModel?> getPlan(String planId) async {
    final document = await _plans.doc(planId).get();

    if (!document.exists) return null;

    return SubscriptionPlanModel.fromFirestore(document);
  }

  /// Creates a new subscription plan.
  /// Must only be called by an authenticated administrator.
  Future<String> createPlan(
    SubscriptionPlanModel plan,
  ) async {
    _validatePlan(plan);

    final document = await _plans.add({
      ...plan.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  /// Updates an existing subscription plan.
  /// Must only be called by an authenticated administrator.
  Future<void> updatePlan(
    SubscriptionPlanModel plan,
  ) async {
    if (plan.id.trim().isEmpty) {
      throw ArgumentError('A valid plan ID is required.');
    }

    _validatePlan(plan);

    await _plans.doc(plan.id).update(
      plan.toFirestore(),
    );
  }

  /// Deactivates a plan without deleting its history.
  Future<void> deactivatePlan(String planId) async {
    if (planId.trim().isEmpty) {
      throw ArgumentError('A valid plan ID is required.');
    }

    await _plans.doc(planId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reactivates a previously deactivated plan.
  Future<void> activatePlan(String planId) async {
    if (planId.trim().isEmpty) {
      throw ArgumentError('A valid plan ID is required.');
    }

    await _plans.doc(planId).update({
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _validatePlan(SubscriptionPlanModel plan) {
    if (plan.name.trim().isEmpty) {
      throw ArgumentError('Plan name is required.');
    }

    if (plan.durationDays <= 0) {
      throw ArgumentError('Plan duration must be greater than zero.');
    }

    if (plan.price < 0) {
      throw ArgumentError('Plan price cannot be negative.');
    }

    if (plan.currency.trim().isEmpty) {
      throw ArgumentError('Plan currency is required.');
    }

    if (plan.features.any((feature) => feature.trim().isEmpty)) {
      throw ArgumentError('Plan features cannot contain empty entries.');
    }
  }
}
