
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/atlas_academy_app.dart';
import '../models/subscription_request_model.dart';
import '../services/subscription_request_service.dart';

class MySubscriptionRequestsScreen extends StatefulWidget {
  const MySubscriptionRequestsScreen({super.key});

  @override
  State<MySubscriptionRequestsScreen> createState() =>
      _MySubscriptionRequestsScreenState();
}

class _MySubscriptionRequestsScreenState
    extends State<MySubscriptionRequestsScreen> {
  final SubscriptionRequestService _service =
      SubscriptionRequestService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: Colors.white,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: StreamBuilder<List<SubscriptionRequestModel>>(
        stream: _service.watchMyRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AtlasColors.royalBlue,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AtlasColors.royalBlue,
            onRefresh: () async {
              await Future<void>.delayed(
                const Duration(milliseconds: 500),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _buildSummary(requests),
                const SizedBox(height: 22),
                const Text(
                  'Request History',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AtlasColors.navy,
                  ),
                ),
                const SizedBox(height: 14),
                ...requests.map(_buildRequestCard),
                const SizedBox(height: 25),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(List<SubscriptionRequestModel> requests) {
    final pending =
        requests.where((request) => request.isPending).length;

    final approved =
        requests.where((request) => request.isApproved).length;

    final rejected =
        requests.where((request) => request.isRejected).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AtlasColors.navy,
            AtlasColors.royalBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Subscription Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _summaryItem('Total', requests.length),
              _summaryItem('Pending', pending),
              _summaryItem('Approved', approved),
              _summaryItem('Rejected', rejected),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, int count) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: AtlasColors.royalBlue,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: const Color(0xFF526B87),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(SubscriptionRequestModel request) {
    final statusColor = _statusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AtlasColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.planName,
                  style: const TextStyle(
                    color: AtlasColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusBadge(request.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${request.currency} ${request.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AtlasColors.royalBlue,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${request.durationDays} days membership',
            style: const TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 12,
            ),
          ),
          const Divider(height: 25),
          _detailRow(
            Icons.payment_outlined,
            'Payment Method',
            request.paymentMethod,
          ),
          const SizedBox(height: 10),
          _detailRow(
            Icons.receipt_long_outlined,
            'Transaction ID',
            request.transactionReference,
          ),
          const SizedBox(height: 10),
          _detailRow(
            Icons.calendar_today_outlined,
            'Submitted',
            _formatDate(request.createdAt),
          ),
          if (request.reviewedAt != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.fact_check_outlined,
              'Reviewed',
              _formatDate(request.reviewedAt),
            ),
          ],
          if (request.adminNote != null &&
              request.adminNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: request.isRejected
                    ? const Color(0xFFFFF0F0)
                    : const Color(0xFFEAF4F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.isRejected
                        ? 'Administrator Feedback'
                        : 'Administrator Note',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    request.adminNote!,
                    style: const TextStyle(
                      color: AtlasColors.charcoal,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (request.isPending) ...[
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  color: AtlasColors.gold,
                  size: 17,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Your payment is awaiting administrator review.',
                    style: TextStyle(
                      color: AtlasColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (request.isApproved) ...[
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AtlasColors.success,
                  size: 17,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Your request has been approved.',
                    style: TextStyle(
                      color: AtlasColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (request.isRejected) ...[
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AtlasColors.error,
                  size: 17,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Your request was rejected. Please review the administrator feedback.',
                    style: TextStyle(
                      color: AtlasColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: AtlasColors.royalBlue,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AtlasColors.charcoal,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AtlasColors.success;
      case 'rejected':
        return AtlasColors.error;
      default:
        return AtlasColors.gold;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Processing';

    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: AtlasColors.softTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AtlasColors.navy,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Requests Yet',
              style: TextStyle(
                color: AtlasColors.navy,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Your subscription and payment requests '
              'will appear here after submission.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AtlasColors.secondaryText,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AtlasColors.error,
              size: 45,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to Load Requests',
              style: TextStyle(
                color: AtlasColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AtlasColors.secondaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
