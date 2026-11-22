import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_feedback.dart';
import '../models/subscription_plan_model.dart';
import '../services/payment_settings_service.dart';
import '../services/subscription_request_service.dart';

class SubscriptionRequestScreen extends StatefulWidget {
  final SubscriptionPlanModel plan;
  const SubscriptionRequestScreen({super.key, required this.plan});

  @override
  State<SubscriptionRequestScreen> createState() => _SubscriptionRequestScreenState();
}

class _SubscriptionRequestScreenState extends State<SubscriptionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _service = SubscriptionRequestService();
  final _settingsService = PaymentSettingsService();
  String? _paymentMethod;
  bool _sending = false;
  static const _methods = ['Bank Transfer', 'JazzCash', 'Easypaisa', 'Other'];

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _sendToWhatsApp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentMethod == null) {
      AtlasFeedback.showError(context, 'Please select your payment method.');
      return;
    }
    setState(() => _sending = true);
    try {
      final settings = await _settingsService.getSettings();
      final number = (settings['whatsappNumber'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (number.isEmpty) {
        throw Exception('The academy WhatsApp number has not been configured yet. Please contact the academy.');
      }
      final requestId = await _service.submitRequest(
        plan: widget.plan,
        paymentMethod: _paymentMethod!,
        transactionReference: _referenceController.text.trim().isEmpty
            ? 'To be confirmed on WhatsApp'
            : _referenceController.text.trim(),
      );
      final user = _service.currentUser;
      final message = [
        'THE ATLAS ACADEMY — SUBSCRIPTION PAYMENT',
        'Request ID: $requestId',
        'Student: ${user?.displayName ?? ''}',
        'Email: ${user?.email ?? ''}',
        'Plan: ${widget.plan.name}',
        'Amount: ${widget.plan.currency} ${widget.plan.price.toStringAsFixed(2)}',
        'Duration: ${widget.plan.durationDays} days',
        'Payment method: $_paymentMethod',
        'Transaction reference: ${_referenceController.text.trim().isEmpty ? 'I will provide confirmation with the receipt.' : _referenceController.text.trim()}',
        '',
        'I have made the payment. Please find my payment screenshot attached and verify my subscription request.',
      ].join('\n');
      final uri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (launched) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.mark_chat_read_rounded, color: AtlasColors.success, size: 42),
            title: const Text('Request Created'),
            content: const Text('WhatsApp has opened with your payment details. Please attach your payment screenshot and send the message. Your subscription remains pending until an administrator verifies and approves it.'),
            actions: [FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context, true);
              },
              child: const Text('Done'),
            )],
          ),
        );
      } else {
        AtlasFeedback.showError(context, 'Your request was saved, but WhatsApp could not be opened. Please contact the academy and quote request ID $requestId.');
      }
    } catch (e) {
      if (mounted) AtlasFeedback.showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(title: const Text('Complete Subscription Payment'), backgroundColor: const Color(0xFFF2F7FF), foregroundColor: AtlasColors.navy, elevation: 0),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _settingsService.watchSettings(),
          builder: (context, snapshot) {
            final settings = snapshot.data ?? {};
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(19),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AtlasColors.navy, AtlasColors.royalBlue]),
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.workspace_premium_rounded, color: AtlasColors.royalBlue, size: 30),
                      const SizedBox(height: 12),
                      const Text('YOUR SELECTED PLAN', style: TextStyle(color: AtlasColors.royalBlue, fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 7),
                      Text(plan.name, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('${plan.currency} ${plan.price.toStringAsFixed(2)}', style: const TextStyle(color: AtlasColors.royalBlue, fontSize: 25, fontWeight: FontWeight.w900)),
                      Text('${plan.durationDays} days • ${plan.features.length} listed benefits', style: const TextStyle(color: Colors.white70)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  _section('1. Transfer your subscription fee'),
                  const SizedBox(height: 11),
                  _paymentCard(settings),
                  const SizedBox(height: 22),
                  _section('2. Enter payment confirmation'),
                  const SizedBox(height: 11),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: _decoration('Payment method', Icons.account_balance_wallet_outlined),
                    items: _methods.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setState(() => _paymentMethod = v),
                    validator: (v) => v == null ? 'Select your payment method.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _referenceController,
                    decoration: _decoration('Transaction ID / reference (if available)', Icons.receipt_long_outlined),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: AtlasColors.paleBlue, borderRadius: BorderRadius.circular(15)),
                    child: const Text('Please have your payment screenshot ready. WhatsApp will open with your student and plan details already filled in. Attach the screenshot and send the message to the academy.', style: TextStyle(color: AtlasColors.navy, height: 1.55, fontSize: 12)),
                  ),
                  const SizedBox(height: 23),
                  SizedBox(height: 55, child: FilledButton.icon(
                    onPressed: _sending ? null : _sendToWhatsApp,
                    icon: _sending ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.chat_rounded),
                    label: Text(_sending ? 'Preparing your request…' : 'Send Payment Details on WhatsApp'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF168B58), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  )),
                  const SizedBox(height: 12),
                  const Text('Your subscription will remain pending until the academy verifies your payment and approves your request.', textAlign: TextAlign.center, style: TextStyle(color: AtlasColors.secondaryText, fontSize: 11, height: 1.5)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _section(String title) => Text(title, style: const TextStyle(color: AtlasColors.navy, fontSize: 17, fontWeight: FontWeight.w900));

  Widget _paymentCard(Map<String, dynamic> data) {
    final holder = (data['accountHolder'] ?? '').toString();
    final provider = (data['provider'] ?? '').toString();
    final account = (data['accountNumber'] ?? '').toString();
    final iban = (data['iban'] ?? '').toString();
    final instructions = (data['instructions'] ?? '').toString();
    final configured = holder.isNotEmpty || provider.isNotEmpty || account.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE0EAF5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!configured) const Text('Payment account details have not been configured yet. Please contact the academy.', style: TextStyle(color: AtlasColors.error)),
        if (provider.isNotEmpty) _paymentLine('Bank / Provider', provider),
        if (holder.isNotEmpty) _paymentLine('Account Holder', holder),
        if (account.isNotEmpty) _paymentLine('Account / Wallet', account),
        if (iban.isNotEmpty) _paymentLine('IBAN', iban),
        if (instructions.isNotEmpty) ...[
          const Divider(height: 22),
          const Text('Instructions', style: TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(instructions, style: const TextStyle(color: AtlasColors.secondaryText, height: 1.5)),
        ],
      ]),
    );
  }

  Widget _paymentLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AtlasColors.secondaryText, fontSize: 11)),
      const SizedBox(height: 3),
      SelectableText(value, style: const TextStyle(color: AtlasColors.navy, fontWeight: FontWeight.w800, fontSize: 14)),
    ]),
  );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}
