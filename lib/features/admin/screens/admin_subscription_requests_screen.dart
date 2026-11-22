import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../subscriptions/models/subscription_request_model.dart';
import '../services/admin_subscription_request_service.dart';

class AdminSubscriptionRequestsScreen extends StatefulWidget {
  const AdminSubscriptionRequestsScreen({super.key});

  @override
  State<AdminSubscriptionRequestsScreen> createState() =>
      _AdminSubscriptionRequestsScreenState();
}

class _AdminSubscriptionRequestsScreenState
    extends State<AdminSubscriptionRequestsScreen> {
  final AdminSubscriptionRequestService _service =
      AdminSubscriptionRequestService();

  String _selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        title: const Text('Payment Management'),
        backgroundColor: const Color(0xFFF3F7FF),
        foregroundColor: AtlasColors.navy,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<SubscriptionRequestModel>>(
              stream: _service.watchAllRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AtlasColors.royalBlue,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

                final allRequests = snapshot.data ?? [];

                final requests = allRequests.where((request) {
                  if (_selectedFilter == 'all') return true;
                  return request.status == _selectedFilter;
                }).toList();

                if (requests.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(requests[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AtlasColors.navy,
            AtlasColors.royalBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.admin_panel_settings_rounded,
            color: AtlasColors.royalBlue,
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Subscription Administration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Review payment receipts and manage student '
            'membership applications.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const filters = [
      ('pending', 'Pending'),
      ('approved', 'Approved'),
      ('rejected', 'Rejected'),
      ('all', 'All'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter.$1;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              label: Text(filter.$2),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedFilter = filter.$1);
              },
              selectedColor: AtlasColors.navy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : AtlasColors.navy,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected
                    ? AtlasColors.navy
                    : Colors.grey.shade300,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(
    SubscriptionRequestModel request,
  ) {
    final color = _statusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AtlasColors.softTeal,
                child: Icon(
                  Icons.person_outline,
                  color: AtlasColors.navy,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      style: const TextStyle(
                        color: AtlasColors.navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.studentEmail,
                      style: const TextStyle(
                        color: AtlasColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(request.status, color),
            ],
          ),
          const Divider(height: 25),
          _detail('Membership', request.planName),
          _detail(
            'Amount',
            '${request.currency} ${request.amount.toStringAsFixed(2)}',
          ),
          _detail('Payment method', request.paymentMethod),
          _detail(
            'Transaction ID',
            request.transactionReference,
          ),
          _detail(
            'Duration',
            '${request.durationDays} days',
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRequestDetails(request),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Review'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AtlasColors.navy,
                  ),
                ),
              ),
              if (request.isPending) ...[
                const SizedBox(width: 9),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmApproval(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AtlasColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
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
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
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
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AtlasColors.success;
      case 'rejected':
        return AtlasColors.error;
      default:
        return AtlasColors.gold;
    }
  }

  Future<void> _showRequestDetails(
    SubscriptionRequestModel request,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Payment Receipt'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AtlasColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(request.studentEmail),
                const SizedBox(height: 18),
                const Text(
                  'Transaction Reference',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                SelectableText(request.transactionReference),
                const SizedBox(height: 18),
                if (request.proofImageUrl != null &&
                    request.proofImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      request.proofImageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (
                        context,
                        child,
                        progress,
                      ) {
                        if (progress == null) return child;

                        return const SizedBox(
                          height: 160,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'Unable to display payment receipt.',
                        );
                      },
                    ),
                  )
                else
                  const Text('No receipt image was provided.'),
                const SizedBox(height: 16),
                Text('Status: ${request.status.toUpperCase()}'),
                if (request.adminNote != null &&
                    request.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Admin note: ${request.adminNote}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            if (request.isPending)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _confirmRejection(request);
                },
                child: const Text(
                  'Reject Request',
                  style: TextStyle(color: AtlasColors.error),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmApproval(
    SubscriptionRequestModel request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Payment?'),
        content: Text(
          'Approve the payment submitted by ${request.studentName}? '
          'The secure backend will verify administrator permission '
          'before activating membership.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AtlasColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _performAction(
      () => _service.approveRequest(
        requestId: request.id,
      ),
      'Payment approved successfully.',
    );
  }

  Future<void> _confirmRejection(
    SubscriptionRequestModel request,
  ) async {
    final controller = TextEditingController();

    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter the reason for rejection...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AtlasColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (note == null || !mounted) return;

    await _performAction(
      () => _service.rejectRequest(
        requestId: request.id,
        adminNote: note,
      ),
      'Payment request rejected.',
    );
  }

  Future<void> _performAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AtlasColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AtlasColors.error,
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: AtlasColors.royalBlue,
              size: 55,
            ),
            const SizedBox(height: 15),
            const Text(
              'No Payment Requests',
              style: TextStyle(
                color: AtlasColors.navy,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'There are no ${_selectedFilter == 'all' ? '' : _selectedFilter} '
              'requests to display.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AtlasColors.secondaryText,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AtlasColors.error,
              size: 45,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to Load Payment Requests',
              style: TextStyle(
                color: AtlasColors.navy,
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
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
