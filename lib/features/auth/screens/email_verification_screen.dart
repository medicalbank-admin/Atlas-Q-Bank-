import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_feedback.dart';
import '../services/student_auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    this.email,
  });

  final String? email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  final StudentAuthService _authService = StudentAuthService();

  bool _isChecking = false;
  bool _isResending = false;

  String get _email =>
      widget.email ??
      FirebaseAuth.instance.currentUser?.email ??
      'your registered email';

  Future<void> _checkVerification() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final isVerified =
          await _authService.refreshEmailVerification();

      if (!mounted) return;

      if (isVerified) {
        AtlasFeedback.showSuccess(
          context,
          'Your email has been verified successfully.',
        );

        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) return;

        Navigator.of(context).pop(true);
      } else {
        AtlasFeedback.showInfo(
          context,
          'Your email is not verified yet. Please check your inbox.',
        );
      }
    } catch (error) {
      if (mounted) {
        AtlasFeedback.showError(
          context,
          'Unable to check verification status. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    try {
      await _authService.resendVerificationEmail();

      if (!mounted) return;

      AtlasFeedback.showSuccess(
        context,
        'A new verification email has been sent.',
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      AtlasFeedback.showError(
        context,
        error.message ?? 'Could not send the verification email.',
      );
    } catch (_) {
      if (!mounted) return;

      AtlasFeedback.showError(
        context,
        'Could not send the verification email. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (_) {
      if (mounted) {
        AtlasFeedback.showError(
          context,
          'Unable to sign out. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AtlasColors.softTeal,
                      boxShadow: [
                        BoxShadow(
                          color: AtlasColors.deepTeal
                              .withValues(alpha: 0.10),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      size: 54,
                      color: AtlasColors.deepTeal,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AtlasColors.deepTeal,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'One final step before continuing your journey '
                    'with The Atlas Academy.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AtlasColors.softTeal.withValues(
                        alpha: 0.65,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AtlasColors.oceanTeal.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 28,
                          color: AtlasColors.deepTeal,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Verification link sent to',
                          style: TextStyle(
                            color: AtlasColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AtlasColors.deepTeal,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _InstructionRow(
                    number: '1',
                    text: 'Open your email inbox.',
                  ),
                  const _InstructionRow(
                    number: '2',
                    text: 'Find the email from The Atlas Academy.',
                  ),
                  const _InstructionRow(
                    number: '3',
                    text: 'Open the email and tap Verify Email.',
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _isChecking ? null : _checkVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtlasColors.deepTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'I Have Verified My Email',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed:
                          _isResending ? null : _resendVerification,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AtlasColors.deepTeal,
                        side: const BorderSide(
                          color: AtlasColors.oceanTeal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isResending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Resend Verification Email',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                    style: TextButton.styleFrom(
                      foregroundColor: AtlasColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If you cannot find the email, check your spam '
                    'or junk folder.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AtlasColors.secondaryText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AtlasColors.softTeal,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AtlasColors.deepTeal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
