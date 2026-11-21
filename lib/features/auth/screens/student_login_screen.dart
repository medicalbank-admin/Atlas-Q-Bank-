import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_feedback.dart';
import '../../../shared/widgets/atlas_logo.dart';
import '../services/student_auth_service.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() =>
      _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final StudentAuthService _authService = StudentAuthService();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (!result.emailVerified) {
        await _showStatusDialog(
          icon: Icons.mark_email_unread_rounded,
          title: 'Verify Your Email',
          message:
              'Your account has been created, but your email address '
              'has not been verified. Please verify your email before '
              'continuing.',
          actionText: 'Resend Verification Email',
          onAction: _resendVerification,
        );
        return;
      }

      // AuthGate listens to Firebase authentication state and routes
      // verified students directly to the dashboard. Subscription status
      // controls paid content, not access to the student portal.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;

      AtlasFeedback.showError(
        context,
        _friendlyError(error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('invalid-credential') ||
        message.contains('wrong-password') ||
        message.contains('user-not-found')) {
      return 'Incorrect email or password.';
    }

    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }

    if (message.contains('network-request-failed')) {
      return 'Please check your internet connection.';
    }

    if (message.contains('permission-denied')) {
      return 'Unable to load your student profile. Please contact support.';
    }

    if (message.contains('profile-not-found')) {
      return 'Your student profile was not found. Please contact support.';
    }

    return 'Login failed. Please try again.';
  }

  Future<void> _showStatusDialog({
    required IconData icon,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AtlasColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
          icon: Icon(
            icon,
            color: AtlasColors.royalBlue,
            size: 48,
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AtlasColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AtlasColors.secondaryText,
              height: 1.6,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (onAction != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onAction();
                },
                child: Text(actionText ?? 'Continue'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resendVerification() async {
    try {
      await _authService.resendVerificationEmail();

      if (!mounted) return;

      AtlasFeedback.showSuccess(
        context,
        'Verification email sent. Please check your inbox.',
      );
    } catch (error) {
      if (!mounted) return;

      AtlasFeedback.showError(
        context,
        'Unable to send verification email. Please try again.',
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || _validateEmail(email) != null) {
      AtlasFeedback.showWarning(
        context,
        'Enter your registered email address first.',
      );
      return;
    }

    try {
      await _authService.sendPasswordReset(email: email);

      if (!mounted) return;

      AtlasFeedback.showSuccess(
        context,
        'If an account exists for this email, a password reset message will be sent.',
      );
    } catch (error) {
      if (!mounted) return;

      AtlasFeedback.showError(
        context,
        'Unable to process your request. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Navy and gold decorative header.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 25, 24, 34),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AtlasColors.navy,
                      AtlasColors.deepNavy,
                      AtlasColors.royalBlue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 82,
                      width: 82,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AtlasColors.champagne.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      child: const AtlasLogo(size: 68),
                    ),
                    const SizedBox(height: 19),
                    const Text(
                      'THE ATLAS ACADEMY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'LEARN  •  PREPARE  •  EXCEL',
                      style: TextStyle(
                        color: AtlasColors.champagne,
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            color: AtlasColors.navy,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue your journey',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AtlasColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AtlasColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          decoration: const InputDecoration(
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AtlasColors.royalBlue,
                            ),
                          ),
                        ),

                        const SizedBox(height: 21),

                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AtlasColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password.';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AtlasColors.royalBlue,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AtlasColors.secondaryText,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            SizedBox(
                              height: 38,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AtlasColors.navy,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: AtlasColors.charcoal,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _forgotPassword,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AtlasColors.royalBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AtlasColors.navy,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: AtlasColors.navy.withValues(
                                alpha: 0.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 23,
                                    height: 23,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(Icons.arrow_forward_rounded),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                              ),
                              child: Text(
                                'NEW TO THE ACADEMY?',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 18),

                        OutlinedButton(
                          onPressed: () => Navigator.maybePop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AtlasColors.navy,
                            backgroundColor: AtlasColors.white,
                            side: const BorderSide(
                              color: AtlasColors.royalBlue,
                            ),
                            minimumSize: const Size.fromHeight(53),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        const Text(
                          'EXCELLENCE IN MEDICAL EDUCATION',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AtlasColors.secondaryText,
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
