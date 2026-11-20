import 'package:flutter/material.dart';

import '../../../app/atlas_academy_app.dart';
import '../../../shared/widgets/atlas_feedback.dart';
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

      if (result.isPendingApproval) {
        await _showStatusDialog(
          icon: Icons.hourglass_top_rounded,
          title: 'Application Under Review',
          message:
              'Your email is verified. Your student registration is '
              'awaiting administrator approval. You will receive '
              'access after your application has been reviewed.',
        );
        return;
      }

      if (result.isRejected) {
        await _showStatusDialog(
          icon: Icons.info_outline_rounded,
          title: 'Registration Not Approved',
          message:
              'Your registration has not been approved. Please '
              'contact The Atlas Academy administration for assistance.',
        );
        return;
      }

      if (!result.isApproved) {
        await _showStatusDialog(
          icon: Icons.lock_outline_rounded,
          title: 'Account Not Active',
          message:
              'Your account is not currently approved for student access. '
              'Please contact the academy administration.',
        );
        return;
      }

      if (!result.accessEnabled ||
          result.subscriptionStatus != 'active') {
        await _showStatusDialog(
          icon: Icons.workspace_premium_rounded,
          title: 'Membership Required',
          message:
              'Your student account is approved, but an active '
              'membership is required to access learning materials. '
              'Please visit the membership section.',
        );
        return;
      }

      await _showStatusDialog(
        icon: Icons.verified_rounded,
        title: 'Welcome to The Atlas Academy',
        message:
            'Your account is verified and your membership is active. '
            'Your student dashboard will be available once navigation '
            'is connected.',
      );
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
          icon: Icon(
            icon,
            color: AtlasColors.oceanTeal,
            size: 48,
          ),
          title: Text(
            title,
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 30,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 15),

                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AtlasColors.deepTeal,
                            AtlasColors.oceanTeal,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AtlasColors.deepTeal.withValues(
                              alpha: 0.20,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 45,
                        color: AtlasColors.champagne,
                      ),
                    ),

                    const SizedBox(height: 27),

                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AtlasColors.deepTeal,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 9),

                    const Text(
                      'Continue your medical learning journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AtlasColors.secondaryText,
                      ),
                    ),

                    const SizedBox(height: 38),

                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                          color: AtlasColors.oceanTeal,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                          color: AtlasColors.oceanTeal,
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
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        SizedBox(
                          height: 35,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AtlasColors.oceanTeal,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                        ),
                        const Text(
                          'Remember me',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _forgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AtlasColors.oceanTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AtlasColors.deepTeal,
                          foregroundColor: Colors.white,
                          elevation: 3,
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

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          child: Text(
                            'NEW TO THE ACADEMY?',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    OutlinedButton(
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AtlasColors.deepTeal,
                        side: const BorderSide(
                          color: AtlasColors.oceanTeal,
                        ),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Create Student Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'THE ATLAS ACADEMY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AtlasColors.secondaryText,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
