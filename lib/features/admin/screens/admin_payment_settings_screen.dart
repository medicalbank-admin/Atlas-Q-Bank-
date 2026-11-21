import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../subscriptions/services/payment_settings_service.dart';

class AdminPaymentSettingsScreen extends StatefulWidget {
  const AdminPaymentSettingsScreen({super.key});

  @override
  State<AdminPaymentSettingsScreen> createState() =>
      _AdminPaymentSettingsScreenState();
}

class _AdminPaymentSettingsScreenState extends State<AdminPaymentSettingsScreen> {
  final _service = PaymentSettingsService();
  final _formKey = GlobalKey<FormState>();
  final _holder = TextEditingController();
  final _provider = TextEditingController();
  final _account = TextEditingController();
  final _iban = TextEditingController();
  final _instructions = TextEditingController();
  final _whatsapp = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getSettings();
      _holder.text = data['accountHolder']?.toString() ?? '';
      _provider.text = data['provider']?.toString() ?? '';
      _account.text = data['accountNumber']?.toString() ?? '';
      _iban.text = data['iban']?.toString() ?? '';
      _instructions.text = data['instructions']?.toString() ?? '';
      _whatsapp.text = data['whatsappNumber']?.toString() ?? '';
    } catch (_) {
      if (mounted) _message('Unable to load payment settings.', true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.saveSettings(
        accountHolder: _holder.text,
        provider: _provider.text,
        accountNumber: _account.text,
        iban: _iban.text,
        instructions: _instructions.text,
        whatsappNumber: _whatsapp.text,
      );
      if (mounted) _message('Payment settings saved.', false);
    } catch (e) {
      if (mounted) _message(e.toString(), true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
      backgroundColor: error ? AtlasColors.error : AtlasColors.success,
    ));
  }

  @override
  void dispose() {
    for (final controller in [_holder, _provider, _account, _iban, _instructions, _whatsapp]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AtlasColors.ivory,
    appBar: AppBar(
      title: const Text('Payment & WhatsApp Settings'),
      backgroundColor: AtlasColors.ivory,
      foregroundColor: AtlasColors.navy,
      elevation: 0,
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AtlasColors.navy, AtlasColors.royalBlue]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.account_balance_rounded, color: AtlasColors.champagne, size: 30),
                SizedBox(height: 12),
                Text('Academy Payment Details', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('These details are displayed to students when they purchase a subscription.', style: TextStyle(color: Colors.white70, height: 1.5)),
              ]),
            ),
            const SizedBox(height: 22),
            _field(_holder, 'Account holder name', Icons.person_outline),
            _field(_provider, 'Bank / payment provider', Icons.account_balance_outlined),
            _field(_account, 'Account / wallet number', Icons.numbers_rounded),
            _field(_iban, 'IBAN (optional)', Icons.credit_card_rounded, required: false),
            _field(_whatsapp, 'WhatsApp number with country code', Icons.chat_rounded, hint: 'Example: 923001234567'),
            _field(_instructions, 'Payment instructions', Icons.notes_rounded, lines: 4, required: false),
            const SizedBox(height: 14),
            SizedBox(height: 54, child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving…' : 'Save Payment Settings'),
            )),
          ],
        ),
      ),
  );

  Widget _field(TextEditingController controller, String label, IconData icon, {bool required = true, int lines = 1, String? hint}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        validator: (value) => required && (value == null || value.trim().isEmpty) ? 'This field is required.' : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: lines == 1 ? Icon(icon) : null,
          alignLabelWithHint: lines > 1,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
}
