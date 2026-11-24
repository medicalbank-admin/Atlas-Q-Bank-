import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../advanced_learning/services/push_notification_service.dart';

class StudentNotificationSetupScreen extends StatefulWidget {
  const StudentNotificationSetupScreen({super.key, required this.onEnabled});
  final VoidCallback onEnabled;

  @override
  State<StudentNotificationSetupScreen> createState() => _StudentNotificationSetupScreenState();
}

class _StudentNotificationSetupScreenState extends State<StudentNotificationSetupScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _enable() async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try {
      final enabled = await PushNotificationService().requestAndRegisterNotifications(context);
      if (!mounted) return;
      if (enabled) {
        widget.onEnabled();
      } else {
        setState(() => _message = kIsWeb
            ? 'Notifications were not allowed. On iPhone, install The Atlas Academy on your Home Screen, open it there, and allow notifications. On other devices, enable notifications in your browser or app settings.'
            : 'Notifications are still turned off. Open your device Settings, allow notifications for The Atlas Academy, then tap “Check again”.');
      }
    } catch (error) {
      if (mounted) setState(() => _message = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkAgain() async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    final enabled = await PushNotificationService().checkAndRegisterNotifications();
    if (!mounted) return;
    setState(() => _busy = false);
    if (enabled) widget.onEnabled();
    else setState(() => _message = 'Permission has not been enabled yet. Please allow notifications in your device settings and check again.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.fromLTRB(25, 30, 25, 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFDCE8F5)),
                  boxShadow: const [BoxShadow(color: Color(0x120E315A), blurRadius: 24, offset: Offset(0, 9))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76, height: 76,
                      decoration: const BoxDecoration(color: Color(0xFFEAF3FF), shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1768C8), size: 39),
                    ),
                    const SizedBox(height: 22),
                    const Text('Stay Updated', textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF123B68), fontSize: 25, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    const Text('Enable notifications to stay connected with The Atlas Academy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF52647C), fontSize: 14, height: 1.5)),
                    const SizedBox(height: 22),
                    const _Benefit(icon: Icons.verified_user_rounded, text: 'Membership requests and approval updates'),
                    const _Benefit(icon: Icons.mark_chat_unread_rounded, text: 'Important messages from the academy'),
                    const _Benefit(icon: Icons.campaign_rounded, text: 'Announcements and important study updates'),
                    const SizedBox(height: 25),
                    SizedBox(width: double.infinity, height: 51,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _enable,
                        icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.notifications_active_outlined),
                        label: Text(_busy ? 'Please wait…' : 'Enable Stay Updated', style: const TextStyle(fontWeight: FontWeight.w800)),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1768C8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!, textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF9A541D), fontSize: 12, height: 1.45)),
                      TextButton(onPressed: _busy ? null : _checkAgain, child: const Text('I enabled it — Check again')),
                    ],
                    const SizedBox(height: 8),
                    const Text('You can change notification preferences later in your device settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7B8CA2), fontSize: 10, height: 1.4)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF168B69), size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF263B59), fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
  );
}
