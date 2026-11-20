
import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_feedback.dart';
import '../models/subscription_plan_model.dart';
import '../services/subscription_request_service.dart';

class SubscriptionRequestScreen extends StatefulWidget {
  final SubscriptionPlanModel plan;

  const SubscriptionRequestScreen({
    super.key,
    required this.plan,
  });

  @override
  State<SubscriptionRequestScreen> createState() =>
      _SubscriptionRequestScreenState();
}

class _SubscriptionRequestScreenState
    extends State<SubscriptionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();

  final _service = SubscriptionRequestService();

  String? _paymentMethod;
  bool _isSubmitting = false;

  final List<String> _paymentMethods = [
    'Bank Transfer',
    'JazzCash',
    'Easypaisa',
    'Debit / Credit Card',
    'International Bank Transfer',
    'Other',
  ];

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentMethod == null) {
      AtlasFeedback.showError(
        context,
        'Please select a payment method.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.submitRequest(
        plan: widget.plan,
        paymentMethod: _paymentMethod!,
        transactionReference: _referenceController.text.trim(),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFE5F1EF),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF28777B),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Request Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your payment details have been submitted. '
                  'Our administration team will review your '
                  'transaction reference and update your request.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      AtlasFeedback.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        title: const Text('Payment Submission'),
        backgroundColor: AtlasColors.ivory,
        foregroundColor: AtlasColors.deepTeal,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              _buildPlanCard(plan),
              const SizedBox(height: 26),
              _buildSectionTitle('Payment Details'),
              const SizedBox(height: 14),
              _buildPaymentMethodField(),
              const SizedBox(height: 18),
              _buildReferenceField(),
              const SizedBox(height: 24),
              _buildPaymentInformationNotice(),
              const SizedBox(height: 18),
              _buildNotice(),
              const SizedBox(height: 26),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtlasColors.deepTeal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Payment for Review',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete Your Enrollment',
          style: TextStyle(
            color: AtlasColors.deepTeal,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Submit your payment information to request access '
          'to The Atlas Academy.',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlanModel plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AtlasColors.deepTeal,
            AtlasColors.oceanTeal,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AtlasColors.deepTeal.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECTED MEMBERSHIP',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            plan.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${plan.currency} ${plan.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AtlasColors.champagne,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${plan.durationDays} days of membership',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AtlasColors.deepTeal,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPaymentMethodField() {
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      decoration: _inputDecoration(
        'Payment Method',
        Icons.account_balance_wallet_outlined,
      ),
      items: _paymentMethods.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Text(method),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _paymentMethod = value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a payment method.';
        }
        return null;
      },
    );
  }

  Widget _buildReferenceField() {
    return TextFormField(
      controller: _referenceController,
      textCapitalization: TextCapitalization.characters,
      decoration: _inputDecoration(
        'Transaction Reference / ID',
        Icons.receipt_long_outlined,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Transaction reference is required.';
        }
        if (value.trim().length < 3) {
          return 'Please enter a valid reference.';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentInformationNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AtlasColors.oceanTeal.withValues(alpha: 0.25),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AtlasColors.oceanTeal,
              ),
              SizedBox(width: 9),
              Text(
                'Payment verification',
                style: TextStyle(
                  color: AtlasColors.deepTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Enter the transaction ID or reference provided '
            'by your bank or payment service. Please ensure '
            'the reference is accurate so our team can verify '
            'your payment.',
            style: TextStyle(
              color: AtlasColors.secondaryText,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AtlasColors.champagne.withValues(alpha: 0.7),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AtlasColors.gold,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Submitting this form does not activate your '
              'membership automatically. Your account will be '
              'activated only after an administrator verifies '
              'your payment and approves your request.',
              style: TextStyle(
                color: AtlasColors.charcoal,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AtlasColors.oceanTeal,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: AtlasColors.oceanTeal,
          width: 1.5,
        ),
      ),
    );
  }
}
