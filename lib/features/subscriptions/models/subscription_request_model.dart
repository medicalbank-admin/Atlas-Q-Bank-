import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionRequestModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String studentEmail;

  final String planId;
  final String planName;
  final int durationDays;

  final double amount;
  final String currency;

  final String paymentMethod;
  final String transactionReference;

  final String? proofImageUrl;
  final String? proofImagePath;

  /// pending, approved, or rejected
  final String status;

  final String? adminNote;
  final String? reviewedBy;

  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const SubscriptionRequestModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    required this.planId,
    required this.planName,
    required this.durationDays,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.transactionReference,
    this.proofImageUrl,
    this.proofImagePath,
    this.status = 'pending',
    this.adminNote,
    this.reviewedBy,
    this.createdAt,
    this.reviewedAt,
  });

  bool get isPending => status == 'pending';

  bool get isApproved => status == 'approved';

  bool get isRejected => status == 'rejected';

  factory SubscriptionRequestModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return SubscriptionRequestModel(
      id: id,
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      studentEmail: data['studentEmail'] as String? ?? '',
      planId: data['planId'] as String? ?? '',
      planName: data['planName'] as String? ?? '',
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'USD',
      paymentMethod: data['paymentMethod'] as String? ?? '',
      transactionReference:
          data['transactionReference'] as String? ?? '',
      proofImageUrl: data['proofImageUrl'] as String?,
      proofImagePath: data['proofImagePath'] as String?,
      status: data['status'] as String? ?? 'pending',
      adminNote: data['adminNote'] as String?,
      reviewedBy: data['reviewedBy'] as String?,
      createdAt: _dateFrom(data['createdAt']),
      reviewedAt: _dateFrom(data['reviewedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'planId': planId,
      'planName': planName,
      'durationDays': durationDays,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'transactionReference': transactionReference,
      'proofImageUrl': proofImageUrl,
      'proofImagePath': proofImagePath,
      'status': status,
      'adminNote': adminNote,
      'reviewedBy': reviewedBy,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'reviewedAt': reviewedAt == null
          ? null
          : Timestamp.fromDate(reviewedAt!),
    };
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  SubscriptionRequestModel copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? studentEmail,
    String? planId,
    String? planName,
    int? durationDays,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? transactionReference,
    String? proofImageUrl,
    String? proofImagePath,
    String? status,
    String? adminNote,
    String? reviewedBy,
    DateTime? createdAt,
    DateTime? reviewedAt,
  }) {
    return SubscriptionRequestModel(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      durationDays: durationDays ?? this.durationDays,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionReference:
          transactionReference ?? this.transactionReference,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
